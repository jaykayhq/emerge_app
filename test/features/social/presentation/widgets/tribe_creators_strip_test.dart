import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_creators_strip.dart';

final _creator1 = CreatorProfile(
  userId: 'creator_1',
  displayName: 'Nova Prime',
  isVerifiedCreator: true,
  blueprintCount: 3,
);

final _creator2 = CreatorProfile(
  userId: 'creator_2',
  displayName: 'Vex',
  isVerifiedCreator: true,
  blueprintCount: 5,
);

final _creator3 = CreatorProfile(
  userId: 'creator_3',
  displayName: 'Lyra',
  isVerifiedCreator: true,
  blueprintCount: 2,
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
                builder: (_, _) => const Scaffold(
                  body: TribeCreatorsStrip(),
                ),
              ),
            ],
          ),
    ),
  );
}

void main() {
  testWidgets('empty creators renders "No creators discovered yet."',
      (tester) async {
    await tester.pumpWidget(
      buildTest(stream: Stream.value(<CreatorProfile>[])),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('No creators discovered yet.'), findsOneWidget);
    expect(find.text('CREATORS'), findsOneWidget);
  });

  testWidgets('populated renders horizontal ListView with N faces',
      (tester) async {
    await tester.pumpWidget(
      buildTest(
        stream: Stream.value(<CreatorProfile>[
          _creator1,
          _creator2,
          _creator3,
        ]),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(TribeCreatorsStrip), findsOneWidget);

    // Each creator's display name should appear in the strip.
    expect(find.text('Nova Prime'), findsOneWidget);
    expect(find.text('Vex'), findsOneWidget);
    expect(find.text('Lyra'), findsOneWidget);

    expect(find.text('CREATORS'), findsOneWidget);
    expect(find.text('View All →'), findsOneWidget);
  });

  testWidgets('tap on a creator face navigates to /social/creator/{userId}',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: TribeCreatorsStrip(),
          ),
        ),
        GoRoute(
          path: '/social/creator/:userId',
          builder: (context, state) {
            final uid = state.pathParameters['userId'];
            return Scaffold(
              body: Text('creator page: $uid'),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      buildTest(
        stream: Stream.value(<CreatorProfile>[_creator1, _creator2]),
        router: router,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Tap on the first creator face by finding its display name widget.
    await tester.tap(find.text('Nova Prime'));
    await tester.pumpAndSettle();

    expect(find.text('creator page: creator_1'), findsOneWidget);
  });
}


