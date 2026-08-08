import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthUser', () {
    test('emailVerified defaults to false', () {
      const user = AuthUser(id: 'u1', email: 'a@b.com');
      expect(user.emailVerified, isFalse);
    });

    test('emailVerified participates in equality', () {
      const a = AuthUser(id: 'u1', email: 'a@b.com', emailVerified: true);
      const b = AuthUser(id: 'u1', email: 'a@b.com', emailVerified: false);
      expect(a == b, isFalse);
    });

    test('empty user is not verified', () {
      expect(AuthUser.empty.emailVerified, isFalse);
    });
  });
}
