import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/flagged_section.dart';

class FlaggedSectionCard extends StatelessWidget {
  final PlagiarismType type;
  final String textSnippet;
  final String sourceName;
  final String? sourceUrl;
  final int matchPercentage;
  final VoidCallback onFixTap;

  const FlaggedSectionCard({
    super.key,
    required this.type,
    required this.textSnippet,
    required this.sourceName,
    this.sourceUrl,
    required this.matchPercentage,
    required this.onFixTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors and icons based on type
    Color accentColor;
    IconData icon;
    String typeLabel;

    switch (type) {
      case PlagiarismType.exactCopy:
        accentColor = AppColors.riskCritical;
        icon = Icons.content_copy_rounded;
        typeLabel = 'Exact Match';
        break;
      case PlagiarismType.aiRewritten:
        accentColor = AppColors.tertiary;
        icon = Icons.psychology_rounded;
        typeLabel = 'AI Generated';
        break;
      case PlagiarismType.paraphrased:
        accentColor = AppColors.riskMedium;
        icon = Icons.wrap_text_rounded;
        typeLabel = 'Paraphrased';
        break;
      case PlagiarismType.semanticSimilarity:
        accentColor = AppColors.riskHigh;
        icon = Icons.difference_rounded;
        typeLabel = 'High Similarity';
        break;
      case PlagiarismType.missingCitation:
        accentColor = AppColors.secondary;
        icon = Icons.format_quote_rounded;
        typeLabel = 'Missing Citation';
        break;
      default:
        accentColor = AppColors.primary;
        icon = Icons.flag_rounded;
        typeLabel = 'Flagged';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  typeLabel,
                  style: AppTypography.labelLarge.copyWith(color: accentColor),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$matchPercentage% Match',
                    style: AppTypography.labelSmall.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Snippet
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    '"$textSnippet"',
                    style: AppTypography.bodyMedium.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Source
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.source_rounded, size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Source: $sourceName',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (sourceUrl != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              sourceUrl!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onFixTap,
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                    label: const Text('Rewrite & Fix'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accentColor,
                      side: BorderSide(color: accentColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
