import 'dart:async';
import 'package:flutter/foundation.dart';
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

// Current user ID (reactive to auth changes)
final currentUserIdProvider = Provider<String?>((ref) {
  final authUser = ref.watch(authStateProvider).asData?.value;
  if (authUser != null) return authUser.id;
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

// Reactive Profile provider
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  return ref.watch(profileStateProvider).asData?.value;
});

// Mutable profile state for updates
final profileStateProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile?>(
  () => ProfileNotifier(),
);

class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  FutureOr<UserProfile?> build() async {
    // Watching currentUserIdProvider automatically resets and reloads profile on sign-in / sign-out
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      return null;
    }
    return _fetchProfile(userId);
  }

  Future<UserProfile?> _fetchProfile(String userId) async {
    if (userId == _demoUserId) {
      return _getFallbackProfile(userId);
    }

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        return UserProfile.fromJson(data);
      }

      // If user profile is not yet in profiles table, bootstrap from authenticated auth.users record
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null && currentUser.id == userId) {
        final meta = currentUser.userMetadata ?? {};
        final email = currentUser.email ?? '';
        final initialName = meta['full_name'] as String? ??
            (email.isNotEmpty ? email.split('@').first : 'User');
        final initialProfile = {
          'id': userId,
          'email': email,
          'full_name': initialName,
          'institution': meta['institution'] as String?,
          'academic_level':
              meta['academic_level'] as String? ?? 'undergraduate',
          'created_at': currentUser.createdAt,
          'updated_at': DateTime.now().toIso8601String(),
        };

        try {
          final inserted = await Supabase.instance.client
              .from('profiles')
              .insert(initialProfile)
              .select()
              .maybeSingle();
          if (inserted != null) {
            return UserProfile.fromJson(inserted);
          }
        } catch (_) {
          // In case of concurrent insert or transient issue, query once more
          final refetched = await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();
          if (refetched != null) return UserProfile.fromJson(refetched);
        }

        return UserProfile(
          id: currentUser.id,
          email: email,
          fullName: meta['full_name'] as String?,
          institution: meta['institution'] as String?,
          academicLevel: meta['academic_level'] as String? ?? 'undergraduate',
          createdAt: DateTime.tryParse(currentUser.createdAt) ?? DateTime.now(),
        );
      }

      return null;
    } catch (e) {
      debugPrint('[ProfileNotifier] Error fetching profile: $e');
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null && currentUser.id == userId) {
        final meta = currentUser.userMetadata ?? {};
        return UserProfile(
          id: currentUser.id,
          email: currentUser.email ?? '',
          fullName: meta['full_name'] as String?,
          institution: meta['institution'] as String?,
          academicLevel: meta['academic_level'] as String?,
          createdAt: DateTime.tryParse(currentUser.createdAt) ?? DateTime.now(),
        );
      }
      rethrow;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    if (userId != _demoUserId) {
      final sanitized = Map<String, dynamic>.from(updates);
      sanitized['updated_at'] = DateTime.now().toIso8601String();

      await Supabase.instance.client
          .from('profiles')
          .update(sanitized)
          .eq('id', userId);

      // Keep userMetadata in sync where applicable
      try {
        final metaUpdates = <String, dynamic>{};
        if (updates.containsKey('full_name')) {
          metaUpdates['full_name'] = updates['full_name'];
        }
        if (updates.containsKey('institution')) {
          metaUpdates['institution'] = updates['institution'];
        }
        if (updates.containsKey('academic_level')) {
          metaUpdates['academic_level'] = updates['academic_level'];
        }
        if (metaUpdates.isNotEmpty) {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(data: metaUpdates),
          );
        }
      } catch (_) {}
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProfile(userId));
  }

  Future<String?> uploadAvatar(dynamic imageFile) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || userId == _demoUserId) return null;

    final client = Supabase.instance.client;
    final pathStr = imageFile.path as String;
    final ext = pathStr.split('.').last.toLowerCase();
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final filePath = '$userId/$fileName';

    final bytes = await imageFile.readAsBytes();
    String mimeType = 'image/jpeg';
    if (ext == 'png') {
      mimeType = 'image/png';
    } else if (ext == 'webp') {
      mimeType = 'image/webp';
    } else if (ext == 'gif') {
      mimeType = 'image/gif';
    }

    await client.storage.from('avatars').uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(
            contentType: mimeType,
            upsert: true,
          ),
        );

    final publicUrl = client.storage.from('avatars').getPublicUrl(filePath);
    final cacheBustedUrl =
        '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

    await updateProfile({'avatar_url': cacheBustedUrl});
    return cacheBustedUrl;
  }

  Future<void> removeAvatar() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await updateProfile({'avatar_url': null});
  }

  Future<void> refresh() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProfile(userId));
  }
}

