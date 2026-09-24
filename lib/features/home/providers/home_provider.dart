import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/models/scan_result.dart';

final recentScansProvider = FutureProvider<List<ScanResult>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null || userId.isEmpty) {
    dev.log('[recentScansProvider] No authenticated user ID found.');
    return [];
  }

  final client = Supabase.instance.client;
  try {
    dev.log('[recentScansProvider] Querying scan_results for authenticated user');
    final data = await client
        .from('scan_results')
        .select('*, documents(title, word_count, file_type, content)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    final rawList = data as List<dynamic>;
    dev.log('[recentScansProvider] Successfully loaded ${rawList.length} scan records.');
    
    return rawList
        .map((e) => ScanResult.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, stackTrace) {
    dev.log('[recentScansProvider] Supabase query error (graceful fallback): $e\n$stackTrace');
    return [];
  }
});

final homeStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return {'total': 0, 'avg_similarity': 0.0, 'avg_writing': 75.0};

  final client = Supabase.instance.client;
  try {
    final scansResult = await client
        .from('scan_results')
        .select('overall_similarity_score, writing_score, overall_writing_score, ai_score, ai_generated_score')
        .eq('user_id', userId)
        .eq('status', 'completed')
        .order('created_at', ascending: false)
        .limit(50);

    final scans = scansResult as List<dynamic>;

    if (scans.isEmpty) return {'total': 0, 'avg_similarity': 0.0, 'avg_writing': 75.0};

    double totalSimilarity = 0;
    double totalWriting = 0;
    int count = 0;

    for (final s in scans) {
      totalSimilarity += (s['overall_similarity_score'] as num? ?? 0).toDouble();
      final w = (s['writing_score'] as num? ?? s['overall_writing_score'] as num? ?? 75).toDouble();
      totalWriting += w;
      count++;
    }

    return {
      'total': count,
      'avg_similarity': count > 0 ? (totalSimilarity / count) : 0.0,
      'avg_writing': count > 0 ? (totalWriting / count) : 75.0,
    };
  } catch (e) {
    return {'total': 0, 'avg_similarity': 0.0, 'avg_writing': 75.0};
  }
});

class DocumentManagementService {
  DocumentManagementService._();
  static final instance = DocumentManagementService._();

  Future<bool> deleteScan(String scanId, {String? documentId}) async {
    try {
      final client = Supabase.instance.client;
      // Delete flagged sections & sources for this scan
      try {
        await client.from('flagged_sections').delete().eq('scan_id', scanId);
      } catch (_) {}

      try {
        await client.from('similarity_sources').delete().eq('scan_id', scanId);
      } catch (_) {}

      try {
        await client.from('writing_analytics').delete().eq('scan_id', scanId);
      } catch (_) {}

      // Delete scan result
      await client.from('scan_results').delete().eq('id', scanId);

      // If documentId provided and no other scans refer to it, delete document chunks and document
      if (documentId != null) {
        try {
          final remaining = await client.from('scan_results').select('id').eq('document_id', documentId);
          if ((remaining as List).isEmpty) {
            await client.from('document_chunks').delete().eq('document_id', documentId);
            await client.from('documents').delete().eq('id', documentId);
          }
        } catch (_) {}
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> renameDocument(String documentId, String newTitle) async {
    try {
      final client = Supabase.instance.client;
      await client.from('documents').update({
        'title': newTitle,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', documentId);

      await client.from('scan_results').update({
        'title': newTitle,
      }).eq('document_id', documentId);

      return true;
    } catch (e) {
      return false;
    }
  }
}
