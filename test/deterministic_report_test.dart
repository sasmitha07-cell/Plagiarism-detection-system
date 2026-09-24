import 'package:flutter_test/flutter_test.dart';
import 'package:academic_writing_coach/core/services/detection_engine.dart';
import 'package:academic_writing_coach/core/services/document_processor.dart';
import 'package:academic_writing_coach/core/models/match_evidence.dart';
import 'package:academic_writing_coach/core/models/flagged_section.dart';

void main() {
  group('DetectionEngine Deterministic Scoring Tests', () {
    test('Zero Evidence gives 0% similarity and clean summary', () {
      const text = 'This is a completely original document with no matching content in any database.';
      final chunks = DocumentProcessor.instance.chunkDocument(text);
      final report = DetectionEngine.instance.computeDeterministicReport(
        text: text,
        evidence: [],
        chunks: chunks,
      );

      expect(report['overall_similarity_score'], 0.0);
      expect(report['exact_match_score'], 0.0);
      expect(report['flagged_sections'], isEmpty);
      expect(report['executive_summary'].toString().contains('highly original'), true);
    });

    test('Exact match evidence computes proper weighted scores and flags', () {
      const text = 'Here is the first copied paragraph with direct source phrases. And here is unique outro.';
      final chunks = DocumentProcessor.instance.chunkDocument(text);
      final evidence = [
        MatchEvidence(
          submittedText: 'Here is the first copied paragraph with direct source phrases.',
          matchedText: 'Here is the first copied paragraph with direct source phrases.',
          sourceTitle: 'Wikipedia Article',
          sourceUrl: 'https://en.wikipedia.org/wiki/Test',
          signals: [PlagiarismType.exactCopy],
          exactSimilarity: 1.0,
          startOffset: 0,
          endOffset: 63,
        ),
      ];

      final report = DetectionEngine.instance.computeDeterministicReport(
        text: text,
        evidence: evidence,
        chunks: chunks,
      );

      expect((report['overall_similarity_score'] as double) > 0, true);
      expect((report['exact_match_score'] as double) > 0, true);
      expect((report['flagged_sections'] as List).isNotEmpty, true);
    });
  });
}
