import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/services/document_extraction_service.dart';

class TextInputScreen extends ConsumerStatefulWidget {
  const TextInputScreen({super.key});

  @override
  ConsumerState<TextInputScreen> createState() => _TextInputScreenState();
}

class _TextInputScreenState extends ConsumerState<TextInputScreen> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_updateWordCount);
  }

  @override
  void dispose() {
    _textController.removeListener(_updateWordCount);
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _updateWordCount() {
    final count = DocumentExtractionService.instance.countWords(_textController.text);
    if (_wordCount != count) {
      setState(() => _wordCount = count);
    }
  }

  void _startAnalysis() {
    if (_textController.text.trim().isEmpty) return;
    
    final sessionScanId = 'session_${DateTime.now().microsecondsSinceEpoch}';
    
    // Navigate to processing screen
    context.go('/scan/processing/$sessionScanId', extra: {
      'title': _titleController.text.isNotEmpty ? _titleController.text : 'Pasted Text',
      'content': _textController.text,
      'type': 'txt'
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paste Text'),
        backgroundColor: AppColors.background,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '$_wordCount words',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      style: AppTypography.titleLarge,
                      decoration: InputDecoration(
                        hintText: 'Document Title (Optional)',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintStyle: AppTypography.titleLarge.copyWith(
                          color: AppColors.textDisabled,
                        ),
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _textController,
                      style: AppTypography.bodyLarge,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Paste your essay, article, or research paper here...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintStyle: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textDisabled,
                        ),
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Bar
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
                text: 'Analyze Text',
                icon: Icons.analytics_rounded,
                onPressed: _wordCount > 10 ? _startAnalysis : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
