import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../scan/providers/scan_provider.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/models/flagged_section.dart';

class RewriteScreen extends ConsumerStatefulWidget {
  final String originalText;
  final String? scanId;
  final String? documentId;
  final int? startPos;
  final int? endPos;
  final PlagiarismType? type;

  const RewriteScreen({
    super.key,
    required this.originalText,
    this.scanId,
    this.documentId,
    this.startPos,
    this.endPos,
    this.type,
  });

  @override
  ConsumerState<RewriteScreen> createState() => _RewriteScreenState();
}

class _RewriteScreenState extends ConsumerState<RewriteScreen> {
  bool _isGenerating = false;
  String? _suggestedText;
  String? _citationReminder;
  String? _errorMessage;
  bool _isNoChanges = false;
  int _selectedToneIndex = 0;

  final List<Map<String, dynamic>> _tones = [
    {'label': 'Academic', 'icon': Icons.school_rounded, 'desc': 'Scholarly & objective'},
    {'label': 'Professional', 'icon': Icons.business_center_rounded, 'desc': 'Direct & authoritative'},
    {'label': 'Concise', 'icon': Icons.compress_rounded, 'desc': 'Eliminates wordiness'},
    {'label': 'Clear', 'icon': Icons.lightbulb_rounded, 'desc': 'Maximizes readability'},
    {'label': 'Formal', 'icon': Icons.account_balance_rounded, 'desc': 'Elevated syntax'},
    {'label': 'Natural', 'icon': Icons.nature_people_rounded, 'desc': 'Fluid scholarly prose'},
    {'label': 'Improve Vocabulary', 'icon': Icons.menu_book_rounded, 'desc': 'Rich academic terms'},
    {'label': 'Simplify', 'icon': Icons.auto_awesome_rounded, 'desc': 'Accessible presentation'},
    {'label': 'Expand', 'icon': Icons.open_in_full_rounded, 'desc': 'Elaborates on logic'},
    {'label': 'Paraphrase', 'icon': Icons.transform_rounded, 'desc': 'Restructures phrasing'},
  ];

  Future<void> _generateRewrite() async {
    setState(() {
      _isGenerating = true;
      _suggestedText = null;
      _citationReminder = null;
      _errorMessage = null;
      _isNoChanges = false;
    });

    try {
      final tone = _tones[_selectedToneIndex]['label'] as String;
      final result = await GeminiService.instance.rewriteText(
        text: widget.originalText,
        style: tone,
      );

      if (!mounted) return;

      final rewritten = (result['rewritten_text'] as String?)?.trim();
      final reminder = result['citation_reminder'] as String?;

      if (rewritten == null || rewritten.isEmpty) {
        setState(() {
          _isGenerating = false;
          _errorMessage = "Couldn't generate a revision. Please try again.";
        });
        return;
      }

      // Check if generated revision is genuinely identical to the original
      if (rewritten.toLowerCase() == widget.originalText.trim().toLowerCase()) {
        setState(() {
          _isGenerating = false;
          _isNoChanges = true;
          _suggestedText = null;
        });
        return;
      }

      setState(() {
        _isGenerating = false;
        _suggestedText = rewritten;
        _citationReminder = reminder;
        _isNoChanges = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorMessage = AppErrorMapper.getUserMessage(
          e,
          fallback: "Couldn't generate a revision. Please try again.",
        );
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    AppSnackbar.showSuccess(context, 'Copied to clipboard');
  }

  @override
  void initState() {
    super.initState();
    _generateRewrite();
  }

  @override
  Widget build(BuildContext context) {
    final isPlagiarismWarningNeeded = widget.type != null &&
        (widget.type == PlagiarismType.exactCopy ||
            widget.type == PlagiarismType.partialCopy ||
            widget.type == PlagiarismType.webDiscovery);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Rewrite Assistant'),
        backgroundColor: AppColors.background,
        elevation: 0,
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
                    // Plagiarism Warning Alert if passage is copied
                    if (isPlagiarismWarningNeeded) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accentSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.accent),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.accent, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Academic Citation Notice',
                                    style: AppTypography.titleSmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'This passage appears similar to an external source. Rewriting does not replace proper scholarly citation. Ensure original authors are credited.',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Original Text Section
                    Text(
                      'Original Text',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        widget.originalText,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                    const SizedBox(height: 28),

                    // Tone Selector
                    Text(
                      'Select Academic Tone Mode',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_tones.length, (index) {
                          final isSelected = _selectedToneIndex == index;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              label: Text(_tones[index]['label']),
                              avatar: Icon(
                                _tones[index]['icon'],
                                size: 16,
                                color: isSelected ? Colors.white : AppColors.primary,
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected && _selectedToneIndex != index) {
                                  setState(() => _selectedToneIndex = index);
                                  _generateRewrite();
                                }
                              },
                              backgroundColor: AppColors.surface,
                              selectedColor: AppColors.primary,
                              labelStyle: AppTypography.labelMedium.copyWith(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected ? AppColors.primary : AppColors.borderLight,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 28),

                    // Suggested Text Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Suggested Revision',
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_suggestedText != null && !_isGenerating)
                          TextButton.icon(
                            onPressed: _generateRewrite,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Regenerate'),
                          ),
                      ],
                    ).animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 12),

                    // 1. Loading State
                    if (_isGenerating)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Preparing your revision...',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Applying ${_tones[_selectedToneIndex]['label']} tone while preserving academic integrity',
                              textAlign: TextAlign.center,
                              style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ).animate().fadeIn()

