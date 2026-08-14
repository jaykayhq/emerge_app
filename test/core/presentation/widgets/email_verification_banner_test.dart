import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/presentation/widgets/email_verification_banner.dart';
import 'package:emerge_app/core/router/router.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/providers/role_provider.dart';


Widget _buildTest({
  AuthUser? authUser,
  DateTime? emailLockedAt,
  List<Override> overrides = const [],
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('app body')),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const Scaffold(body: Text('verify page')),
      ),
    ],
    initialLocation: '/',
  );
  return ProviderScope(
    overrides: [
      authStateChangesProvider.overrideWith(
        (ref) => Stream<AuthUser>.value(authUser ?? AuthUser.empty),
      ),
      currentEmailLockedAtProvider
          .overrideWith((ref) async => emailLockedAt),
      routerProvider.overrideWithValue(router),
      ...overrides,
    ],
    // MaterialApp.router attaches the GoRouter to a Navigator so
    // router.state reflects the live route (the banner reads it).
    child: MaterialApp.router(
      routerConfig: router,
      builder: (context, child) =>
          EmailVerificationBanner(child: child ?? const SizedBox.shrink()),
    ),
  );
}

const unverifiedUser = AuthUser(id: 'u1', email: 'u@example.com');

void main() {
  testWidgets('hidden when signed out', (tester) async {
    await tester.pumpWidget(_buildTest(authUser: null));
    await tester.pumpAndSettle();
    expect(find.textContaining('Verify your email'), findsNothing);
    expect(find.text('app body'), findsOneWidget);
  });

  testWidgets('hidden when the email is verified', (tester) async {
    await tester.pumpWidget(
      _buildTest(
        authUser: const AuthUser(id: 'u1', email: 'u@example.com',
            emailVerified: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Verify your email'), findsNothing);
  });

  testWidgets('shown for an unverified user within the grace period',
      (tester) async {
    await tester.pumpWidget(_buildTest(authUser: unverifiedUser));
    await tester.pumpAndSettle();
    expect(find.textContaining('Verify your email'), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
  });

  testWidgets('hidden once locked — the full-screen lock takes over',
      (tester) async {
    await tester.pumpWidget(
      _buildTest(authUser: unverifiedUser, emailLockedAt: DateTime(2026, 1, 8)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Verify your email'), findsNothing);
  });

  testWidgets('dismiss hides the banner for the session', (tester) async {
    await tester.pumpWidget(_buildTest(authUser: unverifiedUser));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.textContaining('Verify your email'), findsNothing);
    expect(find.text('app body'), findsOneWidget);
  });
}
