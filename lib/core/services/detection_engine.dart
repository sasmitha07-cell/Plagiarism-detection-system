import 'exact_matcher.dart';
import 'vector_service.dart';
import 'document_processor.dart';
import 'gemini_service.dart';
import 'search_provider.dart';
import 'citation_detector.dart';
import 'common_phrase_filter.dart';
import '../models/match_evidence.dart';
import '../models/flagged_section.dart';
import '../models/search_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as dev;
import 'dart:math' as math;

class DetectionEngine {
  DetectionEngine._();
  static final instance = DetectionEngine._();

  static const int maxWebSearchChunks = 5;

  /// Orchestrates the multi-layer evidence detection pipeline.
  /// Returns a tuple of (collected verified evidence, chunks with embeddings).
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

    dev.log('DetectionEngine: Starting multi-layer evidence analysis');

    // 1. Chunking with precise character offsets
    final chunks = DocumentProcessor.instance.chunkDocument(text);
    dev.log('DetectionEngine: Split into ${chunks.length} chunks');

    // 2. Pre-scan for quotations and academic citations
    final quotations = CitationDetector.instance.detectQuotations(text);
    final citations = CitationDetector.instance.detectCitations(text);
    dev.log('DetectionEngine: Detected ${quotations.length} quotes and ${citations.length} citation markers');

    // 3. Batch Embeddings (Gemini Embedding 2 in batches of 100)
    final List<String> textsToEmbed = chunks.map((c) => c.text).toList();
    final List<List<double>> embeddings = [];
    try {
      for (int i = 0; i < textsToEmbed.length; i += 100) {
        final end = (i + 100 < textsToEmbed.length) ? i + 100 : textsToEmbed.length;
        final batch = textsToEmbed.sublist(i, end);
        final batchRes = await GeminiService.instance.batchEmbedTexts(batch);
        embeddings.addAll(batchRes);
      }

      for (int i = 0; i < chunks.length && i < embeddings.length; i++) {
        chunks[i].embedding = embeddings[i];
      }
    } catch (e) {
      dev.log('DetectionEngine: Batch embedding note: $e');
    }

    // 4. Batch Vector Search (Self-Plagiarism and Cross-Document Matching)
    Map<int, List<MatchEvidence>> semanticResultsMap = {};
    if (embeddings.isNotEmpty) {
      try {
        semanticResultsMap = await VectorService.instance.searchSimilarChunksBatch(
          embeddings: chunks.where((c) => c.embedding != null).map((c) => c.embedding!).toList(),
          targetDocumentId: compareWithDocumentId,
          excludeDocumentId: currentDocumentId,
          userId: checkSelfPlagiarism ? userId : null,
        );
      } catch (e) {
        dev.log('DetectionEngine: Vector search fallback note: $e');
      }
    }

    // Store chunks in database for future self-plagiarism checking
    if (currentDocumentId != null && userId != null && !currentDocumentId.startsWith('demo_')) {
      try {
        final chunkPayloads = chunks.map((c) => {
          'document_id': currentDocumentId,
          'user_id': userId,
          'content': c.text,
          if (c.embedding != null) 'embedding': c.embedding,
          'page_number': c.pageNumber,
          'paragraph_number': c.paragraphNumber,
          'sentence_number': c.sentenceNumber,
        }).toList();
        await VectorService.instance.storeChunks(chunkPayloads);
      } catch (e) {
        dev.log('DetectionEngine: Chunk indexing in DB note: $e');
      }
    }

    // 5. Local Exact Matching & Evidence Aggregation
    // Check against previous documents for self-plagiarism
    List<Map<String, dynamic>> previousDocs = [];
    if (checkSelfPlagiarism && userId != null && !userId.startsWith('demo_') && userId != 'anonymous') {
      try {
        final docs = await Supabase.instance.client
            .from('documents')
            .select('id, title, content')
            .eq('user_id', userId)
            .neq('id', currentDocumentId ?? '')
            .limit(10);
        if (docs is List) {
          previousDocs = List<Map<String, dynamic>>.from(docs);
        }
      } catch (e) {
        dev.log('DetectionEngine: Note querying user documents for self-plagiarism: $e');
      }
    }

    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      MatchEvidence? mergedMatch;

