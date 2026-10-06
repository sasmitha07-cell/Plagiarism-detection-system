import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/models/user_profile.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingAvatar = false;

  Future<void> _handleAvatarPick(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      if (!mounted) return;
      setState(() => _isUploadingAvatar = true);

      final file = File(picked.path);
      await ref.read(profileStateProvider.notifier).uploadAvatar(file);

      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        AppSnackbar.showSuccess(context, 'Profile photo updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        debugPrint('[ProfileScreen] Avatar upload error: $e');
        AppSnackbar.showError(context, 'Failed to upload photo. Please try again.');
      }
    }
  }

  void _showAvatarOptions(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SafeArea(
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
              const SizedBox(height: 16),
              Text(
                'Profile Photo',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleAvatarPick(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleAvatarPick(ImageSource.camera);
                },
              ),
              if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.riskCritical),
                  title: const Text('Remove Photo', style: TextStyle(color: AppColors.riskCritical)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await ref.read(profileStateProvider.notifier).removeAvatar();
                      if (context.mounted) {
                        AppSnackbar.showSuccess(context, 'Profile photo removed.');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppSnackbar.showError(context, 'Failed to remove photo.');
                      }
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileModal(BuildContext context, UserProfile profile) {
    final nameController = TextEditingController(text: profile.fullName ?? '');
    final institutionController = TextEditingController(text: profile.institution ?? '');
    String selectedLevel = profile.academicLevel ?? 'undergraduate';
    bool isSaving = false;

    final levels = [
      ('high_school', 'High School'),
      ('undergraduate', 'Undergraduate'),
      ('graduate', 'Graduate'),
      ('doctorate', 'Doctorate / PhD'),
      ('faculty', 'Faculty'),
      ('researcher', 'Researcher'),
      ('other', 'Other'),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Academic Profile',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: institutionController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Institution / University',
                  hintText: 'e.g. Stanford University',
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
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showAvatarOptions(context, profile);
                },
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: Text(
                  profile.avatarUrl != null ? 'Change Profile Photo' : 'Add Profile Photo',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final newName = nameController.text.trim();
                        if (newName.isEmpty) {
                          AppSnackbar.showError(context, 'Please enter your full name.');
                          return;
                        }

                        setModalState(() => isSaving = true);

                        try {
                          await ref.read(profileStateProvider.notifier).updateProfile({
                            'full_name': newName,
                            'institution': institutionController.text.trim().isEmpty
                                ? null
                                : institutionController.text.trim(),
                            'academic_level': selectedLevel,
                          });

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          if (context.mounted) {
                            AppSnackbar.showSuccess(context, 'Profile updated successfully!');
                          }
                        } catch (e) {
                          setModalState(() => isSaving = false);
                          if (context.mounted) {
                            debugPrint('[ProfileScreen] Profile update failed: $e');
                            AppSnackbar.showError(context, 'Failed to update profile. Please try again.');
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authRepositoryProvider).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.riskCritical,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileStateProvider);
    final statsAsync = ref.watch(profileStatsProvider);
    final completion = ref.watch(profileCompletionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Academic Profile'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            tooltip: 'Settings',
            onPressed: () => context.go('/profile/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(profileStateProvider.notifier).refresh();
            ref.invalidate(profileStatsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: profileAsync.when(
                  data: (profile) {
                    if (profile == null) {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_off_outlined, size: 48, color: AppColors.textTertiary),
                              const SizedBox(height: 16),
                              const Text(
                                'No profile found for current account.',
                                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => ref.read(profileStateProvider.notifier).refresh(),
                                child: const Text('Reload Profile'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final memberSince = DateFormat.yMMMM().format(profile.createdAt);
                    final stats = statsAsync.asData?.value ?? const UserAcademicStats();

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── User Info Hero Card ──────────────────────────────
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              gradient: AppColors.gradientHero,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.22),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Avatar with tap to change photo
                                GestureDetector(
                                  onTap: _isUploadingAvatar ? null : () => _showAvatarOptions(context, profile),
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 84,
                                        height: 84,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2.5),
                                          color: Colors.white24,
                                        ),
                                        child: ClipOval(
                                          child: _isUploadingAvatar
                                              ? const Center(
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                                                  ? CachedNetworkImage(
                                                      imageUrl: profile.avatarUrl!,
                                                      fit: BoxFit.cover,
                                                      placeholder: (context, url) => const Center(
                                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                      ),
                                                      errorWidget: (context, url, error) => Center(
                                                        child: Text(
                                                          profile.initials,
                                                          style: AppTypography.displaySmall.copyWith(color: Colors.white),
                                                        ),
                                                      ),
                                                    )
                                                  : Center(
                                                      child: Text(
                                                        profile.initials,
                                                        style: AppTypography.displaySmall.copyWith(color: Colors.white),
                                                      ),
                                                    ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppColors.border, width: 1.5),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.15),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt_rounded,
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Full Name
                                Text(
                                  profile.displayName,
                                  style: AppTypography.headlineSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),

                                // Email
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.email_outlined, size: 14, color: Colors.white70),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        profile.email,
                                        style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Institution / Empty State
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.business_outlined, size: 14, color: Colors.white70),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        (profile.institution != null && profile.institution!.trim().isNotEmpty)
                                            ? profile.institution!
                                            : 'Add your institution',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: (profile.institution != null && profile.institution!.trim().isNotEmpty)
                                              ? Colors.white
                                              : Colors.white60,
                                          fontStyle: (profile.institution == null || profile.institution!.trim().isEmpty)
                                              ? FontStyle.italic
                                              : FontStyle.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // Academic Level Chip + Edit Button
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white24,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.school_outlined, size: 14, color: Colors.white),
                                          const SizedBox(width: 6),
                                          Text(
                                            profile.academicLevelFormatted,
                                            style: AppTypography.labelSmall.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => _showEditProfileModal(context, profile),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.white30),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(Icons.edit_rounded, color: Colors.white, size: 13),
                                            SizedBox(width: 4),
                                            Text(
                                              'Edit',
                                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),
                                Text(
                                  'Member since $memberSince',
                                  style: AppTypography.labelSmall.copyWith(color: Colors.white60),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08),

                          const SizedBox(height: 16),

                          // ── Profile Completion Bar ───────────────────────────
                          if (!completion.isComplete)
                            InkWell(
                              onTap: () => _showEditProfileModal(context, profile),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.primarySurface),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.shadowCard,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Profile Completion',
                                          style: AppTypography.labelMedium.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${completion.percentage}%',
                                          style: AppTypography.labelMedium.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: completion.percentage / 100.0,
                                        backgroundColor: AppColors.primarySurface,
                                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                        minHeight: 6,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Add your ${completion.missingFields.join(', ')} to complete your profile.',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(delay: 150.ms),

                          const SizedBox(height: 24),

                          // ── Academic Statistics ──────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Academic Integrity Stats',
                                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                              ),
                              if (stats.zeroStreak > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.riskSafeLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.riskSafe.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.local_fire_department_rounded, size: 14, color: AppColors.riskSafe),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Streak: ${stats.zeroStreak}',
                                        style: AppTypography.labelSmall.copyWith(color: AppColors.riskSafe, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ).animate().fadeIn(delay: 180.ms),
                          const SizedBox(height: 12),

                          // 4-Card Stats Grid
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Documents',
                                  value: '${stats.totalDocuments}',
                                  icon: Icons.article_outlined,
                                  color: AppColors.primary,
                                  onTap: () => context.go('/scan/upload'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: 'Total Scans',
                                  value: '${stats.totalScans}',
                                  icon: Icons.document_scanner_outlined,
                                  color: AppColors.tertiary,
                                  onTap: () => context.go('/scan'),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 200.ms),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Avg Similarity',
                                  value: stats.totalScans > 0
                                      ? '${stats.averageSimilarityScore.toStringAsFixed(1)}%'
                                      : '0.0%',
                                  icon: Icons.percent_rounded,
                                  color: AppColors.riskMedium,
                                  onTap: () => context.go('/profile/progress'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: 'Writing Quality',
                                  value: stats.totalScans > 0 && stats.averageWritingScore > 0
                                      ? stats.averageWritingScore.toStringAsFixed(0)
                                      : '—',
                                  icon: Icons.star_rounded,
                                  color: AppColors.accent,
                                  onTap: () => context.go('/profile/progress'),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 230.ms),

                          if (stats.totalScans == 0 && stats.totalDocuments == 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'No scans or documents recorded yet. Run your first scan to track academic statistics.',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary, fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          const SizedBox(height: 28),

                          // ── Preferences & Features ───────────────────────────
                          Text(
                            'Preferences & Features',
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                          ).animate().fadeIn(delay: 260.ms),
                          const SizedBox(height: 12),

                          if (profile.isAdmin) ...[
                            _MenuTile(
                              icon: Icons.admin_panel_settings_rounded,
                              title: 'Admin Dashboard',
                              subtitle: 'System analytics and user management',
                              onTap: () => context.go('/admin'),
                            ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.08),
                            const SizedBox(height: 10),
                          ],

                          _MenuTile(
                            icon: Icons.emoji_events_rounded,
                            title: 'Achievements & Badges',
                            subtitle: 'View your milestones and earned badges',
                            onTap: () => context.go('/profile/achievements'),
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.08),

                          const SizedBox(height: 10),
                          _MenuTile(
                            icon: Icons.format_quote_rounded,
                            title: 'Citation Generator & Library',
                            subtitle: stats.totalCitations > 0
                                ? '${stats.totalCitations} saved citation${stats.totalCitations == 1 ? '' : 's'}'
                                : 'Generate and manage saved citations',
                            onTap: () => context.go('/profile/citations'),
                          ).animate().fadeIn(delay: 330.ms).slideY(begin: 0.08),

                          const SizedBox(height: 10),
                          _MenuTile(
                            icon: Icons.insights_rounded,
                            title: 'Progress & Analytics',
                            subtitle: 'Writing quality trends and history',
                            onTap: () => context.go('/profile/progress'),
                          ).animate().fadeIn(delay: 360.ms).slideY(begin: 0.08),

                          const SizedBox(height: 10),
                          _MenuTile(
                            icon: Icons.settings_rounded,
                            title: 'Settings',
                            subtitle: 'Security, password, notifications, and theme',
                            onTap: () => context.go('/profile/settings'),
                          ).animate().fadeIn(delay: 390.ms).slideY(begin: 0.08),

                          const SizedBox(height: 10),
                          _MenuTile(
                            icon: Icons.help_outline_rounded,
                            title: 'Help & Support',
                            subtitle: 'Academic writing FAQs and guide',
                            onTap: () => context.go('/profile/help'),
                          ).animate().fadeIn(delay: 420.ms).slideY(begin: 0.08),

                          const SizedBox(height: 10),
                          _MenuTile(
                            icon: Icons.info_outline_rounded,
                            title: 'About',
                            subtitle: 'App version, AI methodology, and privacy',
                            onTap: () => context.go('/profile/about'),
                          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.08),

                          const SizedBox(height: 28),

                          // ── Sign Out Button ──────────────────────────────────
                          TextButton.icon(
                            onPressed: () => _showSignOutDialog(context),
                            icon: const Icon(Icons.logout_rounded, color: AppColors.riskCritical),
                            label: const Text(
                              'Sign Out',
                              style: TextStyle(
                                color: AppColors.riskCritical,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.riskCritical,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ).animate().fadeIn(delay: 480.ms),

                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                  loading: () => const _ProfileLoadingView(),
                  error: (error, stack) {
                    debugPrint('[ProfileScreen] Error loading profile: $error\n$stack');
                    return _ProfileErrorView(
                      onRetry: () => ref.read(profileStateProvider.notifier).refresh(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.gradientHero,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 140,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading your profile...',
                  style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ProfileErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 54, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'Unable to load your profile.',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            const SizedBox(height: 14),
            Text(
              value,
              style: AppTypography.headlineMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
      title: Text(
        title,
        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textTertiary),
    );
  }
}
