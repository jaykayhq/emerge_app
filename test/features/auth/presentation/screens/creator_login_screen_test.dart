import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/screens/creator_login_screen.dart';
import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import '../../../../helpers/widget_test_utils.dart';
import '../../../../helpers/mocks/auth_mocks.dart';

Widget _buildTest(AuthRepository repo) {
  return createScreenUnderTest(
    screen: const CreatorLoginScreen(),
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

void main() {
  late MockAuthRepository mockAuth;

  setUp(() {
    mockAuth = MockAuthRepository();
    when(() => mockAuth.user).thenAnswer((_) => const Stream.empty());
  });

  Future<void> setMobileViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('renders email and password fields', (tester) async {
    await setMobileViewport(tester);

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login to Creator Hub'), findsOneWidget);
  });

  testWidgets('shows validation on empty submit', (tester) async {
    await setMobileViewport(tester);

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login to Creator Hub'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('shows loading during submission', (tester) async {
    await setMobileViewport(tester);

    final completer = Completer<Either<Failure, AuthUser>>();
    when(() => mockAuth.signInWithEmailAndPassword(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenAnswer((_) async => completer.future);

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login to Creator Hub'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(right<Failure, AuthUser>(testAuthUser));
    await tester.pumpAndSettle();
  });

  testWidgets('shows error on auth failure', (tester) async {
    await setMobileViewport(tester);

    when(() => mockAuth.signInWithEmailAndPassword(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenAnswer((_) async => left(AuthFailure('Invalid credentials')));

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'wrong');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login to Creator Hub'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
  });
}
