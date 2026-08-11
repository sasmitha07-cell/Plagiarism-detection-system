import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: profileAsync.when(
                data: (profile) {
                  if (profile == null) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No profile data available. Try re-logging.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // User Info Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientHero,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.white24,
                                child: Text(
                                  profile.displayName.isNotEmpty
                                      ? profile.displayName[0].toUpperCase()
                                      : '?',
                                  style: AppTypography.displaySmall.copyWith(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                profile.displayName,
                                style: AppTypography.headlineSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Level ${profile.academicLevel ?? "Beginner"}',
                                  style: AppTypography.labelSmall.copyWith(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                        const SizedBox(height: 32),

                        // Stats Grid
                        Text(
                          'Your Academic Stats',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                        ).animate().fadeIn(delay: 150.ms),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Avg Similarity',
                                value: '${profile.averageSimilarityScore.toStringAsFixed(1)}%',
                                icon: Icons.percent_rounded,
                                color: AppColors.riskMedium,
                                onTap: () => context.go('/profile/progress'),
                              ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                title: 'Writing Score',
                                value: profile.averageWritingScore.toStringAsFixed(1),
                                icon: Icons.star_rounded,
                                color: AppColors.primary,
                                onTap: () => context.go('/profile/progress'),
                              ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.1),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Menu
                        Text(
                          'Preferences & More',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                        ).animate().fadeIn(delay: 300.ms),
                        const SizedBox(height: 12),
                        
                        _MenuTile(
                          icon: Icons.emoji_events_rounded,
                          title: 'Achievements',
                          subtitle: 'View your badges and milestones',
                          onTap: () => context.go('/profile/achievements'),
                        ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                        
                        const SizedBox(height: 12),
                        _MenuTile(
                          icon: Icons.format_quote_rounded,
                          title: 'My Citations',
                          subtitle: 'View saved citation history',
                          onTap: () => context.go('/profile/citations'),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                        const SizedBox(height: 12),
                        _MenuTile(
                          icon: Icons.settings_rounded,
                          title: 'Settings',
                          subtitle: 'Notifications, theme, and preferences',
                          onTap: () => context.go('/profile/settings'),
                        ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),

                        const SizedBox(height: 12),
                        _MenuTile(
                          icon: Icons.help_outline_rounded,
                          title: 'Help & Support',
                          subtitle: 'FAQs and contact support',
                          onTap: () => context.go('/profile/help'),
                        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                        const SizedBox(height: 12),
                        _MenuTile(
                          icon: Icons.info_outline_rounded,
                          title: 'About',
                          subtitle: 'App version, privacy policy, and more',
                          onTap: () => context.go('/profile/about'),
                        ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.1),
                        
                        const SizedBox(height: 32),
                        
                        // Sign out
                        TextButton.icon(
                          onPressed: () {
                            ref.read(authRepositoryProvider).signOut();
                          },
                          icon: const Icon(Icons.logout_rounded, color: AppColors.secondary),
                          label: const Text('Sign Out'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ).animate().fadeIn(delay: 500.ms),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: AppTypography.headlineMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      tileColor: AppColors.surface,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: AppTypography.titleSmall),
      subtitle: Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textTertiary),
    );
  }
}
