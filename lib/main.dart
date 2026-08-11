import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/services/gemini_service.dart';

/// Parse a simple KEY=VALUE .env file. Lines starting with '#' and blank
/// lines are ignored. Values are not trimmed beyond removing the newline.
Map<String, String> _parseEnv(String content) {
  final env = <String, String>{};
  for (final line in content.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final idx = trimmed.indexOf('=');
    if (idx == -1) continue;
    final key = trimmed.substring(0, idx).trim();
    final value = trimmed.substring(idx + 1).trim();
    if (key.isNotEmpty) env[key] = value;
  }
  return env;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Main: WidgetsFlutterBinding initialized');

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  print('Main: Orientations set');

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Load .env from bundled assets and override AppConstants
  try {
    print('Main: Loading .env');
    final envString = await rootBundle.loadString('.env');
    final env = _parseEnv(envString);
    if (env['SUPABASE_ANON_KEY']?.isNotEmpty == true) {
      AppConstants.supabaseAnonKey = env['SUPABASE_ANON_KEY']!;
    }
    if (env['GEMINI_API_KEY']?.isNotEmpty == true &&
        env['GEMINI_API_KEY'] != 'your_gemini_api_key_here') {
      AppConstants.geminiApiKey = env['GEMINI_API_KEY']!;
    }
    print('Main: .env loaded');
  } catch (e) {
    print('Main: .env error: $e');
    // .env missing or malformed — fall back to compile-time defaults
  }

  // Initialize Gemini if a valid key was found
  if (AppConstants.geminiApiKey.isNotEmpty) {
    print('Main: Initializing Gemini');
    GeminiService.instance.initialize(AppConstants.geminiApiKey);
  }

  // Initialize Hive for local caching
  try {
    print('Main: Initializing Hive');
    await Hive.initFlutter();
    await Hive.openBox(AppConstants.cacheBoxName);
    await Hive.openBox(AppConstants.draftsBoxName);
    print('Main: Hive initialized');
  } catch (e) {
    print('Main: Hive error: $e');
  }

  // Initialize Supabase
  try {
    print('Main: Initializing Supabase');
    // ignore: deprecated_member_use — anonKey is the correct param name for supabase_flutter ^2.x
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    print('Main: Supabase initialized');
  } catch (e) {
    print('Main: Supabase error: $e');
  }

  print('Main: Running app');
  runApp(
    const ProviderScope(
      child: AcademicWritingCoachApp(),
    ),
  );
}

class AcademicWritingCoachApp extends ConsumerWidget {
  const AcademicWritingCoachApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('App: Building MaterialApp');
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Academic Writing Coach',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
