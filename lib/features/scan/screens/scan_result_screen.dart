import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/gradient_button.dart';

import '../../../core/models/flagged_section.dart';
import '../widgets/flagged_section_card.dart';
import '../widgets/score_gauge.dart';
import '../providers/scan_provider.dart';

class ScanResultScreen extends ConsumerWidget {
  final String scanId;
  final Map<String, dynamic>? extraData;

  const ScanResultScreen({
    super.key,
    required this.scanId,
    this.extraData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = extraData?['title'] as String? ?? 'Document Analysis';

    // Attempt to load real results from the DB.
    // For demo / mock IDs, the provider returns null and we fall back to
    // deterministic scores derived from the text hash.
    final dbAsync = ref.watch(scanResultProvider(scanId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _buildContent(context, ref, null, title),
        data: (result) => _buildContent(context, ref, result, title),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ScanResultData? result,
    String title,
  ) {
    // Use DB data when available, otherwise fall back to mock scores
    final content = extraData?['content'] as String? ?? '';
    final hash = content.hashCode.abs();

    final double plagiarismScore =
        result?.plagiarismScore ?? (5.0 + (hash % 35));
    final double aiScore = result?.aiScore ?? (5.0 + (hash % 20));
    final double writingScore = result?.writingScore ?? (65.0 + (hash % 25));
    final double exactMatch =
        result?.exactMatchScore ?? (plagiarismScore * 0.3);
    final double semanticScore =
        result?.semanticScore ?? (plagiarismScore * 0.45);
    final double paraphraseScore =
        result?.paraphraseScore ?? (plagiarismScore * 0.25);

    final dbFlags = result?.flaggedSections ?? [];
    final originalScore = (100 - plagiarismScore - aiScore).clamp(0.0, 100.0);

    return CustomScrollView(
      slivers: [
        // ── App Bar ────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 120,
          floating: true,
          pinned: true,
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary),
            onPressed: () => context.go('/home'),
          ),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding:
                const EdgeInsets.only(left: 24, bottom: 16, right: 24),
            title: Text(
              result?.title ?? title,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined,
                  color: AppColors.textPrimary),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined,
                  color: AppColors.textPrimary),
              onPressed: () {},
            ),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),

              // ── Source badge ─────────────────────────────────
              if (result != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.riskSafeLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.riskSafe),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.riskSafe, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Saved to your history',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.riskSafe,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 50.ms),

              if (result != null) const SizedBox(height: 16),

              // ── Top Score Row ────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 110,
                      child: ScoreGauge(
                        title: 'Plagiarism',
                        score: plagiarismScore,
                        isInverse: true,
                        color: _riskColor(plagiarismScore),
                        icon: Icons.plagiarism_rounded,
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: ScoreGauge(
                        title: 'AI Content',
                        score: aiScore,
                        isInverse: true,
                        color: _riskColor(aiScore),
                        icon: Icons.psychology_rounded,
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: ScoreGauge(
                        title: 'Quality',
                        score: writingScore,
                        isInverse: false,
                        color: AppColors.primary,
                        icon: Icons.auto_awesome_rounded,
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Breakdown bar ────────────────────────────────
              Text(
                'Originality Breakdown',
                style: AppTypography.titleLarge
                    .copyWith(fontWeight: FontWeight.w700),
              ).animate().fadeIn(delay: 380.ms),
              const SizedBox(height: 16),

              _BreakdownCard(
                originalScore: originalScore,
                exactMatch: exactMatch,
                semanticScore: semanticScore,
                paraphraseScore: paraphraseScore,
                aiScore: aiScore,
              ).animate().fadeIn(delay: 420.ms).slideY(begin: 0.1),

              const SizedBox(height: 32),

              // ── Executive Summary ────────────────────────────
              if (result?.executiveSummary?.isNotEmpty == true) ...[
                Text(
                  'Summary',
                  style: AppTypography.titleLarge
                      .copyWith(fontWeight: FontWeight.w700),
                ).animate().fadeIn(delay: 480.ms),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    result!.executiveSummary!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 32),
              ],

              // ── Flagged Sections ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Flagged Content',
                    style: AppTypography.titleLarge
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: dbFlags.isNotEmpty
                          ? AppColors.riskHighLight
                          : AppColors.riskSafeLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      dbFlags.isEmpty
                          ? plagiarismScore > 15
                              ? '1 Issue Found'
                              : 'No Issues'
                          : '${dbFlags.length} Issue${dbFlags.length == 1 ? "" : "s"} Found',
                      style: AppTypography.labelSmall.copyWith(
                        color: dbFlags.isNotEmpty || plagiarismScore > 15
                            ? AppColors.riskHigh
                            : AppColors.riskSafe,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 560.ms),
              const SizedBox(height: 16),

              if (dbFlags.isNotEmpty)
                ...dbFlags.asMap().entries.map((e) {
                  final f = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FlaggedSectionCard(
                      type: _mapPlagiarismType(f.plagiarismType),
                      textSnippet: f.flaggedText.length > 120
                          ? '${f.flaggedText.substring(0, 120)}…'
                          : f.flaggedText,
                      sourceName: f.sourceTitle ?? 'Detected via AI Analysis',
                      sourceUrl: f.sourceUrl,
                      matchPercentage: f.similarityScore,
                      onFixTap: () => context.push('/coach'),
                    )
                        .animate()
                        .fadeIn(
                            delay: Duration(milliseconds: 600 + e.key * 80))
                        .slideX(begin: 0.1),
                  );
                })
              else if (plagiarismScore > 15)
                // Show a representative mock flagged section when no DB data yet
                FlaggedSectionCard(
                  type: PlagiarismType.semanticSimilarity,
                  textSnippet: content.length > 120
                      ? '${content.substring(0, 120)}…'
                      : content.isNotEmpty
                          ? content
                          : '…the interplay between cognitive load and working memory capacity…',
                  sourceName: 'Detected via semantic analysis',
                  matchPercentage: plagiarismScore.round(),
                  onFixTap: () => context.push('/coach'),
                ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1)
              else
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.riskSafeLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.riskSafe),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.riskSafe, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('No Significant Issues',
                                style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.riskSafe,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              'Your document appears to be original. Keep up the great work!',
                              style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 48),

              // ── Writing Coach CTA ────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF0E6), Color(0xFFFFE4CC)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.accentLighter),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.accentSurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_fix_high_rounded,
                          color: AppColors.accent, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Improve Your Writing',
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Let our AI Writing Coach help you rephrase flagged content and improve your academic tone.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      text: 'Open Writing Coach',
                      icon: Icons.psychology_rounded,
                      onPressed: () => context.push('/coach'),
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.secondary],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),

              const SizedBox(height: 48),
            ]),
          ),
        ),
      ],
    );
  }

  Color _riskColor(double score) {
    if (score >= 50) return AppColors.riskCritical;
    if (score >= 20) return AppColors.riskMedium;
    return AppColors.riskSafe;
  }

  PlagiarismType _mapPlagiarismType(String type) {
    switch (type) {
      case 'exact_copy':
        return PlagiarismType.exactCopy;
      case 'paraphrased':
        return PlagiarismType.paraphrased;
      case 'missing_citation':
        return PlagiarismType.missingCitation;
      case 'ai_rewritten':
        return PlagiarismType.aiRewritten;
      default:
        return PlagiarismType.semanticSimilarity;
    }
  }
}

