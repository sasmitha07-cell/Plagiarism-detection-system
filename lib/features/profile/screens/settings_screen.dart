import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _plagiarismAlerts = true;
  bool _weeklyReport = true;
  bool _writingTips = false;
  bool _biometricLogin = false;
  bool _darkMode = false;
  bool _compactView = false;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'Forest Green';

  final List<String> _languages = ['English', 'Spanish', 'French', 'German', 'Arabic'];
  final List<String> _themes = ['Forest Green', 'Ocean Blue', 'Sunset Coral'];

  void _showChangePasswordDialog() {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null || currentUserId == 'demo-user-id') {
      AppSnackbar.showError(context, 'Password change is only available for registered user accounts.');
      return;
    }

    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Change Password',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Enter a new secure password for your account.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final newPass = newPasswordController.text;
                      final confirmPass = confirmPasswordController.text;

                      if (newPass.length < 6) {
                        AppSnackbar.showError(context, 'Password must be at least 6 characters long.');
                        return;
                      }

                      if (newPass != confirmPass) {
                        AppSnackbar.showError(context, 'Passwords do not match.');
                        return;
                      }

                      setDialogState(() => isSubmitting = true);

                      try {
                        await ref.read(authRepositoryProvider).updatePassword(newPass);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (mounted) {
                          AppSnackbar.showSuccess(context, 'Password updated successfully!');
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (mounted) {
                          debugPrint('[SettingsScreen] Password update error: $e');
                          AppSnackbar.showError(context, 'Failed to update password. Please try again.');
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountNotice() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account'),
        content: const Text(
          'To ensure academic data safety and prevent accidental loss of papers, self-service account deletion requires administrator verification.\n\nPlease contact support to permanently remove your account and all associated documents.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/profile/help');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),

                  // ── Notifications ──────────────────────────────
                  _SectionHeader(title: 'Notifications')
                      .animate()
                      .fadeIn(delay: 100.ms),
                  const SizedBox(height: 12),
                  _ToggleTile(
                    icon: Icons.plagiarism_outlined,
                    iconColor: AppColors.secondary,
                    title: 'Plagiarism Alerts',
                    subtitle: 'Get notified when a scan finishes',
                    value: _plagiarismAlerts,
                    onChanged: (v) => setState(() => _plagiarismAlerts = v),
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
                  const SizedBox(height: 8),
                  _ToggleTile(
                    icon: Icons.bar_chart_rounded,
                    iconColor: AppColors.tertiary,
                    title: 'Weekly Progress Report',
                    subtitle: 'Summary of your writing improvement',
                    value: _weeklyReport,
                    onChanged: (v) => setState(() => _weeklyReport = v),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                  const SizedBox(height: 8),
                  _ToggleTile(
                    icon: Icons.lightbulb_outline_rounded,
                    iconColor: AppColors.accent,
                    title: 'Writing Tips',
                    subtitle: 'Daily AI-powered writing suggestions',
                    value: _writingTips,
                    onChanged: (v) => setState(() => _writingTips = v),
                  ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

                  const SizedBox(height: 24),

                  // ── Security ───────────────────────────────────
                  _SectionHeader(title: 'Security')
                      .animate()
                      .fadeIn(delay: 300.ms),
                  const SizedBox(height: 12),
                  _ToggleTile(
                    icon: Icons.fingerprint_rounded,
                    iconColor: AppColors.primary,
                    title: 'Biometric Login',
                    subtitle: 'Use fingerprint or face to sign in',
                    value: _biometricLogin,
                    onChanged: (v) => setState(() => _biometricLogin = v),
                  ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                  const SizedBox(height: 8),
                  _ActionTile(
                    icon: Icons.lock_reset_rounded,
                    iconColor: AppColors.primary,
                    title: 'Change Password',
                    subtitle: 'Update your account password securely',
                    onTap: _showChangePasswordDialog,
                  ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.1),

                  const SizedBox(height: 24),

                  // ── Appearance ─────────────────────────────────
                  _SectionHeader(title: 'Appearance')
                      .animate()
                      .fadeIn(delay: 400.ms),
                  const SizedBox(height: 12),
                  _ToggleTile(
                    icon: Icons.dark_mode_outlined,
                    iconColor: const Color(0xFF4A3F78),
                    title: 'Dark Mode',
                    subtitle: 'Switch to a dark colour scheme',
                    value: _darkMode,
                    onChanged: (v) => setState(() => _darkMode = v),
                  ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),
                  const SizedBox(height: 8),
                  _ToggleTile(
                    icon: Icons.view_compact_rounded,
                    iconColor: AppColors.textSecondary,
                    title: 'Compact View',
                    subtitle: 'Show more content with smaller cards',
                    value: _compactView,
                    onChanged: (v) => setState(() => _compactView = v),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                  const SizedBox(height: 16),

                  // Theme picker
                  _DropdownTile(
                    icon: Icons.palette_outlined,
                    iconColor: AppColors.accent,
                    title: 'Colour Theme',
                    value: _selectedTheme,
                    items: _themes,
                    onChanged: (v) => setState(() => _selectedTheme = v!),
                  ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.1),

                  const SizedBox(height: 24),

                  // ── Language ───────────────────────────────────
                  _SectionHeader(title: 'Language')
                      .animate()
                      .fadeIn(delay: 600.ms),
                  const SizedBox(height: 12),
                  _DropdownTile(
                    icon: Icons.translate_rounded,
                    iconColor: AppColors.tertiary,
                    title: 'App Language',
                    value: _selectedLanguage,
                    items: _languages,
                    onChanged: (v) => setState(() => _selectedLanguage = v!),
                  ).animate().fadeIn(delay: 650.ms).slideY(begin: 0.1),

                  const SizedBox(height: 24),

                  // ── Data & Privacy ─────────────────────────────
                  _SectionHeader(title: 'Data & Privacy')
                      .animate()
                      .fadeIn(delay: 700.ms),
                  const SizedBox(height: 12),
                  _ActionTile(
                    icon: Icons.download_outlined,
                    iconColor: AppColors.primary,
                    title: 'Export My Data',
                    subtitle: 'Download your document scans and summaries',
                    onTap: () => AppSnackbar.showInfo(context, 'Export requested. Processing your document archives.'),
                  ).animate().fadeIn(delay: 750.ms).slideY(begin: 0.1),
                  const SizedBox(height: 8),
                  _ActionTile(
                    icon: Icons.delete_outline_rounded,
                    iconColor: AppColors.riskCritical,
                    title: 'Delete My Account',
                    subtitle: 'Permanently remove your account and data',
                    onTap: _showDeleteAccountNotice,
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),

                  const SizedBox(height: 48),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable sub-widgets ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textTertiary,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: AppTypography.titleSmall),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
          activeThumbColor: Colors.white,
        ),
      ),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: AppTypography.titleSmall),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowCard,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(title, style: AppTypography.titleSmall),
          subtitle: Text(
            subtitle,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
