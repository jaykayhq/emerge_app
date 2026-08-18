import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/features/social/presentation/screens/leaderboard_screen.dart';
import 'package:emerge_app/features/social/presentation/providers/friends_leaderboard_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/leaderboard_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/domain/entities/leaderboard_entry.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

Tribe _tribe({List<String> members = const []}) {
  return Tribe(
    id: 'tribeA',
    name: 'Tribe A',
    description: '',
    imageUrl: '',
    memberCount: members.length,
    ownerId: 'owner',
    tags: const [],
    levelRequirement: 0,
    rank: 1,
    totalXp: 100,
    members: members,
  );
}

void main() {
  testWidgets('LeaderboardScreen renders loading skeletons', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userStatsStreamProvider.overrideWith((ref) => const Stream.empty()),
          friendsLeaderboardProvider.overrideWith(
            (ref) => const Stream.empty(),
          ),
          worldLeaderboardProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: const MaterialApp(home: LeaderboardScreen()),
      ),
    );

    await tester.pump();
    expect(find.byType(EmergeLoadingSkeleton), findsWidgets);
  });

  testWidgets('LeaderboardScreen renders tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendsLeaderboardProvider.overrideWith((ref) => Stream.value([])),
          userStatsStreamProvider.overrideWith(
            (ref) => Stream.value(const UserProfile(uid: '')),
          ),
          worldLeaderboardProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(home: LeaderboardScreen()),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('LEADERBOARD'), findsOneWidget);
    expect(find.text('FRIENDS'), findsOneWidget);
    expect(find.text('TRIBE'), findsOneWidget);
    expect(find.text('WORLD'), findsOneWidget);
  });

  testWidgets(
    'tribe leaderboard tab watches the ACTIVE tribe, not the archetype club',
    (tester) async {
      final profile = UserProfile(
        uid: 'user1',
        archetype: UserArchetype.athlete,
      );
      const tribeAEntry = LeaderboardEntry(
        userId: 'memberA',
        userName: 'Tribe A Member',
        xp: 100,
        level: 2,
        archetype: UserArchetype.athlete,
        rank: 1,
      );
      const archetypeEntry = LeaderboardEntry(
        userId: 'memberB',
        userName: 'Archetype Member',
        xp: 50,
        level: 1,
        archetype: UserArchetype.athlete,
        rank: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userStatsStreamProvider.overrideWith(
              (ref) => Stream.value(profile),
            ),
            activeMembershipProvider.overrideWith(
              (ref) => Stream.value(
                UserTribeTableData(
                  userId: 'user1',
                  tribeId: 'tribeA',
                  membershipType: 'member',
                  joinedAt: DateTime.now().toIso8601String(),
                  isActive: true,
                ),
              ),
            ),
            // Both candidate clubs are stubbed with distinguishable entries:
            // only the club the tab actually watches must render.
            clubLeaderboardProvider(
              'tribeA',
            ).overrideWith((ref) => Stream.value(const [tribeAEntry])),
            clubLeaderboardProvider(
              'morning_warriors',
            ).overrideWith((ref) => Stream.value(const [archetypeEntry])),
            userTribesProvider('user1').overrideWith(
              (ref) => Stream.value([
                _tribe(members: const ['memberA']),
              ]),
            ),
          ],
          child: const MaterialApp(home: LeaderboardScreen(initialTabIndex: 1)),
        ),
      );

      // userStats -> membership -> clubLeaderboard is a nested chain of
      // stream providers; each level needs a frame for its value to land.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(find.text('Tribe A Member'), findsOneWidget);
      expect(find.text('Archetype Member'), findsNothing);
    },
  );

  testWidgets('tribe leaderboard tab falls back to the archetype club without '
      'membership', (tester) async {
    const archetypeEntry = LeaderboardEntry(
      userId: 'memberB',
      userName: 'Archetype Member',
      xp: 50,
      level: 1,
      archetype: UserArchetype.athlete,
      rank: 1,
    );
    const tribeAEntry = LeaderboardEntry(
      userId: 'memberA',
      userName: 'Tribe A Member',
      xp: 100,
      level: 2,
      archetype: UserArchetype.athlete,
      rank: 1,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userStatsStreamProvider.overrideWith(
            (ref) => Stream.value(
              UserProfile(uid: 'user1', archetype: UserArchetype.athlete),
            ),
          ),
          activeMembershipProvider.overrideWith((ref) => Stream.value(null)),
          clubLeaderboardProvider(
            'tribeA',
          ).overrideWith((ref) => Stream.value(const [tribeAEntry])),
          clubLeaderboardProvider(
            'morning_warriors',
          ).overrideWith((ref) => Stream.value(const [archetypeEntry])),
        ],
        child: const MaterialApp(home: LeaderboardScreen(initialTabIndex: 1)),
      ),
    );

    // Nested stream providers; see the active-tribe test above.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('Archetype Member'), findsOneWidget);
    expect(find.text('Tribe A Member'), findsNothing);
  });

  testWidgets('tribe leaderboard tab hides users who are no longer members', (
    tester,
  ) async {
    const tribeAEntry = LeaderboardEntry(
      userId: 'memberA',
      userName: 'Tribe A Member',
      xp: 100,
      level: 2,
      archetype: UserArchetype.athlete,
      rank: 1,
    );
    const leaverEntry = LeaderboardEntry(
      userId: 'leaverX',
      userName: 'Leaver Member',
      xp: 90,
      level: 2,
      archetype: UserArchetype.athlete,
      rank: 2,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userStatsStreamProvider.overrideWith(
            (ref) => Stream.value(
              UserProfile(uid: 'user1', archetype: UserArchetype.athlete),
            ),
          ),
          activeMembershipProvider.overrideWith(
            (ref) => Stream.value(
              UserTribeTableData(
                userId: 'user1',
                tribeId: 'tribeA',
                membershipType: 'member',
                joinedAt: DateTime.now().toIso8601String(),
                isActive: true,
              ),
            ),
          ),
          clubLeaderboardProvider('tribeA').overrideWith(
            (ref) => Stream.value(const [tribeAEntry, leaverEntry]),
          ),
          clubLeaderboardProvider(
            'morning_warriors',
          ).overrideWith((ref) => const Stream.empty()),
          // The tribe's remote members array lists only memberA — the
          // leaver's history stays in the leaderboard (D2) but must not
          // render (B10).
          userTribesProvider('user1').overrideWith(
            (ref) => Stream.value([
              _tribe(members: const ['memberA']),
            ]),
          ),
        ],
        child: const MaterialApp(home: LeaderboardScreen(initialTabIndex: 1)),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('Tribe A Member'), findsOneWidget);
    expect(find.text('Leaver Member'), findsNothing);
  });
}