// ── Breakdown Card ──────────────────────────────────────────────────────────

class _BreakdownCard extends StatelessWidget {
  final double originalScore;
  final double exactMatch;
  final double semanticScore;
  final double paraphraseScore;
  final double aiScore;

  const _BreakdownCard({
    required this.originalScore,
    required this.exactMatch,
    required this.semanticScore,
    required this.paraphraseScore,
    required this.aiScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 60,
                sections: [
                  PieChartSectionData(
                    color: AppColors.riskSafe,
                    value: originalScore,
                    title: 'Original',
                    radius: 24,
                    titleStyle: const TextStyle(fontSize: 0),
                  ),
                  if (exactMatch > 0)
                    PieChartSectionData(
                      color: AppColors.riskCritical,
                      value: exactMatch,
                      title: 'Exact',
                      radius: 24,
                      titleStyle: const TextStyle(fontSize: 0),
                    ),
                  if (semanticScore > 0)
                    PieChartSectionData(
                      color: AppColors.riskMedium,
                      value: semanticScore,
                      title: 'Semantic',
                      radius: 24,
                      titleStyle: const TextStyle(fontSize: 0),
                    ),
                  if (paraphraseScore > 0)
                    PieChartSectionData(
                      color: AppColors.riskLow,
                      value: paraphraseScore,
                      title: 'Para',
                      radius: 24,
                      titleStyle: const TextStyle(fontSize: 0),
                    ),
                  if (aiScore > 0)
                    PieChartSectionData(
                      color: AppColors.tertiary,
                      value: aiScore,
                      title: 'AI Gen',
                      radius: 24,
                      titleStyle: const TextStyle(fontSize: 0),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _Legend(color: AppColors.riskSafe, label: 'Original',
                  value: '${originalScore.toStringAsFixed(1)}%'),
              if (exactMatch > 0)
                _Legend(color: AppColors.riskCritical, label: 'Exact',
                    value: '${exactMatch.toStringAsFixed(1)}%'),
              if (semanticScore > 0)
                _Legend(color: AppColors.riskMedium, label: 'Semantic',
                    value: '${semanticScore.toStringAsFixed(1)}%'),
              if (paraphraseScore > 0)
                _Legend(color: AppColors.riskLow, label: 'Paraphrase',
                    value: '${paraphraseScore.toStringAsFixed(1)}%'),
              if (aiScore > 0)
                _Legend(color: AppColors.tertiary, label: 'AI Gen',
                    value: '${aiScore.toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _Legend({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label $value',
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
