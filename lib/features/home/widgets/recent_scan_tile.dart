import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/scan_result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class RecentScanTile extends StatelessWidget {
  final ScanResult scan;

  const RecentScanTile({super.key, required this.scan});

  @override
  Widget build(BuildContext context) {
    // Determine risk color based on similarity score
    Color riskColor = AppColors.riskSafe;
    if (scan.overallSimilarityScore >= 70) {
      riskColor = AppColors.riskCritical;
    } else if (scan.overallSimilarityScore >= 50) {
      riskColor = AppColors.riskHigh;
    } else if (scan.overallSimilarityScore >= 30) {
      riskColor = AppColors.riskMedium;
    } else if (scan.overallSimilarityScore >= 15) {
      riskColor = AppColors.riskLow;
    }

    return GestureDetector(
      onTap: () {
        if (scan.isCompleted) {
          context.go('/scan/result/${scan.id}');
        } else if (scan.isProcessing) {
          context.go('/scan/processing/${scan.id}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scan.isProcessing 
                    ? AppColors.tertiarySurface 
                    : riskColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: scan.isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.document_scanner_rounded,
                      color: riskColor,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 16),
            
            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document Scan',
                    style: AppTypography.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, yyyy • h:mm a').format(scan.createdAt),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            // Score / Status
            if (scan.isCompleted)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${scan.overallSimilarityScore.toStringAsFixed(0)}%',
                    style: AppTypography.titleMedium.copyWith(
                      color: riskColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Similarity',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              )
            else if (scan.isProcessing)
              Text(
                'Processing',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.tertiary,
                ),
              )
            else if (scan.hasFailed)
              Text(
                'Failed',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.secondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
