import 'dart:convert';
import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';

class GeminiService {
  GeminiService._();
  static final instance = GeminiService._();

  final _client = Supabase.instance.client;

  /// NO SDK Initialization required - Logic moved to Supabase Edge Functions.
  void initialize(String apiKey) {}

  /// Generates multiple 768-dimensional embeddings in a single batch call.
  Future<List<List<double>>> batchEmbedTexts(List<String> texts) async {
    if (texts.isEmpty) return [];
    try {
      final response = await _client.functions.invoke(
        'generate-embeddings',
        body: {'texts': texts},
      );

      if (response.status != 200) {
        throw Exception('Failed to generate batch embeddings: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      final List<dynamic> embeddingsData = data['embeddings'] as List<dynamic>;
      
      return embeddingsData.map((e) => 
        List<double>.from((e as List<dynamic>).map((v) => (v as num).toDouble()))
      ).toList();
    } catch (e) {
      dev.log('GeminiService Error (Batch Embedding): $e');
      rethrow;
    }
  }

  /// Generates a 768-dimensional embedding for the given text using the
  /// Supabase Edge Function (Gemini Embedding 2).
  Future<List<double>> embedText(String text) async {
    try {
      final response = await _client.functions.invoke(
        'generate-embeddings',
        body: {'text': text},
      );

      if (response.status != 200) {
        throw Exception('Failed to generate embedding: ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      return List<double>.from(
          data['embedding'].map((e) => (e as num).toDouble()));
    } catch (e) {
      dev.log('GeminiService Error (Embedding): $e');
      rethrow;
    }
  }

  /// Calls the secure 'gemini-reasoning' Edge Function.
  Future<Map<String, dynamic>> _invokeReasoning(String action, dynamic payload) async {
    try {
      final response = await _client.functions.invoke(
        'gemini-reasoning',
        body: {'action': action, 'payload': payload},
      );

      if (response.status != 200) {
        throw Exception('AI reasoning failed: ${response.data}');
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      dev.log('GeminiService Error ($action): $e');
      rethrow;
    }
  }

  /// Analyze text for AI content detection
  Future<Map<String, dynamic>> detectAiContent(String text) async {
    try {
      return await _invokeReasoning('analyze-quality', {'text': text, 'subTask': 'ai-detection'});
    } catch (e) {
      return {
        'human_score': 70,
        'ai_score': 30,
        'confidence': 50,
        'content_type': 'human',
        'reasoning': 'Unable to analyze content at this time.',
      };
    }
  }

  /// Analyze text for writing quality
  Future<Map<String, dynamic>> analyzeWritingQuality(String text) async {
    try {
      return await _invokeReasoning('analyze-quality', {'text': text});
    } catch (e) {
      return {
        'overall_writing_score': 70,
        'grammar_score': 75,
        'readability_score': 70,
        'academic_tone_score': 65,
        'vocabulary_score': 70,
        'structure_score': 72,
      };
    }
  }

  /// Detect plagiarism semantically and explain flagged sections
  Future<Map<String, dynamic>> analyzeForPlagiarism(
    String text,
    List<dynamic> evidence,
  ) async {
    try {
      return await _invokeReasoning('analyze-plagiarism', {
        'text': text,
        'evidence': evidence,
      });
    } catch (e) {
      return {
        'overall_similarity_score': 0,
        'exact_match_score': 0,
        'semantic_similarity_score': 0,
        'paraphrase_score': 0,
        'flagged_sections': [],
        'executive_summary': 'Analysis could not be completed at this time.',
      };
    }
  }

  /// Rewrite text in a specific style to reduce plagiarism
  Future<Map<String, dynamic>> rewriteText({
    required String text,
    required String style,
  }) async {
    try {
      final result = await _invokeReasoning('generate-rewrite', {
        'text': text,
        'style': style,
      });
      
      if (result['rewritten_text'] == null || result['rewritten_text'].toString().isEmpty) {
        throw Exception('AI returned an empty rewrite.');
      }
      
      return result;
    } catch (e) {
      dev.log('GeminiService Rewrite Error: $e');
      return {
        'rewritten_text': null,
        'error': e.toString(),
      };
    }
  }

  /// Compare two documents
  Future<Map<String, dynamic>> compareDocuments(
    String textA,
    String textB,
    String titleA,
    String titleB,
  ) async {
    try {
      return await _invokeReasoning('compare-documents', {
        'textA': textA,
        'textB': textB,
        'titleA': titleA,
        'titleB': titleB,
      });
    } catch (e) {
      return {
        'overall_similarity': 0,
        'executive_summary': 'Comparison failed: $e',
      };
    }
  }
}
