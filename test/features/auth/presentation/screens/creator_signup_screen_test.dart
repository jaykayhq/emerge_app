import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/screens/creator_signup_screen.dart';
import 'package:emerge_app/features/auth/presentation/widgets/password_requirement_checklist.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

Widget _buildTest({
  List<Override> overrides = const [],
  required GoRouter router,
}) {
  return ProviderScope(
    overrides: overrides,
    // Disable Riverpod's default retry mechanism so keepAlive FutureProviders
    // immediately surface errors as AsyncError (rather than AsyncLoading+retry).
    // This keeps tests fast and deterministic.
    retry: (count, error) => null,
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  late GoRouter router;

  setUp(() {
    router = GoRouter(
      initialLocation: '/signup',
      routes: [
        GoRoute(
          path: '/signup',
          builder: (context, state) => const CreatorSignUpScreen(),
        ),
        GoRoute(
          path: '/splash',
          builder: (context, state) => const Scaffold(
            body: Text('splash-page'),
          ),
        ),
        GoRoute(
          path: '/creator/dashboard',
          builder: (context, state) => const Scaffold(
            body: Text('dashboard-page'),
          ),
        ),
        GoRoute(
          path: '/creator/login',
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

  testWidgets('renders input fields and buttons', (tester) async {
    await setMobileViewport(tester);

    await tester.pumpWidget(_buildTest(router: router));
    await tester.pumpAndSettle();

    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Invite Code'), findsOneWidget);
    expect(find.text('Register as Creator'), findsOneWidget);
    expect(find.text('Sign up with Google'), findsOneWidget);
  });

  testWidgets('indicates the username must be unique at signup', (
    tester,
  ) async {
    await setMobileViewport(tester);

    await tester.pumpWidget(_buildTest(router: router));
    await tester.pumpAndSettle();

    expect(
      find.text('Must be unique — no one else can use it'),
      findsOneWidget,
    );
  });

  testWidgets('flags a username already in use while typing', (tester) async {
    await setMobileViewport(tester);

    final mockAuth = MockAuthRepository();
    when(() => mockAuth.checkUsernameAvailability(any())).thenAnswer(
      (_) async => right<Failure, bool>(false),
    );

    await tester.pumpWidget(
      _buildTest(
        overrides: [authRepositoryProvider.overrideWithValue(mockAuth)],
        router: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'takenuser');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('This username is already taken'), findsOneWidget);
  });

  testWidgets('shows validation on empty submit', (tester) async {
    await setMobileViewport(tester);

    await tester.pumpWidget(_buildTest(router: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Register as Creator'));
    await tester.pumpAndSettle();

    expect(find.text('Username is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('An invite code is required to become a creator'), findsOneWidget);
  });

  testWidgets('invite code field validates format', (tester) async {
    await setMobileViewport(tester);

    await tester.pumpWidget(_buildTest(router: router));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Invite Code'),
      'bad',
    );
    await tester.tap(find.text('Register as Creator'));
    await tester.pumpAndSettle();

    expect(find.text('Invite codes are 8 characters (A-Z, 2-9)'), findsOneWidget);
  });

  testWidgets('successful email signup navigates to splash', (tester) async {
    await setMobileViewport(tester);

    final mockAuth = MockAuthRepository();
    when(() => mockAuth.checkUsernameAvailability(any())).thenAnswer(
      (_) async => right<Failure, bool>(true),
    );

    final overrides = [
      signUpCreatorProvider('test@example.com', 'Str0ngP@sswd!', 'TestUser', 'ABCDEFGH')
          .overrideWith((ref) async {}),
      authRepositoryProvider.overrideWithValue(mockAuth),
    ];

    await tester.pumpWidget(_buildTest(overrides: overrides, router: router));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'TestUser');
    await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'Str0ngP@sswd!');
    await tester.enterText(find.byType(TextFormField).at(3), 'Str0ngP@sswd!');
    await tester.enterText(find.byType(TextFormField).at(4), 'ABCDEFGH');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Register as Creator'));
    await tester.pumpAndSettle();

    expect(find.text('splash-page'), findsOneWidget);
  });

  testWidgets('failed email signup shows error snackbar', (tester) async {
    await setMobileViewport(tester);

    final mockAuth = MockAuthRepository();
    when(() => mockAuth.checkUsernameAvailability(any())).thenAnswer(
      (_) async => right<Failure, bool>(true),
    );

    final overrides = [
      signUpCreatorProvider('test@example.com', 'Str0ngP@sswd!', 'TestUser', 'ABCDEFGH')
          .overrideWith((ref) async {
            await Future.value();
            throw Exception('Sign up failed');
          }),
      authRepositoryProvider.overrideWithValue(mockAuth),
    ];

    await tester.pumpWidget(_buildTest(overrides: overrides, router: router));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'TestUser');
    await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'Str0ngP@sswd!');
    await tester.enterText(find.byType(TextFormField).at(3), 'Str0ngP@sswd!');
    await tester.enterText(find.byType(TextFormField).at(4), 'ABCDEFGH');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Register as Creator'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Sign up failed'), findsOneWidget);
  });

  testWidgets('successful Google signup navigates to splash', (tester) async {
    await setMobileViewport(tester);

    final overrides = [
      signUpCreatorWithGoogleProvider('ABCDEFGH').overrideWith((ref) async {}),
    ];

    await tester.pumpWidget(_buildTest(overrides: overrides, router: router));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Invite Code'),
      'ABCDEFGH',
    );
    await tester.tap(find.text('Sign up with Google'));
    await tester.pumpAndSettle();

    expect(find.text('splash-page'), findsOneWidget);
  });

  testWidgets('failed Google signup shows error snackbar', (tester) async {
    await setMobileViewport(tester);

    final overrides = [
      signUpCreatorWithGoogleProvider('ABCDEFGH').overrideWith((ref) async {
        await Future<void>.value();
        throw Exception('Google sign-up failed');
      }),
    ];

    await tester.pumpWidget(_buildTest(overrides: overrides, router: router));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Invite Code'),
      'ABCDEFGH',
    );
    await tester.tap(find.text('Sign up with Google'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Google sign-up failed'), findsOneWidget);
  });

  testWidgets('errors appear only after interacting with a field',
      (tester) async {
    await setMobileViewport(tester);

    await tester.pumpWidget(_buildTest(router: router));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(0), 'ab');
    await tester.pumpAndSettle();
    expect(
      find.text('Username must be at least 3 characters long'),
      findsOneWidget,
    );
  });

  testWidgets('password checklist appears while typing, not on confirm field',
      (tester) async {
    await setMobileViewport(tester);

    await tester.pumpWidget(_buildTest(router: router));
    await tester.pumpAndSettle();

    expect(find.text('At least 12 characters'), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(2), 'abc');
    await tester.pumpAndSettle();
    expect(find.text('At least 12 characters'), findsOneWidget);

    // Confirm field gets real-time validation but never the checklist.
    await tester.enterText(find.byType(TextFormField).at(3), 'abc');
    await tester.pumpAndSettle();
    expect(find.byType(PasswordRequirementChecklist), findsOneWidget);
  });
}
