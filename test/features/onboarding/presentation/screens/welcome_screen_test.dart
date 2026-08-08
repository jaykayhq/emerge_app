import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import '../../../../helpers/widget_test_utils.dart';

class _FakeAuthRepo implements AuthRepository {
  _FakeAuthRepo(this.gate);

  final Completer<Either<Failure, AuthUser>> gate;

  @override
  Stream<AuthUser> get user => const Stream.empty();

  @override
  Future<Either<Failure, AuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async =>
      const Left<Failure, AuthUser>(AuthFailure());

  @override
  Future<Either<Failure, AuthUser>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  }) async =>
      const Left<Failure, AuthUser>(AuthFailure());

  @override
  Future<Either<Failure, AuthUser>> signInWithGoogle({bool isLogin = false}) =>
      gate.future;

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async =>
      const Left<Failure, void>(AuthFailure());

  @override
  Future<void> signOut() async {}

  @override
  Future<Either<Failure, void>> updateDisplayName(String displayName) async =>
      const Left<Failure, void>(AuthFailure());

  @override
  Future<Either<Failure, void>> deleteAccount() async =>
      const Left<Failure, void>(AuthFailure());

  @override
  Future<Either<Failure, void>> sendEmailVerificationCode() async =>
      const Right<Failure, void>(null);

  @override
  Future<Either<Failure, void>> verifyEmailCode(String code) async =>
      const Right<Failure, void>(null);

  @override
  Future<Either<Failure, void>> claimUsername(String username) async =>
      const Right<Failure, void>(null);

  @override
  Future<Either<Failure, bool>> checkEmailVerified() async =>
      const Right<Failure, bool>(false);
}

Widget _buildTest() {
  return createScreenUnderTest(screen: const WelcomeScreen());
}

void main() {
  testWidgets('renders without crash', (tester) async {
    await tester.pumpWidget(_buildTest());
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('displays title and welcome text', (tester) async {
    await tester.pumpWidget(_buildTest());
    await tester.pumpAndSettle();

    expect(find.text('Who do you wish to become?'), findsOneWidget);
    expect(find.text('Forge Your Identity. Build Your Habits.'), findsOneWidget);
  });

  testWidgets('get started button renders and is tappable', (tester) async {
    await tester.pumpWidget(_buildTest());
    await tester.pumpAndSettle();

    final button = find.ancestor(
      of: find.text('Begin Your Journey'),
      matching: find.byType(ElevatedButton),
    );
    expect(button, findsOneWidget);
    final ElevatedButton buttonWidget = tester.widget(button);
    expect(buttonWidget.onPressed, isNotNull);
  });

  testWidgets(
    'google sign-in that resolves after the screen unmounts does not crash',
    (tester) async {
      // Regression: the Continue button awaited signInWithGoogle and then
      // called GoRouter.of(context) in the success branch. If the screen was
      // unmounted while the request was in flight, that context was defunct
      // and the lookup threw.
      final gate = Completer<Either<Failure, AuthUser>>();
      final router = GoRouter(
        initialLocation: '/welcome',
        routes: [
          GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
          GoRoute(
            path: '/signup',
            builder: (_, _) => const Scaffold(body: Text('signup page')),
          ),
          GoRoute(
            path: '/world-map',
            builder: (_, _) => const Scaffold(body: Text('world map')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepo(gate)),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue with Google'));
      await tester.pump();

      // Leave the screen while the sign-in request is still in flight.
      router.go('/signup');
      await tester.pumpAndSettle();

      gate.complete(const Right(AuthUser(id: 'u1', email: 'e')));
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );
}
