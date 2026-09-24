class CommonPhraseFilter {
  CommonPhraseFilter._();
  static final instance = CommonPhraseFilter._();

  static const Set<String> _academicStandardPhrases = {
    'this study aims to',
    'the results of this study indicate that',
    'the findings of this research suggest',
    'in order to investigate',
    'in order to examine',
    'in order to determine',
    'in order to better understand',
    'it is important to note that',
    'it is worth noting that',
    'as shown in figure',
    'as demonstrated in table',
    'in conclusion the results',
    'in conclusion the findings',
    'further research is needed to',
    'further investigation is required',
    'a comprehensive review of the literature',
    'according to the literature',
    'on the other hand',
    'for the purpose of this analysis',
    'for the purpose of this study',
    'the primary objective of this',
    'the methodology employed in this study',
    'data was collected using',
    'data were collected using',
    'a statistically significant difference',
    'there is a significant relationship between',
    'the implications of these findings are',
    'plays a pivotal role in',
    'has a substantial impact on',
    'in recent years there has been',
    'to the best of our knowledge',
    'consistent with previous research',
    'contrary to our initial hypothesis',
    'taken together these results suggest',
  };

  static const Set<String> _stopWords = {
    'a', 'an', 'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by',
    'from', 'as', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had',
    'do', 'does', 'did', 'that', 'this', 'these', 'those', 'it', 'its', 'they', 'them', 'their',
    'we', 'our', 'us', 'you', 'your', 'he', 'she', 'his', 'her', 'which', 'who', 'whom', 'what',
    'where', 'when', 'why', 'how', 'all', 'any', 'both', 'each', 'few', 'more', 'most', 'other',
    'some', 'such', 'no', 'nor', 'not', 'only', 'own', 'same', 'so', 'than', 'too', 'very',
    'can', 'will', 'just', 'should', 'now', 'into', 'also', 'then',
  };

  /// Normalizes a phrase for comparison
  static String normalizePhrase(String phrase) {
    return phrase
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Checks if a phrase is a recognized academic discourse boilerplate phrase.
  bool isCommonAcademicPhrase(String phrase) {
    final norm = normalizePhrase(phrase);
    if (norm.isEmpty) return true;

    for (final standard in _academicStandardPhrases) {
      if (norm.contains(standard) || standard.contains(norm)) {
        return true;
      }
    }
    return false;
  }

  /// Computes a distinctiveness score (0.0 to 1.0) for a phrase.
  /// Low score = mostly generic stopwords or academic idioms.
  /// High score = distinct, specialized academic content.
  double computeDistinctivenessScore(String phrase) {
    final norm = normalizePhrase(phrase);
    final words = norm.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 0.0;

    int distinctiveWordCount = 0;
    int totalWordLength = 0;

    for (final w in words) {
      totalWordLength += w.length;
      if (!_stopWords.contains(w) && w.length >= 4) {
        distinctiveWordCount++;
      }
    }

    final distinctiveRatio = distinctiveWordCount / words.length;
    final avgLength = totalWordLength / words.length;

    // Academic common phrase penalty
    double penalty = 0.0;
    if (isCommonAcademicPhrase(phrase)) {
      penalty = 0.45;
    }

    double score = (distinctiveRatio * 0.7) + ((avgLength / 10.0).clamp(0.0, 0.3)) - penalty;
    return score.clamp(0.0, 1.0);
  }
}
