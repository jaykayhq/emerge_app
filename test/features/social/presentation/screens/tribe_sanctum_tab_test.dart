import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/cached_tribe_stats_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_sanctum_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _creatorTribeId = 'creator_tribe_1';

final _creatorTribe = Tribe(
  id: _creatorTribeId,
  name: 'Midnight Wolves',
  description: 'A tribe born from a creator blueprint',
  imageUrl: '',
  memberCount: 5,
  ownerId: 'creator_1',
  tags: const [],
  levelRequirement: 0,
  rank: 0,
  totalXp: 40,
  archetypeId: null,
);

final _membership = UserTribeTableData(
  userId: 'test_user',
  tribeId: _creatorTribeId,
  membershipType: 'creator',
  joinedAt: DateTime.now().toIso8601String(),
  isActive: true,
);

final _profile = UserProfile(
  uid: 'test_user',
  displayName: 'Tester',
  archetype: UserArchetype.athlete,
  avatarStats: const UserAvatarStats(streak: 3),
);

Widget _buildSanctum() {
  return ProviderScope(
    overrides: [
      userStatsStreamProvider.overrideWith((ref) => Stream.value(_profile)),
      activeMembershipProvider.overrideWith((ref) => Stream.value(_membership)),
      userTribeProvider.overrideWith(
        (ref, userId) => Stream.value(_creatorTribe),
      ),
      cachedTribeStatsProvider.overrideWith(
        (ref, tribeId) => Stream.value(
          TribeStats(
            memberCount: 5,
            totalXp: 40,
            totalHabitsCompleted: 3,
            totalChallengesCompleted: 1,
          ),
        ),
      ),
      clubActivityProvider.overrideWith((ref, tribeId) => const Stream.empty()),
      globalActivityProvider.overrideWith((ref) => const Stream.empty()),
    ],
    child: const MaterialApp(home: Scaffold(body: TribeSanctumTab())),
  );
}

void main() {
  testWidgets('renders the creator tribe for its members instead of the '
      'official-only "no clubs" fallback', (tester) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildSanctum());
    // Bounded pumps: flutter_animate effects are one-shot, but the
    // shimmer skeletons repeat, so pumpAndSettle would never settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('MIDNIGHT WOLVES'), findsOneWidget);
    expect(
      find.text('No clubs available for your archetype yet.'),
      findsNothing,
    );
    expect(find.text('No active tribe'), findsNothing);
  });
}
