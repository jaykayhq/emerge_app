import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/screens/login_screen.dart';
import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import '../../../../helpers/widget_test_utils.dart';
import '../../../../helpers/mocks/auth_mocks.dart';

class MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}
class MockUser extends Mock implements firebase_auth.User {}

late MockFirebaseAuth mockFirebaseAuth;
late MockUser mockUser;

Widget _buildTest(
  AuthRepository repo, {
  List<Override> overrides = const [],
}) {
  return createScreenUnderTest(
    screen: const LoginScreen(),
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
      isNormalUserProvider('test-uid').overrideWith((ref) async => true),
      ...overrides,
    ],
  );
}

void main() {
  late MockAuthRepository mockAuth;

  setUp(() {
    mockAuth = MockAuthRepository();
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    
    when(() => mockAuth.user).thenAnswer((_) => const Stream.empty());
    when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('test-uid');
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
    expect(find.text('Login'), findsWidgets);
  });

  testWidgets('shows validation on empty submit', (tester) async {
    await setMobileViewport(tester);

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login').last);
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

    await tester.tap(find.text('Login').last);
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

    await tester.tap(find.text('Login').last);
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('logging in as a creator/non-normal user signs out and shows snackbar', (tester) async {
    await setMobileViewport(tester);

    when(() => mockUser.uid).thenReturn('creator-uid');
    when(() => mockAuth.signInWithEmailAndPassword(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenAnswer((_) async => right(testAuthUser));
    when(() => mockAuth.signOut()).thenAnswer((_) async {});

    await tester.pumpWidget(_buildTest(
      mockAuth,
      overrides: [
        isNormalUserProvider('creator-uid').overrideWith((ref) async {
          await Future.value();
          return false;
        }),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'creator@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login').last);
    await tester.pumpAndSettle();

    verify(() => mockAuth.signOut()).called(1);
    expect(find.text('This is a creator account. Please log in through the Creator Hub.'), findsOneWidget);
  });

  testWidgets('Google Sign-In with a creator account signs out and shows snackbar', (tester) async {
    await setMobileViewport(tester);

    when(() => mockUser.uid).thenReturn('creator-uid');
    when(() => mockAuth.signInWithGoogle(isLogin: true)).thenAnswer((_) async => right(testAuthUser));
    when(() => mockAuth.signOut()).thenAnswer((_) async {});

    await tester.pumpWidget(_buildTest(
      mockAuth,
      overrides: [
        isNormalUserProvider('creator-uid').overrideWith((ref) async {
          await Future.value();
          return false;
        }),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();

    verify(() => mockAuth.signOut()).called(1);
    expect(find.text('This is a creator account. Please log in through the Creator Hub.'), findsOneWidget);
  });
}
