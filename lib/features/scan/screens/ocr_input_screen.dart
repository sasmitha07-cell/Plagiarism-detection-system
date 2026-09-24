import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/services/document_extraction_service.dart';

class OcrInputScreen extends ConsumerStatefulWidget {
  const OcrInputScreen({super.key});

  @override
  ConsumerState<OcrInputScreen> createState() => _OcrInputScreenState();
}

class _OcrInputScreenState extends ConsumerState<OcrInputScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  
  File? _imageFile;
  String? _extractedText;
  bool _isExtracting = false;
  int _wordCount = 0;

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _isExtracting = true;
          _extractedText = null;
          _wordCount = 0;
        });
        
        await _processImage();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExtracting = false);
        AppSnackbar.showError(context, 'Failed to pick image: $e');
      }
    }
  }

  Future<void> _processImage() async {
    if (_imageFile == null) return;

    try {
      final inputImage = InputImage.fromFile(_imageFile!);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (mounted) {
        setState(() {
          _extractedText = recognizedText.text;
          _wordCount = DocumentExtractionService.instance.countWords(_extractedText ?? '');
          _isExtracting = false;
        });

        if (_extractedText == null || _extractedText!.trim().isEmpty) {
          AppSnackbar.showError(context, 'No text could be found in this image.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExtracting = false);
        AppSnackbar.showError(context, 'Failed to process image: $e');
      }
    }
  }

  void _startAnalysis() {
    if (_extractedText == null || _extractedText!.trim().isEmpty) return;

    final sessionScanId = 'session_${DateTime.now().microsecondsSinceEpoch}';

    context.go('/scan/processing/$sessionScanId', extra: {
      'title': 'Scanned Image',
      'content': _extractedText,
      'type': 'image',
      'file': _imageFile,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan Image'),
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
                    if (_imageFile == null) ...[
                      const SizedBox(height: 40),
                      Center(
                        child: Icon(
                          Icons.document_scanner_rounded,
                          size: 100,
                          color: AppColors.secondary.withValues(alpha: 0.2),
                        ),
                      ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 32),
                      Text(
                        'Extract text from images',
                        textAlign: TextAlign.center,
                        style: AppTypography.titleLarge,
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 16),
                      Text(
                        'Take a photo of a document or upload an image to automatically extract text for plagiarism analysis.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 48),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_rounded),
                              label: const Text('Camera'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.secondary,
                                side: const BorderSide(color: AppColors.secondary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_rounded),
                              label: const Text('Gallery'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.secondary,
                                side: const BorderSide(color: AppColors.secondary),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                    ] else ...[
                      // Image Preview
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                              ),
                              onPressed: () {
                                setState(() {
                                  _imageFile = null;
                                  _extractedText = null;
                                  _wordCount = 0;
                                });
                              },
                            ),
                          ),
                        ),
                      ).animate().fadeIn(),
                      
                      const SizedBox(height: 24),
                      
                      if (_isExtracting) ...[
                        const Center(child: CircularProgressIndicator(color: AppColors.secondary)),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Extracting text...',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ] else if (_extractedText != null && _extractedText!.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Extracted Text',
                              style: AppTypography.titleMedium,
                            ),
                            Text(
                              '$_wordCount words',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Text(
                            _extractedText!,
                            style: AppTypography.bodyMedium,
                          ),
                        ).animate().fadeIn().slideY(begin: 0.1),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            
            if (_imageFile != null)
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
                  text: 'Analyze Image Text',
                  icon: Icons.analytics_rounded,
                  onPressed: (_extractedText != null && !_isExtracting && _wordCount > 10) 
                      ? _startAnalysis 
                      : null,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE05A4A), Color(0xFFEB7D6F)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
