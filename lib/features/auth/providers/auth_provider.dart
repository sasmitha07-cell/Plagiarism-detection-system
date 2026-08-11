import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/constants/app_constants.dart';

import 'package:hive_flutter/hive_flutter.dart';

const _demoUserEmail = 'demo.user@academicwritingcoach.dev';
const _demoUserPassword = 'demo123456';
const _demoUserId = 'demo-user-id';

bool isDemoLoginAttempt(String email, String password) {
  return email.trim().toLowerCase() == _demoUserEmail &&
      password == _demoUserPassword;
}

bool shouldCreateDemoUserAccount(String error) {
  final normalizedError = error.toLowerCase();
  return normalizedError.contains('invalid login credentials') ||
      normalizedError.contains('user not found') ||
      normalizedError.contains('invalid email or password');
}

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map((event) {
    return event.session?.user;
  });
});

final passwordRecoveryProvider = StreamProvider<bool>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map(
    (event) => event.event == AuthChangeEvent.passwordRecovery,
  );
});

// Current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  final currentUser = Supabase.instance.client.auth.currentUser;
  if (currentUser != null) return currentUser.id;
  return AuthRepository.isDemoUserActive ? _demoUserId : null;
});

// Auth actions provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

class AuthRepository {
  final SupabaseClient _client;

  static bool _isDemoUserActive = false;

  AuthRepository(this._client);

  static bool get isDemoUserActive => _isDemoUserActive;

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail(
    String email,
    String password,
    String fullName,
    String institution,
    String academicLevel,
  ) async {
    return await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'institution': institution.trim(),
        'academic_level': academicLevel,
      },
    );
  }

  Future<bool> signInWithDemoUser() async {
    try {
      await _client.auth.signInWithPassword(
        email: _demoUserEmail,
        password: _demoUserPassword,
      );
      _isDemoUserActive = true;
      final box = Hive.box(AppConstants.cacheBoxName);
      await box.put('is_demo_active', true);
      return true;
    } catch (e) {
      if (shouldCreateDemoUserAccount(e.toString())) {
        _isDemoUserActive = true;
        final box = Hive.box(AppConstants.cacheBoxName);
        await box.put('is_demo_active', true);
        return true;
      }
      _isDemoUserActive = false;
      return false;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    _isDemoUserActive = false;
    final box = Hive.box(AppConstants.cacheBoxName);
    await box.put('is_demo_active', false);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: AppConstants.authRedirectUrl,
    );
  }

  Future<UserResponse> updatePassword(String newPassword) async {
    return await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
}

UserProfile? _getFallbackProfile(String userId) {
  if (userId == 'demo-user-id') {
    return UserProfile(
      id: 'demo-user-id',
      email: 'demo.user@academicwritingcoach.dev',
      fullName: 'Demo Student',
      institution: 'State University',
      academicLevel: 'Postgraduate',
      department: 'Computer Science',
      totalScans: 12,
      totalDocuments: 8,
      averageSimilarityScore: 14.5,
      averageWritingScore: 88.0,
      zeroPlagiarismStreak: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
  }
  final user = Supabase.instance.client.auth.currentUser;
  if (user != null && user.id == userId) {
    final metadata = user.userMetadata ?? {};
    return UserProfile(
      id: user.id,
      email: user.email ?? '',
      fullName: metadata['full_name'] as String?,
      institution: metadata['institution'] as String?,
      academicLevel: metadata['academic_level'] as String?,
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    );
  }
  return null;
}

// Profile provider
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  try {
    final data = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return _getFallbackProfile(userId);
    return UserProfile.fromJson(data);
  } catch (e) {
    return _getFallbackProfile(userId);
  }
});

// Mutable profile state for updates
final profileStateProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile?>(
  () => ProfileNotifier(),
);

class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  FutureOr<UserProfile?> build() async {
    return _fetchProfile();
  }

  Future<UserProfile?> _fetchProfile() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return null;
    }

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return _getFallbackProfile(userId);
      return UserProfile.fromJson(data);
    } catch (e) {
      return _getFallbackProfile(userId);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    await Supabase.instance.client
        .from('profiles')
        .update(updates)
        .eq('id', userId);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProfile());
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProfile());
  }
}

