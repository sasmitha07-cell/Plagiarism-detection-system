import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/flagged_section.dart';

class CoachScreen extends StatelessWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock list of issues for UI purposes
    final List<Map<String, dynamic>> issues = [
      {
        'title': 'High Semantic Similarity',
        'type': PlagiarismType.semanticSimilarity,
        'snippet': 'The rapid development of machine learning algorithms has significantly altered the landscape of artificial intelligence research...',
        'suggestion': 'Try to express this idea using your own unique perspective rather than relying on common phrasings.',
      },
      {
        'title': 'AI Generated Signature Detected',
        'type': PlagiarismType.aiRewritten,
        'snippet': 'It is crucial to recognize that the multifaceted nature of this problem requires a holistic approach...',
        'suggestion': 'This sentence lacks personal voice and uses typical LLM vocabulary. Rewrite to sound more natural.',
      },
      {
        'title': 'Missing Citation',
        'type': PlagiarismType.missingCitation,
        'snippet': 'Studies show that 78% of students struggle with academic writing formats.',
        'suggestion': 'You need to cite the specific study that provided this statistic.',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Writing Coach'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
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
            return _IssueCard(
              title: issue['title'],
              type: issue['type'],
              snippet: issue['snippet'],
              suggestion: issue['suggestion'],
              onRewrite: () {
                context.push('/coach/rewrite', extra: {
                  'text': issue['snippet'],
                  'type': issue['type'],
                });
              },
            ).animate().fadeIn(delay: Duration(milliseconds: 200 + (index * 100))).slideY(begin: 0.1);
          },
        ),
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final String title;
  final PlagiarismType type;
  final String snippet;
  final String suggestion;
  final VoidCallback onRewrite;

  const _IssueCard({
    required this.title,
    required this.type,
    required this.snippet,
    required this.suggestion,
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
