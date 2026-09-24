class CitationMatch {
  final String citationText;
  final int startOffset;
  final int endOffset;
  final String type; // numbered, authorYear, doi, url

  const CitationMatch({
    required this.citationText,
    required this.startOffset,
    required this.endOffset,
    required this.type,
  });
}

class QuotationRange {
  final String quotedText;
  final int startOffset;
  final int endOffset;

  const QuotationRange({
    required this.quotedText,
    required this.startOffset,
    required this.endOffset,
  });
}

class CitationDetector {
  CitationDetector._();
  static final instance = CitationDetector._();

  // Numbered citations: [1], [1, 2], [1-3], [12, 14, 16]
  static final RegExp _numberedCitationRegex = RegExp(r'\[\s*\d+(?:\s*[,–-]\s*\d+)*\s*\]');

  // Author-Year citations: (Smith, 2020), (Smith & Doe, 2019), (Smith et al., 2022), (Johnson, 2018; Lee, 2020)
  static final RegExp _authorYearCitationRegex = RegExp(
    r'\(\s*(?:[A-Z][a-zA-Z\x7f-\xff-]+(?:\s+et\s+al\.?|\s+(?:&|and)\s+[A-Z][a-zA-Z\x7f-\xff-]+)?\s*,\s*\d{4}[a-z]?(?:\s*;\s*[A-Z][a-zA-Z\x7f-\xff-]+(?:\s+et\s+al\.?|\s+(?:&|and)\s+[A-Z][a-zA-Z\x7f-\xff-]+)?\s*,\s*\d{4}[a-z]?)*)\s*\)',
  );

  // DOI citations
  static final RegExp _doiRegex = RegExp(r'\b(?:doi:\s*|https?://(?:dx\.)?doi\.org/)(10\.\d{4,9}/[-._;()/:A-Z0-9]+)\b', caseSensitive: false);

  // URL references
  static final RegExp _urlRegex = RegExp(r'\bhttps?://[^\s<>"{}|\^~`\[\]]+\b');

  // Quotation matching: double quotes, smart quotes, single quotes with inner content > 5 chars
  static final RegExp _quotationRegex = RegExp(r'''["“]([^"”]{5,})["”]|(?<=\s)['‘]([^'’]{5,})['’](?=\s|[.,;])''');

  /// Detects all quotations present in the text with precise character offsets.
  List<QuotationRange> detectQuotations(String text) {
    final List<QuotationRange> quotations = [];
    for (final match in _quotationRegex.allMatches(text)) {
      final inner = match.group(1) ?? match.group(2);
      if (inner != null && inner.trim().isNotEmpty) {
        quotations.add(QuotationRange(
          quotedText: inner.trim(),
          startOffset: match.start,
          endOffset: match.end,
        ));
      }
    }
    return quotations;
  }

  /// Detects all citation markers in the text.
  List<CitationMatch> detectCitations(String text) {
    final List<CitationMatch> results = [];

    for (final m in _numberedCitationRegex.allMatches(text)) {
      results.add(CitationMatch(
        citationText: m.group(0)!,
        startOffset: m.start,
        endOffset: m.end,
        type: 'numbered',
      ));
    }

    for (final m in _authorYearCitationRegex.allMatches(text)) {
      results.add(CitationMatch(
        citationText: m.group(0)!,
        startOffset: m.start,
        endOffset: m.end,
        type: 'authorYear',
      ));
    }

    for (final m in _doiRegex.allMatches(text)) {
      results.add(CitationMatch(
        citationText: m.group(0)!,
        startOffset: m.start,
        endOffset: m.end,
        type: 'doi',
      ));
    }

    for (final m in _urlRegex.allMatches(text)) {
      results.add(CitationMatch(
        citationText: m.group(0)!,
        startOffset: m.start,
        endOffset: m.end,
        type: 'url',
      ));
    }

    results.sort((a, b) => a.startOffset.compareTo(b.startOffset));
    return results;
  }

  /// Checks whether a given character range [startOffset, endOffset] falls inside a quotation.
  bool isRangeQuoted(String fullText, int startOffset, int endOffset) {
    final quotes = detectQuotations(fullText);
    for (final q in quotes) {
      // If the target range overlaps substantially (or is contained) in the quote
      if (startOffset >= q.startOffset && endOffset <= q.endOffset) {
        return true;
      }
      if ((startOffset >= q.startOffset && startOffset < q.endOffset) ||
          (endOffset > q.startOffset && endOffset <= q.endOffset)) {
        return true;
      }
    }
    return false;
  }

  /// Looks for a citation directly trailing or preceding the given range (within 120 chars).
  CitationMatch? findSurroundingCitation(String fullText, int startOffset, int endOffset) {
    final citations = detectCitations(fullText);
    const int searchMargin = 120;

    final searchStart = (startOffset - searchMargin).clamp(0, fullText.length);
    final searchEnd = (endOffset + searchMargin).clamp(0, fullText.length);

    for (final c in citations) {
      if (c.startOffset >= searchStart && c.endOffset <= searchEnd) {
        return c;
      }
    }
    return null;
  }

  /// Determines if a flagged range is legitimate scholarship (quoted + cited).
  ({bool isQuoted, bool isCited, String? citation}) inspectContext(
    String fullText,
    int startOffset,
    int endOffset,
  ) {
    final quoted = isRangeQuoted(fullText, startOffset, endOffset);
    final citation = findSurroundingCitation(fullText, startOffset, endOffset);

    return (
      isQuoted: quoted,
      isCited: citation != null,
      citation: citation?.citationText,
    );
  }

  /// Identifies empirical claims in text that lack nearby citations
  List<({String text, int startOffset, int endOffset, String reason})> findUncitedClaims(String text) {
    final List<({String text, int startOffset, int endOffset, String reason})> uncited = [];

    // Assertive claim markers
    final claimPatterns = [
      RegExp(r'\b(?:studies\s+have\s+shown|research\s+indicates|evidence\s+demonstrates|according\s+to\s+recent\s+findings|experiments\s+prove|it\s+has\s+been\s+proven|statistics\s+show|data\s+confirms)\b[^.!?]*[.!?]', caseSensitive: false),
      RegExp(r'\b(?:previous\s+literature\s+suggests|scholars\s+argue|scientists\s+discovered|historical\s+records\s+show)\b[^.!?]*[.!?]', caseSensitive: false),
    ];

    for (final pattern in claimPatterns) {
      for (final match in pattern.allMatches(text)) {
        final sentence = match.group(0)!;
        final start = match.start;
        final end = match.end;

        // Check if there is an adjacent citation
        final citation = findSurroundingCitation(text, start, end);
        if (citation == null) {
          uncited.add((
            text: sentence.trim(),
            startOffset: start,
            endOffset: end,
            reason: 'Empirical claim makes reference to external studies or findings without an accompanying citation.',
          ));
        }
      }
    }

    return uncited;
  }
}
