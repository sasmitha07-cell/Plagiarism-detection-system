import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:academic_writing_coach/core/models/user_profile.dart';
import 'package:academic_writing_coach/features/auth/providers/auth_provider.dart';
import 'package:academic_writing_coach/features/profile/providers/profile_provider.dart';
import 'package:academic_writing_coach/features/profile/screens/profile_screen.dart';

class _FakeProfileNotifier extends ProfileNotifier {
  final AsyncValue<UserProfile?> _state;
  _FakeProfileNotifier(this._state);

  @override
  FutureOr<UserProfile?> build() {
    if (_state.hasError) {
      throw _state.error!;
    }
    return _state.value;
  }
}

void main() {
  Widget createWidgetUnderTest({
    required AsyncValue<UserProfile?> profileValue,
    UserAcademicStats stats = const UserAcademicStats(),
    double screenWidth = 390.0,
  }) {
    return ProviderScope(
      overrides: [
        profileStateProvider.overrideWith(() => _FakeProfileNotifier(profileValue)),
        profileStatsProvider.overrideWith((ref) => Future.value(stats)),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(screenWidth, 844)),
          child: const ProfileScreen(),
        ),
      ),
    );
  }

  group('ProfileScreen Widget Tests', () {
    testWidgets('Displays real user profile data correctly', (tester) async {
      final user = UserProfile(
        id: 'user-real-999',
        email: 'sasmitha.research@university.ac.uk',
        fullName: 'Sasmitha Krishnamoorthy',
        institution: 'University of Cambridge',
        academicLevel: 'doctorate',
        createdAt: DateTime(2026, 4, 12),
      );

      final stats = const UserAcademicStats(
        totalDocuments: 6,
        totalScans: 14,
        averageSimilarityScore: 6.2,
        averageWritingScore: 91.0,
        cleanScansCount: 10,
        zeroStreak: 3,
      );

      await tester.pumpWidget(createWidgetUnderTest(
        profileValue: AsyncValue.data(user),
        stats: stats,
      ));
      await tester.pumpAndSettle();

      // Verify User Details
      expect(find.text('Sasmitha Krishnamoorthy'), findsOneWidget);
      expect(find.text('sasmitha.research@university.ac.uk'), findsOneWidget);
      expect(find.text('University of Cambridge'), findsOneWidget);
      expect(find.text('Doctorate / PhD'), findsOneWidget);
      expect(find.text('SK'), findsOneWidget); // Initials
      expect(find.textContaining('Member since'), findsOneWidget);

      // Verify Real Statistics
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('Total Scans'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('6.2%'), findsOneWidget);
      expect(find.text('91'), findsOneWidget);
      expect(find.text('Streak: 3'), findsOneWidget);
    });

    testWidgets('Displays empty state hint when institution is missing', (tester) async {
      final user = UserProfile(
        id: 'user-new',
        email: 'newuser@example.com',
        fullName: 'Alex Student',
        institution: null,
        academicLevel: 'undergraduate',
        createdAt: DateTime(2026, 6, 1),
      );

      await tester.pumpWidget(createWidgetUnderTest(
        profileValue: AsyncValue.data(user),
        stats: const UserAcademicStats(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Add your institution'), findsOneWidget);
      expect(find.text('Undergraduate'), findsOneWidget);
      expect(find.text('AS'), findsOneWidget); // Initials
      // 0 stats rendered cleanly without mock numbers
      expect(find.text('0'), findsNWidgets(2)); // Documents: 0, Total Scans: 0
      expect(find.text('0.0%'), findsOneWidget); // Avg similarity
      expect(find.text('—'), findsOneWidget); // Writing quality
    });

    testWidgets('Displays clean error state with Retry button on load failure', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        profileValue: const AsyncValue.error('Network unreachable', StackTrace.empty),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Unable to load your profile.'), findsOneWidget);
      expect(find.text('Please check your connection and try again.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      // Raw error message should NOT be displayed
      expect(find.textContaining('Network unreachable'), findsNothing);
    });

    testWidgets('Responsive rendering: no overflow on 360px, 375px, 390px, 412px widths', (tester) async {
      final longNamedUser = UserProfile(
        id: 'user-long',
        email: 'very.long.academic.email.address.researcher@prestigious-university.ac.uk',
        fullName: 'Professor Alexandra Victoria Montgomery-Smith',
        institution: 'International Institute of Advanced Technological & Academic Studies',
        academicLevel: 'researcher',
        createdAt: DateTime(2026, 2, 20),
      );

      final widths = [360.0, 375.0, 390.0, 412.0];

      for (final width in widths) {
        await tester.pumpWidget(createWidgetUnderTest(
          profileValue: AsyncValue.data(longNamedUser),
          stats: const UserAcademicStats(
            totalDocuments: 120,
            totalScans: 350,
            averageSimilarityScore: 12.8,
            averageWritingScore: 89.0,
          ),
          screenWidth: width,
        ));
        await tester.pumpAndSettle();

        // Verify no overflow errors were triggered
        expect(tester.takeException(), isNull, reason: 'Failed overflow check on width $width');
      }
    });
  });
}
