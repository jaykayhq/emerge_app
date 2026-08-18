import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/pulse_feed/domain/models/pulse_feed_card.dart';
import 'package:emerge_app/features/pulse_feed/presentation/providers/pulse_feed_providers.dart';
import 'package:emerge_app/features/pulse_feed/presentation/screens/pulse_feed_screen.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_bundle_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/social_hub_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_lobby_screen.dart';

/// The profile is an ATHLETE; the membership points at the STOIC club so the
/// test proves the lobby receives the membership's tribeId (the archetype
/// fallback would otherwise resolve the athlete club).
final _athleteTribe = Tribe(
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

final _stoicTribe = Tribe(
  id: 'tribe_stoic',
  name: 'Stone Court',
  description: '',
  imageUrl: '',
  memberCount: 9,
  ownerId: 'owner_2',
  tags: const [],
  levelRequirement: 0,
  rank: 2,
  totalXp: 0,
  archetypeId: 'stoic',
);

final _testProfile = UserProfile(
  uid: 'test_user',
  displayName: 'Tester',
  archetype: UserArchetype.athlete,
  avatarStats: const UserAvatarStats(streak: 7),
);

final _testMembership = UserTribeTableData(
  userId: 'test_user',
  tribeId: 'tribe_stoic',
  membershipType: 'official',
  joinedAt: '2026-01-01',
  isActive: true,
);

/// Overrides for everything [TribeLobbyScreen]'s subtree watches (same set
/// as tribe_lobby_screen_test.dart).
List<Override> _lobbyOverrides() => [
  userStatsStreamProvider.overrideWith((ref) => Stream.value(_testProfile)),
  allArchetypeClubsProvider.overrideWith(
    (ref) => Stream.value(<Tribe>[_athleteTribe, _stoicTribe]),
  ),
  userChallengesProvider.overrideWith((ref) async => <Challenge>[]),
  dailyQuestFromBundleProvider.overrideWith((ref) => null),
  weeklySpotlightFromBundleProvider.overrideWith((ref) => null),
  verifiedCreatorsStreamProvider.overrideWith((ref) => const Stream.empty()),
  clubActivityProvider.overrideWith((ref, _) => const Stream.empty()),
  worldLeaderboardProvider.overrideWith((ref) => const Stream.empty()),
];

Widget _buildApp(List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(home: SocialHubScreen()),
  );
}

void main() {
  testWidgets(
    'renders TribeLobbyScreen for the JOINED tribe when a membership exists',
    (tester) async {
      await tester.pumpWidget(
        _buildApp([
          activeMembershipProvider.overrideWith(
            (ref) => Stream.value(_testMembership),
          ),
          ..._lobbyOverrides(),
        ]),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TribeLobbyScreen), findsOneWidget);
      expect(find.byType(PulseFeedScreen), findsNothing);
      // The lobby shows the membership's club (stoic), not the archetype club.
      expect(find.text('STONE COURT'), findsOneWidget);
      expect(find.text('IRON VANGUARD'), findsNothing);
    },
  );

  testWidgets('renders PulseFeedScreen when there is no membership', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp([
        activeMembershipProvider.overrideWith((ref) => Stream.value(null)),
        pulseFeedProvider.overrideWith(
          (ref) => Stream.value(<PulseFeedCard>[]),
        ),
      ]),
    );
    await tester.pump(); // single frame; ring animates forever, no settle

    expect(find.byType(PulseFeedScreen), findsOneWidget);
    expect(find.byType(TribeLobbyScreen), findsNothing);
  });

  testWidgets('renders PulseFeedScreen while the membership is still loading', (
    tester,
  ) async {
    final controller = StreamController<UserTribeTableData?>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      _buildApp([
        activeMembershipProvider.overrideWith((ref) => controller.stream),
        pulseFeedProvider.overrideWith(
          (ref) => Stream.value(<PulseFeedCard>[]),
        ),
      ]),
    );
    await tester.pump();

    expect(find.byType(PulseFeedScreen), findsOneWidget);
    expect(find.byType(TribeLobbyScreen), findsNothing);
  });
}
