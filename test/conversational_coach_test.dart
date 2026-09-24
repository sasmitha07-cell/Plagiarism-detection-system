import 'package:flutter_test/flutter_test.dart';
import 'package:academic_writing_coach/core/services/writing_coach_service.dart';

void main() {
  group('AI Writing Coach Studio & Analytics Tests', () {
    test('Analyzes academic text and generates structured metrics and issues', () async {
      const sampleText = 
          'In order to look into the data, we conducted an investigation on kids and things. '
          'A lot of good findings were made by our team because data is very huge and crazy. '
          'According to Smith (2020), empirical evaluations demonstrate strong statistical significance.';

      final report = await WritingCoachService.instance.analyzeText(sampleText);

      expect(report.totalWordCount, greaterThan(20));
      expect(report.totalSentenceCount, greaterThanOrEqualTo(2));
      expect(report.readabilityScore, greaterThan(0));
      expect(report.gradeLevel, greaterThan(0));
      expect(report.issues, isNotEmpty);

      // Verify academic tone suggestions
      final toneIssues = report.issues.where((i) => i.type == WritingIssueType.academicTone);
      expect(toneIssues, isNotEmpty);

      // Verify conciseness suggestions ('in order to' -> 'to')
      final conciseIssues = report.issues.where((i) => i.type == WritingIssueType.conciseness);
      expect(conciseIssues, isNotEmpty);
    });

    test('Exempts clean academic prose from false issues', () async {
      const scholarlyText = 
          'The empirical data indicate that neural architecture search substantially improves model efficiency. '
          'Furthermore, systematic benchmarks demonstrate that latency decreases across heterogeneous hardware configurations.';

      final report = await WritingCoachService.instance.analyzeText(scholarlyText);

      expect(report.overallScore, greaterThanOrEqualTo(80.0));
      expect(report.academicToneScore, greaterThanOrEqualTo(80.0));
      expect(report.grammarScore, equals(100.0));
    });
  });
}
