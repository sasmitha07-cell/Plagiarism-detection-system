import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';

import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _shimmerAnim;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    print('SplashScreen: initState');
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.3, 0.7, curve: Curves.easeOut)),
    );
    _shimmerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.7, 1.0, curve: Curves.easeIn)),
    );

    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted || _isNavigating) return;
    _isNavigating = true;

    print('SplashScreen: Starting navigation logic');

    try {
      final authState = ref.read(authStateProvider);
      final isPasswordRecovery =
          ref.read(passwordRecoveryProvider).value ?? false;

      if (isPasswordRecovery) {
        print('SplashScreen: Recovery mode detected');
        if (mounted) context.go('/auth/update-password');
        return;
      }

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        final box = Hive.box(AppConstants.cacheBoxName);
        final wasDemoActive =
            box.get('is_demo_active', defaultValue: false) == true;

        if (wasDemoActive) {
          print('SplashScreen: Attempting demo login');
          final signedInAsDemo =
              await ref.read(authRepositoryProvider).signInWithDemoUser();
          if (signedInAsDemo && mounted) {
            print('SplashScreen: Navigating to Home (Demo)');
            context.go('/home');
            return;
          }
        }
      }

      if (!mounted) return;

      authState.when(
        data: (user) {
          if (user != null) {
            print('SplashScreen: User logged in, going home');
            context.go('/home');
          } else {
            print('SplashScreen: No user, going to onboarding');
            context.go('/onboarding');
          }
        },
        loading: () {
          print('SplashScreen: Auth state loading');
          if (Supabase.instance.client.auth.currentUser != null) {
            context.go('/home');
          } else {
            context.go('/auth/login');
          }
        },
        error: (error, stack) {
          print('SplashScreen: Auth error: $error');
          context.go('/auth/login');
        },
      );
    } catch (e) {
      print('SplashScreen: Navigation logic error: $e');
      if (mounted) context.go('/auth/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF9F6F1),
              Color(0xFFEFF8F3),
              Color(0xFFF9F6F1),
            ],
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Logo + Icon
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnim.value,
                      child: Opacity(
                        opacity: _fadeAnim.value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // App icon
                      Container(
                        width: 100,
                        height: 100,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/app-logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // App name
                      Text(
                        'Academic Writing',
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Coach',
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'AI-Powered Plagiarism Detection\n& Academic Writing Assistant',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Loading indicator
                AnimatedBuilder(
                  animation: _shimmerAnim,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _shimmerAnim.value,
                      child: child,
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 120,
                        child: LinearProgressIndicator(
                          backgroundColor: AppColors.primarySurface,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.primary,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Initializing AI Engine...',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
