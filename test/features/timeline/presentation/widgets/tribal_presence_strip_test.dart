import 'package:emerge_app/features/timeline/presentation/widgets/tribal_presence_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('shows honest member-count message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TribalPresenceStrip(memberCount: 3)),
      ),
    );

    expect(find.text('Tribe: 3 members strong'), findsOneWidget);
  });

  testWidgets('tapping navigates to /social', (tester) async {
    String? visited;
    final router = GoRouter(
      initialLocation: '/timeline',
      routes: [
        GoRoute(
          path: '/timeline',
          builder: (_, _) =>
              const Scaffold(body: TribalPresenceStrip(memberCount: 5)),
        ),
        GoRoute(
          path: '/social',
          builder: (_, _) {
            visited = '/social';
            return const Scaffold(body: Text('social'));
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    expect(visited, '/social');
  });
}
