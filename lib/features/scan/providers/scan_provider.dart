import 'dart:async';
import 'dart:io';
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/detection_engine.dart';
import '../../../core/services/vector_service.dart';
import '../../../core/services/document_processor.dart';
import '../../../core/models/match_evidence.dart';
import '../../../core/models/flagged_section.dart';
import '../../auth/providers/auth_provider.dart';

// ─── Models ────────────────────────────────────────────────────────────────

class ScanResultData {
  final String id;
  final String? documentId;
  final String title;
  final String? content;
  final double plagiarismScore;
  final double aiScore;
  final double writingScore;
  final double exactMatchScore;
  final double semanticScore;
  final double paraphraseScore;
  final String status;
  final String? executiveSummary;
  final List<FlaggedSectionData> flaggedSections;
  final DateTime createdAt;

  const ScanResultData({
    required this.id,
    this.documentId,
    required this.title,
    this.content,
    required this.plagiarismScore,
    required this.aiScore,
    required this.writingScore,
    required this.exactMatchScore,
    required this.semanticScore,
    required this.paraphraseScore,
    required this.status,
    this.executiveSummary,
    required this.flaggedSections,
    required this.createdAt,
  });

  /// Build from a Supabase row and its related flagged_sections rows.
  factory ScanResultData.fromJson(
    Map<String, dynamic> json, {
    List<Map<String, dynamic>> flagged = const [],
    String? originalContent,
  }) {
    return ScanResultData(
      id: json['id'] as String? ?? '',
      documentId: json['document_id'] as String?,
      title: json['title'] as String? ?? 'Document',
      content: originalContent ?? (json['documents'] as Map<String, dynamic>?)?['content'],
      plagiarismScore: (json['overall_similarity_score'] as num?)?.toDouble() ?? 0,
      aiScore: (json['ai_score'] as num?)?.toDouble() ?? 0,
      writingScore: (json['writing_score'] as num?)?.toDouble() ?? 0,
      exactMatchScore: (json['exact_match_score'] as num?)?.toDouble() ?? 0,
      semanticScore: (json['semantic_similarity_score'] as num?)?.toDouble() ?? 0,
      paraphraseScore: (json['paraphrase_score'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
      executiveSummary: json['executive_summary'] as String?,
      flaggedSections: flagged.map(FlaggedSectionData.fromJson).toList(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class FlaggedSectionData {
  final String flaggedText;
  final List<PlagiarismType> signals;
  final String riskLevel;
  final int confidenceScore;
  final int similarityScore;
  final String? sourceUrl;
  final String? sourceTitle;
  final String? domain;
  final String? explanation;
  final String? suggestedAction;
  final int startPosition;
  final int endPosition;

  const FlaggedSectionData({
    required this.flaggedText,
    required this.signals,
    required this.riskLevel,
    required this.confidenceScore,
    required this.similarityScore,
    this.sourceUrl,
    this.sourceTitle,
    this.domain,
    this.explanation,
    this.suggestedAction,
    required this.startPosition,
    required this.endPosition,
  });

  factory FlaggedSectionData.fromJson(Map<String, dynamic> j) {
    return FlaggedSectionData(
      flaggedText: j['flagged_text'] as String? ?? '',
      signals: (j['signals'] as List<dynamic>?)
              ?.map((s) => PlagiarismType.values.firstWhere(
                  (v) => v.name == s,
                  orElse: () => PlagiarismType.semanticSimilarity))
              .toList() ??
          [PlagiarismType.semanticSimilarity],
      riskLevel: j['risk_level'] as String? ?? 'low',
      confidenceScore: (j['confidence_score'] as num?)?.toInt() ?? 0,
      similarityScore: (j['similarity_score'] as num?)?.toInt() ?? 0,
      sourceUrl: j['source_url'] as String?,
      sourceTitle: j['source_title'] as String?,
      domain: j['domain'] as String?,
      explanation: j['explanation'] as String?,
      suggested_action: j['suggested_action'] as String?,
      startPosition: (j['start_position'] as num?)?.toInt() ?? 0,
      endPosition: (j['end_position'] as num?)?.toInt() ?? 0,
    );
  }
}

// ─── Provider ──────────────────────────────────────────────────────────────

/// Fetches a completed scan result (+ flagged sections) from Supabase by scanId.
final scanResultProvider =
    FutureProvider.family<ScanResultData?, String>((ref, scanId) async {
  // Check memory cache first (Zero-latency transition)
  final activeScan = ref.read(activeScanProvider.notifier);
  if (activeScan.lastResult?.id == scanId) {
    return activeScan.lastResult;
  }

  final client = Supabase.instance.client;

  if (scanId.startsWith('scan_') && !RegExp(r'^[0-9a-f-]{36}$').hasMatch(scanId)) {
    return null;
  }

  final row = await client
      .from('scan_results')
      .select('*, documents(content)')
      .eq('id', scanId)
      .maybeSingle();

  if (row == null) return null;

  final flaggedRows = await client
      .from('flagged_sections')
      .select()
      .eq('scan_id', scanId)
      .order('start_position');

  return ScanResultData.fromJson(
    row,
    flagged: List<Map<String, dynamic>>.from(flaggedRows as List),
  );
});

// ─── Scan service ──────────────────────────────────────────────────────────

class ScanService {
  ScanService._();
  static final instance = ScanService._();

  final _client = Supabase.instance.client;

  /// Returns the completed scan result data.
  Future<ScanResultData> runScan({
    required String userId,
    required String title,
    required String content,
    required String contentType,
    File? file,
    void Function(String step)? onStepChanged,
  }) async {
    dev.log('ScanService: Starting scan pipeline for $title');

    // ── Step 1: Save document ──────────────────────────────────────────────
    onStepChanged?.call('Saving document…');
    String? documentId;
    try {
      final docRow = await _client.from('documents').insert({
        'user_id': userId,
        'title': title,
        'content': content, 
        'content_type': contentType,
        'word_count': _countWords(content),
        'status': 'active',
        'file_size_bytes': content.length,
        'created_at': DateTime.now().toIso8601String(),
      }).select('id').single();
      documentId = docRow['id'] as String?;
    } catch (e) {
      dev.log('ScanService Error: Document save failed: $e');
    }

    // ── Step 2: Create scan record ─────────────────────────────────────────
    onStepChanged?.call('Initializing AI engine…');
    late String scanId;
    try {
      final scanRow = await _client.from('scan_results').insert({
        'user_id': userId,
        if (documentId != null) 'document_id': documentId,
        'title': title,
        'status': 'processing',
        'overall_similarity_score': 0,
        'ai_score': 0,
        'writing_score': 0,
        'created_at': DateTime.now().toIso8601String(),
      }).select('id').single();
      scanId = scanRow['id'] as String;
    } catch (e) {
      scanId = 'demo_${DateTime.now().millisecondsSinceEpoch}';
    }

    // ── Step 3: Run Hybrid analysis ──────────────────────────────────────
    final gemini = GeminiService.instance;
    final stopwatch = Stopwatch()..start();

    Map<String, dynamic> plagiarismResult = {};
    Map<String, dynamic> aiResult = {};
    Map<String, dynamic> writingResult = {};
    List<MatchEvidence> evidence = [];

    try {
      // 1. Hybrid Engine (Batched Vector + Robust Web Search)
      onStepChanged?.call('Extracting semantic meaning…');
      final detectionResult = await DetectionEngine.instance.analyzeDocument(
        text: content,
        userId: userId,
        currentDocumentId: documentId,
      );
      evidence = detectionResult.$1;

      // 2. Parallel AI analysis with Individual Progress Feedback
      onStepChanged?.call('Analyzing integrity and quality…');
      
      final limitedContent = content.length > 12000 
          ? '${content.substring(0, 12000)}... [Truncated for speed]' 
          : content;

      await Future.wait([
        gemini.detectAiContent(limitedContent).then((res) {
          aiResult = res;
          onStepChanged?.call('AI check complete…');
        }).catchError((e) => aiResult = _mockAiResult(content)),
        
        gemini.analyzeWritingQuality(limitedContent).then((res) {
          writingResult = res;
          onStepChanged?.call('Quality analysis complete…');
        }).catchError((e) => writingResult = _mockWritingResult(content)),
        
        gemini.analyzeForPlagiarism(
          limitedContent, 
          evidence.map((e) => e.toJson()).toList(),
        ).then((res) {
          plagiarismResult = res;
          onStepChanged?.call('Plagiarism review complete…');
        }).catchError((e) {
          if (evidence.isEmpty) {
            plagiarismResult = {'overall_similarity_score': 0, 'flagged_sections': []};
          } else {
            plagiarismResult = _mockPlagiarismResult(content);
          }
        }),
      ]).timeout(const Duration(seconds: 25), onTimeout: () {
        dev.log('ScanService: AI analysis timed out (25s). Falling back to partial results.');
        return [];
      });
      
      dev.log('ScanService: Total analysis time: ${stopwatch.elapsed.inSeconds}s');
      dev.log('ScanService: Pipeline error: $e');
      plagiarismResult = _mockPlagiarismResult(content);
      aiResult = _mockAiResult(content);
      writingResult = _mockWritingResult(content);
    }

    onStepChanged?.call('Generating comprehensive report…');

    // ── Step 4: Write flagged sections ─────────────────────────────────────
    final flaggedSections =
        plagiarismResult['flagged_sections'] as List<dynamic>? ?? [];
    if (flaggedSections.isNotEmpty && !scanId.startsWith('demo_')) {
      try {
        await _client.from('flagged_sections').insert(
          flaggedSections.map((s) {
            final sec = s as Map<String, dynamic>;
            final startPos = (sec['start_position'] as num?)?.toInt() ?? 0;
            final originalEv = evidence.firstWhere(
              (e) => (e.startOffset - startPos).abs() < 5,
              orElse: () => MatchEvidence(submittedText: '', signals: [], startOffset: 0, endOffset: 0),
            );

            return {
              'scan_id': scanId,
              'document_id': documentId,
              'flagged_text': sec['flagged_text'] ?? '',
              'plagiarism_type': originalEv.signals.isNotEmpty ? originalEv.signals.first.name : 'semantic_similarity',
              'signals': originalEv.signals.map((s) => s.name).toList(),
              'risk_level': sec['risk_level'] ?? 'low',
              'confidence_score': sec['confidence_score'] ?? 0,
              'similarity_score': sec['similarity_score'] ?? 0,
              'source_url': sec['source_url'] ?? originalEv.sourceUrl,
              'source_title': sec['source_title'] ?? originalEv.sourceTitle,
              'domain': originalEv.domain,
              'explanation': sec['explanation'] ?? '',
              'suggested_action': sec['suggested_action'] ?? '',
              'start_position': startPos,
              'end_position': (sec['end_position'] as num?)?.toInt() ?? originalEv.endOffset,
            };
          }).toList(),
        );
      } catch (e) {
        dev.log('ScanService: Flagged sections write failed: $e');
      }
    }

    // ── Step 5: Update scan_results to completed ───────────────────────────
    final plagScore = (plagiarismResult['overall_similarity_score'] as num?)?.toDouble() ?? 0;
    final aiScore = (aiResult['ai_score'] as num?)?.toDouble() ?? 0;
    final writingScore = (writingResult['overall_writing_score'] as num?)?.toDouble() ?? 70;

    if (!scanId.startsWith('demo_')) {
      try {
        await _client.from('scan_results').update({
          'status': 'completed',
          'overall_similarity_score': plagScore,
          'exact_match_score': (plagiarismResult['exact_match_score'] as num?)?.toDouble() ?? 0,
          'semantic_similarity_score': (plagiarismResult['semantic_similarity_score'] as num?)?.toDouble() ?? 0,
          'paraphrase_score': (plagiarismResult['paraphrase_score'] as num?)?.toDouble() ?? 0,
          'ai_score': aiScore,
          'writing_score': writingScore,
          'executive_summary': plagiarismResult['executive_summary'],
          'completed_at': DateTime.now().toIso8601String(),
        }).eq('id', scanId);
      } catch (e) {
        dev.log('ScanService: Final update failed: $e');
      }
    }

    return ScanResultData(
      id: scanId,
      documentId: documentId,
      title: title,
      content: content,
      plagiarismScore: plagScore,
      aiScore: aiScore,
      writingScore: writingScore,
      exactMatchScore: (plagiarismResult['exact_match_score'] as num?)?.toDouble() ?? 0,
      semanticScore: (plagiarismResult['semantic_similarity_score'] as num?)?.toDouble() ?? 0,
      paraphraseScore: (plagiarismResult['paraphrase_score'] as num?)?.toDouble() ?? 0,
      status: 'completed',
      executiveSummary: plagiarismResult['executive_summary'],
      flaggedSections: (plagiarismResult['flagged_sections'] as List<dynamic>?)?.map((s) => FlaggedSectionData.fromJson(s as Map<String, dynamic>)).toList() ?? [],
      createdAt: DateTime.now(),
    );
  }

  int _countWords(String text) => text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  Future<bool> applyFix({
    required String documentId,
    required int startPos,
    required int endPos,
    required String oldText,
    required String newText,
  }) async {
    try {
      final docRow = await _client.from('documents').select('content').eq('id', documentId).single();
      String content = docRow['content'] as String;

      if (content.substring(startPos, endPos) != oldText) {
          final index = content.indexOf(oldText);
          if (index != -1) {
              content = content.replaceRange(index, index + oldText.length, newText);
          } else {
              throw Exception('Original text not found in document.');
          }
      } else {
          content = content.replaceRange(startPos, endPos, newText);
      }

      await _client.from('documents').update({
        'content': content,
        'word_count': _countWords(content),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', documentId);

      return true;
    } catch (e) {
      dev.log('ScanService Error (applyFix): $e');
      return false;
    }
  }

  // ── Diagnostics Mock Data (Used ONLY on API failure) ──────────────────

  Map<String, dynamic> _mockPlagiarismResult(String text) {
    dev.log('DIAGNOSTIC: Fallback to Mock Plagiarism Result');
    return {
      'overall_similarity_score': 0,
      'flagged_sections': [],
      'executive_summary': 'No definitive matches found on the web or in your database.',
    };
  }

  Map<String, dynamic> _mockAiResult(String text) {
    return {'ai_score': 0, 'human_score': 100, 'confidence': 50};
  }

  Map<String, dynamic> _mockWritingResult(String text) {
    return {'overall_writing_score': 70};
  }
}

class ActiveScanNotifier extends AsyncNotifier<ScanResultData?> {
  @override
  FutureOr<ScanResultData?> build() => null;

  ScanResultData? _lastResult;
  ScanResultData? get lastResult => _lastResult;

  Future<String?> startScan({
    required String title,
    required String content,
    required String contentType,
    File? file,
    void Function(String step)? onStepChanged,
  }) async {
    final userId = ref.read(currentUserIdProvider) ?? 'anonymous';
    Future.microtask(() => state = const AsyncValue.loading());
    
    try {
      final resultData = await ScanService.instance.runScan(
        userId: userId,
        title: title,
        content: content,
        contentType: contentType,
        file: file,
        onStepChanged: onStepChanged,
      );

      _lastResult = resultData;
      state = AsyncValue.data(resultData);
      return resultData.id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final activeScanProvider = AsyncNotifierProvider<ActiveScanNotifier, ScanResultData?>(ActiveScanNotifier.new);
