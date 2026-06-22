import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import '../../../../helpers/widget_test_utils.dart';
import '../../../../helpers/mocks/auth_mocks.dart';

Widget _buildTest(AuthRepository repo) {
  return createScreenUnderTest(
    screen: const SignUpScreen(),
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

  testWidgets('renders form fields and sign up button', (tester) async {
    await setMobileViewport(tester);

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });

  testWidgets('shows validation on empty submit', (tester) async {
    await setMobileViewport(tester);

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    expect(find.text('Username is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Please confirm your password'), findsOneWidget);
  });

  testWidgets('shows loading during submission', (tester) async {
    await setMobileViewport(tester);

    final completer = Completer<Either<Failure, AuthUser>>();
    when(() => mockAuth.signUpWithEmailAndPassword(
      email: any(named: 'email'),
      password: any(named: 'password'),
      username: any(named: 'username'),
    )).thenAnswer((_) async => completer.future);

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'TestUser');
    await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'Str0ngP@sswd!');
    await tester.enterText(find.byType(TextFormField).at(3), 'Str0ngP@sswd!');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign Up'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(right<Failure, AuthUser>(testAuthUser));
    await tester.pumpAndSettle();
  });

  testWidgets('shows error on auth failure', (tester) async {
    await setMobileViewport(tester);

    when(() => mockAuth.signUpWithEmailAndPassword(
      email: any(named: 'email'),
      password: any(named: 'password'),
      username: any(named: 'username'),
    )).thenAnswer((_) async => left(AuthFailure('Email already in use')));

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'TestUser');
    await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'Str0ngP@sswd!');
    await tester.enterText(find.byType(TextFormField).at(3), 'Str0ngP@sswd!');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
  });
}
