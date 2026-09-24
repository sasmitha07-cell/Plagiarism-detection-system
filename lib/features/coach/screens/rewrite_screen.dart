import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../scan/providers/scan_provider.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
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
    });

    try {
      final tone = _tones[_selectedToneIndex]['label'] as String;
      final result = await GeminiService.instance.rewriteText(
        text: widget.originalText,
        style: tone,
      );

      if (!mounted) return;

      setState(() {
        _isGenerating = false;
        if (result['rewritten_text'] != null && result['rewritten_text'].toString().isNotEmpty) {
          _suggestedText = result['rewritten_text'] as String?;
          _citationReminder = result['citation_reminder'] as String?;
        } else {
          // Deterministic fallback rewrite if edge service offline
          _suggestedText = _generateLocalParaphrase(widget.originalText, tone);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        final tone = _tones[_selectedToneIndex]['label'] as String;
        _suggestedText = _generateLocalParaphrase(widget.originalText, tone);
      });
    }
  }

  String _generateLocalParaphrase(String text, String style) {
    String out = text;
    out = out.replaceAll(RegExp(r'\ba lot of\b', caseSensitive: false), 'a substantial volume of');
    out = out.replaceAll(RegExp(r'\bin order to\b', caseSensitive: false), 'to');
    out = out.replaceAll(RegExp(r'\bdue to the fact that\b', caseSensitive: false), 'because');
    out = out.replaceAll(RegExp(r'\blook into\b', caseSensitive: false), 'investigate');
    out = out.replaceAll(RegExp(r'\bshow\b', caseSensitive: false), 'demonstrate');
    out = out.replaceAll(RegExp(r'\bget\b', caseSensitive: false), 'obtain');
    out = out.replaceAll(RegExp(r'\bkids\b', caseSensitive: false), 'adolescents');
    out = out.replaceAll(RegExp(r'\bthings\b', caseSensitive: false), 'variables');
    return out;
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
    final isPlagiarismWarningNeeded = widget.type == PlagiarismType.exactCopy ||
        widget.type == PlagiarismType.webDiscovery ||
        widget.type == PlagiarismType.selfPlagiarism;

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

                    // Suggested Text Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Suggested Revision',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
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

                    if (_isGenerating)
                      Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ).animate().fadeIn()
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
                            Text(
                              _suggestedText!,
                              style: AppTypography.bodyLarge.copyWith(
                                height: 1.6,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_citationReminder != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _citationReminder!,
                                style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
                                  onPressed: () => _copyToClipboard(_suggestedText!),
                                  tooltip: 'Copy to clipboard',
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

            // Bottom Action
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
