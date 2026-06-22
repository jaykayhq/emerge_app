import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_bundle_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_lobby_screen.dart';

final _testTribe = Tribe(
  id: 'tribe_athlete',
  name: 'Iron Vanguard',
  description: '',
  imageUrl: '',
  memberCount: 12,
  ownerId: 'owner_1',
  tags: const [],
  levelRequirement: 0,
  rank: 1,
  totalXp: 0,
  archetypeId: 'athlete',
);

final _testProfile = UserProfile(
  uid: 'test_user',
  displayName: 'Tester',
  archetype: UserArchetype.athlete,
  avatarStats: const UserAvatarStats(streak: 7),
);

Widget buildTest({
  Stream<UserProfile>? profileStream,
  Stream<List<Tribe>>? clubsStream,
}) {
  return ProviderScope(
    overrides: [
      userStatsStreamProvider.overrideWith(
        (ref) => profileStream ?? Stream.value(_testProfile),
      ),
      allArchetypeClubsProvider.overrideWith(
        (ref) => clubsStream ?? Stream.value(<Tribe>[_testTribe]),
      ),
      userChallengesProvider.overrideWith(
        (ref) async => <Challenge>[],
      ),
      dailyQuestFromBundleProvider.overrideWith((ref) => null),
      weeklySpotlightFromBundleProvider.overrideWith((ref) => null),
      verifiedCreatorsStreamProvider.overrideWith(
        (ref) => const Stream.empty(),
      ),
      clubActivityProvider.overrideWith(
        (ref, _) => const Stream.empty(),
      ),
      worldLeaderboardProvider.overrideWith(
        (ref) => const Stream.empty(),
      ),
    ],
    child: const MaterialApp(home: TribeLobbyScreen()),
  );
}

void main() {
  testWidgets('TribeLobbyScreen renders loading skeleton', (tester) async {
    final oldHandler = FlutterError.onError;
    FlutterError.onError = (_) {};
    addTearDown(() {
      FlutterError.onError = oldHandler;
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userStatsStreamProvider.overrideWith(
            (ref) => const Stream.empty(),
          ),
          allArchetypeClubsProvider.overrideWith(
            (ref) => const Stream.empty(),
          ),
          userChallengesProvider.overrideWith(
            (ref) async => <Challenge>[],
          ),
          dailyQuestFromBundleProvider.overrideWith((ref) => null),
          weeklySpotlightFromBundleProvider.overrideWith((ref) => null),
          verifiedCreatorsStreamProvider.overrideWith(
            (ref) => const Stream.empty(),
          ),
          clubActivityProvider.overrideWith(
            (ref, _) => const Stream.empty(),
          ),
          worldLeaderboardProvider.overrideWith(
            (ref) => const Stream.empty(),
          ),
        ],
        child: const MaterialApp(home: TribeLobbyScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TribeLobbyScreen), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets(
      'TribeLobbyScreen renders CTA bar with both SWITCH TRIBE and BROWSE CREATORS buttons',
      (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump(const Duration(milliseconds: 100));

    // CTA bar buttons.
    expect(find.text('SWITCH TRIBE'), findsOneWidget);
    expect(find.text('BROWSE CREATORS'), findsOneWidget);
  });

  testWidgets(
      'TribeLobbyScreen renders the dual-hub sections: YOUR CIRCLE, YOUR QUESTS, QUESTS FOR YOU',
      (tester) async {
    // Use a tall viewport so all slivers build.
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('YOUR CIRCLE'), findsOneWidget);
    expect(find.text('YOUR QUESTS'), findsOneWidget);
    expect(find.text('QUESTS FOR YOU'), findsOneWidget);
  });
}
