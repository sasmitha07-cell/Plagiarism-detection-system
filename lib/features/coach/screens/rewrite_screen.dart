import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/app_snackbar.dart';

class RewriteScreen extends ConsumerStatefulWidget {
  final String originalText;
  final String? scanId;

  const RewriteScreen({
    super.key,
    required this.originalText,
    this.scanId,
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
    setState(() => _isGenerating = true);
    
    // Simulate API call to Gemini
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    setState(() {
      _isGenerating = false;
      // Mock generated text based on tone
      switch (_selectedToneIndex) {
        case 0:
          _suggestedText = 'The proliferation of machine learning paradigms has fundamentally transformed the methodological approaches within artificial intelligence studies.';
          break;
        case 1:
          _suggestedText = 'Machine learning has changed how we do AI research.';
          break;
        case 2:
          _suggestedText = 'It is undeniable that machine learning algorithms are revolutionizing the very foundation of artificial intelligence research.';
          break;
        case 3:
          _suggestedText = 'Machine learning algorithms have significantly changed AI research.';
          break;
      }
    });
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
                  text: 'Apply Fix & Return',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () {
                    // Simulate applying fix
                    AppSnackbar.showSuccess(context, 'Text updated successfully');
                    context.pop();
                  },
                ),
              ).animate().fadeIn().slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}
