import 'package:flutter_test/flutter_test.dart';
import 'package:academic_writing_coach/core/services/exact_matcher.dart';
import 'package:academic_writing_coach/core/models/match_evidence.dart';

void main() {
  group('ExactMatcher Unicode & Edge Case Tests', () {
    test('Normalizes smart quotes, curly quotes and dashes correctly', () {
      const submitted = '“The empirical findings indicate a significant correlation between variables,”—stated Smith.';
      const source = '"The empirical findings indicate a significant correlation between variables," - stated Smith.';

      final matches = ExactMatcher.findMatches(
        submittedText: submitted,
        sourceText: source,
        ngramSize: 5,
      );

      expect(matches, isNotEmpty);
      expect(matches.first.exactSimilarity, equals(1.0));
    });

    test('Handles non-breaking spaces and irregular whitespace without breaking offset mapping', () {
      const submitted = 'This\u00A0study\u2000examines\u2001the\u2002impact\u2003of\u2004machine\u2005learning algorithms on academic writing.';
      const source = 'This study examines the impact of machine learning algorithms on academic writing.';

      final matches = ExactMatcher.findMatches(
        submittedText: submitted,
        sourceText: source,
        ngramSize: 6,
      );

      expect(matches, isNotEmpty);
      expect(matches.first.startOffset, equals(0));
      expect(matches.first.classification, equals(EvidenceClassification.exactMatch));
    });

    test('Distinguishes common academic phrases from distinctive text', () {
      const boilerplate = 'In order to investigate the results indicate that this study aims to explore.';
      const sourceDoc = 'In order to investigate the results indicate that this study aims to explore in deep detail.';

      final matches = ExactMatcher.findMatches(
        submittedText: boilerplate,
        sourceText: sourceDoc,
        ngramSize: 6,
        filterCommonPhrases: true,
      );

      // Even if matched, common phrases should either be classified as commonAcademicPhrase or filtered
      for (final m in matches) {
        expect(m.isCommonPhrase, isTrue);
      }
    });

    test('Detects multiple non-contiguous exact copied regions in long text', () {
      const submitted = 
          'Here is the introduction.\n\n'
          'The fundamental methodology consists of statistical variance analysis across five trials.\n\n'
          'Now we have our own unique intermediate discussion here that was not copied.\n\n'
          'In conclusion, quantitative assessments demonstrate substantial improvements in processing efficiency.\n\n'
          'Final closing thoughts.';

      const source = 
          'The fundamental methodology consists of statistical variance analysis across five trials.\n'
          'In conclusion, quantitative assessments demonstrate substantial improvements in processing efficiency.';

      final matches = ExactMatcher.findMatches(
        submittedText: submitted,
        sourceText: source,
        ngramSize: 6,
      );

      expect(matches.length, greaterThanOrEqualTo(2));
      expect(matches.any((m) => m.submittedText.contains('fundamental methodology')), isTrue);
      expect(matches.any((m) => m.submittedText.contains('quantitative assessments')), isTrue);
    });
  });
}
