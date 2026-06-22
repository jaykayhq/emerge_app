import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/screens/leaderboard_screen.dart';
import 'package:emerge_app/features/social/presentation/providers/friends_leaderboard_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

void main() {
  testWidgets('LeaderboardScreen renders loading skeletons', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userStatsStreamProvider.overrideWith(
            (ref) => const Stream.empty(),
          ),
          friendsLeaderboardProvider.overrideWith(
            (ref) => const Stream.empty(),
          ),
          worldLeaderboardProvider.overrideWith(
            (ref) => const Stream.empty(),
          ),
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
          friendsLeaderboardProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
          userStatsStreamProvider.overrideWith(
            (ref) => Stream.value(const UserProfile(uid: '')),
          ),
          worldLeaderboardProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
        ],
        child: const MaterialApp(home: LeaderboardScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('LEADERBOARD'), findsOneWidget);
    expect(find.text('FRIENDS'), findsOneWidget);
    expect(find.text('TRIBE'), findsOneWidget);
    expect(find.text('WORLD'), findsOneWidget);
  });
}
