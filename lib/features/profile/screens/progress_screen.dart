import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../home/providers/home_provider.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentScansAsync = ref.watch(recentScansProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Progress & Analytics'),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: recentScansAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textTertiary),
                  const SizedBox(height: 12),
                  const Text('Unable to load progress data.', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(recentScansProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (scans) {
            if (scans.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.insights_rounded, size: 48, color: AppColors.primary),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No Scan Activity Yet',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload or scan your first academic document to begin tracking your writing quality and similarity progress over time.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            // Build spots strictly from real scan history
            final spots = <FlSpot>[];
            final reversedScans = scans.reversed.toList();
            for (int i = 0; i < reversedScans.length; i++) {
              final score = reversedScans[i].overallWritingScore ??
                  (100.0 - reversedScans[i].overallSimilarityScore);
              spots.add(FlSpot(i.toDouble(), score.clamp(0.0, 100.0)));
            }

            int exactCount = 0;
            int semanticCount = 0;
            int aiCount = 0;
            int cleanCount = 0;

            for (final s in scans) {
              if (s.exactMatchScore > 10) exactCount++;
              if (s.semanticSimilarityScore > 10) semanticCount++;
              if (s.aiGeneratedScore > 20) aiCount++;
              if (s.overallSimilarityScore < 15) cleanCount++;
            }

            final maxBar = [exactCount, semanticCount, aiCount, cleanCount, 3].reduce(max).toDouble() + 1.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Writing Quality & Integrity Trend',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 12),

                  // Line Chart
                  Container(
                    height: 250,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowCard,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: 100,
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              interval: 25,
                              getTitlesWidget: (val, _) => Text(
                                '${val.toInt()}',
                                style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                              ),
                            ),
                          ),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx == 0) return const Text('Start', style: TextStyle(fontSize: 10));
                                if (idx == spots.length - 1) return const Text('Latest', style: TextStyle(fontSize: 10));
                                if (spots.length <= 6) return Text('Scan ${idx + 1}', style: const TextStyle(fontSize: 10));
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: spots.length > 1,
                            color: AppColors.primary,
                            barWidth: 3.5,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.primary.withValues(alpha: 0.12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                  const SizedBox(height: 32),

                  Text(
                    'Historical Integrity Signals Breakdown',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 12),

                  // Bar Chart
                  Container(
                    height: 250,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowCard,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: BarChart(
                      BarChartData(
                        maxY: maxBar,
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 0:
                                    return const Text('Exact', style: TextStyle(fontSize: 10));
                                  case 1:
                                    return const Text('Semantic', style: TextStyle(fontSize: 10));
                                  case 2:
                                    return const Text('AI High', style: TextStyle(fontSize: 10));
                                  case 3:
                                    return const Text('Clean', style: TextStyle(fontSize: 10));
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(x: 0, barRods: [
                            BarChartRodData(
                              toY: exactCount.toDouble(),
                              color: AppColors.riskCritical,
                              width: 22,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ]),
                          BarChartGroupData(x: 1, barRods: [
                            BarChartRodData(
                              toY: semanticCount.toDouble(),
                              color: AppColors.riskMedium,
                              width: 22,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ]),
                          BarChartGroupData(x: 2, barRods: [
                            BarChartRodData(
                              toY: aiCount.toDouble(),
                              color: AppColors.secondary,
                              width: 22,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ]),
                          BarChartGroupData(x: 3, barRods: [
                            BarChartRodData(
                              toY: cleanCount.toDouble(),
                              color: AppColors.riskSafe,
                              width: 22,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
