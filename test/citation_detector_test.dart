import 'package:flutter_test/flutter_test.dart';
import 'package:academic_writing_coach/core/services/citation_detector.dart';

void main() {
  group('CitationDetector Tests', () {
    test('Detects numbered citations [1], [1, 2], [3-5]', () {
      const text = 'Recent breakthroughs in transformers [1] have achieved state-of-the-art results [2, 3] and surpassed baselines [4-6].';
      final citations = CitationDetector.instance.detectCitations(text);

      expect(citations.length, equals(3));
      expect(citations[0].citationText, equals('[1]'));
      expect(citations[1].citationText, equals('[2, 3]'));
      expect(citations[2].citationText, equals('[4-6]'));
    });

    test('Detects author-year citations (Smith, 2020) and (Johnson et al., 2022)', () {
      const text = 'Cognitive load theory indicates that multimedia learning improves retention (Sweller, 2018; Mayer et al., 2021).';
      final citations = CitationDetector.instance.detectCitations(text);

      expect(citations, isNotEmpty);
      expect(citations.first.type, equals('authorYear'));
    });

    test('Detects DOIs and URLs', () {
      const text = 'Refer to the preprint at https://arxiv.org/abs/2103.00020 and publication doi:10.1016/j.artint.2021.103522.';
      final citations = CitationDetector.instance.detectCitations(text);

      expect(citations.any((c) => c.type == 'url'), isTrue);
      expect(citations.any((c) => c.type == 'doi'), isTrue);
    });

    test('Detects standard and smart quotations', () {
      const text = 'As stated by Turing, "machines can be constructed which will simulate the behaviour of the human mind" and “intelligence is elusive”.';
      final quotes = CitationDetector.instance.detectQuotations(text);

      expect(quotes.length, equals(2));
      expect(quotes.first.quotedText, contains('machines can be constructed'));
      expect(quotes.last.quotedText, equals('intelligence is elusive'));
    });

    test('Identifies legitimate quoted and cited scholarship context', () {
      const text = 'According to Shannon, "the fundamental problem of communication is that of reproducing at one point either exactly or approximately a message selected at another point" [1].';
      const quoteStart = 23;
      const quoteEnd = 163;

      final context = CitationDetector.instance.inspectContext(text, quoteStart, quoteEnd);
      expect(context.isQuoted, isTrue);
      expect(context.isCited, isTrue);
      expect(context.citation, equals('[1]'));
    });

    test('Identifies uncited empirical claims needing evidence', () {
      const text = 'Studies have shown that active retrieval practice enhances long-term memory. '
          'However, we hypothesize that spaced repetition creates better outcomes.';
      final uncited = CitationDetector.instance.findUncitedClaims(text);

      expect(uncited, isNotEmpty);
      expect(uncited.first.text, contains('Studies have shown'));
    });
  });
}
