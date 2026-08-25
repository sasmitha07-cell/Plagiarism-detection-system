import 'flagged_section.dart';

/// Represents a distinct passage identified as a potential match.
/// Contains one or more evidence signals (EXACT, SEMANTIC, WEB).
class MatchEvidence {
  final String submittedText;
  final String? matchedText;
  final String? sourceUrl;
  final String? sourceTitle;
  final String? domain;
  
  /// The collection of detectors that flagged this passage
  final List<PlagiarismType> signals;
  
  final double exactSimilarity;
  final double semanticSimilarity;
  final double webSimilarity;
  final double confidence;
  
  final String? reason;
  final int startOffset;
  final int endOffset;
  final int? pageNumber;
  final int? paragraphNumber;
  final int? sentenceNumber;
  
  final DiscoveryStatus discoveryStatus;

  MatchEvidence({
    required this.submittedText,
    this.matchedText,
    this.sourceUrl,
    this.sourceTitle,
    this.domain,
    required this.signals,
    this.exactSimilarity = 0,
    this.semanticSimilarity = 0,
    this.webSimilarity = 0,
    this.confidence = 0,
    this.reason,
    required this.startOffset,
    required this.endOffset,
    this.pageNumber,
    this.paragraphNumber,
    this.sentenceNumber,
    this.discoveryStatus = DiscoveryStatus.internal,
  });

  Map<String, dynamic> toJson() {
    return {
      'submittedText': submittedText,
      'matchedText': matchedText,
      'sourceUrl': sourceUrl,
      'sourceTitle': sourceTitle,
      'domain': domain,
      'signals': signals.map((s) => s.name).toList(),
      'exactSimilarity': exactSimilarity,
      'semanticSimilarity': semanticSimilarity,
      'webSimilarity': webSimilarity,
      'confidence': confidence,
      'reason': reason,
      'startOffset': startOffset,
      'endOffset': endOffset,
      'pageNumber': pageNumber,
      'paragraphNumber': paragraphNumber,
      'sentenceNumber': sentenceNumber,
      'discoveryStatus': discoveryStatus.name,
    };
  }
}

enum DiscoveryStatus {
  internal,   // Only found in DB/Local
  discovered, // Found on web (discovery only)
  verified,   // Web content compared and verified
  unverified, // Web result exists but content couldn't be checked
  failed      // Web search was attempted but failed
}
