import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_dashboard_scaffold.dart';
import 'package:emerge_app/features/auth/presentation/providers/creator_auth_provider.dart';

Widget _buildTest() {
  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ProviderScope(
            overrides: [
              isVerifiedCreatorProvider.overrideWith(
                (ref) => Future.value(true),
              ),
            ],
            child: CreatorDashboardScaffold(navigationShell: navigationShell),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/dashboard', builder: (_, _) => const SizedBox()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard/blueprints',
                builder: (_, _) => const SizedBox(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard/tribe',
                builder: (_, _) => const SizedBox(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

/// Harness with a manual [Completer] so the verification state can be held
/// in loading and completed later (fresh redeem → profile resolves late).
Widget _buildTestWithCompleter(Completer<bool> completer) {
  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ProviderScope(
            overrides: [
              isVerifiedCreatorProvider.overrideWith((ref) => completer.future),
            ],
            child: CreatorDashboardScaffold(navigationShell: navigationShell),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/dashboard', builder: (_, _) => const SizedBox()),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/creator/login',
        builder: (_, _) => const Scaffold(body: Text('login-page')),
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

void main() {
  testWidgets('CreatorDashboardScaffold renders with navigation', (
    tester,
  ) async {
    await tester.pumpWidget(_buildTest());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CreatorDashboardScaffold), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Blueprints'), findsOneWidget);
    expect(find.text('Tribe'), findsOneWidget);
  });

  testWidgets('does not redirect while verification is loading', (
    tester,
  ) async {
    final completer = Completer<bool>();
    await tester.pumpWidget(_buildTestWithCompleter(completer));
    await tester.pump(const Duration(milliseconds: 100));

    // Still on the dashboard while the profile read is in flight.
    expect(find.byType(CreatorDashboardScaffold), findsOneWidget);
    expect(find.text('login-page'), findsNothing);

    // Completing with false redirects to the creator login.
    completer.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('login-page'), findsOneWidget);
  });
}
