import 'package:flutter/material.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class ScoreSummaryCard extends StatelessWidget {
  final UserProfile profile;

  const ScoreSummaryCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ScoreItem(
            label: 'Avg Similarity',
            value: '${profile.averageSimilarityScore.toStringAsFixed(0)}%',
            color: profile.averageSimilarityScore > 30 
                ? AppColors.riskMedium 
                : AppColors.riskSafe,
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.borderLight,
          ),
          _ScoreItem(
            label: 'Writing Score',
            value: profile.averageWritingScore.toStringAsFixed(0),
            color: AppColors.primary,
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.borderLight,
          ),
          _ScoreItem(
            label: 'Total Scans',
            value: profile.totalScans.toString(),
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScoreItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headlineMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
