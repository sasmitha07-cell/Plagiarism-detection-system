import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> achievements = [
      {'emoji': '🔍', 'title': 'First Scan', 'desc': 'Completed your first plagiarism check', 'earned': true},
      {'emoji': '🛡️', 'title': 'Original Thinker', 'desc': 'Scored 100% original content', 'earned': true},
      {'emoji': '✨', 'title': 'Clean Writer', 'desc': '3 scans in a row with 0% AI content', 'earned': false},
      {'emoji': '📚', 'title': 'Citation Master', 'desc': 'Generated 10 perfect citations', 'earned': false},
      {'emoji': '🎓', 'title': 'Academic Writer', 'desc': 'Reached Writing Score of 95+', 'earned': false},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: AppColors.background,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final ach = achievements[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _AchievementCard(
              emoji: ach['emoji'],
              title: ach['title'],
              desc: ach['desc'],
              earned: ach['earned'],
            ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1),
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
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: earned ? AppColors.primarySurface : AppColors.borderLight,
              shape: BoxShape.circle,
            ),
            child: Text(
              emoji,
              style: TextStyle(fontSize: 28, color: earned ? null : Colors.grey),
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
                  ),
                ),
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
            const Icon(Icons.lock_rounded, color: AppColors.textDisabled),
        ],
      ),
    );
  }
}
