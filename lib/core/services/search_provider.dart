import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/search_result.dart';

/// Decouples the plagiarism engine from specific search vendors.
abstract class SearchProvider {
  Future<List<SearchResult>> search(String query);
}

/// Robust multi-source search service routing across:
/// 1. Supabase Edge Function ('web-search')
/// 2. CrossRef Open Academic Literature API (150M+ scholarly papers/journals)
/// 3. Wikipedia Knowledge & Encyclopedia API
class WebSearchService implements SearchProvider {
  WebSearchService._();
  static final instance = WebSearchService._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
      headers: {
        'User-Agent': 'AcademicWritingCoach/1.0 (academic-coach@antigravity.dev)',
        'Accept': 'application/json',
      },
    ),
  );

  @override
  Future<List<SearchResult>> search(String query) async {
    final cleanQuery = query.replaceAll('"', '').trim();
    if (cleanQuery.isEmpty) return [];

    final List<SearchResult> results = [];

    // 1. Attempt Supabase Edge Function
    try {
      dev.log('WebSearchService: Invoking web-search edge function for "$cleanQuery"');
      final response = await Supabase.instance.client.functions.invoke(
        'web-search',
        body: {'query': cleanQuery},
      );

      if (response.status == 200 && response.data is List) {
        final List<dynamic> resultsData = response.data as List<dynamic>;
        for (final item in resultsData) {
          if (item is Map<String, dynamic>) {
            results.add(SearchResult.fromJson(item));
          }
        }
        if (results.isNotEmpty) {
          dev.log('WebSearchService: Retrieved ${results.length} results via Edge Function');
          return results;
        }
      }
    } catch (e) {
      dev.log('WebSearchService: Edge Function fallback note: $e');
    }

    // 2. Direct Open Academic Literature Fallback (CrossRef API)
    try {
      final crRes = await _dio.get(
        'https://api.crossref.org/works',
        queryParameters: {
          'query': cleanQuery,
          'rows': 3,
        },
      );

      if (crRes.statusCode == 200 && crRes.data != null) {
        final items = crRes.data['message']?['items'] as List<dynamic>? ?? [];
        for (int i = 0; i < items.length; i++) {
          final item = items[i] as Map<String, dynamic>;
          final titles = item['title'] as List<dynamic>?;
          final title = (titles != null && titles.isNotEmpty) ? titles.first.toString() : 'Academic Publication';
          final url = item['URL'] as String? ?? (item['DOI'] != null ? 'https://doi.org/${item['DOI']}' : '');
          final containers = item['container-title'] as List<dynamic>?;
          final journal = (containers != null && containers.isNotEmpty) ? containers.first.toString() : 'Scholarly Journal';
          final authors = item['author'] as List<dynamic>?;
          final authorName = (authors != null && authors.isNotEmpty)
              ? '${(authors.first as Map<String, dynamic>)['family'] ?? ''} et al.'
              : '';
          final rawSnippet = item['abstract'] as String?;
          final snippet = rawSnippet != null
              ? rawSnippet.replaceAll(RegExp(r'<[^>]*>'), ' ').trim()
              : '$title ($authorName, $journal). Peer-reviewed academic source.';

          if (url.isNotEmpty) {
            results.add(SearchResult(
              title: '$title — $journal',
              url: url,
              domain: 'crossref.org',
              snippet: snippet,
              query: cleanQuery,
              rank: results.length + 1,
              sourceType: 'academic',
            ));
          }
        }
      }
    } catch (e) {
      dev.log('WebSearchService: CrossRef query note: $e');
    }

    // 3. Direct Open Encyclopedia & Reference Fallback (Wikipedia API)
    try {
      final wikiRes = await _dio.get(
        'https://en.wikipedia.org/w/api.php',
        queryParameters: {
          'action': 'query',
          'list': 'search',
          'srsearch': cleanQuery,
          'utf8': '',
          'format': 'json',
        },
      );

      if (wikiRes.statusCode == 200 && wikiRes.data != null) {
        final items = wikiRes.data['query']?['search'] as List<dynamic>? ?? [];
        for (int i = 0; i < items.length && i < 3; i++) {
          final item = items[i] as Map<String, dynamic>;
          final rawTitle = item['title'] as String? ?? 'Wikipedia Article';
          final rawSnippet = item['snippet'] as String? ?? '';
          final cleanSnippet = rawSnippet
              .replaceAll(RegExp(r'<[^>]*>'), ' ')
              .replaceAll('&quot;', '"')
              .replaceAll('&#039;', "'")
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          results.add(SearchResult(
            title: '$rawTitle — Wikipedia',
            url: 'https://en.wikipedia.org/wiki/${Uri.encodeComponent(rawTitle.replaceAll(' ', '_'))}',
            domain: 'en.wikipedia.org',
            snippet: cleanSnippet,
            query: cleanQuery,
            rank: results.length + 1,
            sourceType: 'web',
          ));
        }
      }
    } catch (e) {
      dev.log('WebSearchService: Wikipedia query note: $e');
    }

    // 4. Direct DuckDuckGo Instant Answer & Open Reference API
    try {
      final ddgRes = await _dio.get(
        'https://api.duckduckgo.com/',
        queryParameters: {
          'q': cleanQuery,
          'format': 'json',
          'no_html': '1',
          'skip_disambig': '1',
        },
      );
      if (ddgRes.statusCode == 200 && ddgRes.data is Map) {
        final data = ddgRes.data as Map<String, dynamic>;
        final heading = data['Heading'] as String? ?? '';
        final abstractText = data['AbstractText'] as String? ?? '';
        final abstractUrl = data['AbstractURL'] as String? ?? '';
        final abstractSource = data['AbstractSource'] as String? ?? 'Web Source';

        if (abstractText.isNotEmpty && abstractUrl.isNotEmpty) {
          results.add(SearchResult(
            title: heading.isNotEmpty ? '$heading — $abstractSource' : abstractSource,
            url: abstractUrl,
            domain: Uri.tryParse(abstractUrl)?.host ?? 'duckduckgo.com',
            snippet: abstractText,
            query: cleanQuery,
            rank: results.length + 1,
            sourceType: 'web',
          ));
        }

        final related = data['RelatedTopics'] as List<dynamic>? ?? [];
        for (final item in related.take(2)) {
          if (item is Map<String, dynamic> && item.containsKey('Text') && item.containsKey('FirstURL')) {
            final text = item['Text'] as String? ?? '';
            final url = item['FirstURL'] as String? ?? '';
            if (text.isNotEmpty && url.isNotEmpty) {
              results.add(SearchResult(
                title: text.split(' - ').first,
                url: url,
                domain: Uri.tryParse(url)?.host ?? 'web',
                snippet: text,
                query: cleanQuery,
                rank: results.length + 1,
                sourceType: 'web',
              ));
            }
          }
        }
      }
    } catch (e) {
      dev.log('WebSearchService: DuckDuckGo query note: $e');
    }

    // Deduplicate by URL
    final seenUrls = <String>{};
    final unique = <SearchResult>[];
    for (final r in results) {
      if (r.url.isNotEmpty && seenUrls.add(r.url)) {
        unique.add(r);
      }
    }

    return unique;
  }
}

/// Provider routed through WebSearchService
class GoogleSearchProvider implements SearchProvider {
  @override
  Future<List<SearchResult>> search(String query) => WebSearchService.instance.search(query);
}
