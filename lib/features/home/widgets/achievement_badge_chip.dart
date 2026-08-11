import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class AchievementBadgeChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool earned;

  const AchievementBadgeChip({
    super.key,
    required this.emoji,
    required this.label,
    required this.earned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: earned ? AppColors.accentSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: earned ? AppColors.accent : AppColors.borderLight,
          width: earned ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            earned ? emoji : '🔒',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: earned ? AppColors.textPrimary : AppColors.textDisabled,
              fontWeight: earned ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
