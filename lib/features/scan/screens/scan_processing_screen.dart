import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/scan_provider.dart';

class ScanProcessingScreen extends ConsumerStatefulWidget {
  final String scanId;
  final Map<String, dynamic> scanData;

  const ScanProcessingScreen({
    super.key,
    required this.scanId,
    required this.scanData,
  });

  @override
  ConsumerState<ScanProcessingScreen> createState() =>
      _ScanProcessingScreenState();
}

class _ScanProcessingScreenState
    extends ConsumerState<ScanProcessingScreen> {
  String _currentStep = 'Initializing AI engine…';
  int _stepIndex = 0;
  bool _cancelled = false;
  String? _error;

  // The canonical ordered step labels shown in the UI
  static const _stepLabels = [
    'Initializing AI engine…',
    'Saving document…',
    'Extracting semantic meaning…',
    'Checking exact matches…',
    'Detecting AI-generated content…',
    'Analyzing writing quality…',
    'Generating comprehensive report…',
  ];

  @override
  void initState() {
    super.initState();
    _runPipeline();
  }

  Future<void> _runPipeline() async {
    // Small delay to ensure the widget is fully mounted before starting the pipeline
    await Future.delayed(Duration.zero);
    
    final title = widget.scanData['title'] as String? ?? 'Document';
    final content = widget.scanData['content'] as String? ?? '';
    final contentType = widget.scanData['type'] as String? ?? 'txt';
    final file = widget.scanData['file'] as File?;

    try {
      // Kick off the real scan via the provider
      final completedId = await ref.read(activeScanProvider.notifier).startScan(
        title: title,
        content: content,
        contentType: contentType,
        file: file,
        onStepChanged: (step) {
          if (!mounted || _cancelled) return;
          final idx = _stepLabels.indexOf(step);
          setState(() {
            _currentStep = step;
            if (idx >= 0) _stepIndex = idx;
          });
        },
      );

      if (!mounted || _cancelled) return;

      if (completedId != null) {
        // Navigate to results
        context.go('/scan/result/$completedId', extra: widget.scanData);
      } else {
        setState(() => _error = 'The analysis pipeline failed to complete.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'An unexpected error occurred: $e');
      }
    }
  }

  void _cancel() {
    _cancelled = true;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return _buildErrorState();

    final progress = (_stepIndex + 1) / _stepLabels.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // ── Animated Scanner ─────────────────────────────────
              Center(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.15),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 64,
                        color: AppColors.textDisabled,
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.primary,
                                Colors.transparent
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        )
                            .animate(
                                onPlay: (controller) => controller.repeat())
                            .moveY(
                                begin: 0,
                                end: 156,
                                duration: 1500.ms,
                                curve: Curves.easeInOut),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms).scale(curve: Curves.easeOutBack),

              const SizedBox(height: 64),

              // ── Status text ──────────────────────────────────────
              Text(
                'Analyzing Document',
                textAlign: TextAlign.center,
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 16),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _currentStep,
                  key: ValueKey<String>(_currentStep),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Progress bar ─────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AnimatedLinearProgressIndicator(
                  value: progress,
                  color: AppColors.primary,
                  backgroundColor: AppColors.primarySurface,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Step ${_stepIndex + 1} of ${_stepLabels.length}',
                textAlign: TextAlign.center,
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.textTertiary),
              ),

              const Spacer(),

              TextButton(
                onPressed: _cancel,
                child: Text(
                  'Cancel Analysis',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 64),
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.secondary, size: 80),
              const SizedBox(height: 24),
              Text(
                'Analysis Failed',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  setState(() => _error = null);
                  _runPipeline();
                },
                child: const Text('Try Again'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _cancel,
                child: const Text('Go Back'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin wrapper so the progress bar animates when [value] changes.
class AnimatedLinearProgressIndicator extends StatelessWidget {
  final double value;
  final Color color;
  final Color backgroundColor;

  const AnimatedLinearProgressIndicator({
    super.key,
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (_, v, _) => LinearProgressIndicator(
        value: v,
        minHeight: 8,
        backgroundColor: backgroundColor,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}
