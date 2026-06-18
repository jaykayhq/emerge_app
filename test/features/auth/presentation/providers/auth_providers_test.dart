import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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

Future<bool> _readFirstBoolState(ProviderContainer container, dynamic provider) {
  final completer = Completer<bool>();
  final sub = container.listen<AsyncValue<bool>>(
    provider,
    (previous, next) {
      if (next is AsyncData<bool>) {
        if (!completer.isCompleted) {
          completer.complete(next.value);
        }
      } else if (next is AsyncError<bool>) {
        if (!completer.isCompleted) {
          completer.completeError(next.error, next.stackTrace);
        }
      }
    },
    fireImmediately: true,
  );
  completer.future.whenComplete(() => sub.close());
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

  group('role check providers', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('isNormalUserProvider returns true if users/{uid} document exists', () async {
      await fakeFirestore.collection('users').doc('user123').set({'name': 'Test User'});

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );

      final result = await container.read(isNormalUserProvider('user123').future);
      expect(result, isTrue);
      container.dispose();
    });

    test('isNormalUserProvider returns false if users/{uid} document does not exist', () async {
      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );

      final result = await container.read(isNormalUserProvider('user123').future);
      expect(result, isFalse);
      container.dispose();
    });

    test('isCreatorProvider returns true if creator_profiles/{uid} document exists', () async {
      await fakeFirestore.collection('creator_profiles').doc('creator123').set({'name': 'Test Creator'});

      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );

      final result = await container.read(isCreatorProvider('creator123').future);
      expect(result, isTrue);
      container.dispose();
    });

    test('isCreatorProvider returns false if creator_profiles/{uid} document does not exist', () async {
      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );

      final result = await container.read(isCreatorProvider('creator123').future);
      expect(result, isFalse);
      container.dispose();
    });

    test('isNormalUserProvider returns false immediately if uid is empty or whitespace', () async {
      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );

      expect(await container.read(isNormalUserProvider('').future), isFalse);
      expect(await container.read(isNormalUserProvider('   ').future), isFalse);
      container.dispose();
    });

    test('isCreatorProvider returns false immediately if uid is empty or whitespace', () async {
      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );

      expect(await container.read(isCreatorProvider('').future), isFalse);
      expect(await container.read(isCreatorProvider('   ').future), isFalse);
      container.dispose();
    });

    test('isCurrentNormalUserProvider returns true if logged in and users/{uid} doc exists', () async {
      await fakeFirestore.collection('users').doc('current123').set({'name': 'Current Normal'});

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => Stream.value(const AuthUser(id: 'current123', email: 'current@test.com'))),
          firestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );

      final result = await _readFirstBoolState(container, isCurrentNormalUserProvider);
      expect(result, isTrue);
      container.dispose();
    });

    test('isCurrentNormalUserProvider returns false if not logged in or users/{uid} doc does not exist', () async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => Stream.value(AuthUser.empty)),
          firestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );

      final result = await _readFirstBoolState(container, isCurrentNormalUserProvider);
      expect(result, isFalse);
      container.dispose();
    });

    test('isCurrentCreatorProvider returns true if logged in and creator_profiles/{uid} doc exists', () async {
      await fakeFirestore.collection('creator_profiles').doc('current123').set({'name': 'Current Creator'});

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => Stream.value(const AuthUser(id: 'current123', email: 'current@test.com'))),
          firestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );

      final result = await _readFirstBoolState(container, isCurrentCreatorProvider);
      expect(result, isTrue);
      container.dispose();
    });

    test('isCurrentCreatorProvider returns false if not logged in or creator_profiles/{uid} doc does not exist', () async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => Stream.value(AuthUser.empty)),
          firestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );

      final result = await _readFirstBoolState(container, isCurrentCreatorProvider);
      expect(result, isFalse);
      container.dispose();
    });
  });
}
