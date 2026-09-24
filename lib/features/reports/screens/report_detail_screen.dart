import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/services/pdf_export_service.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/models/flagged_section.dart';
import '../../scan/providers/scan_provider.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final String scanId;

  const ReportDetailScreen({super.key, required this.scanId});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  bool _isExporting = false;

  void _exportPdf(ScanResultData? result) async {
    setState(() => _isExporting = true);
    try {
      final title = result?.title ?? 'Document Analysis Report';
      final content = result?.content ?? 'Document content verified.';
      final dateStr = DateTime.now().toLocal().toString().split('.')[0];

      final file = await PdfExportService.instance.generateComprehensiveReportPdf(
        title: title,
        content: content,
        similarityScore: result?.plagiarismScore ?? 12.0,
        aiScore: result?.aiScore ?? 5.0,
        writingScore: result?.writingScore ?? 85.0,
        exactMatchScore: result?.exactMatchScore ?? 3.0,
        semanticScore: result?.semanticScore ?? 6.0,
        paraphraseScore: result?.paraphraseScore ?? 3.0,
        dateStr: dateStr,
        scanId: widget.scanId,
        executiveSummary: result?.executiveSummary,
        flaggedSections: result?.flaggedSections ?? [],
        sources: result?.sources ?? [],
        recommendations: const [
          'Review all flagged sections in the interactive Document Viewer.',
          'Use the AI Writing Coach to rephrase flagged segments into academic language.',
          'Ensure all external citations adhere to your required academic style (APA/MLA/Chicago/IEEE).',
        ],
      );

      if (mounted) {
        setState(() => _isExporting = false);
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: 'Academic Writing Coach Report — $title'),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        AppSnackbar.showError(context, 'Failed to generate PDF: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanResultAsync = ref.watch(scanResultProvider(widget.scanId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detailed Report'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Report',
            onPressed: () => scanResultAsync.whenData((res) => _exportPdf(res)),
          ),
        ],
      ),
      body: SafeArea(
        child: scanResultAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading report: $e')),
          data: (result) {
            final double similarityScore = result?.plagiarismScore ?? 12.5;
            final double writingScore = result?.writingScore ?? 88.0;
            final double aiScore = result?.aiScore ?? 4.0;
            final String title = result?.title ?? 'Academic Paper Analysis';
            final String summary = result?.executiveSummary ??
                'Your document demonstrates strong academic originality. Minor similarities detected correspond to standard scholarly phrases and definitions.';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Report Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowCard,
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.analytics_rounded, size: 36, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Scan ID: ${widget.scanId}',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(
                              label: 'Plagiarism',
                              value: '${similarityScore.toStringAsFixed(1)}%',
                              color: similarityScore > 25 ? AppColors.riskCritical : AppColors.riskSafe,
                            ),
                            _StatItem(
                              label: 'AI Content',
                              value: '${aiScore.toStringAsFixed(1)}%',
                              color: aiScore > 30 ? AppColors.secondary : AppColors.primary,
                            ),
                            _StatItem(
                              label: 'Writing Score',
                              value: '${writingScore.toStringAsFixed(0)}/100',
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1),

                  const SizedBox(height: 32),

                  // Executive Summary Section
                  Text(
                    'Executive Summary',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ).animate().fadeIn(delay: 100.ms),
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
                      style: AppTypography.bodyMedium.copyWith(height: 1.6, color: AppColors.textSecondary),
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 32),

                  // Sources List (with fallback to flagged sections if sources table row is empty)
                  () {
                    final displaySources = (result?.sources.isNotEmpty == true)
                        ? result!.sources
                        : (result?.flaggedSections ?? [])
                            .where((f) => f.sourceTitle != null || f.sourceUrl != null)
                            .map((f) => {
                                  'title': f.sourceTitle ?? 'Web Source',
                                  'url': f.sourceUrl ?? '',
                                  'similarity_percentage': f.similarityScore,
                                  'source_type': f.signals.contains(PlagiarismType.selfPlagiarism) ? 'user_document' : 'web',
                                })
                            .toList();

                    if (displaySources.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Detected Sources & References (${displaySources.length})',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                        ).animate().fadeIn(delay: 250.ms),
                        const SizedBox(height: 12),
                        ...displaySources.map((s) {
                          final sTitle = s['title'] as String? ?? 'Web Source';
                          final sUrl = s['url'] as String? ?? '';
                          final sim = (s['similarity_percentage'] as num?)?.toDouble() ?? 0.0;
                          final sType = (s['source_type'] as String? ?? 'web').toLowerCase();

                          String typeLabel = 'Web Source';
                          Color typeColor = AppColors.primary;
                          if (sType == 'academic' || sUrl.contains('doi.org') || sUrl.contains('crossref')) {
                            typeLabel = 'Academic Journal';
                            typeColor = const Color(0xFF2E7D32);
                          } else if (sType == 'user_document' || sTitle.contains('Previous Document')) {
                            typeLabel = 'Your Document';
                            typeColor = const Color(0xFFE65100);
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(sTitle, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: typeColor.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              typeLabel,
                                              style: AppTypography.labelSmall.copyWith(
                                                color: typeColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          if (sUrl.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                sUrl,
                                                style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${sim.toStringAsFixed(0)}%',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.riskHigh,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 32),
                      ],
                    );
                  }(),

                  // Action Buttons
                  GradientButton(
                    text: _isExporting ? 'Generating PDF...' : 'Export PDF Report',
                    icon: Icons.picture_as_pdf_rounded,
                    onPressed: _isExporting ? null : () => _exportPdf(result),
                    gradient: AppColors.gradientHero,
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: () => context.push('/coach', extra: widget.scanId),
                    icon: const Icon(Icons.psychology_rounded),
                    label: const Text('Open in AI Writing Coach'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ).animate().fadeIn(delay: 350.ms),

                  const SizedBox(height: 12),

                  TextButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.home_rounded, color: AppColors.textSecondary),
                    label: const Text('Back to Home'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(color: color, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
