import 'dart:async';
import 'dart:io';
import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/detection_engine.dart';
import '../../../core/services/document_processor.dart';
import '../../../core/models/match_evidence.dart';
import '../../../core/models/flagged_section.dart';
import '../../../core/services/writing_coach_service.dart';
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
  final List<Map<String, dynamic>> sources;
  final Map<String, dynamic>? writingAnalytics;
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
    this.sources = const [],
    this.writingAnalytics,
    required this.createdAt,
  });

  /// Build from a Supabase row and its related flagged_sections rows.
  factory ScanResultData.fromJson(
    Map<String, dynamic> json, {
    List<Map<String, dynamic>> flagged = const [],
    List<Map<String, dynamic>> sources = const [],
    Map<String, dynamic>? analytics,
    String? originalContent,
  }) {
    return ScanResultData(
      id: json['id'] as String? ?? '',
      documentId: json['document_id'] as String?,
      title: json['title'] as String? ?? (json['documents'] as Map<String, dynamic>?)?['title'] as String? ?? 'Document',
      content: originalContent ?? (json['documents'] as Map<String, dynamic>?)?['content'] as String?,
      plagiarismScore: (json['overall_similarity_score'] as num?)?.toDouble() ?? 0,
      aiScore: (json['ai_score'] as num?)?.toDouble() ?? (json['ai_generated_score'] as num?)?.toDouble() ?? 0,
      writingScore: (json['writing_score'] as num?)?.toDouble() ?? (json['overall_writing_score'] as num?)?.toDouble() ?? 75,
      exactMatchScore: (json['exact_match_score'] as num?)?.toDouble() ?? 0,
      semanticScore: (json['semantic_similarity_score'] as num?)?.toDouble() ?? 0,
      paraphraseScore: (json['paraphrase_score'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
      executiveSummary: json['executive_summary'] as String?,
      flaggedSections: flagged.map(FlaggedSectionData.fromJson).toList(),
      sources: sources,
      writingAnalytics: analytics,
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
      suggestedAction: j['suggested_action'] as String?,
      startPosition: (j['start_position'] as num?)?.toInt() ?? 0,
      endPosition: (j['end_position'] as num?)?.toInt() ?? 0,
    );
  }
}

// ─── Provider ──────────────────────────────────────────────────────────────

/// Fetches a completed scan result (+ flagged sections + sources + analytics) from Supabase by scanId.
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

  try {
    final row = await client
        .from('scan_results')
        .select('*, documents(title, content, word_count)')
        .eq('id', scanId)
        .maybeSingle();

    if (row == null) return null;

    final flaggedRows = await client
        .from('flagged_sections')
        .select()
        .eq('scan_id', scanId)
        .order('start_position');

    List<Map<String, dynamic>> sourceRows = [];
    try {
      final sData = await client
          .from('similarity_sources')
          .select()
          .eq('scan_id', scanId);
      sourceRows = List<Map<String, dynamic>>.from(sData as List);
    } catch (_) {}

    Map<String, dynamic>? analyticsRow;
    try {
      analyticsRow = await client
          .from('writing_analytics')
          .select()
          .eq('scan_id', scanId)
          .maybeSingle();
    } catch (_) {}

    return ScanResultData.fromJson(
      row,
      flagged: List<Map<String, dynamic>>.from(flaggedRows as List),
      sources: sourceRows,
      analytics: analyticsRow,
    );
  } catch (e) {
    dev.log('scanResultProvider error: $e');
    return null;
  }
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
        'file_type': _mapDocumentType(contentType),
        'word_count': _countWords(content),
        'character_count': content.length,
        'file_size_bytes': content.length,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select('id').single();
      documentId = docRow['id'] as String?;
    } catch (e) {
      dev.log('ScanService Error: Document save failed: $e');
    }

    // ── Step 2: Create scan record ─────────────────────────────────────────
    onStepChanged?.call('Initializing AI engine…');
    late String scanId;
    try {
      if (documentId != null) {
        final scanRow = await _client.from('scan_results').insert({
          'user_id': userId,
          'document_id': documentId,
          'status': 'processing',
          'overall_similarity_score': 0.0,
          'exact_match_score': 0.0,
          'semantic_similarity_score': 0.0,
          'paraphrase_score': 0.0,
          'ai_generated_score': 0.0,
          'human_written_score': 100.0,
          'overall_writing_score': 0.0,
          'created_at': DateTime.now().toIso8601String(),
        }).select('id').single();
        scanId = scanRow['id'] as String;
      } else {
        scanId = 'session_${DateTime.now().microsecondsSinceEpoch}';
      }
    } catch (e) {
      dev.log('ScanService Error: Scan record create failed: $e');
      scanId = 'session_${DateTime.now().microsecondsSinceEpoch}';
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

      // 2. Parallel AI & Writing Coach analysis
      onStepChanged?.call('Analyzing integrity and quality…');
      
      // Run comprehensive Writing Coach analysis
      final writingAnalysis = await WritingCoachService.instance.analyzeText(content);
      writingResult = {
        'overall_writing_score': writingAnalysis.overallScore,
        'grammar_score': writingAnalysis.grammarScore,
        'readability_score': writingAnalysis.readabilityScore,
        'academic_tone_score': writingAnalysis.academicToneScore,
        'vocabulary_score': writingAnalysis.vocabularyScore,
      };

      final limitedContent = content.length > 12000 
          ? '${content.substring(0, 12000)}... [Truncated for speed]' 
          : content;

      await Future.wait([
        gemini.detectAiContent(limitedContent).then((res) {
          aiResult = res;
          onStepChanged?.call('AI check complete…');
        }).catchError((err) {
          dev.log('AI Detection Error (Fallback to Statistical Engine): $err');
          aiResult = DetectionEngine.instance.estimateAiProbability(content);
        }),
        
        gemini.analyzeForPlagiarism(
          limitedContent, 
          evidence.map((e) => e.toJson()).toList(),
        ).then((res) {
          plagiarismResult = res;
          onStepChanged?.call('Plagiarism review complete…');
        }).catchError((err) {
          dev.log('Plagiarism Reasoning Note (Fallback to Deterministic): $err');
          plagiarismResult = DetectionEngine.instance.computeDeterministicReport(
            text: content,
            evidence: evidence,
            chunks: detectionResult.$2,
          );
        }),
      ]).timeout(const Duration(seconds: 25), onTimeout: () {
        dev.log('ScanService: AI reasoning timeout (25s). Computing deterministic report.');
        plagiarismResult = DetectionEngine.instance.computeDeterministicReport(
          text: content,
          evidence: evidence,
          chunks: detectionResult.$2,
        );
        if (aiResult.isEmpty) {
          aiResult = DetectionEngine.instance.estimateAiProbability(content);
        }
        return [];
      });
      
      if (plagiarismResult.isEmpty ||
          plagiarismResult['flagged_sections'] == null ||
          ((plagiarismResult['flagged_sections'] as List).isEmpty && evidence.isNotEmpty)) {
        plagiarismResult = DetectionEngine.instance.computeDeterministicReport(
          text: content,
          evidence: evidence,
          chunks: detectionResult.$2,
        );
      }

      if (aiResult.isEmpty) {
        aiResult = DetectionEngine.instance.estimateAiProbability(content);
      }

      dev.log('ScanService: Total analysis time: ${stopwatch.elapsed.inSeconds}s');
    } catch (e) {
      dev.log('ScanService: Pipeline error: $e');
      final chunks = DocumentProcessor.instance.chunkDocument(content);
      plagiarismResult = DetectionEngine.instance.computeDeterministicReport(
        text: content,
        evidence: evidence,
        chunks: chunks,
      );
      aiResult = DetectionEngine.instance.estimateAiProbability(content);
      try {
        final wAnalysis = await WritingCoachService.instance.analyzeText(content);
        writingResult = {
          'overall_writing_score': wAnalysis.overallScore,
          'grammar_score': wAnalysis.grammarScore,
          'readability_score': wAnalysis.readabilityScore,
          'academic_tone_score': wAnalysis.academicToneScore,
          'vocabulary_score': wAnalysis.vocabularyScore,
        };
      } catch (_) {
        writingResult = {'overall_writing_score': 80.0};
      }
    }

    onStepChanged?.call('Generating comprehensive report…');

    // ── Step 4: Write flagged sections & sources ───────────────────────────
    final flaggedSections =
        plagiarismResult['flagged_sections'] as List<dynamic>? ?? [];
    if (flaggedSections.isNotEmpty && !scanId.startsWith('demo_')) {
      try {
        final List<Map<String, dynamic>> sectionRows = [];
        final Map<String, Map<String, dynamic>> uniqueSources = {};

        for (final s in flaggedSections) {
          final sec = s as Map<String, dynamic>;
          final startPos = (sec['start_position'] as num?)?.toInt() ?? 0;
          final originalEv = evidence.firstWhere(
            (e) => (e.startOffset - startPos).abs() < 10,
            orElse: () => MatchEvidence(submittedText: sec['flagged_text'] ?? '', signals: [], startOffset: startPos, endOffset: (sec['end_position'] as num?)?.toInt() ?? startPos),
          );

          final type = originalEv.signals.isNotEmpty ? originalEv.signals.first.name : 'semantic_similarity';
          final sUrl = sec['source_url'] as String? ?? originalEv.sourceUrl;
          final sTitle = sec['source_title'] as String? ?? originalEv.sourceTitle;

          sectionRows.add({
            'scan_id': scanId,
            'document_id': documentId,
            'flagged_text': sec['flagged_text'] ?? '',
            'plagiarism_type': type,
            'signals': originalEv.signals.map((sig) => sig.name).toList(),
            'risk_level': sec['risk_level'] ?? 'low',
            'confidence_score': sec['confidence_score'] ?? 80,
            'similarity_score': sec['similarity_score'] ?? 75,
            'source_url': sUrl,
            'source_title': sTitle,
            'domain': originalEv.domain,
            'explanation': sec['explanation'] ?? '',
            'suggested_action': sec['suggested_action'] ?? '',
            'start_position': startPos,
            'end_position': (sec['end_position'] as num?)?.toInt() ?? originalEv.endOffset,
          });

          // Determine appropriate source type based on signals and domain
          String sourceType = 'web';
          if (originalEv.signals.contains(PlagiarismType.selfPlagiarism)) {
            sourceType = 'user_document';
          } else if (sUrl?.contains('crossref') == true ||
              sUrl?.contains('doi.org') == true ||
              sTitle?.toLowerCase().contains('journal') == true ||
              sTitle?.toLowerCase().contains('proceedings') == true) {
            sourceType = 'academic';
          } else if (originalEv.signals.contains(PlagiarismType.exactCopy) && (sUrl == null || sUrl.isEmpty)) {
            sourceType = 'personal_source';
          }

          final sourceKey = (sUrl != null && sUrl.isNotEmpty) ? sUrl : (sTitle ?? 'source_${uniqueSources.length}');
          final sourceSim = (sec['similarity_score'] as num?)?.toDouble() ?? 75.0;

          if (uniqueSources.containsKey(sourceKey)) {
            final prev = uniqueSources[sourceKey]!;
            final currentSim = (prev['similarity_percentage'] as num?)?.toDouble() ?? 0.0;
            uniqueSources[sourceKey] = {
              ...prev,
              'match_count': (prev['match_count'] as int? ?? 1) + 1,
              'similarity_percentage': math.max(currentSim, sourceSim),
            };
          } else {
            uniqueSources[sourceKey] = {
              'scan_id': scanId,
              'url': sUrl,
              'title': sTitle ?? (sourceType == 'user_document' ? 'Your Previous Document' : 'Document Source'),
              'domain': originalEv.domain ?? (sUrl != null ? Uri.tryParse(sUrl)?.host : null),
              'snippet': originalEv.matchedText ?? sec['flagged_text'],
              'similarity_percentage': sourceSim,
              'source_type': sourceType,
              'match_count': 1,
            };
          }
        }

        if (sectionRows.isNotEmpty) {
          await _client.from('flagged_sections').insert(sectionRows);
        }

        if (uniqueSources.isNotEmpty) {
          try {
            await _client.from('similarity_sources').insert(uniqueSources.values.toList());
          } catch (e) {
            dev.log('ScanService: similarity_sources insert note: $e');
          }
        }
      } catch (e) {
        dev.log('ScanService: Flagged sections write failed: $e');
      }
    }

    // ── Step 5: Update scan_results to completed ───────────────────────────
    final plagScore = (plagiarismResult['overall_similarity_score'] as num?)?.toDouble() ?? 0.0;
    final aiScore = (aiResult['ai_score'] as num?)?.toDouble() ?? (aiResult['ai_generated_score'] as num?)?.toDouble() ?? 0.0;
    final writingScore = (writingResult['overall_writing_score'] as num?)?.toDouble() ?? 75.0;

    if (!scanId.startsWith('session_')) {
      try {
        await _client.from('scan_results').update({
          'status': 'completed',
          'overall_similarity_score': plagScore,
          'exact_match_score': (plagiarismResult['exact_match_score'] as num?)?.toDouble() ?? 0.0,
          'semantic_similarity_score': (plagiarismResult['semantic_similarity_score'] as num?)?.toDouble() ?? 0.0,
          'paraphrase_score': (plagiarismResult['paraphrase_score'] as num?)?.toDouble() ?? 0.0,
          'ai_generated_score': aiScore,
          'overall_writing_score': writingScore,
          'grammar_score': (writingResult['grammar_score'] as num?)?.toDouble(),
          'readability_score': (writingResult['readability_score'] as num?)?.toDouble(),
          'academic_tone_score': (writingResult['academic_tone_score'] as num?)?.toDouble(),
          'vocabulary_score': (writingResult['vocabulary_score'] as num?)?.toDouble(),
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
      exactMatchScore: (plagiarismResult['exact_match_score'] as num?)?.toDouble() ?? 0.0,
      semanticScore: (plagiarismResult['semantic_similarity_score'] as num?)?.toDouble() ?? 0.0,
      paraphraseScore: (plagiarismResult['paraphrase_score'] as num?)?.toDouble() ?? 0.0,
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

      final isWithinBounds = startPos >= 0 && endPos <= content.length && startPos <= endPos;
      if (isWithinBounds && content.substring(startPos, endPos) == oldText) {
          content = content.replaceRange(startPos, endPos, newText);
      } else {
          final index = content.indexOf(oldText);
          if (index != -1) {
              content = content.replaceRange(index, index + oldText.length, newText);
          } else {
              throw Exception('Original text not found in document.');
          }
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

  String _mapDocumentType(String? type) {
    if (type == null) return 'txt';
    final lower = type.toLowerCase().replaceAll('.', '').trim();
    if (['pdf', 'docx', 'doc', 'txt', 'rtf', 'image', 'voice'].contains(lower)) {
      return lower;
    }
    return 'txt';
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
