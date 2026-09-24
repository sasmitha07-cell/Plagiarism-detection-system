import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/scan_result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../providers/home_provider.dart';

class RecentScanTile extends ConsumerWidget {
  final ScanResult scan;

  const RecentScanTile({super.key, required this.scan});

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Document Scan?', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "${scan.title}"? This action cannot be undone and will remove all associated flagged sections and reports.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await DocumentManagementService.instance.deleteScan(
                scan.id,
                documentId: scan.documentId,
              );
              if (success && context.mounted) {
                ref.invalidate(recentScansProvider);
                ref.invalidate(homeStatsProvider);
                AppSnackbar.showSuccess(context, 'Document deleted.');
              } else if (context.mounted) {
                AppSnackbar.showError(context, 'Failed to delete document.');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.riskCritical,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: scan.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rename Document', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter new document title',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isEmpty) return;
              Navigator.pop(ctx);
              final success = await DocumentManagementService.instance.renameDocument(
                scan.documentId,
                newTitle,
              );
              if (success && context.mounted) {
                ref.invalidate(recentScansProvider);
                AppSnackbar.showSuccess(context, 'Document renamed.');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowCard,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scan.isProcessing
                    ? AppColors.tertiarySurface
                    : riskColor.withValues(alpha: 0.12),
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
                    scan.title,
                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
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
                      fontWeight: FontWeight.w800,
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
                  fontWeight: FontWeight.w700,
                ),
              )
            else if (scan.hasFailed)
              Text(
                'Failed',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.riskCritical,
                  fontWeight: FontWeight.w700,
                ),
              ),

            const SizedBox(width: 6),

            // Actions Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textTertiary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    context.go('/scan/result/${scan.id}');
                    break;
                  case 'coach':
                    context.push('/coach', extra: scan.id);
                    break;
                  case 'rename':
                    _showRenameDialog(context, ref);
                    break;
                  case 'delete':
                    _showDeleteDialog(context, ref);
                    break;
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('View Report'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'coach',
                  child: Row(
                    children: [
                      Icon(Icons.psychology_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('AI Writing Coach'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Rename'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: AppColors.riskCritical, size: 18),
                      SizedBox(width: 10),
                      Text('Delete', style: TextStyle(color: AppColors.riskCritical)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
