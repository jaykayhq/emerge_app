import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:emerge_app/features/auth/presentation/widgets/password_requirement_checklist.dart';
import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import '../../../../helpers/widget_test_utils.dart';
import '../../../../helpers/mocks/auth_mocks.dart';

Widget _buildTest(AuthRepository repo) {
  return createScreenUnderTest(
    screen: const SignUpScreen(),
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
  );
}

void main() {
  late MockAuthRepository mockAuth;

  setUp(() {
    mockAuth = MockAuthRepository();
    when(() => mockAuth.user).thenAnswer((_) => const Stream.empty());
    when(() => mockAuth.checkUsernameAvailability(any())).thenAnswer(
      (_) async => right<Failure, bool>(true),
    );
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

  testWidgets('indicates the username must be unique at signup', (
    tester,
  ) async {
    await setMobileViewport(tester);

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    expect(
      find.text('Must be unique — no one else can use it'),
      findsOneWidget,
      reason: 'signup must tell users the username is unique per account',
    );
  });

  testWidgets('flags a username already in use while typing', (tester) async {
    await setMobileViewport(tester);

    when(() => mockAuth.checkUsernameAvailability('takenuser'))
        .thenAnswer((_) async => right<Failure, bool>(false));

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'takenuser');
    await tester.pump();
    // No error before the debounce window elapses.
    expect(find.text('This username is already taken'), findsNothing);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(
      find.text('This username is already taken'),
      findsOneWidget,
      reason: 'typing a claimed username must surface the conflict',
    );
    verify(() => mockAuth.checkUsernameAvailability('takenuser')).called(1);
  });

  testWidgets('clears the conflict error once the username is free again', (
    tester,
  ) async {
    await setMobileViewport(tester);

    when(() => mockAuth.checkUsernameAvailability('takenuser'))
        .thenAnswer((_) async => right<Failure, bool>(false));

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'takenuser');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('This username is already taken'), findsOneWidget);

    // Editing the name clears the stale conflict; the new probe says free.
    when(() => mockAuth.checkUsernameAvailability('takenuser2'))
        .thenAnswer((_) async => right<Failure, bool>(true));
    await tester.enterText(find.byType(TextFormField).at(0), 'takenuser2');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('This username is already taken'), findsNothing);
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
    when(
      () => mockAuth.signUpWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
        username: any(named: 'username'),
      ),
    ).thenAnswer((_) async => completer.future);

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'TestUser');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'Str0ngP@sswd!');
    await tester.enterText(find.byType(TextFormField).at(3), 'Str0ngP@sswd!');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign Up'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(right<Failure, AuthUser>(testAuthUser));
    await tester.pumpAndSettle();
  });

  testWidgets('unverified signup calls the repository and does not crash', (
    tester,
  ) async {
    await setMobileViewport(tester);
    when(
      () => mockAuth.signUpWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
        username: any(named: 'username'),
      ),
    ).thenAnswer(
      (_) async => right<Failure, AuthUser>(
        AuthUser(id: 'u1', email: 't@example.com', displayName: 'TestUser'),
      ),
    );

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'TestUser');
    await tester.enterText(find.byType(TextFormField).at(1), 't@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'Str0ngP@sswd!');
    await tester.enterText(find.byType(TextFormField).at(3), 'Str0ngP@sswd!');
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    verify(
      () => mockAuth.signUpWithEmailAndPassword(
        email: 't@example.com',
        password: 'Str0ngP@sswd!',
        username: 'TestUser',
      ),
    ).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows error on auth failure', (tester) async {
    await setMobileViewport(tester);

    when(
      () => mockAuth.signUpWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
        username: any(named: 'username'),
      ),
    ).thenAnswer((_) async => left(AuthFailure('Email already in use')));

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'TestUser');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'Str0ngP@sswd!');
    await tester.enterText(find.byType(TextFormField).at(3), 'Str0ngP@sswd!');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('errors appear only after interacting with a field', (
    tester,
  ) async {
    await setMobileViewport(tester);

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    // Untouched fields must not show errors on first frame.
    expect(find.text('Email is required'), findsNothing);
    expect(find.text('Username is required'), findsNothing);

    // Typing invalid text then leaving the field surfaces the error.
    await tester.enterText(find.byType(TextFormField).at(0), 'ab');
    await tester.pumpAndSettle();
    expect(find.text('Username is required'), findsNothing);
    expect(
      find.text('Username must be at least 3 characters long'),
      findsOneWidget,
    );
  });

  testWidgets('password checklist appears while typing, not on confirm field', (
    tester,
  ) async {
    await setMobileViewport(tester);

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    expect(find.text('At least 12 characters'), findsNothing);

    // Typing into the password field shows the checklist.
    await tester.enterText(find.byType(TextFormField).at(2), 'abc');
    await tester.pumpAndSettle();
    expect(find.text('At least 12 characters'), findsOneWidget);

    // Typing into the confirm field must NOT show the checklist — the
    // widget is attached only to the password field.
    await tester.enterText(find.byType(TextFormField).at(3), 'abc');
    await tester.pumpAndSettle();
    expect(find.byType(PasswordRequirementChecklist), findsOneWidget);
    expect(find.text('Password looks good'), findsNothing);
  });
}
