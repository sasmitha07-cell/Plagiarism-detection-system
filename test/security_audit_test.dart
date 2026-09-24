import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Security and Zero-Secret Client Audit Tests', () {
    test('Ensures no hardcoded Gemini API keys exist in lib directory', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

      for (final file in files) {
        final content = file.readAsStringSync();

        // Check for Google AI Studio / Gemini API Key patterns
        expect(
          content.contains(RegExp(r'AIza[0-9A-Za-z-_]{35}')),
          isFalse,
          reason: 'Hardcoded Gemini API key found in ${file.path}',
        );

        // Check for client-side search engine API key assignments
        expect(
          content.contains(RegExp(r'SEARCH_API_KEY\s*=\s*["\x27][A-Za-z0-9_-]+')),
          isFalse,
          reason: 'Hardcoded Search API key found in ${file.path}',
        );
      }
    });

    test('Ensures all external AI and search requests route via Supabase functions', () {
      final geminiServiceFile = File('lib/core/services/gemini_service.dart');
      expect(geminiServiceFile.existsSync(), isTrue);

      final content = geminiServiceFile.readAsStringSync();

      // Confirms calls are routed through functions.invoke
      expect(content.contains("functions.invoke(\n        'gemini-reasoning'") || content.contains("functions.invoke('gemini-reasoning'"), isTrue);
      expect(content.contains("generate-embeddings"), isTrue);
    });
  });
}
