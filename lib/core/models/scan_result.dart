import 'flagged_section.dart';
import 'similarity_source.dart';

enum ScanStatus { pending, processing, completed, failed }
enum ContentType { human, ai, mixed }

class ScanResult {
  final String id;
  final String userId;
  final String documentId;
  final String title;
  final ScanStatus status;

  // Plagiarism scores
  final double overallSimilarityScore;
  final double exactMatchScore;
  final double semanticSimilarityScore;
  final double paraphraseScore;

  // AI detection
  final double aiGeneratedScore;
  final double humanWrittenScore;
  final double aiDetectionConfidence;
  final ContentType contentType;

  // Writing quality
  final double? grammarScore;
  final double? readabilityScore;
  final double? academicToneScore;
  final double? vocabularyScore;
  final double? structureScore;
  final double? overallWritingScore;

  // Stats
  final int totalFlaggedSections;
  final int totalSourcesFound;
  final int sourcesChecked;
  final int? processingTimeMs;

  final String? reportUrl;
  final String? executiveSummary;
  final List<String> recommendations;
  final DateTime createdAt;
  final DateTime? completedAt;

  // Nested data (populated on demand)
  final List<FlaggedSection> flaggedSections;
  final List<SimilaritySource> sources;

  const ScanResult({
    required this.id,
    required this.userId,
    required this.documentId,
    this.title = 'Document Scan',
    this.status = ScanStatus.pending,
    this.overallSimilarityScore = 0,
    this.exactMatchScore = 0,
    this.semanticSimilarityScore = 0,
    this.paraphraseScore = 0,
    this.aiGeneratedScore = 0,
    this.humanWrittenScore = 100,
    this.aiDetectionConfidence = 0,
    this.contentType = ContentType.human,
    this.grammarScore,
    this.readabilityScore,
    this.academicToneScore,
    this.vocabularyScore,
    this.structureScore,
    this.overallWritingScore,
    this.totalFlaggedSections = 0,
    this.totalSourcesFound = 0,
    this.sourcesChecked = 0,
    this.processingTimeMs,
    this.reportUrl,
    this.executiveSummary,
    this.recommendations = const [],
    required this.createdAt,
    this.completedAt,
    this.flaggedSections = const [],
    this.sources = const [],
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    final docMap = json['documents'] is Map<String, dynamic>
        ? json['documents'] as Map<String, dynamic>
        : null;
    final docTitle = docMap?['title'] as String?;
    final docContent = docMap?['content'] as String?;

    return ScanResult(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      documentId: json['document_id']?.toString() ?? '',
      title: json['title'] as String? ?? docTitle ?? 'Document Scan',
      status: _parseStatus(json['status'] as String? ?? 'pending'),
      overallSimilarityScore:
          (json['overall_similarity_score'] as num?)?.toDouble() ?? 0.0,
      exactMatchScore:
          (json['exact_match_score'] as num?)?.toDouble() ?? 0.0,
      semanticSimilarityScore:
          (json['semantic_similarity_score'] as num?)?.toDouble() ?? 0.0,
      paraphraseScore:
          (json['paraphrase_score'] as num?)?.toDouble() ?? 0.0,
      aiGeneratedScore: (json['ai_generated_score'] as num?)?.toDouble() ??
          (json['ai_score'] as num?)?.toDouble() ??
          0.0,
      humanWrittenScore:
          (json['human_written_score'] as num?)?.toDouble() ?? 100.0,
      aiDetectionConfidence:
          (json['ai_detection_confidence'] as num?)?.toDouble() ?? 0.0,
      contentType: _parseContentType(json['content_type'] as String? ?? 'human'),
      grammarScore: (json['grammar_score'] as num?)?.toDouble(),
      readabilityScore: (json['readability_score'] as num?)?.toDouble(),
      academicToneScore: (json['academic_tone_score'] as num?)?.toDouble(),
      vocabularyScore: (json['vocabulary_score'] as num?)?.toDouble(),
      structureScore: (json['structure_score'] as num?)?.toDouble(),
      overallWritingScore:
          (json['overall_writing_score'] as num?)?.toDouble() ??
              (json['writing_score'] as num?)?.toDouble() ??
              75.0,
      totalFlaggedSections:
          (json['total_flagged_sections'] as num?)?.toInt() ?? 0,
      totalSourcesFound: (json['total_sources_found'] as num?)?.toInt() ?? 0,
      sourcesChecked: (json['sources_checked'] as num?)?.toInt() ?? 0,
      processingTimeMs: (json['processing_time_ms'] as num?)?.toInt(),
      reportUrl: json['report_url'] as String?,
      executiveSummary: json['executive_summary'] as String?,
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
    );
  }

  static ScanStatus _parseStatus(String s) {
    switch (s.toLowerCase()) {
      case 'processing':
        return ScanStatus.processing;
      case 'completed':
        return ScanStatus.completed;
      case 'failed':
        return ScanStatus.failed;
      default:
        return ScanStatus.pending;
    }
  }

  static ContentType _parseContentType(String s) {
    switch (s.toLowerCase()) {
      case 'ai':
        return ContentType.ai;
      case 'mixed':
        return ContentType.mixed;
      default:
        return ContentType.human;
    }
  }

  bool get isCompleted => status == ScanStatus.completed;
  bool get isProcessing => status == ScanStatus.processing;
  bool get hasFailed => status == ScanStatus.failed;

  double get originalityScore => (100.0 - overallSimilarityScore).clamp(0.0, 100.0);

  String get riskLabel {
    if (overallSimilarityScore < 15) return 'Safe';
    if (overallSimilarityScore < 30) return 'Low Risk';
    if (overallSimilarityScore < 50) return 'Medium Risk';
    if (overallSimilarityScore < 70) return 'High Risk';
    return 'Critical';
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
