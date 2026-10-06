import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized utility to map raw technical errors (PostgREST, Auth, Network, AI)
/// into polished, user-friendly messages for the UI layer while logging the
/// full technical exception for debugging.
class AppErrorMapper {
  AppErrorMapper._();

  static String toUserFriendlyMessage(dynamic error, {String? defaultAction}) {
    if (error == null) return 'An unexpected error occurred.';

    final raw = error.toString();
    dev.log('AppErrorMapper caught: $raw', error: error);

    // 1. PostgREST / Database Errors
    if (error is PostgrestException ||
        raw.contains('PostgrestException') ||
        raw.contains('PGRST') ||
        raw.contains('22P02') ||
        raw.contains('schema cache') ||
        raw.contains('relation') ||
        raw.contains('column') ||
        raw.contains('database') ||
        raw.contains('infinite recursion')) {
      return defaultAction != null
          ? 'Unable to $defaultAction. Please try again.'
          : "We couldn't load your saved data. Please try again.";
    }

    // 2. Supabase Auth Errors
    if (error is AuthException ||
        raw.contains('AuthException') ||
        raw.contains('invalid login credentials') ||
        raw.contains('Invalid login') ||
        raw.contains('session expired') ||
        raw.contains('JWT') ||
        raw.contains('Bad Gateway') ||
        raw.contains('502')) {
      if (raw.contains('Invalid login credentials')) {
        return 'Invalid email or password. Please try again.';
      }
      if (raw.contains('User already registered') || raw.contains('user_already_exists')) {
        return 'An account with this email already exists.';
      }
      return 'Your session has expired or the server is busy. Please try again.';
    }

    // 3. Network / Connection Errors
    if (raw.contains('SocketException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('Network error') ||
        raw.contains('ClientException') ||
        raw.contains('TimeoutException') ||
        raw.contains('Connecting timed out') ||
        raw.contains('HandshakeException')) {
      return 'No internet connection. Check your connection and try again.';
    }

    // 4. AI / Edge Function Errors
    if (raw.contains('gemini-reasoning') ||
        raw.contains('EDGE_FUNCTION_ERROR') ||
        raw.contains('AI reasoning') ||
        raw.contains('generativelanguage') ||
        raw.contains('model')) {
      return 'The AI service is temporarily unavailable. Please try again.';
    }

    // 5. Default Friendly Fallback
    return defaultAction != null
        ? 'Could not $defaultAction. Please try again.'
        : 'Something went wrong. Please try again.';
  }

  static String getUserMessage(dynamic error, {String? fallback}) {
    if (fallback != null) {
      return toUserFriendlyMessage(error, defaultAction: fallback);
    }
    return toUserFriendlyMessage(error);
  }
}
