import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_status_hud_top_bar.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

void main() {
  group('EmergeStatusHudTopBar', () {
    testWidgets('renders user profile details from stream', (tester) async {
      final mockProfile = UserProfile(
        uid: 'user123',
        displayName: 'Test User',
        archetype: UserArchetype.athlete,
        avatarStats: const UserAvatarStats(
          level: 12,
          strengthXp: 250,
          intellectXp: 100,
          vitalityXp: 100,
          focusXp: 50,
          spiritXp: 50,
        ),
        worldState: const UserWorldState(
          claimedNodes: ['node1'],
          highestCompletedNodeLevel: 12,
        ),
        hasEmerged: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userStatsStreamProvider.overrideWithValue(AsyncValue.data(mockProfile)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  EmergeStatusHudTopBar(),
                ],
              ),
            ),
          ),
        ),
      );

      // Assertions
      expect(find.byType(EmergeStatusHudTopBar), findsOneWidget);
      expect(find.text('LVL 12'), findsOneWidget);
      expect(find.text('SUMMIT PEAK'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('renders empty box when profile is null', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userStatsStreamProvider.overrideWithValue(const AsyncValue.loading()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  EmergeStatusHudTopBar(),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Should render nothing or empty box
      expect(find.byType(EmergeStatusHudTopBar, skipOffstage: false), findsOneWidget);
      expect(find.text('LVL 12'), findsNothing);
    });
  });
}
