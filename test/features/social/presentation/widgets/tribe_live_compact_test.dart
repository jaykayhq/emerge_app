import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_live_compact.dart';

final _testProfile = UserProfile(
  uid: 'test_user',
  displayName: 'Tester',
  archetype: UserArchetype.athlete,
);

final _testClub = Tribe(
  id: 'tribe_athlete',
  name: 'Iron Vanguard',
  description: '',
  imageUrl: '',
  memberCount: 12,
  ownerId: 'owner',
  tags: const [],
  levelRequirement: 0,
  rank: 1,
  totalXp: 0,
);

Widget buildLiveCompact({
  Stream<List<Map<String, dynamic>>>? activityStream,
  Stream<List<({Tribe tribe, TribeStats stats})>>? leaderboardStream,
}) {
  final activityOverride =
      activityStream ?? const Stream<List<Map<String, dynamic>>>.empty();
  final lbOverride =
      leaderboardStream ?? const Stream<List<({Tribe tribe, TribeStats stats})>>.empty();
  return ProviderScope(
    overrides: [
      clubActivityProvider.overrideWith((ref, _) => activityOverride),
      worldLeaderboardProvider.overrideWith((ref) => lbOverride),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: TribeLiveCompact(
          clubId: 'tribe_athlete',
          profile: _testProfile,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders header and segmented control with default LIVE FEED',
      (tester) async {
    await tester.pumpWidget(buildLiveCompact());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('TRIBE PULSE'), findsOneWidget);
    expect(find.text('LIVE FEED'), findsOneWidget);
    expect(find.text('LEADERBOARD'), findsOneWidget);
  });

  testWidgets('empty feed shows "No activity yet."', (tester) async {
    await tester.pumpWidget(
      buildLiveCompact(activityStream: Stream.value(const <Map<String, dynamic>>[])),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('No activity yet.'), findsOneWidget);
  });

  testWidgets('empty leaderboard shows "Leaderboard is empty."',
      (tester) async {
    await tester.pumpWidget(
      buildLiveCompact(
        leaderboardStream:
            Stream.value(const <({Tribe tribe, TribeStats stats})>[]),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('LEADERBOARD'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Leaderboard is empty.'), findsOneWidget);
  });

  testWidgets('tapping LEADERBOARD tab swaps the visible content',
      (tester) async {
    await tester.pumpWidget(
      buildLiveCompact(
        activityStream: Stream.value(const <Map<String, dynamic>>[]),
        leaderboardStream: Stream.value(<({Tribe tribe, TribeStats stats})>[
          (
            tribe: _testClub,
            stats: TribeStats(
              memberCount: 12,
              totalXp: 500,
              totalHabitsCompleted: 10,
              totalChallengesCompleted: 3,
            ),
          ),
        ]),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Initially on LIVE FEED — empty activity shows empty state.
    expect(find.text('No activity yet.'), findsOneWidget);

    // Switch to LEADERBOARD — shows the row.
    await tester.tap(find.text('LEADERBOARD'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Iron Vanguard'), findsOneWidget);
    expect(find.text('500 XP'), findsOneWidget);
  });

  testWidgets('activity stream renders rows', (tester) async {
    await tester.pumpWidget(
      buildLiveCompact(
        activityStream: Stream.value(<Map<String, dynamic>>[
          {
            'type': 'habit_complete',
            'userName': 'Vega',
            'data': {'habitTitle': 'Morning Run', 'streakDay': 5},
          },
        ]),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Vega'), findsOneWidget);
  });

  testWidgets('loading state shows CircularProgressIndicator', (tester) async {
    // Empty Stream that doesn't emit leaves AsyncValue in loading state.
    await tester.pumpWidget(buildLiveCompact());
    // Only pump once — don't advance microtasks enough for loading to resolve.
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
