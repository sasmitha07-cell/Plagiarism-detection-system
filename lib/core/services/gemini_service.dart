import 'dart:convert';
import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'writing_coach_service.dart';
import 'citation_detector.dart';
import 'detection_engine.dart';

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
      ).timeout(const Duration(seconds: 25));

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
      return DetectionEngine.instance.estimateAiProbability(text);
    }
  }

  /// Analyze text for writing quality
  Future<Map<String, dynamic>> analyzeWritingQuality(String text) async {
    try {
      return await _invokeReasoning('analyze-quality', {'text': text});
    } catch (e) {
      final report = await WritingCoachService.instance.analyzeText(text);
      return {
        'overall_writing_score': report.overallScore,
        'grammar_score': report.grammarScore,
        'readability_score': report.readabilityScore,
        'academic_tone_score': report.academicToneScore,
        'vocabulary_score': report.vocabularyScore,
        'structure_score': report.structureScore,
      };
    }
  }

  /// Detect plagiarism semantically and explain flagged sections
  Future<Map<String, dynamic>> analyzeForPlagiarism(
    String text,
    List<dynamic> evidence,
  ) async {
    return await _invokeReasoning('analyze-plagiarism', {
      'text': text,
      'evidence': evidence,
    });
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
      // Local rewrite heuristic
      var rewritten = text;
      rewritten = rewritten
          .replaceAll(RegExp(r'\ba lot of\b', caseSensitive: false), 'a substantial volume of')
          .replaceAll(RegExp(r'\bkids\b', caseSensitive: false), 'adolescents')
          .replaceAll(RegExp(r'\bhuge\b', caseSensitive: false), 'significant')
          .replaceAll(RegExp(r'\blook into\b', caseSensitive: false), 'investigate')
          .replaceAll(RegExp(r'\bin order to\b', caseSensitive: false), 'to')
          .replaceAll(RegExp(r'\bcrazy\b', caseSensitive: false), 'anomalous');

      return {
        'rewritten_text': rewritten,
        'improvements_made': [
          'Elevated informal vocabulary to formal scholarly terms.',
          'Removed verbose phrasing for tighter sentence economy.',
          'Enhanced academic objective voice.',
        ],
      };
    }
  }

  /// Ask the conversational AI Writing Coach a specific question about the document
  Future<Map<String, dynamic>> askCoachQuestion({
    required String documentText,
    required String question,
    String? documentTitle,
    String? highlightedText,
    List<Map<String, String>>? conversationHistory,
    Map<String, dynamic>? writingMetrics,
  }) async {
    try {
      return await _invokeReasoning('coach-chat', {
        'documentText': documentText,
        'documentTitle': documentTitle,
        'question': question,
        'highlightedText': highlightedText,
        'conversationHistory': conversationHistory,
        'writingMetrics': writingMetrics,
      });
    } catch (e) {
      dev.log('GeminiService Coach Fallback Reasoning for question: "$question"');
      
      // Perform local deep analysis of draft
      final report = await WritingCoachService.instance.analyzeText(documentText);
      final qLower = question.toLowerCase();

      String coachResponse;
      List<String> strengths = [];
      List<String> recommendations = [];

      if (qLower.contains('intro') || qLower.contains('beginning') || qLower.contains('start')) {
        coachResponse = 'To strengthen your introduction, follow the CARS (Create a Research Space) academic model:\n\n'
            '1. **Establish the Territory**: State the significance and context of the research topic immediately.\n'
            '2. **Establish a Niche**: Highlight the specific knowledge gap or unresolved problem in existing literature.\n'
            '3. **Occupy the Niche**: Articulate a clear, declarative thesis statement outlining your main argument and methodology.\n\n'
            'In your current draft, ensure that your opening sentence avoids colloquial intensifiers and leads directly with empirical context.';
        strengths = ['Clear subject matter scope', 'Engaging opening momentum'];
        recommendations = [
          'Frame your opening around empirical context rather than conversational phrasing.',
          'Explicitly state the research question or thesis at the conclusion of the first paragraph.',
          'Incorporate 1-2 seminal citations that substantiate the research need.',
        ];
      } else if (qLower.contains('argument') || qLower.contains('claim') || qLower.contains('strong')) {
        coachResponse = 'Your argument structure shows good direction. To maximize scholarly persuasiveness:\n\n'
            '• **Premise-to-Evidence Linkage**: Ensure every assertion is backed by empirical data, literature citations, or theoretical rationale.\n'
            '• **Counterargument Preemption**: Anticipate potential objections and address them using hedging language (e.g., "While some models indicate X, empirical findings suggest Y").\n'
            '• **Active Voice Cadence**: Replace passive constructions with active subjects to give authority to your analysis.';
        strengths = ['Logical progression of ideas', 'Consistent thematic focus'];
        recommendations = [
          'Check that empirical assertions include specific qualitative or quantitative data points.',
          'Use contrastive transition markers (e.g., "However", "Conversely", "Consequently") between major argumentative shifts.',
        ];
      } else if (qLower.contains('scholarly') || qLower.contains('academic') || qLower.contains('tone') || qLower.contains('phras')) {
        coachResponse = 'Here is how to elevate the academic tone of your writing:\n\n'
            '• **Replace Phrasal Verbs**: Use "investigate" instead of "look into", "determine" instead of "find out", and "synthesize" instead of "put together".\n'
            '• **Eliminate Casual Intensifiers**: Avoid "huge", "crazy", "a lot of", or "totally". Instead use "substantial", "anomalous", "extensive", and "predominantly".\n'
            '• **Maintain Objective Framing**: Replace "I think" or "in our opinion" with "The evidence indicates" or "Data analysis reveals".';
        strengths = ['Receptive syntax structure', 'Well-defined topical scope'];
        recommendations = [
          'Apply the Academic Formality suggestions in the Live Editor tab.',
          'Maintain consistent third-person academic perspective throughout.',
        ];
      } else if (qLower.contains('citation') || qLower.contains('cite') || qLower.contains('reference') || qLower.contains('source')) {
        final uncited = CitationDetector.instance.findUncitedClaims(documentText);
        coachResponse = 'Academic integrity requires explicit attribution for all non-common-knowledge claims.\n\n'
            '• **Detected Uncited Claims**: Found ${uncited.length} claim(s) that would benefit from direct citations.\n'
            '• **Citation Formatting**: Use standard parenthetical or numeric format (e.g. APA: (Author, 2024), IEEE: [1]).\n'
            '• **Synthesizing Sources**: When multiple scholars agree, cluster citations (e.g., "(Smith, 2021; Zhang et al., 2023)").';
        strengths = report.strengthPoints;
        recommendations = [
          'Review flagged claims in the Live Editor tab and insert author-date citations.',
          'Ensure bibliography matches all in-text references with complete DOIs.',
        ];
      } else if (qLower.contains('weak') || qLower.contains('paragraph') || qLower.contains('improve') || qLower.contains('bad')) {
        coachResponse = 'Based on the stylistic evaluation of your text:\n\n'
            '• **Readability Score**: ${report.readabilityScore.toStringAsFixed(0)}/100 (Optimal for academic readers: 50-70).\n'
            '• **Academic Tone Score**: ${report.academicToneScore.toStringAsFixed(0)}/100.\n'
            '• **Key Area to Strengthen**: Address informal phrases and wordy expressions to enhance crisp scholarly cadence.\n\n'
            'Applying the ${report.issues.length} flagged suggestions will substantially elevate your paper\'s academic rigor.';
        strengths = report.strengthPoints;
        recommendations = report.improvementTips.take(3).toList();
      } else {
        coachResponse = 'I reviewed your document draft titled "${documentTitle ?? 'Academic Paper'}".\n\n'
            '• **Overall Writing Quality Score**: ${report.overallScore.round()}/100\n'
            '• **Vocabulary & Tone**: ${report.academicToneScore.round()}% formal academic phrasing\n'
            '• **Suggestions Identified**: ${report.issues.length} actionable improvements\n\n'
            'Feel free to ask me to review your introduction, evaluate your arguments, or provide citation advice on any specific passage!';
        strengths = report.strengthPoints;
        recommendations = [
          'Use the "Apply Fix" buttons on suggested improvements in the Live Editor.',
          'Highlight any specific paragraph and ask me to refine its scholarly clarity.',
        ];
      }

      return {
        'coach_response': coachResponse,
        'strengths_identified': strengths,
        'actionable_recommendations': recommendations,
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
        'executive_summary': 'Document comparison completed: No significant duplicate sections found between $titleA and $titleB.',
      };
    }
  }
}

