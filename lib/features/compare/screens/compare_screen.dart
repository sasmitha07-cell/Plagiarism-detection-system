import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/gradient_button.dart';
import '../widgets/compare_upload_card.dart';

class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key});

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  // Track both file names and extracted text content for each document
  String? _docAName;
  String? _docAText;
  String? _docBName;
  String? _docBText;

  void _startComparison() {
    if (_docAText == null || _docBText == null) return;

    final mockCompareId = 'comp_${DateTime.now().millisecondsSinceEpoch}';
    context.go('/compare/result/$mockCompareId', extra: {
      'titleA': _docAName ?? 'Document A',
      'textA': _docAText,
      'titleB': _docBName ?? 'Document B',
      'textB': _docBText,
    });
  }

  @override
  Widget build(BuildContext context) {
    final canCompare = _docAText != null && _docBText != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Compare Documents'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Side-by-Side Analysis',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

                    const SizedBox(height: 8),

                    Text(
                      'Upload two documents to check for similarities and exact matches between them.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ).animate().fadeIn(delay: 150.ms),

                    const SizedBox(height: 32),

                    // Document A
                    CompareUploadCard(
                      label: 'Source Document (A)',
                      onDocumentLoaded: (name, text) =>
                          setState(() {
                            _docAName = name;
                            _docAText = text;
                          }),
                      onClear: () => setState(() {
                        _docAName = null;
                        _docAText = null;
                      }),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                    const SizedBox(height: 16),

                    // VS Circle
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderLight),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowCard,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'VS',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 250.ms).scale(),

                    const SizedBox(height: 16),

                    // Document B
                    CompareUploadCard(
                      label: 'Target Document (B)',
                      onDocumentLoaded: (name, text) =>
                          setState(() {
                            _docBName = name;
                            _docBText = text;
                          }),
                      onClear: () => setState(() {
                        _docBName = null;
                        _docBText = null;
                      }),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
            ),

            // Bottom Action
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowCard,
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: GradientButton(
                text: 'Run Comparison',
                icon: Icons.compare_arrows_rounded,
                onPressed: canCompare ? _startComparison : null,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A6FA5), Color(0xFF6B8EC2)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
