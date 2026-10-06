import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../home/providers/home_provider.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentScansAsync = ref.watch(recentScansProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Achievements & Badges'),
        backgroundColor: AppColors.background,
      ),
      body: recentScansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textTertiary),
                const SizedBox(height: 12),
                const Text('Unable to load achievements.', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.invalidate(recentScansProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (scans) {
          final totalScans = scans.length;
          final hasZeroPlag = scans.any((s) => s.overallSimilarityScore < 10);
          final hasLowAi = scans.any((s) => s.aiGeneratedScore < 15);
          final hasHighWriting = scans.any((s) => (s.overallWritingScore ?? 0) >= 85);
          final hasFiveScans = totalScans >= 5;

          final List<Map<String, dynamic>> achievements = [
            {
              'emoji': '🔍',
              'title': 'First Scan',
              'desc': 'Completed your first plagiarism check',
              'earned': totalScans >= 1,
            },
            {
              'emoji': '🛡️',
              'title': 'Original Thinker',
              'desc': 'Scored under 10% similarity on a document',
              'earned': hasZeroPlag,
            },
            {
              'emoji': '✨',
              'title': 'Clean Writer',
              'desc': 'Achieved <15% AI detection score',
              'earned': hasLowAi,
            },
            {
              'emoji': '📚',
              'title': 'Citation Scholar',
              'desc': 'Maintained high academic integrity across scans',
              'earned': hasFiveScans,
            },
            {
              'emoji': '🎓',
              'title': 'Academic Writer',
              'desc': 'Reached a Writing Quality Score of 85+',
              'earned': hasHighWriting,
            },
            {
              'emoji': '🏆',
              'title': 'Prolific Researcher',
              'desc': 'Analyzed 10 or more academic documents',
              'earned': totalScans >= 10,
            },
          ];

          final unlockedCount = achievements.where((a) => a['earned'] == true).length;

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: achievements.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C5E43), Color(0xFF1B3B2B)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$unlockedCount of ${achievements.length} Unlocked',
                              style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              unlockedCount == 0
                                  ? 'Start using the app to unlock achievements.'
                                  : 'Keep scanning and improving your writing to unlock all badges.',
                              style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final ach = achievements[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _AchievementCard(
                  emoji: ach['emoji'],
                  title: ach['title'],
                  desc: ach['desc'],
                  earned: ach['earned'],
                ).animate().fadeIn(delay: Duration(milliseconds: 80 * index)).slideX(begin: 0.1),
              );
            },
          );
        },
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  final bool earned;

  const _AchievementCard({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.earned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: earned ? AppColors.surface : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: earned ? AppColors.primarySurface : AppColors.borderLight,
        ),
        boxShadow: earned
            ? [
                BoxShadow(
                  color: AppColors.shadowCard,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: earned ? AppColors.primarySurface : AppColors.borderLight,
              shape: BoxShape.circle,
            ),
            child: Text(
              emoji,
              style: TextStyle(fontSize: 26, color: earned ? null : Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: earned ? AppColors.textPrimary : AppColors.textTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: AppTypography.bodySmall.copyWith(
                    color: earned ? AppColors.textSecondary : AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
          if (earned)
            const Icon(Icons.check_circle_rounded, color: AppColors.riskSafe)
          else
            const Icon(Icons.lock_outline_rounded, color: AppColors.textDisabled),
        ],
      ),
    );
  }
}