      // Local Exact Match (if comparing against another specific document text)
      if (compareWithDocumentText != null) {
        final exactMatches = ExactMatcher.findMatches(
          submittedText: chunk.text,
          sourceText: compareWithDocumentText,
          baseOffset: chunk.startOffset,
        );
        if (exactMatches.isNotEmpty) {
          mergedMatch = exactMatches.first;
        }
      }

      // Check against previous documents in the user's repository
      if (mergedMatch == null && previousDocs.isNotEmpty) {
        for (final prevDoc in previousDocs) {
          final prevContent = prevDoc['content'] as String? ?? '';
          if (prevContent.trim().isNotEmpty) {
            final matches = ExactMatcher.findMatches(
              submittedText: chunk.text,
              sourceText: prevContent,
              sourceTitle: prevDoc['title'] as String? ?? 'Your Previous Document',
              baseOffset: chunk.startOffset,
            );
            if (matches.isNotEmpty) {
              final m = matches.first;
              mergedMatch = MatchEvidence(
                submittedText: m.submittedText,
                matchedText: m.matchedText,
                sourceTitle: prevDoc['title'] as String? ?? 'Your Previous Document',
                signals: [PlagiarismType.selfPlagiarism, PlagiarismType.exactCopy],
                exactSimilarity: 1.0,
                selfPlagiarismSimilarity: 1.0,
                confidence: 0.98,
                startOffset: m.startOffset,
                endOffset: m.endOffset,
                pageNumber: chunk.pageNumber,
                paragraphNumber: chunk.paragraphNumber,
                sentenceNumber: chunk.sentenceNumber,
                classification: EvidenceClassification.possibleSelfPlagiarism,
                reason: 'Passage is identical to text in your previous document "${prevDoc['title']}".',
              );
              break;
            }
          }
        }
      }

      // Merge Semantic Results
      final semanticResults = semanticResultsMap[i] ?? [];
      for (final match in semanticResults) {
        if (mergedMatch == null) {
          final isSelf = match.signals.contains(PlagiarismType.selfPlagiarism);
          mergedMatch = MatchEvidence(
            submittedText: chunk.text,
            matchedText: match.matchedText,
            sourceTitle: match.sourceTitle ?? (isSelf ? 'Your Previous Document' : 'Repository Document'),
            sourceUrl: match.sourceUrl,
            signals: [isSelf ? PlagiarismType.selfPlagiarism : PlagiarismType.semanticSimilarity],
            semanticSimilarity: match.semanticSimilarity,
            selfPlagiarismSimilarity: match.selfPlagiarismSimilarity,
            startOffset: chunk.startOffset,
            endOffset: chunk.endOffset,
            pageNumber: chunk.pageNumber,
            paragraphNumber: chunk.paragraphNumber,
            sentenceNumber: chunk.sentenceNumber,
            classification: isSelf
                ? EvidenceClassification.possibleSelfPlagiarism
                : EvidenceClassification.semanticParaphrase,
            reason: isSelf
                ? 'Passage appears in one of your previously submitted documents (${(match.semanticSimilarity * 100).toStringAsFixed(1)}% similarity).'
                : 'Semantic paraphrase detected (${(match.semanticSimilarity * 100).toStringAsFixed(1)}% conceptual similarity).',
          );
        } else {
          if (!mergedMatch.signals.contains(PlagiarismType.semanticSimilarity)) {
            mergedMatch.signals.add(PlagiarismType.semanticSimilarity);
          }
        }
      }

