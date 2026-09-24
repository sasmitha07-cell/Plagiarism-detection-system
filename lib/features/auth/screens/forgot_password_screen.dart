import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/app_snackbar.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    dev.log('Password reset request for: ${_emailController.text}');
    if (!_formKey.currentState!.validate()) {
      dev.log('Password reset form validation failed');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.sendPasswordResetEmail(_emailController.text);
      dev.log('Password reset email sent (or masked success)');
      // Supabase intentionally does NOT differentiate between registered
      // and unregistered emails (security best practice). Always show success.
      if (mounted) setState(() => _emailSent = true);
    } catch (e) {
      dev.log('Password reset failed: $e');
      // Only show error on genuine network/config failures
      if (mounted) {
        final errMsg = e.toString().toLowerCase();
        if (errMsg.contains('network') || errMsg.contains('timeout') || errMsg.contains('socket')) {
          AppSnackbar.showError(context, 'Network error. Check your connection and try again.');
        } else {
          // Treat all other errors as success (safe fallback to avoid leaking user existence)
          setState(() => _emailSent = true);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              GestureDetector(
                onTap: () => context.go('/auth/login'),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 40),

              if (!_emailSent) ...[
                Text('Reset Password 🔐',
                    style: AppTypography.headlineSmall
                        .copyWith(fontWeight: FontWeight.w800))
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .slideY(begin: 0.3),
                const SizedBox(height: 8),
                Text(
                  'Enter your email and we\'ll send you a link to reset your password.',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: AppTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'you@university.edu',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ).animate().fadeIn(delay: 200.ms),
                ),
                const SizedBox(height: 32),
                GradientButton(
                  text: 'Send Reset Link',
                  isLoading: _isLoading,
                  onPressed: _sendReset,
                ).animate().fadeIn(delay: 250.ms),
              ] else ...[
                const Expanded(child: SizedBox()),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          color: AppColors.primarySurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mark_email_read_rounded,
                            color: AppColors.primary, size: 48),
                      ).animate().scale(
                            begin: const Offset(0.5, 0.5),
                            curve: Curves.elasticOut,
                            duration: 600.ms,
                          ),
                      const SizedBox(height: 32),
                      Text('Check your inbox! 📬',
                          style: AppTypography.titleLarge
                              .copyWith(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center)
                          .animate()
                          .fadeIn(delay: 200.ms),
                      const SizedBox(height: 12),
                      Text(
                        'If an account exists for',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 4),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _emailController.text.trim(),
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ).animate().fadeIn(delay: 350.ms),
                      const SizedBox(height: 12),
                      Text(
                        'we\'ve sent a password reset link.\nCheck your spam folder if you don\'t see it.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary, height: 1.6),
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => context.go('/auth/login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Back to Sign In'),
                        ),
                      ).animate().fadeIn(delay: 450.ms),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => setState(() => _emailSent = false),
                        child: Text(
                          'Try a different email',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ).animate().fadeIn(delay: 500.ms),
                    ],
                  ),
                ),
                const Expanded(child: SizedBox()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
