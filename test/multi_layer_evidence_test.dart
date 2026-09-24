import 'package:flutter_test/flutter_test.dart';
import 'package:academic_writing_coach/core/services/detection_engine.dart';
import 'package:academic_writing_coach/core/services/document_processor.dart';
import 'package:academic_writing_coach/core/models/match_evidence.dart';
import 'package:academic_writing_coach/core/models/flagged_section.dart';

void main() {
  group('Multi-Layer Evidence & Transparent Scoring Tests', () {
    test('Zero evidence produces 0.0% plagiarism risk and safe status', () {
      const text = 'This is an entirely unique scholarly thesis written with high original academic rigor.';
      final chunks = DocumentProcessor.instance.chunkDocument(text);
      final report = DetectionEngine.instance.computeDeterministicReport(
        text: text,
        evidence: [],
        chunks: chunks,
      );

      expect(report['overall_similarity_score'], equals(0.0));
      expect(report['exact_match_score'], equals(0.0));
      expect(report['flagged_sections'], isEmpty);
      expect(report['executive_summary'], contains('adheres to standard academic integrity'));
    });

    test('Quoted and Cited evidence is exempted from plagiarism risk penalty', () {
      const text = 'As stated by Knuth, "premature optimization is the root of all evil" [1].';
      final chunks = DocumentProcessor.instance.chunkDocument(text);

      final citedEvidence = MatchEvidence(
        submittedText: '"premature optimization is the root of all evil"',
        matchedText: 'premature optimization is the root of all evil',
        sourceTitle: 'Structured Programming with go to Statements',
        signals: [PlagiarismType.exactCopy, PlagiarismType.quotedAndCited],
        exactSimilarity: 1.0,
        startOffset: 20,
        endOffset: 67,
        isQuoted: true,
        isCited: true,
        classification: EvidenceClassification.quotedAndCited,
        reason: 'Legitimate quotation with valid citation ([1]).',
      );

      final report = DetectionEngine.instance.computeDeterministicReport(
        text: text,
        evidence: [citedEvidence],
        chunks: chunks,
      );

      // Should have 0.0% penalized score because it is legitimately quoted and cited
      expect(report['overall_similarity_score'], equals(0.0));
      final flags = report['flagged_sections'] as List;
      expect(flags.length, equals(1));
      expect(flags.first['risk_level'], equals('safe'));
      expect(flags.first['suggested_action'], contains('Quotation and citation verified'));
    });

    test('Self-plagiarism signal correctly identifies previous document reuse', () {
      const text = 'Our methodology implements distributed gradient descent across multi-node GPU clusters.';
      final chunks = DocumentProcessor.instance.chunkDocument(text);

      final selfPlagEvidence = MatchEvidence(
        submittedText: text,
        matchedText: text,
        sourceTitle: 'Your Previous Document: Thesis Proposal',
        signals: [PlagiarismType.selfPlagiarism],
        semanticSimilarity: 0.95,
        selfPlagiarismSimilarity: 0.95,
        startOffset: 0,
        endOffset: text.length,
        classification: EvidenceClassification.possibleSelfPlagiarism,
        reason: 'Passage appears in one of your previously submitted documents.',
      );

      final report = DetectionEngine.instance.computeDeterministicReport(
        text: text,
        evidence: [selfPlagEvidence],
        chunks: chunks,
      );

      expect(report['overall_similarity_score'], greaterThan(0.0));
      final flags = report['flagged_sections'] as List;
      expect(flags.first['suggested_action'], contains('previous work'));
    });

    test('Multi-layer exact and web verified merge computes accurate risk scores', () {
      const text = 'Sentence one is verbatim copying. Sentence two is also matching online content.';
      final chunks = DocumentProcessor.instance.chunkDocument(text);

      final ev1 = MatchEvidence(
        submittedText: 'Sentence one is verbatim copying.',
        signals: [PlagiarismType.exactCopy],
        exactSimilarity: 1.0,
        startOffset: 0,
        endOffset: 33,
        classification: EvidenceClassification.exactMatch,
      );

      final ev2 = MatchEvidence(
        submittedText: 'Sentence two is also matching online content.',
        signals: [PlagiarismType.webDiscovery],
        webSimilarity: 0.85,
        startOffset: 34,
        endOffset: text.length,
        classification: EvidenceClassification.verifiedWebMatch,
      );

      final report = DetectionEngine.instance.computeDeterministicReport(
        text: text,
        evidence: [ev1, ev2],
        chunks: chunks,
      );

      expect(report['overall_similarity_score'], greaterThan(30.0));
      expect(report['exact_match_score'], greaterThan(0.0));
      expect((report['flagged_sections'] as List).length, equals(2));
    });
  });
}
