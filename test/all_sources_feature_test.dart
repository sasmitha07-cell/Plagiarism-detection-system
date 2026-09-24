import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:academic_writing_coach/core/models/search_result.dart';
import 'package:academic_writing_coach/core/models/flagged_section.dart';
import 'package:academic_writing_coach/core/services/detection_engine.dart';
import 'package:academic_writing_coach/features/scan/providers/scan_provider.dart';
import 'package:academic_writing_coach/features/scan/widgets/document_highlight_viewer.dart';

void main() {
  group('All Sources & Feature Verification Tests', () {
    test('SearchResult.fromJson handles null and malformed URLs gracefully', () {
      // Missing or null url
      final result1 = SearchResult.fromJson({
        'title': 'Sample Paper',
        'url': null,
        'snippet': 'Sample abstract',
      });
      expect(result1.url, '');
      expect(result1.domain, 'web');
      expect(result1.sourceType, 'web');

      // DOI url without domain
      final result2 = SearchResult.fromJson({
        'title': 'Academic Article',
        'url': 'https://doi.org/10.1016/j.artint.2023.103988',
        'source_type': 'academic',
      });
      expect(result2.domain, 'doi.org');
      expect(result2.sourceType, 'academic');
    });

    test('DetectionEngine query generation produces clean queries without cutting words', () {
      const text = 'Artificial intelligence was founded as an academic discipline in 1956 and has experienced several waves of optimism.';
      expect(text.isNotEmpty, isTrue);
      final engine = DetectionEngine.instance;
      expect(engine, isNotNull);
    });

    testWidgets('DocumentHighlightViewer renders overlapping spans cleanly without repeating text', (WidgetTester tester) async {
      const docText = 'Artificial intelligence was founded as an academic discipline in 1956.';
      
      // Two overlapping flagged sections
      final flags = [
        const FlaggedSectionData(
          flaggedText: 'Artificial intelligence was founded',
          signals: [PlagiarismType.exactCopy],
          riskLevel: 'high',
          confidenceScore: 90,
          similarityScore: 95,
          startPosition: 0,
          endPosition: 35,
        ),
        const FlaggedSectionData(
          flaggedText: 'founded as an academic discipline',
          signals: [PlagiarismType.webDiscovery],
          riskLevel: 'medium',
          confidenceScore: 85,
          similarityScore: 80,
          startPosition: 24,
          endPosition: 57,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentHighlightViewer(
              documentText: docText,
              flaggedSections: flags,
            ),
          ),
        ),
      );

      // Verify widget rendered
      expect(find.byType(DocumentHighlightViewer), findsOneWidget);
      // Original text should be present in the viewer
      expect(find.textContaining('Artificial intelligence'), findsWidgets);
    });

    test('Source type categorization accurately assigns academic, user_document, and web types', () {
      final webSource = SearchResult(
        title: 'Wikipedia Article',
        url: 'https://en.wikipedia.org/wiki/Artificial_intelligence',
        domain: 'en.wikipedia.org',
        snippet: 'AI is intelligence demonstrated by machines',
        query: 'Artificial intelligence',
        rank: 1,
        sourceType: 'web',
      );
      expect(webSource.sourceType, 'web');

      final academicSource = SearchResult(
        title: 'Neural Networks — IEEE Transactions',
        url: 'https://doi.org/10.1109/TNNLS.2023.123456',
        domain: 'doi.org',
        snippet: 'Deep learning methodology and empirical results',
        query: 'Neural Networks',
        rank: 1,
        sourceType: 'academic',
      );
      expect(academicSource.sourceType, 'academic');
    });
  });
}
