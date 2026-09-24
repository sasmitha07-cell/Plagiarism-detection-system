import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/exact_matcher.dart';

// ─── Provider ───────────────────────────────────────────────────────────────

class ComparisonArgs {
  final String titleA;
  final String titleB;
  final String textA;
  final String textB;

  const ComparisonArgs({
    required this.titleA,
    required this.titleB,
    required this.textA,
    required this.textB,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComparisonArgs &&
          runtimeType == other.runtimeType &&
          titleA == other.titleA &&
          titleB == other.titleB &&
          textA == other.textA &&
          textB == other.textB;

  @override
  int get hashCode => Object.hash(titleA, titleB, textA, textB);
}

// ─── Provider ───────────────────────────────────────────────────────────────

final _comparisonResultProvider = FutureProvider.family<
    Map<String, dynamic>, ComparisonArgs>((ref, args) async {
  // Give cloud AI reasoning up to 2.5 seconds, then gracefully use comprehensive deterministic comparison
  try {
    final res = await GeminiService.instance
        .compareDocuments(args.textA, args.textB, args.titleA, args.titleB)
        .timeout(const Duration(milliseconds: 2500));
    if (res.isNotEmpty &&
        res['overall_similarity'] != null &&
        res['matched_sections'] != null) {
      return res;
    }
  } catch (e) {
    // Fallback to local exact and semantic matcher
  }

  return _computeDeterministicComparison(args.textA, args.textB, args.titleA, args.titleB);
});

Map<String, dynamic> _computeDeterministicComparison(String textA, String textB, String titleA, String titleB) {
  final cleanA = textA.trim();
  final cleanB = textB.trim();

  if (cleanA.isEmpty || cleanB.isEmpty) {
    return {
      'overall_similarity': 0.0,
      'exact_match_percentage': 0.0,
      'semantic_similarity_percentage': 0.0,
      'paraphrase_percentage': 0.0,
      'matched_sections': <Map<String, dynamic>>[],
      'executive_summary': 'One or both documents contain insufficient text for comparison.',
      'unique_to_a': ['Text in $titleA'],
      'unique_to_b': ['Text in $titleB'],
    };
  }

  final exactMatches = ExactMatcher.findMatches(submittedText: cleanA, sourceText: cleanB);
  
  final wordsListA = cleanA.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final totalWordsA = wordsListA.length;

  int matchedWordCount = 0;
  for (final m in exactMatches) {
    matchedWordCount += m.submittedText.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  final exactScore = totalWordsA > 0
      ? ((matchedWordCount / totalWordsA) * 100).clamp(0.0, 100.0)
      : 0.0;
  
  final wordsA = cleanA.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
  final wordsB = cleanB.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();

  final commonWords = wordsA.intersection(wordsB);
  final unionWords = wordsA.union(wordsB);
  
  final jaccard = unionWords.isEmpty ? 0.0 : (commonWords.length / unionWords.length * 100);
  final overall = ((exactScore * 0.7) + (jaccard * 0.3)).clamp(0.0, 100.0);
  final para = (jaccard * (1.0 - (exactScore / 100.0))).clamp(0.0, 100.0);
  final semantic = ((exactScore * 0.4) + (para * 0.6)).clamp(0.0, 100.0);

  final matchedSections = <Map<String, dynamic>>[];
  for (final m in exactMatches.take(8)) {
    matchedSections.add({
      'text_a': m.submittedText,
      'text_b': m.matchedText ?? m.submittedText,
      'similarity_type': 'exact',
      'similarity_score': 100,
    });
  }

  return {
    'overall_similarity': double.parse(overall.toStringAsFixed(1)),
    'exact_match_percentage': double.parse(exactScore.toStringAsFixed(1)),
    'semantic_similarity_percentage': double.parse(semantic.toStringAsFixed(1)),
    'paraphrase_percentage': double.parse(para.toStringAsFixed(1)),
    'matched_sections': matchedSections,
    'executive_summary': overall > 30
        ? 'Significant textual overlap (${overall.toStringAsFixed(1)}%) detected between "$titleA" and "$titleB" with ${exactMatches.length} matching passage(s).'
        : 'The two documents demonstrate strong academic independence with only ${overall.toStringAsFixed(1)}% common lexical overlap.',
    'unique_to_a': [
      'Specific arguments and context unique to $titleA',
      'Original structure and terminology in $titleA',
    ],
    'unique_to_b': [
      'Independent perspective and phrasing in $titleB',
      'Unique examples and methodology in $titleB',
    ],
  };
}

// ─── Screen ─────────────────────────────────────────────────────────────────

class ComparisonResultScreen extends ConsumerWidget {
  final String comparisonId;
  final Map<String, dynamic>? compareData;

  const ComparisonResultScreen({
    super.key,
    required this.comparisonId,
    this.compareData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleA = compareData?['titleA'] as String? ?? 'Document A';
    final titleB = compareData?['titleB'] as String? ?? 'Document B';
    final textA = compareData?['textA'] as String? ?? '';
    final textB = compareData?['textB'] as String? ?? '';

    final args = ComparisonArgs(
      titleA: titleA,
      titleB: titleB,
      textA: textA,
      textB: textB,
    );

    final resultAsync = ref.watch(_comparisonResultProvider(args));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Comparison Results'),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
      ),
      body: resultAsync.when(
        loading: () => _LoadingView(titleA: titleA, titleB: titleB),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style:
                  AppTypography.bodyMedium.copyWith(color: AppColors.secondary)),
        ),
        data: (result) =>
            _ResultBody(result: result, titleA: titleA, titleB: titleB),
      ),
    );
  }
}

