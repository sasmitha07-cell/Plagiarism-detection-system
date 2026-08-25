import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/flagged_section.dart';
import '../../scan/providers/scan_provider.dart';

class CoachScreen extends ConsumerWidget {
  final String? scanId;
  const CoachScreen({super.key, this.scanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If no scanId is provided, show a message or last scan
    if (scanId == null) {
        return const Scaffold(body: Center(child: Text('No active scan results found.')));
    }

    final scanResultAsync = ref.watch(scanResultProvider(scanId!));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Writing Coach'),
        backgroundColor: AppColors.background,
      ),
      body: scanResultAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading results: $e')),
        data: (result) {
          if (result == null || result.flaggedSections.isEmpty) {
            return _buildEmptyState(context);
          }

          final issues = result.flaggedSections;

          return SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: issues.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Needs Improvement',
                        style: AppTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                      const SizedBox(height: 8),
                      Text(
                        'Review the flagged issues below and use our AI assistant to rewrite them.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 24),
                    ],
                  );
                }

                final issue = issues[index - 1];
                final isVerified = issue.signals.contains(PlagiarismType.exactCopy) || 
                                 (issue.signals.contains(PlagiarismType.webDiscovery) && issue.similarityScore > 60);

                return _IssueCard(
                  title: _getIssueTitle(issue),
                  type: issue.signals.isNotEmpty ? issue.signals.first : PlagiarismType.semanticSimilarity,
                  snippet: issue.flaggedText,
                  suggestion: issue.suggestedAction ?? 'Consider rephrasing this section.',
                  isVerified: isVerified,
                  onRewrite: () {
                    context.push('/coach/rewrite', extra: {
                      'text': issue.flaggedText,
                      'scanId': scanId,
                      'documentId': result.documentId,
                      'startPos': issue.startPosition,
                      'endPos': issue.endPosition,
                      'type': issue.signals.isNotEmpty ? issue.signals.first : PlagiarismType.semanticSimilarity,
                    });
                  },
                ).animate().fadeIn(delay: Duration(milliseconds: 200 + (index * 100))).slideY(begin: 0.1);
              },
            ),
          );
        },
      ),
    );
  }

  String _getIssueTitle(FlaggedSectionData issue) {
    if (issue.signals.contains(PlagiarismType.exactCopy)) return 'Exact Match Detected';
    if (issue.signals.contains(PlagiarismType.webDiscovery)) return 'Web Match Found';
    return 'High Semantic Similarity';
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.riskSafe),
          const SizedBox(height: 16),
          Text('All Good!', style: AppTypography.headlineSmall),
          const SizedBox(height: 8),
          Text('No writing issues detected in this document.', style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final String title;
  final PlagiarismType type;
  final String snippet;
  final String suggestion;
  final bool isVerified;
  final VoidCallback onRewrite;

  const _IssueCard({
    required this.title,
    required this.type,
    required this.snippet,
    required this.suggestion,
    this.isVerified = false,
    required this.onRewrite,
  });

  @override
  Widget build(BuildContext context) {
    Color accentColor;
    IconData icon;

    switch (type) {
      case PlagiarismType.missingCitation:
        accentColor = AppColors.secondary;
        icon = Icons.format_quote_rounded;
        break;
      case PlagiarismType.aiRewritten:
        accentColor = AppColors.tertiary;
        icon = Icons.psychology_rounded;
        break;
      default:
        accentColor = AppColors.riskMedium;
        icon = Icons.warning_amber_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (isVerified) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.riskSafe,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'VERIFIED',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"$snippet"',
                  style: AppTypography.bodyMedium.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRewrite,
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                    label: const Text('Open Rewrite Assistant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
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
