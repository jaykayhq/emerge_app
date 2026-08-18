import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/data/services/tribe_stats_service.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/domain/services/tribe_membership_service.dart';
import 'package:emerge_app/features/social/presentation/providers/cached_tribe_stats_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockTribeMembershipService extends Mock
    implements TribeMembershipService {}

class MockTribeStatsService extends Mock implements TribeStatsService {}

void main() {
  final emptyUser = const AuthUser(id: '', email: '');

  final tribe = Tribe(
    id: 'morning_warriors',
    name: 'Morning Warriors',
    description: 'Early risers unite',
    imageUrl: '',
    memberCount: 100,
    ownerId: '',
    tags: [],
    levelRequirement: 0,
    rank: 1,
    totalXp: 5000,
    archetypeId: 'athlete',
    members: const [''],
  );

  final unjoinedTribe = Tribe(
    id: 'morning_warriors',
    name: 'Morning Warriors',
    description: 'Early risers unite',
    imageUrl: '',
    memberCount: 100,
    ownerId: '',
    tags: [],
    levelRequirement: 0,
    rank: 1,
    totalXp: 5000,
    archetypeId: 'athlete',
  );

  Widget buildTest({
    Tribe? cardTribe,
    MockTribeMembershipService? membership,
    MockTribeStatsService? stats,
  }) {
    final membershipService = membership ?? MockTribeMembershipService();
    final statsService = stats ?? MockTribeStatsService();
    final t = cardTribe ?? tribe;
    return ProviderScope(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => Stream.value(emptyUser)),
        cachedTribeStatsProvider(t.id).overrideWith((ref) {
          return Stream.value(
            TribeStats(
              memberCount: 100,
              totalXp: 5000,
              totalHabitsCompleted: 50,
              totalChallengesCompleted: 10,
            ),
          );
        }),
        tribeMembershipServiceProvider.overrideWithValue(membershipService),
        tribeStatsServiceProvider.overrideWithValue(statsService),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, state) => Scaffold(body: TribeCard(tribe: t)),
            ),
            GoRoute(
              path: '/social/tribe/:id',
              builder: (_, state) => Scaffold(
                body: Center(
                  child: Text('TRIBE_DETAIL:${state.pathParameters['id']}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets(
    'tapping a TribeCard navigates into that club (/social/tribe/:id)',
    (tester) async {
      await tester.pumpWidget(buildTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap the card body (the emblem/info area), not the JOIN button.
      await tester.tap(find.text('MORNING WARRIORS'));
      await tester.pumpAndSettle();

      expect(find.text('TRIBE_DETAIL:morning_warriors'), findsOneWidget);
    },
  );

  testWidgets('leave dialog says contributions stay on the tribe record', (
    tester,
  ) async {
    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('LEAVE'));
    await tester.pumpAndSettle();

    // The mandated D2 copy (plan verbatim): "Your streak progress stays, and
    // your contributions remain on the tribe's record." The plan's sketch
    // needle ('contributions stay') is not a substring of that sentence.
    expect(find.textContaining('streak progress stays'), findsOneWidget);
    expect(find.textContaining("tribe's record"), findsOneWidget);
    expect(find.textContaining('lose your'), findsNothing);
  });

  testWidgets('leaving does not call syncTribeStats — membership only', (
    tester,
  ) async {
    final membershipService = MockTribeMembershipService();
    final statsService = MockTribeStatsService();
    when(
      () => membershipService.leaveTribe(any()),
    ).thenAnswer((_) async => Right(null));

    await tester.pumpWidget(
      buildTest(membership: membershipService, stats: statsService),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('LEAVE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(find.text('Left tribe successfully'), findsOneWidget);
    verify(() => membershipService.leaveTribe('')).called(1);
    verifyNoMoreInteractions(membershipService);
    verifyZeroInteractions(statsService);
  });

  testWidgets('joining does not call syncTribeStats — membership only', (
    tester,
  ) async {
    final membershipService = MockTribeMembershipService();
    final statsService = MockTribeStatsService();
    when(
      () => membershipService.joinTribe(
        userId: any(named: 'userId'),
        tribeId: any(named: 'tribeId'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async => Right(null));

    await tester.pumpWidget(
      buildTest(
        cardTribe: unjoinedTribe,
        membership: membershipService,
        stats: statsService,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('JOIN'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Joined Morning Warriors!'), findsOneWidget);
    verify(
      () => membershipService.joinTribe(
        userId: '',
        tribeId: 'morning_warriors',
        type: 'archetype',
      ),
    ).called(1);
    verifyNoMoreInteractions(membershipService);
    verifyZeroInteractions(statsService);
  });
}
