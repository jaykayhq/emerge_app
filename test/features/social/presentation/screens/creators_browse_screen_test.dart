import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/creators_browse_screen.dart';

final _creatorA = CreatorProfile(
  userId: 'creator_a',
  displayName: 'Aurora',
  isVerifiedCreator: true,
  blueprintCount: 4,
);

final _creatorB = CreatorProfile(
  userId: 'creator_b',
  displayName: 'Borealis',
  isVerifiedCreator: true,
  blueprintCount: 1,
);

Widget buildTest({
  Stream<List<CreatorProfile>>? stream,
  GoRouter? router,
}) {
  return ProviderScope(
    overrides: [
      verifiedCreatorsStreamProvider.overrideWith(
        (ref) => stream ?? const Stream.empty(),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router ??
          GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const CreatorsBrowseScreen(),
              ),
            ],
          ),
    ),
  );
}

void main() {
  testWidgets('loading state shows EmergeLoadingSkeleton', (tester) async {
    // Stream that never emits keeps the AsyncValue in loading.
    await tester.pumpWidget(buildTest());
    await tester.pump();

    expect(find.byType(EmergeLoadingSkeleton), findsOneWidget);
  });

  testWidgets('empty state shows "No creators yet"', (tester) async {
    await tester.pumpWidget(
      buildTest(stream: Stream.value(<CreatorProfile>[])),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('No creators yet'), findsOneWidget);
    expect(find.text('CREATORS'), findsOneWidget);
  });

  testWidgets('populated shows creator tiles with name and blueprint count',
      (tester) async {
    await tester.pumpWidget(
      buildTest(
        stream: Stream.value(<CreatorProfile>[_creatorA, _creatorB]),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Aurora'), findsOneWidget);
    expect(find.text('Borealis'), findsOneWidget);
    expect(find.text('4 blueprints'), findsOneWidget);
    expect(find.text('1 blueprint'), findsOneWidget);
  });

  testWidgets('tap a creator tile navigates to /social/creator/{userId}',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const CreatorsBrowseScreen(),
        ),
        GoRoute(
          path: '/social/creator/:userId',
          builder: (context, state) {
            final uid = state.pathParameters['userId'];
            return Scaffold(body: Text('creator page: $uid'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      buildTest(
        stream: Stream.value(<CreatorProfile>[_creatorA]),
        router: router,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Aurora'));
    await tester.pumpAndSettle();

    expect(find.text('creator page: creator_a'), findsOneWidget);
  });
}
