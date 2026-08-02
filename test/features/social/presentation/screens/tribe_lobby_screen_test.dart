import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
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

/// Tutorials always off — the lobby is wrapped in a [NodeGuideHost], and the
/// first-visit coach mark overlay would swallow the taps these tests drive.
class _NoTutorialsSettings extends LocalSettingsRepository {
  @override
  bool isTutorialsEnabled() => false;
}

List<Override> testOverrides({
  Stream<UserProfile>? profileStream,
  Stream<List<Tribe>>? clubsStream,
}) {
  return [
    localSettingsRepositoryProvider.overrideWithValue(_NoTutorialsSettings()),
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
  ];
}

Widget buildTest({
  Stream<UserProfile>? profileStream,
  Stream<List<Tribe>>? clubsStream,
}) {
  return ProviderScope(
    overrides: testOverrides(
      profileStream: profileStream,
      clubsStream: clubsStream,
    ),
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
      'TribeLobbyScreen renders CTA bar with CHALLENGES and SWITCH TRIBES buttons',
      (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump(const Duration(milliseconds: 100));

    // CTA bar buttons.
    expect(find.text('CHALLENGES'), findsOneWidget);
    expect(find.text('SWITCH TRIBES'), findsOneWidget);
    expect(find.text('BROWSE BLUEPRINTS'), findsNothing);
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

  testWidgets('hides the back button when the lobby is the root route',
      (tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TribeLobbyScreen), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
  });

  testWidgets('shows a back button that pops when the lobby was pushed',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(),
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TribeLobbyScreen(),
                    ),
                  ),
                  child: const Text('open lobby'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open lobby'));
    await tester.pump(); // start push transition
    // Material 3 page transitions run for 800ms; pumping less leaves the
    // navigator's AbsorbPointer active and the tap below gets swallowed.
    await tester.pump(const Duration(milliseconds: 900)); // finish it
    await tester.pump(); // finalize route disposal

    expect(find.byType(TribeLobbyScreen), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pump(); // start pop transition
    await tester.pump(const Duration(milliseconds: 900)); // finish it
    await tester.pump(); // finalize route disposal

    expect(find.byType(TribeLobbyScreen), findsNothing);
    expect(find.text('open lobby'), findsOneWidget);
  });
}
