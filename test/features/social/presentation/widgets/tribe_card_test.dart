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
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockTribeMembershipService extends Mock implements TribeMembershipService {}

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
  );

  Widget buildTest() {
    return ProviderScope(
      overrides: [
        authStateChangesProvider
            .overrideWith((ref) => Stream.value(emptyUser)),
        cachedTribeStatsProvider('morning_warriors').overrideWith((ref) {
          return Stream.value(TribeStats(
            memberCount: 100,
            totalXp: 5000,
            totalHabitsCompleted: 50,
            totalChallengesCompleted: 10,
          ));
        }),
        tribeMembershipServiceProvider
            .overrideWithValue(MockTribeMembershipService()),
        tribeStatsServiceProvider.overrideWithValue(MockTribeStatsService()),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, state) => Scaffold(body: TribeCard(tribe: tribe)),
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
  });
}
