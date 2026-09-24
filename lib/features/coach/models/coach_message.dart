import 'package:flutter/foundation.dart';

enum MessageSender { user, coach }

@immutable
class CoachMessage {
  final String id;
  final MessageSender sender;
  final String content;
  final DateTime timestamp;
  final bool isThinking;
  final String? error;
  
  // Structured Academic Coach Data
  final List<String> strengths;
  final List<String> recommendations;
  final String? suggestedRevision;
  final String? citationAdvice;
  final String? referencedPassage;

  const CoachMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.isThinking = false,
    this.error,
    this.strengths = const [],
    this.recommendations = const [],
    this.suggestedRevision,
    this.citationAdvice,
    this.referencedPassage,
  });

  CoachMessage copyWith({
    String? id,
    MessageSender? sender,
    String? content,
    DateTime? timestamp,
    bool? isThinking,
    String? error,
    List<String>? strengths,
    List<String>? recommendations,
    String? suggestedRevision,
    String? citationAdvice,
    String? referencedPassage,
  }) {
    return CoachMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isThinking: isThinking ?? this.isThinking,
      error: error ?? this.error,
      strengths: strengths ?? this.strengths,
      recommendations: recommendations ?? this.recommendations,
      suggestedRevision: suggestedRevision ?? this.suggestedRevision,
      citationAdvice: citationAdvice ?? this.citationAdvice,
      referencedPassage: referencedPassage ?? this.referencedPassage,
    );
  }

  factory CoachMessage.user({
    required String content,
    String? referencedPassage,
  }) {
    return CoachMessage(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
      sender: MessageSender.user,
      content: content,
      timestamp: DateTime.now(),
      referencedPassage: referencedPassage,
    );
  }

  factory CoachMessage.thinking() {
    return CoachMessage(
      id: 'thinking_${DateTime.now().microsecondsSinceEpoch}',
      sender: MessageSender.coach,
      content: 'Reviewing your draft against academic benchmarks…',
      timestamp: DateTime.now(),
      isThinking: true,
    );
  }

  factory CoachMessage.fromCoachJson(Map<String, dynamic> json, {String? userQuery}) {
    return CoachMessage(
      id: 'coach_${DateTime.now().microsecondsSinceEpoch}',
      sender: MessageSender.coach,
      content: json['coach_response']?.toString() ?? 'Here is my academic writing feedback on your draft.',
      timestamp: DateTime.now(),
      strengths: (json['strengths_identified'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      recommendations: (json['actionable_recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      suggestedRevision: json['suggested_revision_example']?.toString(),
      citationAdvice: json['citation_advice']?.toString(),
    );
  }

  factory CoachMessage.error(String errorText) {
    return CoachMessage(
      id: 'err_${DateTime.now().microsecondsSinceEpoch}',
      sender: MessageSender.coach,
      content: 'Unable to complete coaching review at this time.',
      timestamp: DateTime.now(),
      error: errorText,
    );
  }
}
