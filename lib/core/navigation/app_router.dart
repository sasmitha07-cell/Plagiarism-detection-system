
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/update_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/scan/screens/scan_hub_screen.dart';
import '../../features/scan/screens/text_input_screen.dart';
import '../../features/scan/screens/document_upload_screen.dart';
import '../../features/scan/screens/voice_input_screen.dart';
import '../../features/scan/screens/ocr_input_screen.dart';
import '../../features/scan/screens/scan_processing_screen.dart';
import '../../features/scan/screens/scan_result_screen.dart';
import '../../features/compare/screens/compare_screen.dart';
import '../../features/compare/screens/comparison_result_screen.dart';
import '../../features/coach/screens/coach_screen.dart';
import '../../features/coach/screens/rewrite_screen.dart';
import '../../features/citations/screens/citation_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/progress_screen.dart';
import '../../features/profile/screens/achievements_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/profile/screens/help_support_screen.dart';
import '../../features/profile/screens/about_screen.dart';
import '../../features/reports/screens/report_detail_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../shell/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/splash',
    redirect: (context, state) {
      final matchedLocation = state.matchedLocation;
      final targetPath = state.uri.path;
      // A user is "logged in" if Supabase has a real session OR the demo user
      // flag is active (demo login bypasses Supabase auth).
      final isLoggedIn =
          authState.value != null || AuthRepository.isDemoUserActive;
      final isAuthRoute = matchedLocation.startsWith('/auth');
      final isSplash = matchedLocation == '/splash';
      final isOnboarding = matchedLocation == '/onboarding';

      print('Router Redirect: location=$matchedLocation, target=$targetPath, isLoggedIn=$isLoggedIn');

      if (isSplash || isOnboarding) return null;

      if (matchedLocation == '/auth/update-password') {
        return isLoggedIn ? null : '/auth/login';
      }

      if (!isLoggedIn && !isAuthRoute) {
        print('Redirecting to login: User not logged in and not on auth route');
        return '/auth/login';
      }
      if (isLoggedIn && isAuthRoute) {
        print('Redirecting to home: User already logged in on auth route');
        return '/home';
      }
      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth routes
      GoRoute(
        path: '/auth',
        redirect: (context, state) {
          // Only redirect bare '/auth' to the login screen.
          // We check state.uri.path (the full target) instead of state.matchedLocation
          // because matchedLocation is partial when matching a parent route.
          if (state.uri.path == '/auth' || state.uri.path == '/auth/') {
            return '/auth/login';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: 'login',
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: 'register',
            name: 'register',
            builder: (context, state) => const RegisterScreen(),
          ),
          GoRoute(
            path: 'forgot-password',
            name: 'forgot-password',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: 'update-password',
            name: 'update-password',
            builder: (context, state) => const UpdatePasswordScreen(),
          ),
        ],
      ),

      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/scan',
            name: 'scan',
            builder: (context, state) => const ScanHubScreen(),
            routes: [
              GoRoute(
                path: 'text',
                name: 'scan-text',
                builder: (context, state) => const TextInputScreen(),
              ),
              GoRoute(
                path: 'upload',
                name: 'scan-upload',
                builder: (context, state) => const DocumentUploadScreen(),
              ),
              GoRoute(
                path: 'voice',
                name: 'scan-voice',
                builder: (context, state) => const VoiceInputScreen(),
              ),
              GoRoute(
                path: 'ocr',
                name: 'scan-ocr',
                builder: (context, state) => const OcrInputScreen(),
              ),
              GoRoute(
                path: 'processing/:scanId',
                name: 'scan-processing',
                builder: (context, state) => ScanProcessingScreen(
                  scanId: state.pathParameters['scanId']!,
                  scanData: state.extra as Map<String, dynamic>? ?? {},
                ),
              ),
              GoRoute(
                path: 'result/:scanId',
                name: 'scan-result',
                builder: (context, state) => ScanResultScreen(
                  scanId: state.pathParameters['scanId']!,
                  extraData: state.extra as Map<String, dynamic>?,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/compare',
            name: 'compare',
            builder: (context, state) => const CompareScreen(),
            routes: [
              GoRoute(
                path: 'result/:comparisonId',
                name: 'comparison-result',
                builder: (context, state) => ComparisonResultScreen(
                  comparisonId: state.pathParameters['comparisonId']!,
                  compareData: state.extra as Map<String, dynamic>?,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/coach',
            name: 'coach',
            builder: (context, state) => const CoachScreen(),
            routes: [
              GoRoute(
                path: 'rewrite',
                name: 'rewrite',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return RewriteScreen(
                    originalText: extra?['text'] ?? '',
                    scanId: extra?['scanId'],
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'progress',
                name: 'progress',
                builder: (context, state) => const ProgressScreen(),
              ),
              GoRoute(
                path: 'achievements',
                name: 'achievements',
                builder: (context, state) => const AchievementsScreen(),
              ),
              GoRoute(
                path: 'citations',
                name: 'citations',
                builder: (context, state) => const CitationScreen(),
              ),
              GoRoute(
                path: 'settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'help',
                name: 'help',
                builder: (context, state) => const HelpSupportScreen(),
              ),
              GoRoute(
                path: 'about',
                name: 'about',
                builder: (context, state) => const AboutScreen(),
              ),
            ],
          ),
        ],
      ),

      // Reports (accessible from scan results)
      GoRoute(
        path: '/report/:scanId',
        name: 'report',
        builder: (context, state) => ReportDetailScreen(
          scanId: state.pathParameters['scanId']!,
        ),
      ),

      // Notifications
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Admin
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
});
