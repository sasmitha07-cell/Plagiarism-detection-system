/// Represents discovery data from a web search engine.
class SearchResult {
  final String title;
  final String url;
  final String domain;
  final String snippet;
  final String query;
  final int rank;
  final String sourceType;

  SearchResult({
    required this.title,
    required this.url,
    required this.domain,
    required this.snippet,
    required this.query,
    required this.rank,
    this.sourceType = 'web',
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['url'] as String? ?? '';
    final uri = Uri.tryParse(rawUrl);
    final domain = json['domain'] as String? ?? (uri?.host.isNotEmpty == true ? uri!.host : 'web');
    return SearchResult(
      title: json['title'] as String? ?? 'No Title',
      url: rawUrl,
      domain: domain,
      snippet: json['snippet'] as String? ?? '',
      query: json['query'] as String? ?? '',
      rank: json['rank'] as int? ?? 0,
      sourceType: json['sourceType'] as String? ?? json['source_type'] as String? ?? 'web',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'domain': domain,
      'snippet': snippet,
      'query': query,
      'rank': rank,
      'sourceType': sourceType,
    };
  }
}
