import 'flagged_section.dart';

enum EvidenceClassification {
  noMatch,
  quotedAndCited,
  commonAcademicPhrase,
  exactMatch,
  semanticParaphrase,
  possibleSelfPlagiarism,
  verifiedWebMatch,
  citationRequired,
}

enum DiscoveryStatus {
  internal,   // Found in DB/Local submission
  discovered, // Found on web (query match)
  verified,   // Web snippet or source text verified for word overlap
  unverified, // Web result exists but snippet not yet verified
  failed      // Web search was attempted but failed
}

/// Represents a distinct passage identified through multi-layer detection.
/// Contains independent evidence signals (EXACT, SEMANTIC, WEB, SELF_PLAGIARISM),
/// character offsets for source and submitted text, citation context, and explainability signals.
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
  final double selfPlagiarismSimilarity;
  final double confidence;
  
  final String? reason;
  final int startOffset;
  final int endOffset;
  final int sourceStartOffset;
  final int sourceEndOffset;
  final int? pageNumber;
  final int? paragraphNumber;
  final int? sentenceNumber;
  
  final DiscoveryStatus discoveryStatus;
  final EvidenceClassification classification;
  
  final bool isQuoted;
  final bool isCited;
  final bool isCommonPhrase;
  final String? matchedCitation;

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
    this.selfPlagiarismSimilarity = 0,
    this.confidence = 0,
    this.reason,
    required this.startOffset,
    required this.endOffset,
    this.sourceStartOffset = 0,
    this.sourceEndOffset = 0,
    this.pageNumber,
    this.paragraphNumber,
    this.sentenceNumber,
    this.discoveryStatus = DiscoveryStatus.internal,
    this.classification = EvidenceClassification.exactMatch,
    this.isQuoted = false,
    this.isCited = false,
    this.isCommonPhrase = false,
    this.matchedCitation,
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
      'selfPlagiarismSimilarity': selfPlagiarismSimilarity,
      'confidence': confidence,
      'reason': reason,
      'startOffset': startOffset,
      'endOffset': endOffset,
      'sourceStartOffset': sourceStartOffset,
      'sourceEndOffset': sourceEndOffset,
      'pageNumber': pageNumber,
      'paragraphNumber': paragraphNumber,
      'sentenceNumber': sentenceNumber,
      'discoveryStatus': discoveryStatus.name,
      'classification': classification.name,
      'isQuoted': isQuoted,
      'isCited': isCited,
      'isCommonPhrase': isCommonPhrase,
      'matchedCitation': matchedCitation,
    };
  }
}
