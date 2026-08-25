import 'exact_matcher.dart';
import 'vector_service.dart';
import 'document_processor.dart';
import 'gemini_service.dart';
import 'search_provider.dart';
import '../models/match_evidence.dart';
import '../models/flagged_section.dart';
import '../models/search_result.dart';
import 'dart:developer' as dev;

class DetectionEngine {
  DetectionEngine._();
  static final instance = DetectionEngine._();

  static const int maxWebSearchChunks = 5;

  /// Orchestrates the hybrid detection pipeline for a document.
  /// Returns a tuple of (evidence found, chunks with embeddings for storage).
  Future<(List<MatchEvidence>, List<DocumentChunk>)> analyzeDocument({
    required String text,
    String? userId,
    bool checkSelfPlagiarism = true,
    String? compareWithDocumentId,
    String? currentDocumentId,
    String? compareWithDocumentText,
    SearchProvider? searchProvider,
  }) async {
    final List<MatchEvidence> allEvidence = [];
    final provider = searchProvider ?? GoogleSearchProvider();
    
    dev.log('DetectionEngine: Starting analysis');
    
    // 1. Chunking (Precise offsets)
    final chunks = DocumentProcessor.instance.chunkDocument(text);
    dev.log('DetectionEngine: Split into ${chunks.length} chunks');

    // 2. Batch Embedding (Speed Optimization)
    final List<String> textsToEmbed = chunks.map((c) => c.text).toList();
    
    // Safety check: Gemini has a 100-request limit for batch embedding.
    // If we have more than 100 chunks, we process in mini-batches.
    final List<List<double>> embeddings = [];
    for (int i = 0; i < textsToEmbed.length; i += 100) {
      final end = (i + 100 < textsToEmbed.length) ? i + 100 : textsToEmbed.length;
      final batch = textsToEmbed.sublist(i, end);
      final batchRes = await GeminiService.instance.batchEmbedTexts(batch);
      embeddings.addAll(batchRes);
    }
    
    for (int i = 0; i < chunks.length; i++) {
      chunks[i].embedding = embeddings[i];
    }

    // 3. Batch Vector Search (Ultra-Speed Optimization)
    final Map<int, List<MatchEvidence>> semanticResultsMap = await VectorService.instance.searchSimilarChunksBatch(
      embeddings: chunks.map((c) => c.embedding!).toList(),
      targetDocumentId: compareWithDocumentId,
      excludeDocumentId: currentDocumentId,
    );

    // 4. Local Exact Matching & Evidence Merging
    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      MatchEvidence? mergedMatch;

      // Local Exact Match
      if (compareWithDocumentText != null) {
        final exactMatches = ExactMatcher.findMatches(
          submittedText: chunk.text,
          sourceText: compareWithDocumentText,
          baseOffset: chunk.startOffset,
        );
        if (exactMatches.isNotEmpty) mergedMatch = exactMatches.first;
      }

      // Merge Semantic Results
      final semanticResults = semanticResultsMap[i] ?? [];
      for (final match in semanticResults) {
        if (mergedMatch == null) {
          mergedMatch = MatchEvidence(
            submittedText: chunk.text,
            matchedText: match.matchedText,
            sourceTitle: match.sourceTitle,
            sourceUrl: match.sourceUrl,
            signals: [PlagiarismType.semanticSimilarity],
            semanticSimilarity: match.semanticSimilarity,
            startOffset: chunk.startOffset,
            endOffset: chunk.endOffset,
            pageNumber: chunk.pageNumber,
            paragraphNumber: chunk.paragraphNumber,
            sentenceNumber: chunk.sentenceNumber,
            reason: 'Semantic similarity detected (${(match.semanticSimilarity * 100).toStringAsFixed(1)}%)',
          );
        } else {
          if (!mergedMatch.signals.contains(PlagiarismType.semanticSimilarity)) {
            mergedMatch.signals.add(PlagiarismType.semanticSimilarity);
          }
        }
      }

      if (mergedMatch != null) allEvidence.add(mergedMatch);
    }

    // 5. Parallel Web Discovery (Speed & Robustness Optimization)
    // Identify top N suspicious or distinctive chunks
    final candidateChunks = _rankSuspiciousChunks(chunks, allEvidence).take(maxWebSearchChunks).toList();
    
    final List<Future<List<SearchResult>>> webSearchFutures = [];
    
    for (final chunk in candidateChunks) {
      // Use Robust Multi-Query Discovery
      final queries = _generateRobustQueries(chunk.text);
      webSearchFutures.add(_robustSearch(provider, queries));
    }