                    // 2. Fallback: No Meaningful Changes Made
                    else if (_isNoChanges)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 40, color: AppColors.secondary),
                            const SizedBox(height: 12),
                            Text(
                              'AI returned no meaningful changes. Try another tone or regenerate.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _generateRewrite,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Regenerate'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn()

                    // 3. Error State
                    else if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.textTertiary),
                            const SizedBox(height: 12),
                            Text(
                              "Couldn't generate a revision. Please try again.",
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _generateRewrite,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Retry'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn()

                    // 4. Success State: Display Generated Revision
                    else if (_suggestedText != null)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primarySurface),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SelectableText(
                              _suggestedText!,
                              style: AppTypography.bodyLarge.copyWith(
                                height: 1.6,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_citationReminder != null && _citationReminder!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.format_quote_rounded, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _citationReminder!,
                                        style: AppTypography.labelSmall.copyWith(color: AppColors.primary, height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _copyToClipboard(_suggestedText!),
                                  icon: const Icon(Icons.copy_rounded, size: 16),
                                  label: const Text('Copy'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textSecondary,
                                    side: const BorderSide(color: AppColors.borderLight),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                TextButton.icon(
                                  onPressed: _generateRewrite,
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('Regenerate'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn().scale(begin: const Offset(0.98, 0.98)),
                  ],
                ),
              ),
            ),

            // Bottom Action: Apply Revision & Update Document
            if (_suggestedText != null && !_isGenerating)
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
                  text: 'Apply Revision & Update Document',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () async {
                    if (widget.documentId != null &&
                        widget.startPos != null &&
                        widget.endPos != null &&
                        _suggestedText != null) {
                      final success = await ScanService.instance.applyFix(
                        documentId: widget.documentId!,
                        startPos: widget.startPos!,
                        endPos: widget.endPos!,
                        oldText: widget.originalText,
                        newText: _suggestedText!,
                      );

                      if (!mounted) return;
                      if (success) {
                        AppSnackbar.showSuccess(context, 'Document updated! Run a scan to see your updated score.');
                        if (mounted) context.pop();
                      } else {
                        AppSnackbar.showError(context, 'Failed to update document content');
                      }
                    } else {
                      _copyToClipboard(_suggestedText!);
                      if (mounted) context.pop();
                    }
                  },
                ),
              ).animate().fadeIn().slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}
