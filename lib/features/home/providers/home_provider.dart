import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/models/scan_result.dart';

final recentScansProvider = FutureProvider<List<ScanResult>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final data = await Supabase.instance.client
      .from('scan_results')
      .select('*, documents(title, word_count, file_type)')
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(10);

  return (data as List<dynamic>)
      .map((e) => ScanResult.fromJson(e as Map<String, dynamic>))
      .toList();
});

final homeStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return {};

  final scansResult = await Supabase.instance.client
      .from('scan_results')
      .select('overall_similarity_score, overall_writing_score, ai_generated_score')
      .eq('user_id', userId)
      .eq('status', 'completed')
      .order('created_at', ascending: false)
      .limit(30);

  final scans = scansResult as List<dynamic>;

  if (scans.isEmpty) return {'total': 0};

  double avgSimilarity = 0;
  double avgWriting = 0;
  for (final s in scans) {
    avgSimilarity += (s['overall_similarity_score'] as num? ?? 0).toDouble();
    avgWriting += (s['overall_writing_score'] as num? ?? 0).toDouble();
  }

  return {
    'total': scans.length,
    'avg_similarity': avgSimilarity / scans.length,
    'avg_writing': avgWriting / scans.length,
  };
});
