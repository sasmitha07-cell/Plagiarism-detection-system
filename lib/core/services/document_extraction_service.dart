import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class DocumentExtractionService {
  DocumentExtractionService._();
  static DocumentExtractionService get instance =>
      DocumentExtractionService._();

  /// Extract text from a file picked by user
  Future<String?> extractFromFile(PlatformFile file) async {
    final path = file.path;
    if (path == null) return null;

    final ext = file.extension?.toLowerCase() ?? '';
    switch (ext) {
      case 'pdf':
        return await _extractFromPdf(File(path));
      case 'txt':
        return await File(path).readAsString();
      case 'rtf':
        return await _extractFromRtf(File(path));
      case 'docx':
      case 'doc':
        return await _extractFromDocx(File(path));
      default:
        return await File(path).readAsString();
    }
  }

  /// Extract text from PDF using Syncfusion
  Future<String> _extractFromPdf(File file) async {
    final Uint8List bytes = await file.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < document.pages.count; i++) {
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String text = extractor.extractText(startPageIndex: i, endPageIndex: i);
      buffer.write(text);
      buffer.write('\n\n');
    }

    document.dispose();
    return buffer.toString().trim();
  }

  /// Extract text from RTF (strip RTF markup)
  Future<String> _extractFromRtf(File file) async {
    final content = await file.readAsString();
    // Basic RTF stripping
    final plainText = content
        .replaceAll(RegExp(r'\\[a-z]+\d* ?'), ' ')
        .replaceAll(RegExp(r'\{.*?\}'), '')
        .replaceAll(RegExp(r'[\\{}]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return plainText;
  }

  /// Extract text from DOCX (read XML content)
  Future<String> _extractFromDocx(File file) async {
    // For DOCX, we use a simple XML extraction approach
    // Full implementation would use a DOCX parser package
    try {
      final bytes = await file.readAsBytes();
      // Convert bytes to string and extract text between XML tags
      final content = String.fromCharCodes(bytes);
      final regex = RegExp(r'<w:t[^>]*>([^<]*)</w:t>');
      final matches = regex.allMatches(content);
      final textParts = matches.map((m) => m.group(1) ?? '').toList();
      return textParts.join(' ').trim();
    } catch (e) {
      return 'Could not extract text from DOCX file. Please try converting to PDF or TXT.';
    }
  }

  /// Count words in text
  int countWords(String text) {
    return text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  /// Get character count (excluding spaces)
  int countCharacters(String text) {
    return text.replaceAll(' ', '').length;
  }

  /// Split text into sentences for analysis
  List<String> splitIntoSentences(String text) {
    return text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  /// Extract key phrases for web search
  List<String> extractKeyPhrases(String text, {int maxPhrases = 5}) {
    final sentences = splitIntoSentences(text);
    final phrases = <String>[];

    for (final sentence in sentences.take(10)) {
      final words = sentence.trim().split(' ');
      if (words.length >= 6) {
        // Take 6-10 word phrases for searching
        final end = words.length.clamp(0, 10);
        phrases.add(words.take(end).join(' '));
      }
      if (phrases.length >= maxPhrases) break;
    }

    return phrases;
  }
}
