import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/recent_scan_tile.dart';
import '../widgets/score_summary_card.dart';
import '../widgets/achievement_badge_chip.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileStateProvider);
    final recentScansAsync = ref.watch(recentScansProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with greeting
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroHeader(profileAsync: profileAsync),
              collapseMode: CollapseMode.parallax,
            ),
            actions: [
              IconButton(
                onPressed: () => context.go('/notifications'),
                icon: Stack(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textPrimary,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Score summary card
                profileAsync.when(
                  data: (profile) => profile != null
                      ? ScoreSummaryCard(profile: profile)
                          .animate()
                          .fadeIn(delay: 100.ms)
                          .slideY(begin: 0.2)
                      : const SizedBox(),
                  loading: () => _shimmerCard(height: 130),
                  error: (error, stack) => const SizedBox(),
                ),

                const SizedBox(height: 28),

                // Section: Quick Actions
                _SectionHeader(title: 'START ANALYSIS', onSeeAll: null),
                const SizedBox(height: 12),

                // 2x2 grid of quick action cards
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: [
                    QuickActionCard(
                      icon: Icons.edit_note_rounded,
                      title: 'Paste Text',
                      subtitle: 'Type or paste content',
                      gradient: AppColors.gradientHero,
                      onTap: () => context.go('/scan/text'),
                    ),
                    QuickActionCard(
                      icon: Icons.upload_file_rounded,
                      title: 'Upload File',
                      subtitle: 'PDF, DOCX, TXT',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4A6FA5), Color(0xFF6B8EC2)],
                      ),
                      onTap: () => context.go('/scan/upload'),
                    ),
                    QuickActionCard(
                      icon: Icons.mic_rounded,
                      title: 'Voice Input',
                      subtitle: 'Speak your text',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE8A427), Color(0xFFF5C46B)],
                      ),
                      onTap: () => context.go('/scan/voice'),
                    ),
                    QuickActionCard(
                      icon: Icons.camera_alt_rounded,
                      title: 'Scan Image',
                      subtitle: 'OCR extraction',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE05A4A), Color(0xFFEB7D6F)],
                      ),
                      onTap: () => context.go('/scan/ocr'),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.2),

                const SizedBox(height: 28),

                // Document comparison promo
                _ComparePromoCard(
                  onTap: () => context.go('/compare'),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 28),

                // Recent scans
                _SectionHeader(
                  title: 'RECENT SCANS',
                  onSeeAll: null,
                ),
                const SizedBox(height: 12),

                recentScansAsync.when(
                  data: (scans) => scans.isEmpty
                      ? _EmptyScansCard()
                      : Column(
                          children: scans
                              .take(5)
                              .map((scan) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 10),
                                    child: RecentScanTile(scan: scan),
                                  ))
                              .toList(),
                        ),
                  loading: () => Column(
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _shimmerCard(height: 80),
                      ),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text('Failed to load scans',
                        style: AppTypography.bodySmall),
                  ),
                ).animate().fadeIn(delay: 400.ms),

                // Achievements strip
                const SizedBox(height: 28),
                _SectionHeader(title: 'ACHIEVEMENTS', onSeeAll: () => context.go('/profile/achievements')),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: const [
                      AchievementBadgeChip(emoji: '🔍', label: 'First Scan', earned: true),
                      SizedBox(width: 8),
                      AchievementBadgeChip(emoji: '✨', label: 'Clean Writer', earned: false),
                      SizedBox(width: 8),
                      AchievementBadgeChip(emoji: '📚', label: 'Citation Master', earned: false),
                      SizedBox(width: 8),
                      AchievementBadgeChip(emoji: '🎓', label: 'Academic Writer', earned: false),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _HeroHeader extends ConsumerWidget {
  final AsyncValue<dynamic> profileAsync;

  const _HeroHeader({required this.profileAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
      child: profileAsync.when(
        data: (profile) {
          final hour = DateTime.now().hour;
          String greeting;
          if (hour < 12) {
            greeting = 'Good morning';
          } else if (hour < 17) {
            greeting = 'Good afternoon';
          } else {
            greeting = 'Good evening';
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$greeting,',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                profile?.displayName ?? 'Scholar',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ready to analyze your writing today?',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          );
        },
        loading: () => const SizedBox(),
        error: (error, stack) => const SizedBox(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.sectionLabel,
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See All',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _ComparePromoCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ComparePromoCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF8EC), Color(0xFFFFF0E6)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accentLighter),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.compare_arrows_rounded,
                color: AppColors.accent,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document Comparison',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Compare two documents side-by-side for similarities',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.accent,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyScansCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          const Icon(Icons.document_scanner_outlined,
              color: AppColors.textDisabled, size: 48),
          const SizedBox(height: 12),
          Text('No scans yet',
              style: AppTypography.titleSmall
                  .copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: 4),
          Text('Run your first plagiarism check above',
              style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}