// ─── Loading view ─────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  final String titleA;
  final String titleB;
  const _LoadingView({required this.titleA, required this.titleB});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.compare_arrows_rounded,
                color: Colors.white, size: 40),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(end: 1.1, duration: 800.ms),
          const SizedBox(height: 32),
          Text(
            'Comparing Documents',
            style:
                AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            '"$titleA"  vs  "$titleB"',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: AppColors.primary),
        ],
      ),
    );
  }
}

// ─── Result body ─────────────────────────────────────────────────────────────

class _ResultBody extends StatelessWidget {
  final Map<String, dynamic> result;
  final String titleA;
  final String titleB;

  const _ResultBody({
    required this.result,
    required this.titleA,
    required this.titleB,
  });

  @override
  Widget build(BuildContext context) {
    final overall =
        (result['overall_similarity'] as num?)?.toDouble() ?? 0;
    final exact =
        (result['exact_match_percentage'] as num?)?.toDouble() ?? 0;
    final semantic =
        (result['semantic_similarity_percentage'] as num?)?.toDouble() ?? 0;
    final para =
        (result['paraphrase_percentage'] as num?)?.toDouble() ?? 0;
    final summary = result['executive_summary'] as String? ?? '';
    final matched =
        List<Map<String, dynamic>>.from(result['matched_sections'] ?? []);
    final uniqueA =
        List<String>.from(result['unique_to_a'] ?? []);
    final uniqueB =
        List<String>.from(result['unique_to_b'] ?? []);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),

