import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/match_evidence.dart';
import '../models/flagged_section.dart';

class VectorService {
  VectorService._();
  static final instance = VectorService._();

  final _client = Supabase.instance.client;

  /// Stores a list of document chunks in Supabase.
  Future<void> storeChunks(List<Map<String, dynamic>> chunks) async {
    try {
      await _client.from('document_chunks').insert(chunks);
    } catch (e) {
      // Non-fatal if offline or demo mode
      print('VectorService Error (storeChunks): $e');
    }
  }

  /// Searches for similar chunks using pgvector RPC (Single Chunk).
  Future<List<MatchEvidence>> searchSimilarChunks({
    required List<double> embedding,
    double matchThreshold = 0.72,
    int matchCount = 5,
    String? targetDocumentId,
    String? excludeDocumentId,
    String? userId,
  }) async {
    try {
      final response = await _client.rpc(
        'match_document_chunks',
        params: {
          'query_embedding': embedding,
          'match_threshold': matchThreshold,
          'match_count': matchCount,
          if (targetDocumentId != null) 'target_document_id': targetDocumentId,
          if (excludeDocumentId != null) 'exclude_document_id': excludeDocumentId,
          if (userId != null) 'p_user_id': userId,
        },
      );

      final List<dynamic> data = response as List<dynamic>;
      return data.map<MatchEvidence>((item) {
        final isSelf = item['user_id'] == userId;
        return MatchEvidence(
          submittedText: '', // Filled by orchestrator
          matchedText: item['content'] as String,
          sourceTitle: isSelf ? 'Your Previous Document' : 'Referenced Document',
          signals: [
            isSelf ? PlagiarismType.selfPlagiarism : PlagiarismType.semanticSimilarity,
          ],
          semanticSimilarity: (item['similarity'] as num).toDouble(),
          selfPlagiarismSimilarity: isSelf ? (item['similarity'] as num).toDouble() : 0.0,
          startOffset: 0,
          endOffset: 0,
          pageNumber: item['page_number'] as int?,
          paragraphNumber: item['paragraph_number'] as int?,
          sentenceNumber: item['sentence_number'] as int?,
          classification: isSelf
              ? EvidenceClassification.possibleSelfPlagiarism
              : EvidenceClassification.semanticParaphrase,
        );
      }).toList();
    } catch (e) {
      print('VectorService Error (searchSimilarChunks): $e');
      return [];
    }
  }

  /// Searches for multiple chunks in a single batch RPC call.
  /// Returns a map of queryIndex -> list of matches.
  Future<Map<int, List<MatchEvidence>>> searchSimilarChunksBatch({
    required List<List<double>> embeddings,
    double matchThreshold = 0.72,
    int matchCount = 5,
    String? targetDocumentId,
    String? excludeDocumentId,
    String? userId,
  }) async {
    if (embeddings.isEmpty) return {};
    try {
      // PostgreSQL pgvector vector[] expects each element formatted as a vector literal string: ['[0.1, 0.2, ...]', ...]
      final formattedEmbeddings = embeddings
          .map((e) => '[${e.join(',')}]')
          .toList();

      final response = await _client.rpc(
        'match_document_chunks_batch',
        params: {
          'query_embeddings': formattedEmbeddings,
          'match_threshold': matchThreshold,
          'match_count': matchCount,
          if (targetDocumentId != null) 'target_document_id': targetDocumentId,
          if (excludeDocumentId != null) 'exclude_document_id': excludeDocumentId,
          if (userId != null) 'p_user_id': userId,
        },
      );

      final List<dynamic> data = response as List<dynamic>;
      final Map<int, List<MatchEvidence>> results = {};

      for (final item in data) {
        // SQL ordinality starts at 1
        final int idx = (item['query_index'] as int) - 1;
        final isSelf = userId != null && item['user_id'] == userId;

        final match = MatchEvidence(
          submittedText: '',
          matchedText: item['content'] as String,
          sourceTitle: isSelf ? 'Your Previous Document' : 'Repository Document',
          signals: [
            isSelf ? PlagiarismType.selfPlagiarism : PlagiarismType.semanticSimilarity,
          ],
          semanticSimilarity: (item['similarity'] as num).toDouble(),
          selfPlagiarismSimilarity: isSelf ? (item['similarity'] as num).toDouble() : 0.0,
          startOffset: 0,
          endOffset: 0,
          pageNumber: item['page_number'] as int?,
          paragraphNumber: item['paragraph_number'] as int?,
          sentenceNumber: item['sentence_number'] as int?,
          classification: isSelf
              ? EvidenceClassification.possibleSelfPlagiarism
              : EvidenceClassification.semanticParaphrase,
        );

        results.putIfAbsent(idx, () => []).add(match);
      }
      return results;
    } catch (e) {
      print('VectorService Error (searchSimilarChunksBatch): $e');
      return {};
    }
  }
}
