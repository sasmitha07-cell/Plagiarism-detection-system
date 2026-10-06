import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';

class UserAcademicStats {
  final int totalScans;
  final int totalDocuments;
  final int totalCitations;
  final double averageSimilarityScore;
  final double averageWritingScore;
  final int cleanScansCount;
  final int zeroStreak;

  const UserAcademicStats({
    this.totalScans = 0,
    this.totalDocuments = 0,
    this.totalCitations = 0,
    this.averageSimilarityScore = 0.0,
    this.averageWritingScore = 0.0,
    this.cleanScansCount = 0,
    this.zeroStreak = 0,
  });
}

class ProfileCompletionInfo {
  final int percentage;
  final List<String> missingFields;

  const ProfileCompletionInfo({
    required this.percentage,
    required this.missingFields,
  });

  bool get isComplete => percentage >= 100;
}

/// Computes real academic statistics scoped strictly to current authenticated user
final profileStatsProvider = FutureProvider<UserAcademicStats>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const UserAcademicStats();
  }

  // If in demo mode, return demo stats
  if (userId == 'demo-user-id') {
    return const UserAcademicStats(
      totalScans: 12,
      totalDocuments: 8,
      totalCitations: 5,
      averageSimilarityScore: 14.5,
      averageWritingScore: 88.0,
      cleanScansCount: 7,
      zeroStreak: 5,
    );
  }

  final client = Supabase.instance.client;

  try {
    // 1. Documents count for this authenticated user
    int docCount = 0;
    try {
      final docRes = await client
          .from('documents')
          .select('id')
          .eq('user_id', userId);
      docCount = (docRes as List).length;
    } catch (e) {
      debugPrint('[profileStatsProvider] Error querying documents count: $e');
    }

    // 2. Scans for this authenticated user
    int scanCount = 0;
    double totalSim = 0.0;
    double totalWriting = 0.0;
    int writingScansCount = 0;
    int cleanCount = 0;
    int streak = 0;

    try {
      final scanRes = await client
          .from('scan_results')
          .select('overall_similarity_score, overall_writing_score, writing_score, status')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      final scans = scanRes as List;
      scanCount = scans.length;

      for (final s in scans) {
        final sim = (s['overall_similarity_score'] as num?)?.toDouble() ?? 0.0;
        totalSim += sim;

        final w = (s['overall_writing_score'] as num? ?? s['writing_score'] as num?)?.toDouble();
        if (w != null && w > 0) {
          totalWriting += w;
          writingScansCount++;
        }

        if (sim < 10.0) {
          cleanCount++;
        }
      }

      // Calculate streak from latest scans backwards
      for (final s in scans) {
        final sim = (s['overall_similarity_score'] as num?)?.toDouble() ?? 0.0;
        if (sim == 0.0) {
          streak++;
        } else {
          break;
        }
      }
    } catch (e) {
      debugPrint('[profileStatsProvider] Error querying scans stats: $e');
    }

    // 3. Citations count for this authenticated user
    int citationCount = 0;
    try {
      final citRes = await client
          .from('citations')
          .select('id')
          .eq('user_id', userId);
      citationCount = (citRes as List).length;
    } catch (e) {
      debugPrint('[profileStatsProvider] Error querying citations count: $e');
    }

    return UserAcademicStats(
      totalScans: scanCount,
      totalDocuments: docCount,
      totalCitations: citationCount,
      averageSimilarityScore: scanCount > 0 ? (totalSim / scanCount) : 0.0,
      averageWritingScore: writingScansCount > 0 ? (totalWriting / writingScansCount) : 0.0,
      cleanScansCount: cleanCount,
      zeroStreak: streak,
    );
  } catch (e) {
    debugPrint('[profileStatsProvider] Unexpected error: $e');
    return const UserAcademicStats();
  }
});

/// Dynamically calculates profile completion based on actual populated fields
final profileCompletionProvider = Provider<ProfileCompletionInfo>((ref) {
  final profile = ref.watch(profileStateProvider).asData?.value;
  if (profile == null) {
    return const ProfileCompletionInfo(percentage: 0, missingFields: ['Full name', 'Institution', 'Academic level', 'Profile photo']);
  }

  int completed = 0;
  final missing = <String>[];

  // Full Name (20%)
  if (profile.fullName != null && profile.fullName!.trim().isNotEmpty) {
    completed += 20;
  } else {
    missing.add('Full name');
  }

  // Email (20%)
  if (profile.email.trim().isNotEmpty) {
    completed += 20;
  } else {
    missing.add('Email');
  }

  // Institution (20%)
  if (profile.institution != null && profile.institution!.trim().isNotEmpty) {
    completed += 20;
  } else {
    missing.add('Institution');
  }

  // Academic Level (20%)
  if (profile.academicLevel != null && profile.academicLevel!.trim().isNotEmpty) {
    completed += 20;
  } else {
    missing.add('Academic level');
  }

  // Avatar Photo (20%)
  if (profile.avatarUrl != null && profile.avatarUrl!.trim().isNotEmpty) {
    completed += 20;
  } else {
    missing.add('Profile photo');
  }

  return ProfileCompletionInfo(
    percentage: completed,
    missingFields: missing,
  );
});
