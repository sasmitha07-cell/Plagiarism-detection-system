import '../models/match_evidence.dart';
import '../models/flagged_section.dart';

class ExactMatcher {
  static const int defaultNgramSize = 7;

  /// Standardizes text for comparison while attempting to preserve structure.
  static String normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Identifies deterministic exact matches between two documents.
  /// Returns a list of [MatchEvidence] found.
  static List<MatchEvidence> findMatches({
    required String submittedText,
    required String sourceText,
    int ngramSize = defaultNgramSize,
    String? sourceTitle,
    String? sourceUrl,
    int baseOffset = 0,
  }) {
    if (submittedText.trim().isEmpty || sourceText.trim().isEmpty) return [];

    final normSub = normalize(submittedText);
    final normSrc = normalize(sourceText);

    final subWords = normSub.split(' ');
    final srcWords = normSrc.split(' ');

    if (subWords.length < ngramSize || srcWords.length < ngramSize) return [];

    // Build lookup for source n-grams
    final Map<String, List<int>> srcMap = {};
    for (int i = 0; i <= srcWords.length - ngramSize; i++) {
      final gram = srcWords.sublist(i, i + ngramSize).join(' ');
      srcMap.putIfAbsent(gram, () => []).add(i);
    }

    final List<MatchEvidence> matches = [];
    int i = 0;
    
    while (i <= subWords.length - ngramSize) {
      final currentGram = subWords.sublist(i, i + ngramSize).join(' ');
      
      if (srcMap.containsKey(currentGram)) {
        // Expand the match as far as possible
        int subStartWordIdx = i;
        int subEndWordIdx = i + ngramSize;
        
        // Match against the first occurrence in source
        int srcStartWordIdx = srcMap[currentGram]![0];
        int srcEndWordIdx = srcStartWordIdx + ngramSize;

        while (subEndWordIdx < subWords.length && 
               srcEndWordIdx < srcWords.length && 
               subWords[subEndWordIdx] == srcWords[srcEndWordIdx]) {
          subEndWordIdx++;
          srcEndWordIdx++;
        }

        final matchedFragment = subWords.sublist(subStartWordIdx, subEndWordIdx).join(' ');
        
        // Map word indices back to character offsets in the submittedText
        final originalFragmentStart = submittedText.toLowerCase().indexOf(
          subWords[subStartWordIdx].toLowerCase(),
          0,
        );
        
        // Find the end by looking for the last word of the match
        final lastWord = subWords[subEndWordIdx - 1];
        final lastWordIdxInSubmitted = submittedText.toLowerCase().indexOf(
          lastWord.toLowerCase(),
          originalFragmentStart,
        );
        
        // We include trailing punctuation if it exists in the original string
        int originalFragmentEnd = lastWordIdxInSubmitted + lastWord.length;
        if (originalFragmentEnd < submittedText.length) {
            final nextChar = submittedText[originalFragmentEnd];
            if (RegExp(r'[.!?]').hasMatch(nextChar)) {
                originalFragmentEnd++;
            }
        }

        matches.add(MatchEvidence(
          submittedText: matchedFragment,
          matchedText: srcWords.sublist(srcStartWordIdx, srcEndWordIdx).join(' '),
          sourceTitle: sourceTitle,
          sourceUrl: sourceUrl,
          signals: [PlagiarismType.exactCopy],
          exactSimilarity: 1.0,
          confidence: 1.0,
          reason: 'Direct match of ${subEndWordIdx - subStartWordIdx} words detected.',
          startOffset: baseOffset + (originalFragmentStart != -1 ? originalFragmentStart : 0),
          endOffset: baseOffset + originalFragmentEnd,
        ));
        
        i = subEndWordIdx;
      } else {
        i++;
      }
    }

    return matches;
  }
}
