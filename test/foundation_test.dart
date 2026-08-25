import 'package:flutter_test/flutter_test.dart';
import 'package:academic_writing_coach/core/services/exact_matcher.dart';
import 'package:academic_writing_coach/core/models/flagged_section.dart';

void main() {
  group('ExactMatcher Tests', () {
    test('Identity Test: Identical strings should match 100%', () {
      const text = "Indian culture is one of the oldest and most diverse in the world, spanning over 4,500 years.";
      final matches = ExactMatcher.findMatches(
        submittedText: text,
        sourceText: text,
        ngramSize: 5,
      );

      expect(matches.isNotEmpty, true);
      expect(matches.first.signals.contains(PlagiarismType.exactCopy), true);
      expect(matches.first.exactSimilarity, 1.0);
    });

    test('Noise Test: Unrelated strings should have 0 matches', () {
      const textA = "The quick brown fox jumps over the lazy dog.";
      const textB = "In a galaxy far far away star wars begin.";
      final matches = ExactMatcher.findMatches(
        submittedText: textA,
        sourceText: textB,
        ngramSize: 3,
      );

      expect(matches.isEmpty, true);
    });

    test('Normalization: Formatting should not affect matches', () {
      const textA = "Indian   Culture (IS) one OF the oldest...";
      const textB = "indian culture is one of the oldest";
      final matches = ExactMatcher.findMatches(
        submittedText: textA,
        sourceText: textB,
        ngramSize: 4,
      );

      expect(matches.isNotEmpty, true);
    });
  });
}