    final List<List<SearchResult>> webResultsList = await Future.wait(webSearchFutures);

    for (int i = 0; i < candidateChunks.length; i++) {
      final chunk = candidateChunks[i];
      final webResults = webResultsList[i];

      if (webResults.isNotEmpty) {
        // Snippet Verification: Ensure the snippet actually matches some of the text
        final topResult = webResults.first;
        final overlap = _calculateOverlap(chunk.text, topResult.snippet);
        
        if (overlap < 0.4) { // Requires 40% significant word overlap
          dev.log('DetectionEngine: Discarding weak web result (Overlap: ${(overlap*100).toStringAsFixed(1)}%)');
          continue; 
        }
        
        int existingIdx = allEvidence.indexWhere((e) => e.startOffset == chunk.startOffset);
        MatchEvidence existingMatch = existingIdx != -1 
          ? allEvidence[existingIdx]
          : MatchEvidence(
              submittedText: chunk.text,
              signals: [],
              startOffset: chunk.startOffset,
              endOffset: chunk.endOffset,
              pageNumber: chunk.pageNumber,
              paragraphNumber: chunk.paragraphNumber,
              sentenceNumber: chunk.sentenceNumber,
            );

        final updatedMatch = MatchEvidence(
          submittedText: existingMatch.submittedText,
          matchedText: existingMatch.matchedText ?? topResult.snippet,
          sourceTitle: topResult.title,
          sourceUrl: topResult.url,
          domain: topResult.domain,
          signals: [...existingMatch.signals, PlagiarismType.webDiscovery],
          exactSimilarity: existingMatch.exactSimilarity,
          semanticSimilarity: existingMatch.semanticSimilarity,
          webSimilarity: overlap,
          confidence: existingMatch.confidence,
          startOffset: existingMatch.startOffset,
          endOffset: existingMatch.endOffset,
          pageNumber: existingMatch.pageNumber,
          paragraphNumber: existingMatch.paragraphNumber,
          sentenceNumber: existingMatch.sentenceNumber,
          discoveryStatus: DiscoveryStatus.discovered,
          reason: '${existingMatch.reason ?? ""} Web match: ${topResult.url}'.trim(),
        );

        if (existingIdx != -1) {
          allEvidence[existingIdx] = updatedMatch;
        } else {
          allEvidence.add(updatedMatch);
        }
      }
    }

    dev.log('DetectionEngine: Analysis complete, found ${allEvidence.length} pieces of evidence');
    return (allEvidence, chunks);
  }

  /// Tries multiple queries sequentially (Quoted -> Keywords) for one chunk
  Future<List<SearchResult>> _robustSearch(SearchProvider provider, List<String> queries) async {
    for (final q in queries) {
      final results = await provider.search(q);
      if (results.isNotEmpty) return results;
    }
    return [];
  }

  /// Ranks chunks based on distinctiveness and existing similarity flags.
  List<DocumentChunk> _rankSuspiciousChunks(List<DocumentChunk> chunks, List<MatchEvidence> existingEvidence) {
    final List<DocumentChunk> sorted = List.from(chunks);
    
    sorted.sort((a, b) {
      final evA = existingEvidence.any((e) => e.startOffset == a.startOffset);
      final evB = existingEvidence.any((e) => e.startOffset == b.startOffset);
      
      if (evA && !evB) return -1;
      if (!evA && evB) return 1;

      return b.text.length.compareTo(a.text.length);
    });

    return sorted;
  }

  /// Generates a list of queries (Quoted exact phrase + distinctive keywords)
  List<String> _generateRobustQueries(String text) {
    final List<String> queries = [];
    String base = text.trim();
    if (base.length > 150) base = base.substring(0, 150);
    
    // 1. Quoted exact phrase (Precision)
    queries.add('"$base"');
    
    // 2. Distinctive keywords (Recall)
    final keywords = base.split(' ')
        .where((w) => w.length > 4) 
        .take(8) 
        .join(' ');
    if (keywords.isNotEmpty) queries.add(keywords);
    
    return queries;
  }

  /// Word-level Jaccard similarity for snippet verification.
  double _calculateOverlap(String chunkText, String snippet) {
    final cleanChunk = chunkText.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final cleanSnippet = snippet.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    
    final chunkWords = cleanChunk.split(' ').where((w) => w.length > 3).toSet();
    final snippetWords = cleanSnippet.split(' ').where((w) => w.length > 3).toSet();
    
    if (chunkWords.isEmpty || snippetWords.isEmpty) return 0.0;
    
    final intersection = chunkWords.intersection(snippetWords);
    return intersection.length / chunkWords.length;
  }
}
