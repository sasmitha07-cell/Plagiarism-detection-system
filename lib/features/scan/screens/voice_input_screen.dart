import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/services/document_extraction_service.dart';

class VoiceInputScreen extends ConsumerStatefulWidget {
  const VoiceInputScreen({super.key});

  @override
  ConsumerState<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = '';
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          setState(() => _isListening = false);
          AppSnackbar.showError(context, 'Speech recognition error: ${error.errorMsg}');
        },
      );
    } catch (e) {
      // Handle initialization error silently on first load
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: _onSpeechResult,
          listenOptions: stt.SpeechListenOptions(
            listenFor: const Duration(seconds: 30),
            pauseFor: const Duration(seconds: 3),
            partialResults: true,
            cancelOnError: true,
          ),
        );
      } else {
        setState(() => _isListening = false);
        if (mounted) {
          AppSnackbar.showError(context, 'Microphone permission denied.');
        }
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _text = result.recognizedWords;
      _wordCount = DocumentExtractionService.instance.countWords(_text);
    });
  }

  void _startAnalysis() {
    if (_text.trim().isEmpty) return;

    final mockScanId = 'scan_${DateTime.now().millisecondsSinceEpoch}';

    context.go('/scan/processing/$mockScanId', extra: {
      'title': 'Voice Note',
      'content': _text,
      'type': 'voice',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Voice Input'),
        backgroundColor: AppColors.background,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '$_wordCount words',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_text.isEmpty && !_isListening)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'Tap the microphone to start speaking...',
                          textAlign: TextAlign.center,
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textDisabled,
                          ),
                        ),
                      )
                    else
                      Text(
                        _text,
                        style: AppTypography.bodyLarge.copyWith(
                          height: 1.6,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Controls
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowCard,
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_text.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _text = '';
                              _wordCount = 0;
                            });
                          },
                          icon: const Icon(Icons.delete_outline, color: AppColors.secondary),
                        ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _listen,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: EdgeInsets.all(_isListening ? 24 : 20),
                          decoration: BoxDecoration(
                            color: _isListening ? AppColors.accent : AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isListening ? Colors.transparent : AppColors.accent,
                              width: 2,
                            ),
                            boxShadow: _isListening
                                ? [
                                    BoxShadow(
                                      color: AppColors.accent.withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 4,
                                    )
                                  ]
                                : null,
                          ),
                          child: Icon(
                            _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                            color: _isListening ? Colors.white : AppColors.accent,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_text.isNotEmpty)
                        const SizedBox(width: 48), // Balance spacing
                    ],
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    text: 'Analyze Voice Note',
                    icon: Icons.analytics_rounded,
                    onPressed: (_wordCount > 10 && !_isListening) ? _startAnalysis : null,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8A427), Color(0xFFF5C46B)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
