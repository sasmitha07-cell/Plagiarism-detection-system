import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditProfileModal(BuildContext context, WidgetRef ref, dynamic profile) {
    final nameController = TextEditingController(text: profile.displayName);
    final institutionController = TextEditingController(text: profile.institution ?? '');
    String selectedLevel = profile.academicLevel ?? 'undergraduate';

    final levels = [
      ('high_school', 'High School'),
      ('undergraduate', 'Undergraduate'),
      ('graduate', 'Graduate'),
      ('doctorate', 'Doctorate / PhD'),
      ('faculty', 'Faculty'),
      ('researcher', 'Researcher'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Edit Academic Profile',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: institutionController,
                decoration: InputDecoration(
                  labelText: 'Institution / University',
                  prefixIcon: const Icon(Icons.business_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: levels.any((l) => l.$1 == selectedLevel) ? selectedLevel : 'undergraduate',
                decoration: InputDecoration(
                  labelText: 'Academic Level',
                  prefixIcon: const Icon(Icons.school_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: levels
                    .map((l) => DropdownMenuItem(
                          value: l.$1,
                          child: Text(l.$2),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setModalState(() => selectedLevel = v);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final newName = nameController.text.trim();
                  if (newName.isEmpty) return;

                  try {
                    final userId = ref.read(currentUserIdProvider);
                    if (userId != null && !userId.startsWith('demo_')) {
                      await Supabase.instance.client.from('profiles').update({
                        'full_name': newName,
                        'institution': institutionController.text.trim(),
                        'academic_level': selectedLevel,
                        'updated_at': DateTime.now().toIso8601String(),
                      }).eq('id', userId);
                    }
                    if (context.mounted) {
                      ref.invalidate(profileStateProvider);
                      Navigator.pop(ctx);
                      AppSnackbar.showSuccess(context, 'Profile updated successfully!');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppSnackbar.showError(context, 'Failed to update profile: $e');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                                color: AppColors.primary.withValues(alpha: 0.2),
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
                              if (profile.institution != null && profile.institution!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  profile.institution!,
                                  style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      profile.academicLevel ?? 'Undergraduate',
                                      style: AppTypography.labelSmall.copyWith(color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                                    tooltip: 'Edit Profile',
                                    onPressed: () => _showEditProfileModal(context, ref, profile),
                                  ),
                                ],
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
                                value: profile.averageWritingScore.toStringAsFixed(0),
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
                          'Preferences & Features',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                        ).animate().fadeIn(delay: 300.ms),
                        const SizedBox(height: 12),

                        if (profile.isAdmin) ...[
                          _MenuTile(
                            icon: Icons.admin_panel_settings_rounded,
                            title: 'Admin Dashboard',
                            subtitle: 'System analytics and user management',
                            onTap: () => context.go('/admin'),
                          ).animate().fadeIn(delay: 320.ms).slideY(begin: 0.1),
                          const SizedBox(height: 12),
                        ],

                        _MenuTile(
                          icon: Icons.emoji_events_rounded,
                          title: 'Achievements & Badges',
                          subtitle: 'View your milestones and badges',
                          onTap: () => context.go('/profile/achievements'),
                        ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),

                        const SizedBox(height: 12),
                        _MenuTile(
                          icon: Icons.format_quote_rounded,
                          title: 'Citation Generator & Library',
                          subtitle: 'Generate and manage saved citations',
                          onTap: () => context.go('/profile/citations'),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                        const SizedBox(height: 12),
                        _MenuTile(
                          icon: Icons.insights_rounded,
                          title: 'Progress & Analytics',
                          subtitle: 'Writing quality trends and history',
                          onTap: () => context.go('/profile/progress'),
                        ).animate().fadeIn(delay: 430.ms).slideY(begin: 0.1),

                        const SizedBox(height: 12),
                        _MenuTile(
                          icon: Icons.settings_rounded,
                          title: 'Settings',
                          subtitle: 'Scan sensitivity, theme, and API keys',
                          onTap: () => context.go('/profile/settings'),
                        ).animate().fadeIn(delay: 460.ms).slideY(begin: 0.1),

                        const SizedBox(height: 12),
                        _MenuTile(
                          icon: Icons.help_outline_rounded,
                          title: 'Help & Support',
                          subtitle: 'Academic writing FAQs and guide',
                          onTap: () => context.go('/profile/help'),
                        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                        const SizedBox(height: 12),
                        _MenuTile(
                          icon: Icons.info_outline_rounded,
                          title: 'About',
                          subtitle: 'App version, AI methodology, and privacy',
                          onTap: () => context.go('/profile/about'),
                        ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.1),

                        const SizedBox(height: 32),

                        // Sign out
                        TextButton.icon(
                          onPressed: () {
                            ref.read(authRepositoryProvider).signOut();
                          },
                          icon: const Icon(Icons.logout_rounded, color: AppColors.riskCritical),
                          label: const Text('Sign Out', style: TextStyle(color: AppColors.riskCritical)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.riskCritical,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ).animate().fadeIn(delay: 600.ms),
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
                color: color.withValues(alpha: 0.12),
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
      title: Text(title, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textTertiary),
    );
  }
}
