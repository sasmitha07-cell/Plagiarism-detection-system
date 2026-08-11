import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/services/pdf_export_service.dart';
import '../../../core/widgets/app_snackbar.dart';

class ReportDetailScreen extends StatefulWidget {
  final String scanId;

  const ReportDetailScreen({super.key, required this.scanId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool _isExporting = false;

  void _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final file = await PdfExportService.instance.generateReportPdf(
        title: 'Document Analysis',
        content: 'This is a sample text representing the analyzed document content.',
        similarityScore: 12.5,
        writingScore: 88.0,
        dateStr: DateTime.now().toString().split(' ')[0],
        scanId: widget.scanId,
      );

      if (mounted) {
        setState(() => _isExporting = false);
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(file.path)], text: 'Plagiarism & Writing Report');
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detailed Report'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
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
                  children: [
                    const Icon(Icons.analytics_rounded, size: 48, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Scan Complete',
                      style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'ID: ${widget.scanId}',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(label: 'Similarity', value: '12.5%', color: AppColors.riskSafe),
                        _StatItem(label: 'Writing Score', value: '88', color: AppColors.primary),
                        _StatItem(label: 'Words', value: '1,245', color: AppColors.textPrimary),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 32),

              Text(
                'Report Summary',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 12),
              
              Text(
                'Your document shows strong originality. The minor similarities found are correctly cited. The writing is clear and well-structured, but could benefit from a few vocabulary enhancements.',
                style: AppTypography.bodyMedium.copyWith(height: 1.6),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 48),

              GradientButton(
                text: _isExporting ? 'Generating PDF...' : 'Export as PDF',
                icon: Icons.picture_as_pdf_rounded,
                onPressed: _isExporting ? null : _exportPdf,
                gradient: AppColors.gradientHero,
              ).animate().fadeIn(delay: 300.ms),
              
              const SizedBox(height: 16),
              
              TextButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home_rounded, color: AppColors.secondary),
                label: const Text('Back to Home'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
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
          style: AppTypography.titleMedium.copyWith(color: color, fontWeight: FontWeight.w800),
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
