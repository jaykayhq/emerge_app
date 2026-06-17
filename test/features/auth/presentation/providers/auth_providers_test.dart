import 'dart:async';

import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

ProviderContainer _makeContainer({
  required AuthRepository repo,
  Stream<AuthUser>? userStream,
}) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      if (userStream != null)
        authStateChangesProvider.overrideWith((ref) => userStream),
    ],
  );
}

Future<AuthUser> _readFirstAuthState(ProviderContainer container) {
  final completer = Completer<AuthUser>();
  container.listen<AsyncValue<AuthUser>>(
    authStateChangesProvider,
    (previous, next) {
      if (next is AsyncData<AuthUser>) {
        completer.complete(next.value);
      }
    },
    fireImmediately: true,
  );
  return completer.future;
}

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  group('authStateChangesProvider', () {
    test('emits user stream from repository', () async {
      when(() => mockRepo.user).thenAnswer(
        (_) => Stream.value(
          const AuthUser(id: 'test', email: 'test@example.com'),
        ),
      );

      final container = _makeContainer(repo: mockRepo);
      final result = await _readFirstAuthState(container);
      expect(result.id, 'test');
      expect(result.email, 'test@example.com');
      container.dispose();
    });

    test('emits anonymous when repo emits empty', () async {
      when(() => mockRepo.user).thenAnswer(
        (_) => Stream.value(AuthUser.empty),
      );

      final container = _makeContainer(repo: mockRepo);
      final result = await _readFirstAuthState(container);
      expect(result.isEmpty, true);
      container.dispose();
    });
  });

  group('signInProvider', () {
    test('calls repository signInWithEmailAndPassword', () async {
      when(() => mockRepo.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer(
        (_) async => Right(
          const AuthUser(id: 'test', email: 'test@test.com'),
        ),
      );

      final container = _makeContainer(repo: mockRepo);
      await container.read(signInProvider('test@test.com', 'password').future);
      verify(() => mockRepo.signInWithEmailAndPassword(
        email: 'test@test.com',
        password: any(named: 'password'),
      )).called(1);
      container.dispose();
    });

    test('throws on sign in failure', () async {
      when(() => mockRepo.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer(
        (_) async => Left(AuthFailure('Invalid credentials')),
      );

      final container = _makeContainer(repo: mockRepo);
      expect(
        () => container.read(signInProvider('bad@test.com', 'wrong').future),
        throwsA(isA<Exception>()),
      );
      container.dispose();
    });
  });

  group('signOutProvider', () {
    test('calls repository signOut', () async {
      when(() => mockRepo.signOut()).thenAnswer((_) async {});

      final container = _makeContainer(repo: mockRepo);
      await container.read(signOutProvider.future);
      verify(() => mockRepo.signOut()).called(1);
      container.dispose();
    });
  });
}
