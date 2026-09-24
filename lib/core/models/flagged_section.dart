enum PlagiarismType {
  exactCopy,
  partialCopy,
  semanticSimilarity,
  missingCitation,
  paraphrased,
  aiRewritten,
  webDiscovery, // Match found on the live web
  selfPlagiarism, // Reused from author's previous document
  quotedAndCited, // Properly quoted and referenced
}

enum RiskLevel { safe, low, medium, high, critical }

class FlaggedSection {
  final String id;
  final String scanId;
  final String documentId;
  final int startPosition;
  final int endPosition;
  final String flaggedText;
  final PlagiarismType plagiarismType;
  final RiskLevel riskLevel;
  final double confidenceScore;
  final double similarityScore;
  final String? sourceUrl;
  final String? sourceTitle;
  final String? sourceAuthor;
  final String? sourcePublicationDate;
  final String? matchedSourceText;
  final String explanation;
  final String? suggestedAction;
  final List<Map<String, dynamic>> rewriteSuggestions;
  final Map<String, dynamic>? citationSuggestion;
  final DateTime createdAt;

  const FlaggedSection({
    required this.id,
    required this.scanId,
    required this.documentId,
    required this.startPosition,
    required this.endPosition,
    required this.flaggedText,
    required this.plagiarismType,
    required this.riskLevel,
    required this.confidenceScore,
    required this.similarityScore,
    this.sourceUrl,
    this.sourceTitle,
    this.sourceAuthor,
    this.sourcePublicationDate,
    this.matchedSourceText,
    required this.explanation,
    this.suggestedAction,
    this.rewriteSuggestions = const [],
    this.citationSuggestion,
    required this.createdAt,
  });

  factory FlaggedSection.fromJson(Map<String, dynamic> json) {
    return FlaggedSection(
      id: json['id'] as String,
      scanId: json['scan_id'] as String,
      documentId: json['document_id'] as String,
      startPosition: json['start_position'] as int,
      endPosition: json['end_position'] as int,
      flaggedText: json['flagged_text'] as String,
      plagiarismType: _parsePlagiarismType(json['plagiarism_type'] as String),
      riskLevel: _parseRiskLevel(json['risk_level'] as String),
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      similarityScore: (json['similarity_score'] as num).toDouble(),
      sourceUrl: json['source_url'] as String?,
      sourceTitle: json['source_title'] as String?,
      sourceAuthor: json['source_author'] as String?,
      sourcePublicationDate: json['source_publication_date'] as String?,
      matchedSourceText: json['matched_source_text'] as String?,
      explanation: json['explanation'] as String,
      suggestedAction: json['suggested_action'] as String?,
      rewriteSuggestions:
          (json['rewrite_suggestions'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [],
      citationSuggestion:
          json['citation_suggestion'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static PlagiarismType _parsePlagiarismType(String s) {
    switch (s) {
      case 'exact_copy':
        return PlagiarismType.exactCopy;
      case 'partial_copy':
        return PlagiarismType.partialCopy;
      case 'semantic_similarity':
        return PlagiarismType.semanticSimilarity;
      case 'missing_citation':
        return PlagiarismType.missingCitation;
      case 'paraphrased':
        return PlagiarismType.paraphrased;
      case 'ai_rewritten':
        return PlagiarismType.aiRewritten;
      case 'webDiscovery':
      case 'web_discovery':
        return PlagiarismType.webDiscovery;
      case 'selfPlagiarism':
      case 'self_plagiarism':
        return PlagiarismType.selfPlagiarism;
      case 'quotedAndCited':
      case 'quoted_and_cited':
        return PlagiarismType.quotedAndCited;
      default:
        return PlagiarismType.exactCopy;
    }
  }

  static RiskLevel _parseRiskLevel(String s) {
    switch (s) {
      case 'safe':
        return RiskLevel.safe;
      case 'low':
        return RiskLevel.low;
      case 'medium':
        return RiskLevel.medium;
      case 'high':
        return RiskLevel.high;
      case 'critical':
        return RiskLevel.critical;
      default:
        return RiskLevel.low;
    }
  }

  String get plagiarismTypeLabel {
    switch (plagiarismType) {
      case PlagiarismType.exactCopy:
        return 'Exact Copy';
      case PlagiarismType.partialCopy:
        return 'Partial Copy';
      case PlagiarismType.semanticSimilarity:
        return 'Semantic Similarity';
      case PlagiarismType.missingCitation:
        return 'Missing Citation';
      case PlagiarismType.paraphrased:
        return 'Paraphrased Content';
      case PlagiarismType.aiRewritten:
        return 'AI-Rewritten Content';
      case PlagiarismType.webDiscovery:
        return 'Web Discovery';
      case PlagiarismType.selfPlagiarism:
        return 'Possible Self-Plagiarism';
      case PlagiarismType.quotedAndCited:
        return 'Quoted & Cited';
    }
  }

  String get riskLabel {
    switch (riskLevel) {
      case RiskLevel.safe:
        return 'Safe';
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.medium:
        return 'Medium Risk';
      case RiskLevel.high:
        return 'High Risk';
      case RiskLevel.critical:
        return 'Critical';
    }
  }
}
