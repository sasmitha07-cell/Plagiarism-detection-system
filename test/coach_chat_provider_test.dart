import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:academic_writing_coach/features/coach/models/coach_message.dart';
import 'package:academic_writing_coach/features/coach/providers/coach_chat_provider.dart';
import 'package:academic_writing_coach/core/models/scan_result.dart';

void main() {
  group('CoachChatProvider & CoachMessage Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initializes with welcome message and empty generating state', () {
      final state = container.read(coachChatProvider);
      expect(state.messages, isNotEmpty);
      expect(state.messages.first.sender, equals(MessageSender.coach));
      expect(state.isGenerating, isFalse);
      expect(state.activeDocumentTitle, equals('Live Editor Draft'));
    });

    test('Sets document context correctly from scanned document', () {
      final notifier = container.read(coachChatProvider.notifier);
      final scanResult = ScanResult(
        id: 'scan_123',
        userId: 'user_456',
        documentId: 'doc_789',
        title: 'Neural Architecture Analysis.pdf',
        overallSimilarityScore: 12.0,
        overallWritingScore: 88.0,
        totalFlaggedSections: 2,
        createdAt: DateTime.now(),
      );

      notifier.setDocumentContext(
        title: scanResult.title,
        text: 'This empirical study explores neural architecture search…',
        documentId: scanResult.documentId,
        scanResult: scanResult,
      );

      final state = container.read(coachChatProvider);
      expect(state.activeDocumentTitle, equals('Neural Architecture Analysis.pdf'));
      expect(state.activeDocumentId, equals('doc_789'));
      expect(state.activeScanResult, isNotNull);
      expect(state.activeScanResult?.originalityScore, equals(88.0));
    });

    test('CoachMessage model formats json and fallback gracefully', () {
      final json = {
        'coach_response': 'Your thesis statement is clear and well supported.',
        'strengths_identified': ['Strong empirical grounding', 'Logical paragraph transitions'],
        'actionable_recommendations': ['Add recent literature citations in paragraph 2'],
        'suggested_revision_example': 'Recent empirical findings (Smith, 2024) substantiate this premise.',
        'citation_advice': 'Use IEEE or APA style for consistent referencing.',
      };

      final msg = CoachMessage.fromCoachJson(json);
      expect(msg.sender, equals(MessageSender.coach));
      expect(msg.content, contains('thesis statement'));
      expect(msg.strengths.length, equals(2));
      expect(msg.recommendations.length, equals(1));
      expect(msg.suggestedRevision, isNotNull);
      expect(msg.citationAdvice, contains('IEEE'));
    });

    test('Handles sending message and updates chat history', () async {
      final notifier = container.read(coachChatProvider.notifier);
      final initialCount = container.read(coachChatProvider).messages.length;

      await notifier.sendMessage('How can I improve my introduction?');
      final state = container.read(coachChatProvider);

      expect(state.isGenerating, isFalse);
      expect(state.messages.length, greaterThan(initialCount));
      expect(state.messages.any((m) => m.content == 'How can I improve my introduction?'), isTrue);
    });

    test('Clears history and resets to welcome state', () {
      final notifier = container.read(coachChatProvider.notifier);
      notifier.clearHistory();
      final state = container.read(coachChatProvider);
      expect(state.messages.length, equals(1));
      expect(state.messages.first.content, contains('Welcome'));
    });
  });
}
