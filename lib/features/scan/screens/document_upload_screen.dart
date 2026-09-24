import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/services/document_extraction_service.dart';

class DocumentUploadScreen extends ConsumerStatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  ConsumerState<DocumentUploadScreen> createState() =>
      _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  File? _selectedFile;
  String? _extractedText;
  bool _isExtracting = false;
  int _wordCount = 0;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'rtf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _isExtracting = true;
          _extractedText = null;
          _wordCount = 0;
        });

        // Extract text
        final text = await DocumentExtractionService.instance
            .extractFromFile(result.files.single);

        if (mounted) {
          setState(() {
            _extractedText = text;
            _isExtracting = false;
            _wordCount = DocumentExtractionService.instance.countWords(text ?? '');
          });

          if (text == null || text.trim().isEmpty) {
            AppSnackbar.showError(
                context, 'Could not extract text from this document.');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExtracting = false);
        AppSnackbar.showError(context, 'Error picking file: $e');
      }
    }
  }

  void _startAnalysis() {
    if (_extractedText == null || _extractedText!.trim().isEmpty) return;

    final sessionScanId = 'session_${DateTime.now().microsecondsSinceEpoch}';
    final fileName = _selectedFile?.path.split(Platform.pathSeparator).last ?? 'Document';

    context.go('/scan/processing/$sessionScanId', extra: {
      'title': fileName,
      'content': _extractedText,
      'type': fileName.split('.').last,
      'file': _selectedFile,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Upload Document'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select a file to analyze',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Supported formats: PDF, DOCX, TXT, RTF (Max 50MB)',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Upload Area
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.tertiaryLight,
                      width: 2,
                      style: BorderStyle.none, // Can't easily do dashed in basic container, using solid light blue
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.tertiary.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.tertiarySurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          color: AppColors.tertiary,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tap to browse files',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 32),

              // File Status
              if (_isExtracting) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Extracting text...',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ] else if (_selectedFile != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.riskSafeLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description_rounded,
                          color: AppColors.riskSafe, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFile!.path.split(Platform.pathSeparator).last,
                              style: AppTypography.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_wordCount words extracted',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textTertiary),
                        onPressed: () {
                          setState(() {
                            _selectedFile = null;
                            _extractedText = null;
                            _wordCount = 0;
                          });
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
              ],

              const Spacer(),

              GradientButton(
                text: 'Analyze Document',
                icon: Icons.analytics_rounded,
                onPressed: (_selectedFile != null &&
                        !_isExtracting &&
                        _wordCount > 10)
                    ? _startAnalysis
                    : null,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A6FA5), Color(0xFF6B8EC2)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
