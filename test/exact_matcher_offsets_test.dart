import 'package:flutter_test/flutter_test.dart';
import 'package:academic_writing_coach/core/services/exact_matcher.dart';
import 'package:academic_writing_coach/core/models/flagged_section.dart';

void main() {
  group('ExactMatcher Offsets & Character-Level Mapping Tests', () {
    test('Identical text: maps exact character offsets from start to finish', () {
      const text = 'Artificial intelligence enables automated reasoning across vast textual datasets.';
      final matches = ExactMatcher.findMatches(
        submittedText: text,
        sourceText: text,
        ngramSize: 5,
      );

      expect(matches, isNotEmpty);
      final firstMatch = matches.first;
      expect(firstMatch.startOffset, equals(0));
      expect(firstMatch.endOffset, equals(text.length));
      expect(firstMatch.signals, contains(PlagiarismType.exactCopy));
      expect(firstMatch.exactSimilarity, equals(1.0));
      expect(firstMatch.sourceStartOffset, equals(0));
      expect(firstMatch.sourceEndOffset, equals(text.length));
    });

    test('Middle of document match: preserves exact substring slice', () {
      const source = 'This benchmark demonstrates that recurrent architectures struggle with long-context memory retention over time.';
      const submitted = 'In our initial experiments, recurrent architectures struggle with long-context memory retention over time in many cases.';

      final matches = ExactMatcher.findMatches(
        submittedText: submitted,
        sourceText: source,
        ngramSize: 6,
      );

      expect(matches, isNotEmpty);
      final m = matches.first;
      final sliced = submitted.substring(m.startOffset, m.endOffset);
      expect(sliced, equals('recurrent architectures struggle with long-context memory retention over time'));
    });

    test('Punctuation, case, and whitespace variations match accurately', () {
      const source = 'The algorithm, which is highly efficient, utilizes parallel processing.';
      const submitted = 'THE ALGORITHM   WHICH IS HIGHLY EFFICIENT   UTILIZES PARALLEL PROCESSING.';

      final matches = ExactMatcher.findMatches(
        submittedText: submitted,
        sourceText: source,
        ngramSize: 5,
      );

      expect(matches, isNotEmpty);
    });

    test('Multiple non-contiguous copied sections in one document', () {
      const sourceA = 'Deep neural networks require substantial computational infrastructure for training.';
      const sourceB = 'Bayesian inference provides robust uncertainty quantification in critical applications.';
      const submitted = 'First, deep neural networks require substantial computational infrastructure for training. Secondly, Bayesian inference provides robust uncertainty quantification in critical applications.';

      final matchesA = ExactMatcher.findMatches(
        submittedText: submitted,
        sourceText: sourceA,
        ngramSize: 5,
      );

      final matchesB = ExactMatcher.findMatches(
        submittedText: submitted,
        sourceText: sourceB,
        ngramSize: 5,
      );

      expect(matchesA, isNotEmpty);
      expect(matchesB, isNotEmpty);
      expect(matchesA.first.startOffset, lessThan(matchesB.first.startOffset));
    });

    test('Common academic phrase threshold does not falsely flag boilerplate', () {
      const source = 'In conclusion the findings of this study suggest that further research is needed.';
      const submitted = 'In conclusion the findings of this study suggest that future work should explore new avenues.';

      final matches = ExactMatcher.findMatches(
        submittedText: submitted,
        sourceText: source,
        ngramSize: 6,
        filterCommonPhrases: true,
      );

      // Common phrase should be flagged as commonAcademicPhrase or filtered
      if (matches.isNotEmpty) {
        expect(matches.first.isCommonPhrase, isTrue);
      }
    });
  });
}
