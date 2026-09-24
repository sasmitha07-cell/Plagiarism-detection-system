import 'package:flutter_test/flutter_test.dart';
import 'package:academic_writing_coach/core/services/writing_coach_service.dart';

void main() {
  group('WritingCoachService Comprehensive Tests', () {
    test('Academic Tone: detects informal words and suggests scholarly alternatives', () async {
      const input = 'A lot of kids did a huge project to look into things.';
      final report = await WritingCoachService.instance.analyzeText(input);

      expect(report.issues.isNotEmpty, true);
      final toneIssues = report.issues.where((i) => i.type == WritingIssueType.academicTone).toList();
      expect(toneIssues.isNotEmpty, true);

      final replacements = toneIssues.map((i) => i.suggestedReplacement).join(' ');
      expect(replacements.contains('numerous') || replacements.contains('substantial') || replacements.contains('children'), true);
    });

    test('Conciseness: flags redundant phrasing', () async {
      const input = 'In order to test the system due to the fact that we need precision.';
      final report = await WritingCoachService.instance.analyzeText(input);

      final conciseIssues = report.issues.where((i) => i.type == WritingIssueType.conciseness).toList();
      expect(conciseIssues.isNotEmpty, true);
      expect(conciseIssues.any((i) => i.suggestedReplacement == 'to'), true);
      expect(conciseIssues.any((i) => i.suggestedReplacement == 'because'), true);
    });

    test('Grammar & Mechanics: catches common grammatical errors', () async {
      const input = 'The team should of known that the data is ready and these kind of errors occur.';
      final report = await WritingCoachService.instance.analyzeText(input);

      expect(report.issues.any((i) => i.originalText.contains('should of')), true);
      expect(report.issues.any((i) => i.originalText.contains('data is')), true);
      expect(report.issues.any((i) => i.originalText.contains('these kind')), true);
    });

    test('Readability Metrics: calculates Flesch Reading Ease and sentence stats', () async {
      const input = 'This is a clear academic text with standard length sentences. It provides concise evidence to support the main thesis.';
      final report = await WritingCoachService.instance.analyzeText(input);

      expect(report.totalWordCount > 0, true);
      expect(report.totalSentenceCount, 2);
      expect(report.readabilityScore > 0 && report.readabilityScore <= 100, true);
      expect(report.overallScore > 50, true);
    });
  });
}
