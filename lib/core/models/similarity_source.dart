class SimilaritySource {
  final String id;
  final String scanId;
  final String? url;
  final String? title;
  final String? author;
  final String? publicationDate;
  final String? domain;
  final String? snippet;
  final double similarityPercentage;
  final int matchCount;
  final String sourceType;
  final DateTime accessedAt;

  const SimilaritySource({
    required this.id,
    required this.scanId,
    this.url,
    this.title,
    this.author,
    this.publicationDate,
    this.domain,
    this.snippet,
    required this.similarityPercentage,
    this.matchCount = 1,
    this.sourceType = 'web',
    required this.accessedAt,
  });

  factory SimilaritySource.fromJson(Map<String, dynamic> json) {
    return SimilaritySource(
      id: json['id'] as String,
      scanId: json['scan_id'] as String,
      url: json['url'] as String?,
      title: json['title'] as String?,
      author: json['author'] as String?,
      publicationDate: json['publication_date'] as String?,
      domain: json['domain'] as String?,
      snippet: json['snippet'] as String?,
      similarityPercentage:
          (json['similarity_percentage'] as num).toDouble(),
      matchCount: json['match_count'] as int? ?? 1,
      sourceType: json['source_type'] as String? ?? 'web',
      accessedAt: DateTime.parse(
        json['accessed_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  String get displayTitle => title ?? domain ?? url ?? 'Unknown Source';
  String get sourceTypeLabel {
    switch (sourceType) {
      case 'academic':
        return 'Academic Journal';
      case 'user_document':
        return 'Your Document';
      case 'personal_source':
        return 'Personal Source';
      default:
        return 'Web Source';
    }
  }
}
