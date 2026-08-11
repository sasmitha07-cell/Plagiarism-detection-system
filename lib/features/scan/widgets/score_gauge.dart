import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'package:fl_chart/fl_chart.dart';

class ScoreGauge extends StatelessWidget {
  final String title;
  final double score;
  final bool isInverse;
  final Color color;
  final IconData icon;

  const ScoreGauge({
    super.key,
    required this.title,
    required this.score,
    required this.isInverse,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: 180,
                    sectionsSpace: 0,
                    centerSpaceRadius: 22,
                    sections: [
                      PieChartSectionData(
                        color: color,
                        value: score,
                        title: '',
                        radius: 6,
                      ),
                      PieChartSectionData(
                        color: AppColors.surfaceVariant,
                        value: 100 - score,
                        title: '',
                        radius: 6,
                      ),
                      // Invisible section for the bottom half
                      PieChartSectionData(
                        color: Colors.transparent,
                        value: 100,
                        title: '',
                        radius: 6,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 12,
                  child: Text(
                    '${score.toStringAsFixed(0)}%',
                    style: AppTypography.titleMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
