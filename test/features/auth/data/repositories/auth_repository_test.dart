import 'package:emerge_app/features/auth/data/repositories/fake_auth_repository.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeAuthRepository authRepository;

  setUp(() {
    authRepository = FakeAuthRepository();
  });

  tearDown(() {
    authRepository.dispose();
  });

  group('FakeAuthRepository', () {
    test('initial user should be empty', () {
      expect(authRepository.user, emits(AuthUser.empty));
    });

    test('signInWithEmailAndPassword returns user on success', () async {
      final result = await authRepository.signInWithEmailAndPassword(
        email: 'test@emerge.com',
        password: 'password',
      );

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (user) {
        expect(user.email, 'test@emerge.com');
        expect(user.id, '123');
      });
    });

    test(
      'signInWithEmailAndPassword returns failure on wrong credentials',
      () async {
        final result = await authRepository.signInWithEmailAndPassword(
          email: 'wrong@email.com',
          password: 'wrong',
        );

        expect(result.isLeft(), true);
      },
    );

    test('signUpWithEmailAndPassword returns new user', () async {
      final result = await authRepository.signUpWithEmailAndPassword(
        email: 'new@emerge.com',
        password: 'password',
        username: 'NewUser',
      );

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (user) {
        expect(user.email, 'new@emerge.com');
        expect(user.displayName, 'NewUser');
      });
    });

    test('signOut emits empty user', () async {
      await authRepository.signInWithEmailAndPassword(
        email: 'test@emerge.com',
        password: 'password',
      );

      await authRepository.signOut();

      expect(
        authRepository.user,
        emitsInOrder([
          // We might need to handle the stream emission timing carefully
          // but for FakeAuthRepository it emits immediately on add
          AuthUser.empty,
        ]),
      );
    });
  });
}