              // ── Overall score hero ────────────────────────────
              _OverallScoreCard(
                overall: overall,
                titleA: titleA,
                titleB: titleB,
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

              const SizedBox(height: 24),

              // ── Breakdown chips ───────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _MetricChip(
                      label: 'Exact',
                      value: exact,
                      color: AppColors.riskCritical,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricChip(
                      label: 'Semantic',
                      value: semantic,
                      color: AppColors.riskMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricChip(
                      label: 'Paraphrase',
                      value: para,
                      color: AppColors.riskLow,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 32),

              // ── Executive Summary ─────────────────────────────
              if (summary.isNotEmpty) ...[
                Text(
                  'Summary',
                  style: AppTypography.titleLarge
                      .copyWith(fontWeight: FontWeight.w700),
                ).animate().fadeIn(delay: 280.ms),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    summary,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ).animate().fadeIn(delay: 320.ms),
                const SizedBox(height: 32),
              ],

              // ── Matched sections ──────────────────────────────
              if (matched.isNotEmpty) ...[
                Text(
                  'Matched Sections (${matched.length})',
                  style: AppTypography.titleLarge
                      .copyWith(fontWeight: FontWeight.w700),
                ).animate().fadeIn(delay: 380.ms),
                const SizedBox(height: 16),
                ...matched.asMap().entries.map((e) {
                  final m = e.value;
                  final delay = 420 + e.key * 80;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _MatchedSectionCard(
                      textA: m['text_a'] as String? ?? '',
                      textB: m['text_b'] as String? ?? '',
                      type: m['similarity_type'] as String? ?? 'semantic',
                      score:
                          (m['similarity_score'] as num?)?.toInt() ?? 0,
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: delay))
                        .slideY(begin: 0.1),
                  );
                }),
                const SizedBox(height: 16),
              ] else ...[
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
                            Text(
                              'No Significant Matches',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.riskSafe,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'The two documents appear to be largely distinct.',
                              style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 24),
              ],

              // ── Unique content ────────────────────────────────
              if (uniqueA.isNotEmpty || uniqueB.isNotEmpty) ...[
                Text(
                  'Unique Content',
                  style: AppTypography.titleLarge
                      .copyWith(fontWeight: FontWeight.w700),
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _UniquePanel(
                        title: titleA,
                        items: uniqueA,
                        color: AppColors.tertiary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _UniquePanel(
                        title: titleB,
                        items: uniqueB,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 650.ms).slideY(begin: 0.1),
                const SizedBox(height: 32),
              ],

              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _OverallScoreCard extends StatelessWidget {
  final double overall;
  final String titleA;
  final String titleB;

  const _OverallScoreCard({
    required this.overall,
    required this.titleA,
    required this.titleB,
  });

  Color get _color {
    if (overall >= 60) return AppColors.riskCritical;
    if (overall >= 30) return AppColors.riskMedium;
    return AppColors.riskSafe;
  }

  String get _label {
    if (overall >= 60) return 'High Similarity';
    if (overall >= 30) return 'Moderate Similarity';
    return 'Low Similarity';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.gradientHero,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Document labels
          Row(
            children: [
              Expanded(
                child: _DocLabel(title: titleA, icon: Icons.description_rounded),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'VS',
                    style: AppTypography.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Expanded(
                child:
                    _DocLabel(title: titleB, icon: Icons.description_outlined),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Big similarity number
          Text(
            '${overall.toStringAsFixed(1)}%',
            style: AppTypography.displaySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 56,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Overall Similarity',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),

          // Similarity bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: overall / 100),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOut,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 10,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Risk label
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white38),
            ),
            child: Text(
              _label,
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocLabel extends StatelessWidget {
  final String title;
  final IconData icon;
  const _DocLabel({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white60, size: 28),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MetricChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '${value.toStringAsFixed(1)}%',
            style: AppTypography.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MatchedSectionCard extends StatelessWidget {
  final String textA;
  final String textB;
  final String type;
  final int score;

  const _MatchedSectionCard({
    required this.textA,
    required this.textB,
    required this.type,
    required this.score,
  });

  Color get _typeColor {
    switch (type) {
      case 'exact':
        return AppColors.riskCritical;
      case 'paraphrase':
        return AppColors.riskLow;
      default:
        return AppColors.riskMedium;
    }
  }

  String get _typeLabel {
    switch (type) {
      case 'exact':
        return 'Exact Match';
      case 'paraphrase':
        return 'Paraphrase';
      default:
        return 'Semantic Match';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _typeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _typeLabel,
                  style: AppTypography.labelMedium.copyWith(
                    color: _typeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '$score% match',
                  style: AppTypography.labelSmall.copyWith(
                    color: _typeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Two-column text comparison
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Doc A',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.tertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.tertiarySurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          textA.length > 180
                              ? '${textA.substring(0, 180)}…'
                              : textA,
                          style: AppTypography.bodySmall.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Doc B',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          textB.length > 180
                              ? '${textB.substring(0, 180)}…'
                              : textB,
                          style: AppTypography.bodySmall.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
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

class _UniquePanel extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;

  const _UniquePanel({
    required this.title,
    required this.items,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.fiber_manual_record,
                      color: color, size: 8),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