      if (mergedMatch != null) {
        allEvidence.add(mergedMatch);
      }
    }

    // 6. Selective Web Evidence Discovery
    final candidateChunks = _rankSuspiciousChunks(chunks, allEvidence).take(maxWebSearchChunks).toList();
    final List<Future<List<SearchResult>>> webSearchFutures = [];

    for (final chunk in candidateChunks) {
      final queries = _generateRobustQueries(chunk.text);
      webSearchFutures.add(_robustSearch(provider, queries));
    }

    final List<List<SearchResult>> webResultsList = await Future.wait(webSearchFutures);

    for (int i = 0; i < candidateChunks.length; i++) {
      final chunk = candidateChunks[i];
      final webResults = webResultsList[i];

      if (webResults.isNotEmpty) {
        SearchResult? bestResult;
        double bestOverlap = 0.0;

        for (final res in webResults) {
          final overlap = _calculateOverlap(chunk.text, res.snippet.isNotEmpty ? res.snippet : res.title);
          if (overlap > bestOverlap) {
            bestOverlap = overlap;
            bestResult = res;
          }
        }

        if (bestResult == null || bestOverlap < 0.20) {
          dev.log('DetectionEngine: Discarding weak web result (Best overlap: ${(bestOverlap * 100).toStringAsFixed(1)}%)');
          continue;
        }

        final topResult = bestResult;
        final overlap = bestOverlap;

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

        final isAcademic = topResult.sourceType == 'academic' ||
            topResult.domain.contains('doi.org') ||
            topResult.domain.contains('crossref') ||
            topResult.domain.contains('arxiv') ||
            topResult.domain.contains('sciencedirect');

        final updatedMatch = MatchEvidence(
          submittedText: existingMatch.submittedText,
          matchedText: topResult.snippet.isNotEmpty ? topResult.snippet : existingMatch.matchedText,
          sourceTitle: topResult.title,
          sourceUrl: topResult.url,
          domain: topResult.domain,
          signals: [...existingMatch.signals, PlagiarismType.webDiscovery],
          exactSimilarity: existingMatch.exactSimilarity,
          semanticSimilarity: existingMatch.semanticSimilarity,
          webSimilarity: overlap,
          selfPlagiarismSimilarity: existingMatch.selfPlagiarismSimilarity,
          confidence: 0.90,
          startOffset: existingMatch.startOffset,
          endOffset: existingMatch.endOffset,
          pageNumber: existingMatch.pageNumber,
          paragraphNumber: existingMatch.paragraphNumber,
          sentenceNumber: existingMatch.sentenceNumber,
          discoveryStatus: DiscoveryStatus.verified,
          classification: EvidenceClassification.verifiedWebMatch,
          reason: isAcademic
              ? 'Verified academic source match on ${topResult.domain}: ${(overlap * 100).toStringAsFixed(0)}% content overlap.'
              : 'Verified match on ${topResult.domain}: ${(overlap * 100).toStringAsFixed(0)}% distinctive content overlap.',
        );

        if (existingIdx != -1) {
          allEvidence[existingIdx] = updatedMatch;
        } else {
          allEvidence.add(updatedMatch);
        }
      }
    }

    // 7. Citation Context & Common Phrase Verification
    final List<MatchEvidence> verifiedEvidence = [];
    for (final ev in allEvidence) {
      final context = CitationDetector.instance.inspectContext(text, ev.startOffset, ev.endOffset);
      final isCommon = CommonPhraseFilter.instance.isCommonAcademicPhrase(ev.submittedText);

      EvidenceClassification finalClassification = ev.classification;
      String explainReason = ev.reason ?? 'Textual overlap identified.';
      List<PlagiarismType> finalSignals = List.from(ev.signals);

      if (context.isQuoted && context.isCited) {
        finalClassification = EvidenceClassification.quotedAndCited;
        if (!finalSignals.contains(PlagiarismType.quotedAndCited)) {
          finalSignals.add(PlagiarismType.quotedAndCited);
        }
        explainReason = 'Legitimate quotation with valid citation (${context.citation ?? "cited reference"}).';
      } else if (isCommon) {
        finalClassification = EvidenceClassification.commonAcademicPhrase;
        explainReason = 'Standard academic discourse phrase with no plagiarism penalty.';
      } else if (context.isCited && !context.isQuoted && ev.exactSimilarity > 0.8) {
        explainReason = 'Source is cited (${context.citation}), but verbatim text should be enclosed in quotation marks.';
      }

      verifiedEvidence.add(MatchEvidence(
        submittedText: ev.submittedText,
        matchedText: ev.matchedText,
        sourceUrl: ev.sourceUrl,
        sourceTitle: ev.sourceTitle,
        domain: ev.domain,
        signals: finalSignals,
        exactSimilarity: ev.exactSimilarity,
        semanticSimilarity: ev.semanticSimilarity,
        webSimilarity: ev.webSimilarity,
        selfPlagiarismSimilarity: ev.selfPlagiarismSimilarity,
        confidence: ev.confidence,
        reason: explainReason,
        startOffset: ev.startOffset,
        endOffset: ev.endOffset,
        sourceStartOffset: ev.sourceStartOffset,
        sourceEndOffset: ev.sourceEndOffset,
        pageNumber: ev.pageNumber,
        paragraphNumber: ev.paragraphNumber,
        sentenceNumber: ev.sentenceNumber,
        discoveryStatus: ev.discoveryStatus,
        classification: finalClassification,
        isQuoted: context.isQuoted,
        isCited: context.isCited,
        isCommonPhrase: isCommon,
        matchedCitation: context.citation,
      ));
    }

    dev.log('DetectionEngine: Verified ${verifiedEvidence.length} multi-layer evidence items');
    return (verifiedEvidence, chunks);
  }

  /// Tries multiple queries sequentially (Quoted exact phrase -> Distinctive keywords)
  Future<List<SearchResult>> _robustSearch(SearchProvider provider, List<String> queries) async {
    for (final q in queries) {
      final results = await provider.search(q);
      if (results.isNotEmpty) return results;
    }
    return [];
  }

  /// Ranks chunks based on distinctiveness and existing similarity flags
  List<DocumentChunk> _rankSuspiciousChunks(List<DocumentChunk> chunks, List<MatchEvidence> existingEvidence) {
    final List<DocumentChunk> sorted = List.from(chunks);

    sorted.sort((a, b) {
      final evA = existingEvidence.any((e) => e.startOffset == a.startOffset);
      final evB = existingEvidence.any((e) => e.startOffset == b.startOffset);

      if (evA && !evB) return -1;
      if (!evA && evB) return 1;

      final distA = CommonPhraseFilter.instance.computeDistinctivenessScore(a.text);
      final distB = CommonPhraseFilter.instance.computeDistinctivenessScore(b.text);

      return distB.compareTo(distA);
    });

    return sorted;
  }

  /// Generates precision queries for web evidence discovery without mid-word cut-offs
  List<String> _generateRobustQueries(String text) {
    final List<String> queries = [];
    final clean = text.trim();

    // 1. Identify complete sentences or distinctive clauses
    final sentences = clean
        .split(RegExp(r'[.!?\n]+'))
        .map((s) => s.trim())
        .where((s) => s.split(RegExp(r'\s+')).length >= 4)
        .toList();

    // Sort by distinctive words (highest distinctiveness first)
    sentences.sort((a, b) {
      final distA = CommonPhraseFilter.instance.computeDistinctivenessScore(a);
      final distB = CommonPhraseFilter.instance.computeDistinctivenessScore(b);
      return distB.compareTo(distA);
    });

    final targetSentence = sentences.isNotEmpty ? sentences.first : clean;
    final words = targetSentence.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    // 2. Distinctive high-entropy keywords (unquoted works best with search APIs)
    final distinctiveWords = words
        .where((w) => w.length > 3 && !CommonPhraseFilter.instance.isCommonAcademicPhrase(w))
        .take(7)
        .join(' ');
    if (distinctiveWords.isNotEmpty) {
      queries.add(distinctiveWords);
    }

    // 3. Quoted exact phrase of 5 to 7 distinctive words
    if (words.length >= 5) {
      final quotedWords = words.take(6).join(' ').replaceAll('"', '');
      queries.add('"$quotedWords"');
    }

    // 4. Fallback: clean sentence without quotes if reasonably sized
    if (targetSentence.length < 80 && !queries.contains(targetSentence)) {
      queries.add(targetSentence.replaceAll('"', ''));
    }

    return queries;
  }

  /// Word-level and sentence-level containment overlap for snippet verification
  double _calculateOverlap(String chunkText, String snippet) {
    final cleanSnippetRaw = snippet
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&');

    final cleanChunk = chunkText.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final cleanSnippet = cleanSnippetRaw.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    // 1. Substring / 4-word n-gram check
    final chunkTokens = cleanChunk.split(' ').where((w) => w.length > 2).toList();
    double ngramMatchScore = 0.0;
    if (chunkTokens.length >= 4) {
      for (int i = 0; i <= chunkTokens.length - 4; i++) {
        final phrase = chunkTokens.sublist(i, i + 4).join(' ');
        if (cleanSnippet.contains(phrase)) {
          ngramMatchScore = 0.75;
          break;
        }
      }
    }

    // 2. Distinctive word set intersection
    final chunkWords = cleanChunk.split(' ').where((w) => w.length > 3).toSet();
    final snippetWords = cleanSnippet.split(' ').where((w) => w.length > 3).toSet();

    if (chunkWords.isEmpty || snippetWords.isEmpty) return ngramMatchScore;

    final intersection = chunkWords.intersection(snippetWords);
    if (intersection.isEmpty) return ngramMatchScore;

    // Snippet containment score (proportion of distinctive snippet words present in chunk)
    final snippetContainment = intersection.length / snippetWords.length;

    // Chunk containment score (proportion of chunk matched)
    final chunkContainment = intersection.length / chunkWords.length;

    // Sentence-level containment: check if snippet matches any individual sentence
    double sentenceScore = 0.0;
    final sentences = chunkText.split(RegExp(r'[.!?\n]+')).where((s) => s.trim().length > 15);
    for (final s in sentences) {
      final sWords = s.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').split(' ').where((w) => w.length > 3).toSet();
      if (sWords.isNotEmpty) {
        final sInter = sWords.intersection(snippetWords);
        final score = sInter.length / math.min(sWords.length, snippetWords.length);
        if (score > sentenceScore) sentenceScore = score;
      }
    }

    final bestOverlap = math.max(
      ngramMatchScore,
      math.max(sentenceScore, math.max(snippetContainment * 0.85, chunkContainment)),
    );
    return bestOverlap.clamp(0.0, 1.0);
  }

  /// Computes a transparent, explainable mathematical integrity report based on verified evidence
  Map<String, dynamic> computeDeterministicReport({
    required String text,
    required List<MatchEvidence> evidence,
    required List<DocumentChunk> chunks,
  }) {
    if (chunks.isEmpty || text.trim().isEmpty) {
      return {
        'overall_similarity_score': 0.0,
        'exact_match_score': 0.0,
        'semantic_similarity_score': 0.0,
        'paraphrase_score': 0.0,
        'flagged_sections': [],
        'executive_summary': 'No text content available for analysis.',
        'recommendations': ['Submit an academic document to generate an originality assessment.'],
      };
    }

    final tokenSpans = ExactMatcher.tokenizeWithOffsets(text);
    final totalTokens = math.max(1, tokenSpans.length);

    final matchedIndices = <int>{};
    final exactIndices = <int>{};
    final webIndices = <int>{};
    final selfIndices = <int>{};
    final semanticIndices = <int>{};

    final flaggedSections = <Map<String, dynamic>>[];

    for (final ev in evidence) {
      final isExempt = ev.classification == EvidenceClassification.quotedAndCited ||
          ev.classification == EvidenceClassification.commonAcademicPhrase;

      for (int i = 0; i < tokenSpans.length; i++) {
        final t = tokenSpans[i];
        if (t.startOffset >= ev.startOffset && t.endOffset <= ev.endOffset) {
          if (!isExempt) {
            matchedIndices.add(i);
            if (ev.signals.contains(PlagiarismType.exactCopy)) exactIndices.add(i);
            if (ev.signals.contains(PlagiarismType.webDiscovery)) webIndices.add(i);
            if (ev.signals.contains(PlagiarismType.selfPlagiarism)) selfIndices.add(i);
            if (ev.signals.contains(PlagiarismType.semanticSimilarity) ||
                ev.signals.contains(PlagiarismType.paraphrased)) {
              semanticIndices.add(i);
            }
          }
        }
      }

      final rawScore = (ev.exactSimilarity > 0
          ? ev.exactSimilarity
          : (ev.webSimilarity > 0 ? ev.webSimilarity : ev.semanticSimilarity)) * 100;

      final risk = isExempt
          ? 'safe'
          : (rawScore > 65 ? 'critical' : (rawScore > 40 ? 'high' : (rawScore > 20 ? 'medium' : 'low')));

      flaggedSections.add({
        'start_position': ev.startOffset,
        'end_position': ev.endOffset,
        'flagged_text': ev.submittedText,
        'risk_level': risk,
        'confidence_score': (ev.confidence * 100).round(),
        'similarity_score': rawScore.round(),
        'source_url': ev.sourceUrl,
        'source_title': ev.sourceTitle ?? 'Database / Web Source',
        'domain': ev.domain,
        'signals': ev.signals.map((s) => s.name).toList(),
        'explanation': ev.reason ?? 'Similarity detected against external literature.',
        'suggested_action': isExempt
            ? 'Quotation and citation verified. No revision needed.'
            : (ev.signals.contains(PlagiarismType.selfPlagiarism)
                ? 'Attribute previous work or cite prior publication.'
                : 'Rephrase in scholarly voice or add formal academic citation.'),
      });
    }

    double overall = 0.0;
    double exactScore = 0.0;
    double webScore = 0.0;
    double selfScore = 0.0;
    double semanticScore = 0.0;
    double paraphraseScore = 0.0;

    if (flaggedSections.isNotEmpty) {
      if (matchedIndices.isNotEmpty) {
        overall = ((matchedIndices.length / totalTokens) * 100).clamp(0.0, 100.0);
        exactScore = ((exactIndices.length / totalTokens) * 100).clamp(0.0, 100.0);
        webScore = ((webIndices.length / totalTokens) * 100).clamp(0.0, 100.0);
        selfScore = ((selfIndices.length / totalTokens) * 100).clamp(0.0, 100.0);
        semanticScore = ((semanticIndices.length / totalTokens) * 100).clamp(0.0, 100.0);
        paraphraseScore = ((semanticScore + (webScore > 0 && exactScore < webScore ? (webScore - exactScore) : 0)) / 1.5).clamp(0.0, 100.0);
      } else {
        final penalizedChunks = evidence.where((e) =>
          e.classification != EvidenceClassification.quotedAndCited &&
          e.classification != EvidenceClassification.commonAcademicPhrase
        ).length;
        overall = ((penalizedChunks / chunks.length) * 100).clamp(0.0, 100.0);
        exactScore = evidence.any((e) => e.signals.contains(PlagiarismType.exactCopy)) ? overall : 0.0;
        webScore = evidence.any((e) => e.signals.contains(PlagiarismType.webDiscovery)) ? overall : 0.0;
        semanticScore = overall;
        paraphraseScore = overall * 0.8;
      }
    }

    final double roundedOverall = double.parse(overall.toStringAsFixed(1));
    final double roundedExact = double.parse(exactScore.toStringAsFixed(1));
    final double roundedSemantic = double.parse(semanticScore.toStringAsFixed(1));
    final double roundedParaphrase = double.parse(paraphraseScore.toStringAsFixed(1));

    String summary;
    if (roundedOverall == 0.0) {
      summary = 'Academic Integrity Verification: The submitted document ($totalTokens words across ${chunks.length} section(s)) demonstrated 100% originality with zero detected verbatim matches or unattributed passages. All content adheres to standard academic integrity benchmarks.';
    } else if (roundedOverall < 20.0) {
      summary = 'Low Similarity Index (${roundedOverall}%). Detected ${flaggedSections.length} minor passage(s) with external or internal similarity. Document demonstrates strong original authorship with small areas to verify attribution.';
    } else if (roundedOverall < 50.0) {
      summary = 'Moderate Similarity Alert (${roundedOverall}%). Detected ${flaggedSections.length} passage(s) matching external web sources or prior documents. Review highlighted sections and incorporate formal citations or quotation marks.';
    } else {
      summary = 'Substantial Similarity Detected (${roundedOverall}%). A significant portion ($matchedIndices tokens of $totalTokens) matches external literature or existing submissions. Immediate academic revision and attribution are required.';
    }

    return {
      'overall_similarity_score': roundedOverall,
      'exact_match_score': roundedExact,
      'semantic_similarity_score': roundedSemantic,
      'paraphrase_score': roundedParaphrase,
      'flagged_sections': flaggedSections,
      'executive_summary': summary,
      'recommendations': [
        'Review the flagged passages in the interactive Document Viewer.',
        'Use the AI Writing Coach Studio to polish academic phrasing and strengthen arguments.',
        'Ensure all external citations conform to your target style guide (APA/MLA/IEEE/Chicago).',
      ],
    };
  }

  /// Evaluates statistical AI-writing indicators with cautious, accurate, non-absolute framing
  Map<String, dynamic> estimateAiProbability(String text) {
    final cleanText = text.trim();
    final words = cleanText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final totalWords = words.length;

    if (totalWords < 30) {
      return {
        'ai_score': 0.0,
        'human_score': 100.0,
        'confidence': 50.0,
        'reasoning': 'Text sample is too brief for statistical linguistic assessment.',
      };
    }

    final lower = cleanText.toLowerCase();

    // 1. Generic AI transition markers and cliches
    const aiMarkers = [
      'in conclusion', 'it is crucial to', 'it is important to note', 'delve into', 'delves into',
      'a testament to', 'plays a pivotal role', 'tapestry of', 'multifaceted nature',
      'paramount importance', 'underscores the need', 'beacon of hope', 'fosters a sense',
      'seamlessly integrated', 'as an ai language model', 'in summary, it is evident',
    ];

    int aiMarkerCount = 0;
    for (final m in aiMarkers) {
      if (lower.contains(m)) aiMarkerCount++;
    }

    // 2. Human indicators (casual colloquialisms, contractions, informal phrasal verbs)
    const humanMarkers = [
      'kids', 'stuff', 'things', 'crazy', 'huge', 'a lot of', 'lots of', 'look into',
      'pretty much', 'kind of', 'sort of', 'gonna', 'wanna', 'totally', 'awesome',
      "didn't", "can't", "won't", "i'm", "we've", "you're",
    ];

    int humanMarkerCount = 0;
    for (final hm in humanMarkers) {
      if (RegExp(r'\b' + RegExp.escape(hm) + r'\b', caseSensitive: false).hasMatch(lower)) {
        humanMarkerCount++;
      }
    }

    // 3. Sentence Length Variance / Burstiness (requires >= 4 sentences)
    final sentences = cleanText.split(RegExp(r'[.!?]+')).where((s) => s.trim().length > 5).toList();
    double burstinessBonus = 0.0;
    if (sentences.length >= 4 && totalWords >= 70) {
      final lengths = sentences.map((s) => s.trim().split(RegExp(r'\s+')).length).toList();
      final avg = lengths.reduce((a, b) => a + b) / lengths.length;
      final variance = lengths.map((l) => (l - avg) * (l - avg)).reduce((a, b) => a + b) / lengths.length;
      final burstiness = (variance / (avg + 1)).clamp(0.0, 10.0);
      
      // Extremely low variance across long text is characteristic of synthetic generation
      if (burstiness < 1.5) {
        burstinessBonus = 15.0;
      }
    }

    // AI score calculation
    double aiScore = 0.0;
    if (aiMarkerCount > 0) {
      aiScore += ((aiMarkerCount / totalWords) * 350.0).clamp(5.0, 45.0);
    }
    aiScore += burstinessBonus;

    // Human markers heavily discount AI score (LLMs avoid casual words in academic context)
    if (humanMarkerCount > 0) {
      aiScore = (aiScore - (humanMarkerCount * 12.0)).clamp(0.0, 100.0);
    }

    aiScore = aiScore.clamp(0.0, 92.0);
    final humanScore = (100.0 - aiScore).clamp(8.0, 100.0);

    return {
      'ai_score': double.parse(aiScore.toStringAsFixed(1)),
      'human_score': double.parse(humanScore.toStringAsFixed(1)),
      'confidence': totalWords > 60 ? 85.0 : 65.0,
      'reasoning': aiScore > 35
          ? 'Identified formulaic transition density and sentence uniformity characteristic of generative models.'
          : 'Authentic lexical diversity and human stylistic variation identified.',
    };
  }
}
