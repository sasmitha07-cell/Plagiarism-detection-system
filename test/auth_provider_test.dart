import 'package:flutter_test/flutter_test.dart';
import 'package:academic_writing_coach/features/auth/providers/auth_provider.dart';

void main() {
  group('demo auth fallback', () {
    test('creates a demo account when sign-in reports invalid credentials', () {
      expect(shouldCreateDemoUserAccount('Invalid login credentials'), isTrue);
    });

    test('does not create a demo account for unrelated auth errors', () {
      expect(shouldCreateDemoUserAccount('Network request failed'), isFalse);
    });
  });
}
