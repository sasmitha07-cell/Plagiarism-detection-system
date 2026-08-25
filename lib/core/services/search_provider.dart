import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/search_result.dart';
import 'dart:developer' as dev;

/// Decouples the plagiarism engine from specific search vendors.
abstract class SearchProvider {
  Future<List<SearchResult>> search(String query);
}

/// Implementation using Supabase Edge Function to route search requests.
class WebSearchService implements SearchProvider {
  WebSearchService._();
  static final instance = WebSearchService._();

  @override
  Future<List<SearchResult>> search(String query) async {
    try {
      dev.log('WebSearchService: Searching for "$query"');
      
      final response = await Supabase.instance.client.functions.invoke(
        'web-search',
        body: {'query': query},
      );

      if (response.status != 200) {
        throw Exception('Web search failed: ${response.data}');
      }

      final List<dynamic> resultsData = response.data as List<dynamic>;
      return resultsData.map((j) => SearchResult.fromJson(j)).toList();
      
    } catch (e) {
      dev.log('WebSearchService Error: $e');
      // Return empty list on failure to allow offline/foundation results to proceed
      return [];
    }
  }
}

/// Specific Google CSE Provider (currently routed through WebSearchService Edge Function)
class GoogleSearchProvider implements SearchProvider {
  @override
  Future<List<SearchResult>> search(String query) => WebSearchService.instance.search(query);
}
