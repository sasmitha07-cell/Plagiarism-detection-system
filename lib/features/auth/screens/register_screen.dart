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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _institutionController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _emailSent = false;
  String _registeredEmail = '';
  String _selectedLevel = 'undergraduate';

  final _levels = [
    ('high_school', 'High School'),
    ('undergraduate', 'Undergraduate'),
    ('graduate', 'Graduate'),
    ('doctorate', 'Doctorate / PhD'),
    ('faculty', 'Faculty'),
    ('researcher', 'Researcher'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _institutionController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    print('Registration attempt for: ${_emailController.text}');
    if (!_formKey.currentState!.validate()) {
      print('Registration form validation failed');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.signUpWithEmail(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
        _institutionController.text,
        _selectedLevel,
      );

      if (!mounted) return;
      if (response.session != null) {
        print('Registration successful, session created');
        // Email confirmation disabled — logged in directly
        context.go('/home');
      } else {
        print('Registration successful, email confirmation sent');
        // Email confirmation required — show confirmation screen
        setState(() {
          _emailSent = true;
          _registeredEmail = _emailController.text.trim();
        });
      }
    } catch (e) {
      print('Registration failed: $e');
      if (mounted) AppSnackbar.showError(context, _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  String _friendlyError(String error) {
    if (error.contains('already registered') ||
        error.contains('already been registered')) {
      return 'An account with this email already exists.';
    }
    if (error.contains('weak password') || error.contains('Password should')) {
      return 'Password is too weak. Use at least 8 characters.';
    }
    if (error.contains('Invalid email')) return 'Enter a valid email address.';
    return 'Registration failed. Please try again.';
  }

  Widget _buildEmailConfirmation() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_rounded,
                  color: AppColors.primary,
                  size: 48,
                ),
              ).animate().scale(
                begin: const Offset(0.5, 0.5),
                curve: Curves.elasticOut,
                duration: 600.ms,
              ),
              const SizedBox(height: 32),
              Text(
                'Verify your email ✉️',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 16),
              Text(
                'We sent a confirmation link to:',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _registeredEmail,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ).animate().fadeIn(delay: 450.ms),
              const SizedBox(height: 24),
              Text(
                'Open your email app, click the link, then come back and sign in.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 500.ms),
              const Spacer(),
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
                  child: const Text('Go to Sign In'),
                ),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _emailSent = false),
                child: Text(
                  'Use a different email',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ).animate().fadeIn(delay: 650.ms),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_emailSent) return _buildEmailConfirmation();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Back button
                GestureDetector(
                  onTap: () {
                    print('Navigating back to Login from Register');
                    context.go('/auth/login');
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 20),
                  ),
                ).animate().fadeIn(),

                const SizedBox(height: 32),

                Text(
                  'Create Account ✨',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3),

                const SizedBox(height: 8),

                Text(
                  'Join thousands of students and researchers using AI to improve their writing',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 32),

                AppTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Dr. Jane Smith',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Name is required' : null,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                const SizedBox(height: 14),

                AppTextField(
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
                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2),

                const SizedBox(height: 14),

                AppTextField(
                  controller: _institutionController,
                  label: 'Institution (Optional)',
                  hint: 'Harvard University',
                  prefixIcon: Icons.business_outlined,
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

                const SizedBox(height: 14),

                // Academic level dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Academic Level',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLevel,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textTertiary),
                          style: AppTypography.bodyMedium,
                          items: _levels
                              .map((l) => DropdownMenuItem(
                                    value: l.$1,
                                    child: Text(l.$2),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedLevel = v ?? _selectedLevel),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 350.ms),

                const SizedBox(height: 14),

                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: '8+ characters',
                  obscureText: !_showPassword,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'At least 6 characters required';
                    return null;
                  },
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                const SizedBox(height: 32),

                GradientButton(
                  text: 'Create Account',
                  isLoading: _isLoading,
                  onPressed: _register,
                ).animate().fadeIn(delay: 450.ms),

                const SizedBox(height: 24),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          print('Navigating to Login Screen');
                          context.go('/auth/login');
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Text(
                            'Sign In',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
