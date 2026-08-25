import 'package:flutter_test/flutter_test.dart';
import 'package:academic_writing_coach/core/services/exact_matcher.dart';
import 'package:academic_writing_coach/core/models/flagged_section.dart';

void main() {
  test('End-to-End Exact Match Test', () {
    const textA = "The rapid development of artificial intelligence has transformed modern education.";
    const textB = "The rapid development of artificial intelligence has transformed modern education.";
    
    final matches = ExactMatcher.findMatches(
      submittedText: textA, 
      sourceText: textB,
      ngramSize: 7,
    );
    
    expect(matches.length, 1);
    final match = matches.first;
    
    expect(match.signals.contains(PlagiarismType.exactCopy), true);
    expect(match.exactSimilarity, 1.0);
    expect(match.startOffset, 0);
    expect(match.endOffset, textA.length);
    
    // Verify highlighted substring
    final highlighted = textA.substring(match.startOffset, match.endOffset);
    expect(highlighted, textA);
  });
}
