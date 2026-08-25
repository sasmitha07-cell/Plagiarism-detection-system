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

class RewriteScreen extends ConsumerStatefulWidget {
  final String originalText;
  final String? scanId;
  final String? documentId;
  final int? startPos;
  final int? endPos;

  const RewriteScreen({
    super.key,
    required this.originalText,
    this.scanId,
    this.documentId,
    this.startPos,
    this.endPos,
  });

  @override
  ConsumerState<RewriteScreen> createState() => _RewriteScreenState();
}

class _RewriteScreenState extends ConsumerState<RewriteScreen> {
  bool _isGenerating = false;
  String? _suggestedText;
  int _selectedToneIndex = 0;

  final List<Map<String, dynamic>> _tones = [
    {'label': 'Academic', 'icon': Icons.school_rounded},
    {'label': 'Simplified', 'icon': Icons.auto_awesome_rounded},
    {'label': 'Persuasive', 'icon': Icons.campaign_rounded},
    {'label': 'Concise', 'icon': Icons.compress_rounded},
  ];

  Future<void> _generateRewrite() async {
    setState(() {
      _isGenerating = true;
      _suggestedText = null;
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
        if (result['rewritten_text'] != null) {
          _suggestedText = result['rewritten_text'] as String?;
        } else {
          AppSnackbar.showError(context, result['error'] ?? 'AI failed to generate a rewrite. Please try again.');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      AppSnackbar.showError(context, 'Connection error. Please check your internet.');
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    AppSnackbar.showSuccess(context, 'Copied to clipboard');
  }

  @override
  void initState() {
    super.initState();
    // Auto-generate on load
    _generateRewrite();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rewrite Assistant'),
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
                    // Original Text Section
                    Text(
                      'Original Text',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 12),
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
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    
                    const SizedBox(height: 32),
                    
                    // Tone Selector
                    Text(
                      'Select Tone',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_tones.length, (index) {
                          final isSelected = _selectedToneIndex == index;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ChoiceChip(
                              label: Text(_tones[index]['label']),
                              avatar: Icon(
                                _tones[index]['icon'],
                                size: 16,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected && _selectedToneIndex != index) {
                                  setState(() {
                                    _selectedToneIndex = index;
                                  });
                                  _generateRewrite();
                                }
                              },
                              backgroundColor: AppColors.surface,
                              selectedColor: AppColors.primary,
                              labelStyle: AppTypography.labelMedium.copyWith(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          );
                        }),
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),
                    
                    const SizedBox(height: 32),
                    
                    // Suggested Text Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AI Suggestion',
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
                        height: 150,
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
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF9F6F1), Color(0xFFEFF8F3)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primarySurface),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.05),
                              blurRadius: 10,
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
                              ),
                            ),
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
                      ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
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
                  text: 'Apply Fix & Save',
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

                      if (success && mounted) {
                        AppSnackbar.showSuccess(context, 'Document updated! Run a new scan to see your improved score.');
                        context.pop();
                      } else if (mounted) {
                        AppSnackbar.showError(context, 'Failed to update document');
                      }
                    } else {
                      AppSnackbar.showSuccess(context, 'Text copied to clipboard');
                      context.pop();
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
