import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_live_compact.dart';

final _testProfile = UserProfile(
  uid: 'test_user',
  displayName: 'Tester',
  archetype: UserArchetype.athlete,
);

Widget buildTest() {
  return ProviderScope(
    overrides: [
      clubActivityProvider.overrideWith(
        (ref, arg) => Stream.value([
          {
            'id': 'e1',
            'type': 'habit_complete',
            'userName': 'Alex',
            'data': {'habitTitle': 'Run'},
            'timestamp': DateTime.now().toUtc().toIso8601String(),
          },
        ]),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: TribeLiveCompact(
                clubId: 'c1',
                profile: _testProfile,
              ),
            ),
          ),
          GoRoute(
            path: '/social/activity',
            builder: (_, _) =>
                const Scaffold(body: Center(child: Text('ACTIVITY_SCREEN'))),
          ),
          GoRoute(
            path: '/social/accountability',
            builder: (_, _) =>
                const Scaffold(body: Center(child: Text('FRIENDS_SCREEN'))),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets(
      'View More navigates to /social/activity, not /social/accountability',
      (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.textContaining('View More'));
    await tester.pumpAndSettle();

    expect(find.text('ACTIVITY_SCREEN'), findsOneWidget);
    expect(find.text('FRIENDS_SCREEN'), findsNothing);
  });
}
