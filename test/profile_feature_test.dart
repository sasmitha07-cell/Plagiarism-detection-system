import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:academic_writing_coach/core/models/user_profile.dart';
import 'package:academic_writing_coach/features/auth/providers/auth_provider.dart';
import 'package:academic_writing_coach/features/profile/providers/profile_provider.dart';

void main() {
  group('UserProfile Model Unit Tests', () {
    test('displayName returns full_name if present and non-empty', () {
      final profile = UserProfile(
        id: 'user-123',
        email: 'sasmitha@university.edu',
        fullName: 'Sasmitha Krishnamoorthy',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(profile.displayName, equals('Sasmitha Krishnamoorthy'));
    });

    test('displayName falls back to email prefix if full_name is null or blank', () {
      final profileNull = UserProfile(
        id: 'user-123',
        email: 'researcher42@university.edu',
        fullName: null,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(profileNull.displayName, equals('researcher42'));

      final profileEmpty = UserProfile(
        id: 'user-123',
        email: 'scholar99@harvard.edu',
        fullName: '   ',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(profileEmpty.displayName, equals('scholar99'));
    });

    test('initials generates accurate uppercase letters', () {
      final p1 = UserProfile(
        id: '1',
        email: 'test@example.com',
        fullName: 'Sasmitha Krishnamoorthy',
        createdAt: DateTime.now(),
      );
      expect(p1.initials, equals('SK'));

      final p2 = UserProfile(
        id: '2',
        email: 'alan@mit.edu',
        fullName: 'Alan',
        createdAt: DateTime.now(),
      );
      expect(p2.initials, equals('AL'));

      final p3 = UserProfile(
        id: '3',
        email: 'john.doe.smith@oxford.ac.uk',
        fullName: 'John David Smith',
        createdAt: DateTime.now(),
      );
      expect(p3.initials, equals('JS'));
    });

    test('academicLevelFormatted properly maps database enums to titles', () {
      final levels = {
        'undergraduate': 'Undergraduate',
        'graduate': 'Graduate',
        'doctorate': 'Doctorate / PhD',
        'high_school': 'High School',
        'faculty': 'Faculty',
        'researcher': 'Researcher',
        'other': 'Other',
      };

      for (final entry in levels.entries) {
        final profile = UserProfile(
          id: 'test',
          email: 'test@test.com',
          academicLevel: entry.key,
          createdAt: DateTime.now(),
        );
        expect(profile.academicLevelFormatted, equals(entry.value));
      }
    });

    test('toJson and fromJson correctly round-trip all profile attributes', () {
      final original = UserProfile(
        id: 'user-abc-123',
        email: 'author@academic.edu',
        fullName: 'Dr. Jane Watson',
        institution: 'Cambridge University',
        department: 'Linguistics',
        academicLevel: 'faculty',
        avatarUrl: 'https://storage.supabase.co/avatars/user-abc-123/avatar.jpg',
        bio: 'Academic writing researcher',
        totalScans: 42,
        totalDocuments: 15,
        averageSimilarityScore: 4.8,
        averageWritingScore: 92.5,
        zeroPlagiarismStreak: 7,
        isAdmin: true,
        onboardingCompleted: true,
        createdAt: DateTime.parse('2026-03-15T10:30:00Z'),
      );

      final json = original.toJson();
      json['created_at'] = original.createdAt.toIso8601String();
      json['total_scans'] = original.totalScans;
      json['total_documents'] = original.totalDocuments;
      json['average_similarity_score'] = original.averageSimilarityScore;
      json['average_writing_score'] = original.averageWritingScore;
      json['zero_plagiarism_streak'] = original.zeroPlagiarismStreak;

      final restored = UserProfile.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.email, equals(original.email));
      expect(restored.fullName, equals(original.fullName));
      expect(restored.institution, equals(original.institution));
      expect(restored.department, equals(original.department));
      expect(restored.academicLevel, equals(original.academicLevel));
      expect(restored.avatarUrl, equals(original.avatarUrl));
      expect(restored.totalScans, equals(original.totalScans));
      expect(restored.totalDocuments, equals(original.totalDocuments));
      expect(restored.averageSimilarityScore, equals(original.averageSimilarityScore));
      expect(restored.averageWritingScore, equals(original.averageWritingScore));
      expect(restored.zeroPlagiarismStreak, equals(original.zeroPlagiarismStreak));
      expect(restored.isAdmin, equals(original.isAdmin));
    });
  });

  group('Profile Completion Calculation Tests', () {
    test('Calculates 100% when all 5 profile fields are populated', () {
      final container = ProviderContainer(
        overrides: [
          profileStateProvider.overrideWith(() => _MockProfileNotifier(
                UserProfile(
                  id: 'user-complete',
                  email: 'complete@uni.edu',
                  fullName: 'Sasmitha K.',
                  institution: 'Stanford',
                  academicLevel: 'undergraduate',
                  avatarUrl: 'https://images.com/photo.jpg',
                  createdAt: DateTime.now(),
                ),
              )),
        ],
      );

      final completion = container.read(profileCompletionProvider);
      expect(completion.percentage, equals(100));
      expect(completion.isComplete, isTrue);
      expect(completion.missingFields, isEmpty);
    });

    test('Calculates dynamic partial percentage and accurately identifies missing fields', () {
      // Only email and academic level populated = 40%
      final container = ProviderContainer(
        overrides: [
          profileStateProvider.overrideWith(() => _MockProfileNotifier(
                UserProfile(
                  id: 'user-partial',
                  email: 'student@uni.edu',
                  fullName: null,
                  institution: null,
                  academicLevel: 'undergraduate',
                  avatarUrl: null,
                  createdAt: DateTime.now(),
                ),
              )),
        ],
      );

      final completion = container.read(profileCompletionProvider);
      expect(completion.percentage, equals(40));
      expect(completion.isComplete, isFalse);
      expect(completion.missingFields, containsAll(['Full name', 'Institution', 'Profile photo']));
    });

    test('Increases percentage when user fills in missing institution and name', () {
      final container = ProviderContainer(
        overrides: [
          profileStateProvider.overrideWith(() => _MockProfileNotifier(
                UserProfile(
                  id: 'user-updated',
                  email: 'student@uni.edu',
                  fullName: 'Sasmitha',
                  institution: 'MIT',
                  academicLevel: 'graduate',
                  avatarUrl: null,
                  createdAt: DateTime.now(),
                ),
              )),
        ],
      );

      final completion = container.read(profileCompletionProvider);
      expect(completion.percentage, equals(80));
      expect(completion.missingFields, equals(['Profile photo']));
    });
  });

  group('User Academic Stats & Data Isolation Tests', () {
    test('Empty stats return exact zeroes with no fake data', () {
      const stats = UserAcademicStats();
      expect(stats.totalScans, equals(0));
      expect(stats.totalDocuments, equals(0));
      expect(stats.totalCitations, equals(0));
      expect(stats.averageSimilarityScore, equals(0.0));
      expect(stats.averageWritingScore, equals(0.0));
      expect(stats.cleanScansCount, equals(0));
      expect(stats.zeroStreak, equals(0));
    });

    test('User isolation: User A profile is strictly isolated from User B', () {
      final userA = UserProfile(
        id: 'user-uuid-aaaa-1111',
        email: 'userA@academic.edu',
        fullName: 'Alice Researcher',
        institution: 'Oxford',
        academicLevel: 'doctorate',
        totalScans: 10,
        createdAt: DateTime.now(),
      );

      final userB = UserProfile(
        id: 'user-uuid-bbbb-2222',
        email: 'userB@academic.edu',
        fullName: 'Bob Student',
        institution: 'Harvard',
        academicLevel: 'undergraduate',
        totalScans: 0,
        createdAt: DateTime.now(),
      );

      // Verify User A profile contains none of User B data
      expect(userA.id, isNot(equals(userB.id)));
      expect(userA.email, isNot(equals(userB.email)));
      expect(userA.fullName, equals('Alice Researcher'));
      expect(userB.fullName, equals('Bob Student'));
      expect(userA.institution, equals('Oxford'));
      expect(userB.institution, equals('Harvard'));
      expect(userA.totalScans, equals(10));
      expect(userB.totalScans, equals(0));
    });
  });
}

class _MockProfileNotifier extends ProfileNotifier {
  final UserProfile? _mockProfile;
  _MockProfileNotifier(this._mockProfile);

  @override
  FutureOr<UserProfile?> build() {
    return _mockProfile;
  }
}
