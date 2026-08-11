import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/services/document_extraction_service.dart';

/// Upload card used in the document comparison screen.
/// Calls [onDocumentLoaded] with both the file name and its extracted text.
class CompareUploadCard extends StatefulWidget {
  final String label;
  /// Called with (fileName, extractedText) once a file is picked and parsed.
  final void Function(String fileName, String text) onDocumentLoaded;
  final VoidCallback onClear;

  const CompareUploadCard({
    super.key,
    required this.label,
    required this.onDocumentLoaded,
    required this.onClear,
  });

  @override
  State<CompareUploadCard> createState() => _CompareUploadCardState();
}

class _CompareUploadCardState extends State<CompareUploadCard> {
  File? _file;
  bool _isExtracting = false;
  String? _fileName;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _file = File(result.files.single.path!);
          _fileName =
              result.files.single.name;
          _isExtracting = true;
        });

        final text = await DocumentExtractionService.instance
            .extractFromFile(result.files.single);

        if (!mounted) return;
        setState(() => _isExtracting = false);

        if (text == null || text.trim().isEmpty) {
          AppSnackbar.showError(context, 'Could not extract text from this file.');
          setState(() => _file = null);
          return;
        }

        widget.onDocumentLoaded(_fileName!, text);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _file = null;
          _isExtracting = false;
        });
        AppSnackbar.showError(context, 'Failed to pick file: $e');
      }
    }
  }

  void _clear() {
    setState(() {
      _file = null;
      _fileName = null;
    });
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        if (_file == null && !_isExtracting)
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.borderLight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.upload_file_rounded,
                      color: AppColors.textDisabled,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to upload file',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (_isExtracting)
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.riskSafe),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_rounded,
                    color: AppColors.riskSafe),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _fileName ?? _file!.path.split(Platform.pathSeparator).last,
                    style: AppTypography.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textTertiary),
                  onPressed: _clear,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
