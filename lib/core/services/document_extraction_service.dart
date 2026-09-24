import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:docx_to_text/docx_to_text.dart';

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

  /// Extract text from DOCX
  Future<String> _extractFromDocx(File file) async {
    try {
      final bytes = await file.readAsBytes();
      String text = docxToText(bytes);

      // If docx_to_text returned raw WordprocessingML XML (e.g. <w:document...)
      if (text.contains('<w:document') || text.contains('<?xml') || text.contains('<w:p') || text.contains('<w:t')) {
        text = _cleanDocxXml(text);
      }

      if (text.trim().isNotEmpty) {
        return text.trim();
      }
      return 'Could not extract text from DOCX file. The document might be empty or password protected.';
    } catch (e) {
      return 'Could not extract text from DOCX file: $e. Please try converting to PDF or TXT.';
    }
  }

  String _cleanDocxXml(String xml) {
    // 1. Extract text from <w:t> tags
    final matches = RegExp(r'<w:t[^>]*>(.*?)</w:t>', dotAll: true).allMatches(xml);
    if (matches.isNotEmpty) {
      final buffer = StringBuffer();
      for (final m in matches) {
        final val = m.group(1) ?? '';
        buffer.write(val);
        buffer.write(' ');
      }
      var clean = buffer.toString();
      clean = clean
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&amp;', '&')
          .replaceAll('&quot;', '"')
          .replaceAll('&apos;', "'");
      return clean.replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    // 2. Fallback: Strip all XML tags and decode entities
    final stripped = xml
        .replaceAll(RegExp(r'</w:p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return stripped;
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
