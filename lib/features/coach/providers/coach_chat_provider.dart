import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coach_message.dart';
import '../../../core/models/scan_result.dart';
import '../../../core/services/gemini_service.dart';

class CoachChatState {
  final List<CoachMessage> messages;
  final String? activeDocumentId;
  final String activeDocumentTitle;
  final String activeDocumentText;
  final ScanResult? activeScanResult;
  final bool isGenerating;
  final String? error;

  const CoachChatState({
    this.messages = const [],
    this.activeDocumentId,
    this.activeDocumentTitle = 'Live Editor Draft',
    this.activeDocumentText = '',
    this.activeScanResult,
    this.isGenerating = false,
    this.error,
  });

  CoachChatState copyWith({
    List<CoachMessage>? messages,
    String? activeDocumentId,
    String? activeDocumentTitle,
    String? activeDocumentText,
    ScanResult? activeScanResult,
    bool? isGenerating,
    String? error,
  }) {
    return CoachChatState(
      messages: messages ?? this.messages,
      activeDocumentId: activeDocumentId ?? this.activeDocumentId,
      activeDocumentTitle: activeDocumentTitle ?? this.activeDocumentTitle,
      activeDocumentText: activeDocumentText ?? this.activeDocumentText,
      activeScanResult: activeScanResult ?? this.activeScanResult,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
    );
  }
}

class CoachChatNotifier extends Notifier<CoachChatState> {
  @override
  CoachChatState build() {
    return CoachChatState(
      messages: [
        CoachMessage(
          id: 'welcome_1',
          sender: MessageSender.coach,
          content:
              'Welcome to your Academic Writing Coach Studio! Ask me anything about your paper’s structure, arguments, academic tone, or literature citations. Select a scanned paper or coach your live draft.',
          timestamp: DateTime.now(),
          recommendations: const [
            'Ask: "How can I improve my introduction?"',
            'Ask: "Is my argument clear and evidenced?"',
            'Ask: "Make this paragraph sound more scholarly."',
          ],
        ),
      ],
    );
  }

  void setDocumentContext({
    required String title,
    required String text,
    String? documentId,
    ScanResult? scanResult,
  }) {
    state = state.copyWith(
      activeDocumentId: documentId,
      activeDocumentTitle: title,
      activeDocumentText: text,
      activeScanResult: scanResult,
    );
  }

  void updateDraftText(String text) {
    state = state.copyWith(activeDocumentText: text);
  }

  Future<void> sendMessage(String question, {String? highlightedPassage}) async {
    final cleanQuestion = question.trim();
    if (cleanQuestion.isEmpty || state.isGenerating) return;

    final userMsg = CoachMessage.user(
      content: cleanQuestion,
      referencedPassage: highlightedPassage,
    );

    final thinkingMsg = CoachMessage.thinking();

    // Append user message & thinking placeholder
    state = state.copyWith(
      messages: [...state.messages, userMsg, thinkingMsg],
      isGenerating: true,
      error: null,
    );

    try {
      final docText = state.activeDocumentText.trim();
      final effectiveText = docText.isNotEmpty
          ? docText
          : 'No specific document draft text supplied yet. The student is asking general academic coaching guidance.';

      // Extract conversation history for multi-turn coherence
      final history = state.messages
          .where((m) => !m.isThinking && m.error == null)
          .take(6)
          .map((m) => {
                'role': m.sender == MessageSender.user ? 'user' : 'model',
                'text': m.content,
              })
          .toList();

      Map<String, dynamic>? metrics;
      if (state.activeScanResult != null) {
        metrics = {
          'similarity_score': state.activeScanResult!.overallSimilarityScore,
          'writing_score': state.activeScanResult!.overallWritingScore,
          'flagged_sections_count': state.activeScanResult!.totalFlaggedSections,
        };
      }

      final response = await GeminiService.instance.askCoachQuestion(
        documentText: effectiveText,
        question: cleanQuestion,
        documentTitle: state.activeDocumentTitle,
        highlightedText: highlightedPassage,
        conversationHistory: history,
        writingMetrics: metrics,
      );

      final coachMsg = CoachMessage.fromCoachJson(response, userQuery: cleanQuestion);

      // Replace thinking message with real coach response
      final currentList = List<CoachMessage>.from(state.messages)
        ..removeWhere((m) => m.id == thinkingMsg.id)
        ..add(coachMsg);

      state = state.copyWith(
        messages: currentList,
        isGenerating: false,
      );
    } catch (e) {
      dev.log('CoachChatNotifier Error: $e');
      final errorMsg = CoachMessage.error(e.toString());
      final currentList = List<CoachMessage>.from(state.messages)
        ..removeWhere((m) => m.id == thinkingMsg.id)
        ..add(errorMsg);

      state = state.copyWith(
        messages: currentList,
        isGenerating: false,
        error: e.toString(),
      );
    }
  }

  void retryLastMessage() {
    final userMsgs = state.messages.where((m) => m.sender == MessageSender.user).toList();
    if (userMsgs.isNotEmpty) {
      final lastUserMsg = userMsgs.last;
      sendMessage(lastUserMsg.content, highlightedPassage: lastUserMsg.referencedPassage);
    }
  }

  void clearHistory() {
    state = build();
  }
}

final coachChatProvider = NotifierProvider<CoachChatNotifier, CoachChatState>(CoachChatNotifier.new);
