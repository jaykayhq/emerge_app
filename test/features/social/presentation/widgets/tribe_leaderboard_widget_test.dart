import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_leaderboard_widget.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';

Tribe _tribe(String id, String name, {int totalXp = 1000}) {
  return Tribe(
    id: id,
    name: name,
    description: '',
    imageUrl: '',
    memberCount: 10,
    ownerId: 'owner',
    tags: [],
    levelRequirement: 0,
    rank: 1,
    totalXp: totalXp,
  );
}

List<({Tribe tribe, TribeStats stats})> _makeEntries(int count) {
  return List.generate(count, (i) {
    final xp = (count - i) * 10000;
    return (
      tribe: _tribe('tribe_$i', 'Tribe $i', totalXp: xp),
      stats: TribeStats(memberCount: 10 + i, totalXp: xp, totalHabitsCompleted: 50, totalChallengesCompleted: 5),
    );
  });
}

void main() {
  testWidgets('renders time toggle', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: TribeLeaderboardSection()),
        ),
      ),
    );
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('All-time'), findsOneWidget);
  });

  testWidgets('renders loading skeleton while data loads', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worldLeaderboardProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: TribeLeaderboardSection()),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(EmergeLoadingSkeleton), findsOneWidget);
  });

  testWidgets('renders empty state when no rankings', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worldLeaderboardProvider.overrideWith((ref) => Stream.value(<({Tribe tribe, TribeStats stats})>[])),
        ],
        child: const MaterialApp(
          home: Scaffold(body: TribeLeaderboardSection()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('No rankings yet'), findsOneWidget);
  });

  testWidgets('renders leaderboard entries with podium and rows', (tester) async {
    final entries = _makeEntries(5);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worldLeaderboardProvider.overrideWith((ref) => Stream.value(entries)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: TribeLeaderboardSection()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Tribe 0'), findsOneWidget);
    expect(find.text('Tribe 1'), findsOneWidget);
    expect(find.text('Tribe 4'), findsOneWidget);
    expect(find.textContaining('K XP'), findsWidgets);
  });

  testWidgets('renders error state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worldLeaderboardProvider.overrideWith((ref) => Stream.error(Exception('Failed to load'))),
        ],
        child: const MaterialApp(
          home: Scaffold(body: TribeLeaderboardSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not load leaderboard'), findsOneWidget);
  });

  testWidgets('renders header and full board link', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: TribeLeaderboardSection()),
        ),
      ),
    );
    expect(find.text('ELITE RANKINGS'), findsOneWidget);
    expect(find.text('Full Board →'), findsOneWidget);
  });

  testWidgets('shows you pinned row at bottom', (tester) async {
    final entries = _makeEntries(2);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worldLeaderboardProvider.overrideWith((ref) => Stream.value(entries)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: TribeLeaderboardSection()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Your Tribe'), findsOneWidget);
  });
}
