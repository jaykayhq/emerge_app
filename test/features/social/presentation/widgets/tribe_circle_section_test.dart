import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:emerge_app/features/social/presentation/providers/friend_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_circle_section.dart';

Widget buildTest({
  List<Friend> partners = const [],
  List<PartnerRequest> requests = const [],
  int contractCount = 0,
}) {
  return ProviderScope(
    overrides: [
      partnersListStreamProvider.overrideWith((ref) => Stream.value(partners)),
      pendingPartnerRequestsStreamProvider
          .overrideWith((ref) => Stream.value(requests)),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(
              body: SingleChildScrollView(child: TribeCircleSection()),
            ),
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

Friend _friend(String id, String name) => Friend(
      id: id,
      name: name,
      archetype: FriendArchetype.creator,
    );

void main() {
  testWidgets('header reads YOUR CIRCLE', (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('YOUR CIRCLE'), findsOneWidget);
  });

  testWidgets('renders partner avatars', (tester) async {
    await tester.pumpWidget(buildTest(partners: [
      _friend('p1', 'Alex'),
      _friend('p2', 'Sam'),
    ]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget);
  });

  testWidgets('shows request badge when requests pending', (tester) async {
    await tester.pumpWidget(buildTest(
      requests: [
        PartnerRequest(
          id: 'r1',
          senderId: 's1',
          senderName: 'Pat',
          senderArchetype: 'creator',
          senderLevel: 1,
          recipientId: 'me',
          status: 'pending',
          createdAt: DateTime.now(),
        ),
      ],
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // The badge shows the request count as text "1".
    expect(find.text('1'), findsWidgets);
  });
}
