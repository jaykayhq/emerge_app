import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/screens/creator_login_screen.dart';
import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import '../../../../helpers/mocks/auth_mocks.dart';

class MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}
class MockUser extends Mock implements firebase_auth.User {}

late GoRouter router;
late MockAuthRepository mockAuth;
late MockFirebaseAuth mockFirebaseAuth;
late MockUser mockUser;

Widget _buildTest(
  AuthRepository repo, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
      isCreatorProvider('test-uid').overrideWith((ref) async => true),
      ...overrides,
    ],
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  setUp(() {
    mockAuth = MockAuthRepository();
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();

    when(() => mockAuth.user).thenAnswer((_) => const Stream.empty());
    when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('test-uid');

    router = GoRouter(
      initialLocation: '/creator/login',
      routes: [
        GoRoute(
          path: '/creator/login',
          builder: (context, state) => const CreatorLoginScreen(),
        ),
        GoRoute(
          path: '/creator/dashboard',
          builder: (context, state) => const Scaffold(
            body: Text('dashboard-page'),
          ),
        ),
        GoRoute(
          path: '/creator/signup',
          builder: (context, state) => const Scaffold(
            body: Text('signup-page'),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(
            body: Text('login-page'),
          ),
        ),
      ],
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

  testWidgets('renders email and password fields', (tester) async {
    await setMobileViewport(tester);

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login to Creator Hub'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
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

  testWidgets('logging in as a non-creator signs out and shows snackbar', (tester) async {
    await setMobileViewport(tester);

    when(() => mockUser.uid).thenReturn('non-creator-uid');
    when(() => mockAuth.signInWithEmailAndPassword(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenAnswer((_) async => right(testAuthUser));
    when(() => mockAuth.signOut()).thenAnswer((_) async {});

    await tester.pumpWidget(_buildTest(
      mockAuth,
      overrides: [
        isCreatorProvider('non-creator-uid').overrideWith((ref) async => false),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login to Creator Hub'));
    await tester.pumpAndSettle();

    verify(() => mockAuth.signOut()).called(1);
    expect(find.text('This account is not registered as a creator. Please log out or switch accounts.'), findsOneWidget);
  });

  testWidgets('logging in as a creator redirects to dashboard', (tester) async {
    await setMobileViewport(tester);

    when(() => mockUser.uid).thenReturn('creator-uid');
    when(() => mockAuth.signInWithEmailAndPassword(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenAnswer((_) async => right(testAuthUser));

    await tester.pumpWidget(_buildTest(
      mockAuth,
      overrides: [
        isCreatorProvider('creator-uid').overrideWith((ref) async => true),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login to Creator Hub'));
    await tester.pumpAndSettle();

    expect(find.text('dashboard-page'), findsOneWidget);
  });

  testWidgets('Google sign-in success redirects to dashboard', (tester) async {
    await setMobileViewport(tester);

    when(() => mockAuth.signInWithGoogle(isLogin: true))
        .thenAnswer((_) async => right(testAuthUser));

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();

    expect(find.text('dashboard-page'), findsOneWidget);
  });

  testWidgets('Google sign-in failure shows snackbar', (tester) async {
    await setMobileViewport(tester);

    when(() => mockAuth.signInWithGoogle(isLogin: true))
        .thenAnswer((_) async => left(AuthFailure('Google sign-in failed')));

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Google sign-in failed'), findsOneWidget);
  });

  testWidgets('tapping Sign Up link navigates to creator signup page', (tester) async {
    await setMobileViewport(tester);

    await tester.pumpWidget(_buildTest(mockAuth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    expect(find.text('signup-page'), findsOneWidget);
  });
}
