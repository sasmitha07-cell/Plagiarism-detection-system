import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

void main() {
  test('Test search_similar_documents RPC', () async {
    const url = 'https://nzawcebunfbwhrwfyrjz.supabase.co';
    const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im56YXdjZWJ1bmZid2hyd2Z5cmp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUyODUzNDksImV4cCI6MjEwMDg2MTM0OX0.Ew3eJIyvdOHMTWttpEXqFif5TqOXSkWKi4PPybZobrM';

    final dio = Dio(BaseOptions(
      baseUrl: url,
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
      },
      validateStatus: (status) => true,
    ));

    final res = await dio.post('/rest/v1/rpc/search_similar_documents', data: {
      'query_embedding': List.filled(768, 0.0),
      'user_uuid': '00000000-0000-0000-0000-000000000000',
    });
    print('search_similar_documents status: ${res.statusCode}');
    print('search_similar_documents body: ${jsonEncode(res.data)}');

    final resBatch = await dio.post('/rest/v1/rpc/match_document_chunks_batch', data: {
      'query_embeddings': [List.filled(768, 0.0)],
    });
    print('match_document_chunks_batch status: ${resBatch.statusCode}');
    print('match_document_chunks_batch body: ${jsonEncode(resBatch.data)}');
  });
}
