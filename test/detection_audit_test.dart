import 'package:flutter_test/flutter_test.dart';
import 'package:academic_writing_coach/core/services/exact_matcher.dart';
import 'package:academic_writing_coach/core/services/document_processor.dart';
import 'package:academic_writing_coach/core/models/flagged_section.dart';

void main() {
  group('ExactMatcher Comprehensive Audit', () {
    test('A. Identical text: Should match 100%', () {
      const text = "This is a long sentence with more than seven words to test matching.";
      final matches = ExactMatcher.findMatches(submittedText: text, sourceText: text);
      expect(matches.length, 1);
      expect(matches.first.signals.contains(PlagiarismType.exactCopy), true);
      expect(matches.first.exactSimilarity, 1.0);
    });

    test('B. Completely unrelated text: Should have 0 matches', () {
      const textA = "The quick brown fox jumps over the lazy dog.";
      const textB = "To be or not to be that is the question.";
      final matches = ExactMatcher.findMatches(submittedText: textA, sourceText: textB);
      expect(matches.isEmpty, true);
    });

    test('C. Same text with punctuation differences: Should match', () {
      const textA = "This is a sentence, with punctuation; and symbols!";
      const textB = "This is a sentence with punctuation and symbols";
      final matches = ExactMatcher.findMatches(submittedText: textA, sourceText: textB, ngramSize: 5);
      expect(matches.isNotEmpty, true);
    });

    test('D. Same text with whitespace differences: Should match', () {
      const textA = "This   is a    sentence with   lots   of space.";
      const textB = "This is a sentence with lots of space.";
      final matches = ExactMatcher.findMatches(submittedText: textA, sourceText: textB, ngramSize: 5);
      expect(matches.isNotEmpty, true);
    });

    test('E. Partial copied paragraph: Should detect the overlap', () {
      const source = "The first part is unique. The second part is a direct copy of a well known source. The third part is also unique.";
      const submitted = "The second part is a direct copy of a well known source.";
      final matches = ExactMatcher.findMatches(submittedText: submitted, sourceText: source);
      expect(matches.isNotEmpty, true);
      expect(matches.first.submittedText.contains("direct copy"), true);
    });

    test('G. Text shorter than 7 words: Should be handled gracefully (no match)', () {
      const text = "Too short.";
      final matches = ExactMatcher.findMatches(submittedText: text, sourceText: text);
      expect(matches.isEmpty, true);
    });

    test('H. Multiple copied sections: Should detect all', () {
      const source = "This is the first copied section. Here is some noise. This is the second copied section.";
      const submitted = "This is the first copied section. And here is more noise. This is the second copied section.";
      final matches = ExactMatcher.findMatches(submittedText: submitted, sourceText: source, ngramSize: 5);
      // We expect 2 distinct match groups because of the "i = subEnd" logic in while loop
      expect(matches.length, 2);
    });
  });

  group('DocumentProcessor Comprehensive Audit', () {
    test('Offsets: Chunks should wrap their exact text in original document', () {
      const text = "Para 1 Sent 1. Para 1 Sent 2.\n\nPara 2 Sent 1.";
      final chunks = DocumentProcessor.instance.chunkDocument(text);
      
      for (final chunk in chunks) {
          final extracted = text.substring(chunk.startOffset, chunk.endOffset);
          expect(extracted, chunk.text);
      }
    });

    test('Exact Match Offsets: Match range should be correct', () {
      const source = "This is a very specific sentence that we will copy exactly.";
      const submitted = "Here is some intro. " + source + " And some outro.";
      final introLen = "Here is some intro. ".length;
      
      final matches = ExactMatcher.findMatches(
          submittedText: submitted, 
          sourceText: source,
          baseOffset: 0,
      );
      
      expect(matches.length, 1);
      expect(matches.first.startOffset, introLen);
      expect(submitted.substring(matches.first.startOffset, matches.first.endOffset), source);
    });
  });
}
