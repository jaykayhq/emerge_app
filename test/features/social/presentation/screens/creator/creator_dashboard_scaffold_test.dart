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
              GoRoute(
                path: '/dashboard',
                builder: (_, _) => const SizedBox(),
              ),
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

void main() {
  testWidgets('CreatorDashboardScaffold renders with navigation',
      (tester) async {
    await tester.pumpWidget(_buildTest());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CreatorDashboardScaffold), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Blueprints'), findsOneWidget);
    expect(find.text('Tribe'), findsOneWidget);
  });
}
