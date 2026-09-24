import '../models/match_evidence.dart';
import '../models/flagged_section.dart';
import 'common_phrase_filter.dart';

class TokenSpan {
  final String normalizedWord;
  final int startOffset;
  final int endOffset;

  const TokenSpan({
    required this.normalizedWord,
    required this.startOffset,
    required this.endOffset,
  });
}

class ExactMatcher {
  static const int defaultNgramSize = 6;
  static const double minDistinctivenessThreshold = 0.25;

  /// Normalizes Unicode characters: smart quotes, accents, dashes, non-standard whitespace.
  static String normalizeUnicode(String text) {
    String res = text;
    // Normalize smart/curly quotes
    res = res.replaceAll(RegExp(r'[\u2018\u2019\u201A\u201B\u2032\u2035]'), "'");
    res = res.replaceAll(RegExp(r'[\u201C\u201D\u201E\u201F\u2033\u2036]'), '"');
    // Normalize dashes & hyphens (en-dash, em-dash, minus, hyphen)
    res = res.replaceAll(RegExp(r'[\u2010\u2011\u2012\u2013\u2014\u2015\u2212]'), '-');
    // Normalize non-breaking spaces & zero-width spaces
    res = res.replaceAll(RegExp(r'[\u00A0\u2000-\u200B\u202F\u205F\u3000\uFEFF]'), ' ');
    return res;
  }

  /// Tokenizes text into normalized words while recording exact character offsets in the raw string.
  static List<TokenSpan> tokenizeWithOffsets(String text) {
    final List<TokenSpan> tokens = [];
    final normalizedText = normalizeUnicode(text);
    final RegExp wordRegex = RegExp(r'[a-zA-Z0-9\x7f-\xff]+');

    for (final match in wordRegex.allMatches(normalizedText)) {
      final rawWord = match.group(0)!;
      final normalized = rawWord.toLowerCase();
      tokens.add(TokenSpan(
        normalizedWord: normalized,
        startOffset: match.start,
        endOffset: match.end,
      ));
    }

    return tokens;
  }

  /// Identifies deterministic exact matches between two documents with character-level accuracy.
  static List<MatchEvidence> findMatches({
    required String submittedText,
    required String sourceText,
    int ngramSize = defaultNgramSize,
    String? sourceTitle,
    String? sourceUrl,
    int baseOffset = 0,
    bool filterCommonPhrases = true,
  }) {
    if (submittedText.trim().isEmpty || sourceText.trim().isEmpty) return [];

    final subTokens = tokenizeWithOffsets(submittedText);
    final srcTokens = tokenizeWithOffsets(sourceText);

    if (subTokens.length < ngramSize || srcTokens.length < ngramSize) return [];

    // Build n-gram lookup map for source document
    final Map<String, List<int>> srcMap = {};
    for (int i = 0; i <= srcTokens.length - ngramSize; i++) {
      final gram = srcTokens.sublist(i, i + ngramSize).map((t) => t.normalizedWord).join(' ');
      srcMap.putIfAbsent(gram, () => []).add(i);
    }

    final List<MatchEvidence> matches = [];
    int i = 0;

    while (i <= subTokens.length - ngramSize) {
      final currentGram = subTokens.sublist(i, i + ngramSize).map((t) => t.normalizedWord).join(' ');

      if (srcMap.containsKey(currentGram)) {
        // Expand the match as far as possible
        int subStartWordIdx = i;
        int subEndWordIdx = i + ngramSize;

        // Take the first matching source index
        int srcStartWordIdx = srcMap[currentGram]!.first;
        int srcEndWordIdx = srcStartWordIdx + ngramSize;

        while (subEndWordIdx < subTokens.length &&
            srcEndWordIdx < srcTokens.length &&
            subTokens[subEndWordIdx].normalizedWord == srcTokens[srcEndWordIdx].normalizedWord) {
          subEndWordIdx++;
          srcEndWordIdx++;
        }

        final matchWordCount = subEndWordIdx - subStartWordIdx;
        final rawSubStartChar = subTokens[subStartWordIdx].startOffset;
        int rawSubEndChar = subTokens[subEndWordIdx - 1].endOffset;
        if (rawSubEndChar < submittedText.length && RegExp(r'[.!?]').hasMatch(submittedText[rawSubEndChar])) {
          rawSubEndChar++;
        }
        final rawMatchedSubString = submittedText.substring(rawSubStartChar, rawSubEndChar);

        final rawSrcStartChar = srcTokens[srcStartWordIdx].startOffset;
        int rawSrcEndChar = srcTokens[srcEndWordIdx - 1].endOffset;
        if (rawSrcEndChar < sourceText.length && RegExp(r'[.!?]').hasMatch(sourceText[rawSrcEndChar])) {
          rawSrcEndChar++;
        }
        final rawMatchedSrcString = sourceText.substring(rawSrcStartChar, rawSrcEndChar);

        // Calculate distinctiveness
        final distinctiveness = CommonPhraseFilter.instance.computeDistinctivenessScore(rawMatchedSubString);
        final isCommon = CommonPhraseFilter.instance.isCommonAcademicPhrase(rawMatchedSubString);

        if (!filterCommonPhrases || matchWordCount >= 9 || distinctiveness >= minDistinctivenessThreshold) {
          matches.add(MatchEvidence(
            submittedText: rawMatchedSubString,
            matchedText: rawMatchedSrcString,
            sourceTitle: sourceTitle ?? 'Compared Document',
            sourceUrl: sourceUrl,
            signals: [PlagiarismType.exactCopy],
            exactSimilarity: 1.0,
            confidence: 1.0,
            reason: 'Direct match of $matchWordCount consecutive words detected.',
            startOffset: baseOffset + rawSubStartChar,
            endOffset: baseOffset + rawSubEndChar,
            sourceStartOffset: rawSrcStartChar,
            sourceEndOffset: rawSrcEndChar,
            isCommonPhrase: isCommon,
            classification: isCommon ? EvidenceClassification.commonAcademicPhrase : EvidenceClassification.exactMatch,
          ));
        }

        i = subEndWordIdx;
      } else {
        i++;
      }
    }

    return matches;
  }
}

