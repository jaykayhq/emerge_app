import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/screens/creator_signup_screen.dart';

Widget _buildTest({
  List<Override> overrides = const [],
  required GoRouter router,
}) {
  return ProviderScope(
    overrides: overrides,
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
          path: '/creator/verify-email',
          builder: (context, state) => const Scaffold(
            body: Text('verify-email-page'),
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
    expect(find.text('Register as Creator'), findsOneWidget);
    expect(find.text('Sign up with Google'), findsOneWidget);
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
  });

  testWidgets('successful email signup redirects to verify email screen', (tester) async {
    await setMobileViewport(tester);

    final overrides = [
      signUpCreatorProvider('test@example.com', 'Str0ngP@sswd!', 'TestUser')
          .overrideWith((ref) async {}),
    ];

    await tester.pumpWidget(_buildTest(overrides: overrides, router: router));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'TestUser');
    await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'Str0ngP@sswd!');
    await tester.enterText(find.byType(TextFormField).at(3), 'Str0ngP@sswd!');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Register as Creator'));
    await tester.pumpAndSettle();

    expect(find.text('verify-email-page'), findsOneWidget);
  });

  testWidgets('failed email signup shows error snackbar', (tester) async {
    await setMobileViewport(tester);

    final overrides = [
      signUpCreatorProvider('test@example.com', 'Str0ngP@sswd!', 'TestUser')
          .overrideWith((ref) async {
            await Future.value();
            throw Exception('Sign up failed');
          }),
    ];

    await tester.pumpWidget(_buildTest(overrides: overrides, router: router));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'TestUser');
    await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'Str0ngP@sswd!');
    await tester.enterText(find.byType(TextFormField).at(3), 'Str0ngP@sswd!');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Register as Creator'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Sign up failed'), findsOneWidget);
  });

  testWidgets('successful Google signup redirects to dashboard screen', (tester) async {
    await setMobileViewport(tester);

    final overrides = [
      signUpCreatorWithGoogleProvider.overrideWith((ref) async {}),
    ];

    await tester.pumpWidget(_buildTest(overrides: overrides, router: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign up with Google'));
    await tester.pumpAndSettle();

    expect(find.text('dashboard-page'), findsOneWidget);
  });

  testWidgets('failed Google signup shows error snackbar', (tester) async {
    await setMobileViewport(tester);

    final overrides = [
      signUpCreatorWithGoogleProvider.overrideWith((ref) async {
        await Future.value();
        throw Exception('Google sign-up failed');
      }),
    ];

    await tester.pumpWidget(_buildTest(overrides: overrides, router: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign up with Google'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Google sign-up failed'), findsOneWidget);
  });
}
