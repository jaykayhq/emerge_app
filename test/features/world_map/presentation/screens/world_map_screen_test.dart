import 'dart:async';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/models/habit_completion_result.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_node_state.dart';
import 'package:emerge_app/features/world_map/domain/models/next_identity_vote.dart';
import 'package:emerge_app/features/world_map/presentation/providers/archetype_node_states_provider.dart';
import 'package:emerge_app/features/world_map/presentation/providers/next_identity_vote_provider.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_spark_burst.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_stoking_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emerge_app/core/presentation/providers/world_theme_provider.dart';
import 'package:emerge_app/features/companion/data/repositories/companion_repository.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/features/world_map/presentation/screens/world_map_screen.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/ambient_particles.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/constellation_lines.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/nebula_background.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_ring_layout.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_bonfire.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/world_status_panel.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'companion_visited_/world-map': true,
      // Node-id key (underscore) — the legacy hyphenated key is ignored by
      // getHasSeenNarratorGuide and would let the guide render unasserted.
      'hasSeenNarratorGuide_world_map': true,
      'isFirstLaunch': false,
      'tutorialsEnabled': true,
    });
    final repo = CompanionRepository();
    await repo.init();
    // Refresh the static prefs handle so the seeded seen-flag is honored.
    await LocalSettingsRepository().init();
  });

  group('WorldMapScreen', () {
    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userStatsStreamProvider.overrideWith((ref) => const Stream.empty()),
            worldThemeProvider.overrideWith(WorldThemeNotifier.new),
            worldHealthStreamProvider.overrideWith(
              (ref) => const Stream.empty(),
            ),
            worldEntropyStreamProvider.overrideWith(
              (ref) => const Stream.empty(),
            ),
            companionRepositoryProvider.overrideWith(
              (ref) => CompanionRepository(),
            ),
          ],
          child: const MaterialApp(home: WorldMapScreen()),
        ),
      );
      await tester.pump();

      expect(find.byType(EmergeLoadingSkeleton), findsOneWidget);
    });

    testWidgets('shows loaded data state with background and layout elements', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userStatsStreamProvider.overrideWith((ref) => const Stream.empty()),
            worldThemeProvider.overrideWith(WorldThemeNotifier.new),
            worldHealthStreamProvider.overrideWith((ref) => Stream.value(0.5)),
            worldEntropyStreamProvider.overrideWith((ref) => Stream.value(0.0)),
            companionRepositoryProvider.overrideWith(
              (ref) => CompanionRepository(),
            ),
          ],
          child: const MaterialApp(home: WorldMapScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('Failed to load world state.'), findsNothing);
      // Asset videos don't initialize under flutter_test, so the flame video
      // background renders its NebulaBackground fallback:
      expect(find.byType(WorldMapScreen), findsOneWidget);
      expect(find.byType(NebulaBackground), findsOneWidget);
      expect(find.byType(WorldRingLayout), findsOneWidget);
      expect(find.byType(WorldBonfire), findsOneWidget);
      expect(find.byType(AmbientParticles), findsOneWidget);
      expect(find.byType(ConstellationLines), findsOneWidget);
      expect(find.byType(WorldStokingDock), findsOneWidget);
    });

    testWidgets('center flame toggles the world status panel', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userStatsStreamProvider.overrideWith((ref) => const Stream.empty()),
            worldThemeProvider.overrideWith(WorldThemeNotifier.new),
            worldHealthStreamProvider.overrideWith((ref) => Stream.value(0.5)),
            worldEntropyStreamProvider.overrideWith((ref) => Stream.value(0.0)),
            companionRepositoryProvider.overrideWith(
              (ref) => CompanionRepository(),
            ),
          ],
          child: const MaterialApp(home: WorldMapScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.byType(WorldStatusPanel), findsNothing);

      await tester.tap(find.bySemanticsLabel('World health 50 percent'));
      await tester.pump();
      expect(find.byType(WorldStatusPanel), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('World health 50 percent'));
      await tester.pump();
      expect(find.byType(WorldStatusPanel), findsNothing);
    });

    testWidgets('supplies archetype node states to WorldRingLayout', (
      tester,
    ) async {
      final customNodeStates = {
        HabitAttribute.vitality: const ArchetypeNodeState(
          status: NodeHealthStatus.complete,
          completedCount: 3,
        ),
        HabitAttribute.focus: const ArchetypeNodeState(
          status: NodeHealthStatus.decaying,
          pendingCount: 1,
          hasDecay: true,
        ),
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userStatsStreamProvider.overrideWith((ref) => const Stream.empty()),
            worldThemeProvider.overrideWith(WorldThemeNotifier.new),
            worldHealthStreamProvider.overrideWith((ref) => Stream.value(0.7)),
            worldEntropyStreamProvider.overrideWith((ref) => Stream.value(0.1)),
            archetypeNodeStatesProvider.overrideWith(
              (ref) => customNodeStates,
            ),
            companionRepositoryProvider.overrideWith(
              (ref) => CompanionRepository(),
            ),
          ],
          child: const MaterialApp(home: WorldMapScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      final ringLayout = tester.widget<WorldRingLayout>(
        find.byType(WorldRingLayout),
      );
      expect(ringLayout.nodeStates, customNodeStates);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets(
      'tapping CAST VOTE triggers spark burst overlay and habit completion',
      (tester) async {
        final habit = Habit(
          id: 'test-habit-vote',
          userId: 'user-1',
          title: 'Daily Meditation',
          attribute: HabitAttribute.spirit,
          frequency: HabitFrequency.daily,
          specificDays: const [1, 2, 3, 4, 5, 6, 7],
          difficulty: HabitDifficulty.medium,
          createdAt: DateTime.now(),
        );

        final vote = NextIdentityVote.actionable(
          habit: habit,
          attribute: HabitAttribute.spirit,
          vitalityImpactPercent: 20,
        );

        var completeCalled = false;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              userStatsStreamProvider.overrideWith(
                (ref) => const Stream.empty(),
              ),
              worldThemeProvider.overrideWith(WorldThemeNotifier.new),
              worldHealthStreamProvider.overrideWith(
                (ref) => Stream.value(0.5),
              ),
              worldEntropyStreamProvider.overrideWith(
                (ref) => Stream.value(0.0),
              ),
              nextIdentityVoteProvider.overrideWith((ref) => vote),
              completeHabitProvider('test-habit-vote').overrideWith((ref) async {
                completeCalled = true;
                return HabitCompletionResult.empty();
              }),
              companionRepositoryProvider.overrideWith(
                (ref) => CompanionRepository(),
              ),
            ],
            child: const MaterialApp(home: WorldMapScreen()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));

        expect(find.text('Daily Meditation'), findsOneWidget);
        expect(find.text('CAST VOTE'), findsOneWidget);
        expect(find.byType(WorldSparkBurst), findsNothing);

        // Tap CAST VOTE
        await tester.tap(find.text('CAST VOTE'));
        await tester.pump();

        expect(completeCalled, isTrue);
        expect(find.byType(WorldSparkBurst), findsOneWidget);

        // Advance animation to completion of burst -> triggers flare
        await tester.pump(const Duration(milliseconds: 1000));
        expect(find.byType(WorldSparkBurst), findsNothing);
      },
    );

    testWidgets('handles first-visit check without crashing when already seen', (
      tester,
    ) async {
      // hasSeenNarratorGuide_world_map is set to true in setUp,
      // so the narrator guide should not show
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userStatsStreamProvider.overrideWith((ref) => const Stream.empty()),
            worldThemeProvider.overrideWith(WorldThemeNotifier.new),
            worldHealthStreamProvider.overrideWith((ref) => Stream.value(0.5)),
            worldEntropyStreamProvider.overrideWith((ref) => Stream.value(0.0)),
            companionRepositoryProvider.overrideWith(
              (ref) => CompanionRepository(),
            ),
          ],
          child: const MaterialApp(home: WorldMapScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      // Screen renders without narrator dialog
      expect(find.text('EMERGE'), findsNothing);
      // ...and without the narrator-guide overlay (node marked seen in setUp).
      expect(find.text('COACH'), findsNothing);
    });

    testWidgets('skips narrator check when isFirstLaunch is true', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'companion_visited_/world-map': true,
        // Node unseen — the narrator guide IS due here (positive branch).
        'hasSeenNarratorGuide_world_map': false,
        'isFirstLaunch': true,
        'tutorialsEnabled': true,
      });
      await CompanionRepository().init();
      await LocalSettingsRepository().init();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userStatsStreamProvider.overrideWith((ref) => const Stream.empty()),
            worldThemeProvider.overrideWith(WorldThemeNotifier.new),
            worldHealthStreamProvider.overrideWith((ref) => Stream.value(0.5)),
            worldEntropyStreamProvider.overrideWith((ref) => Stream.value(0.0)),
            companionRepositoryProvider.overrideWith(
              (ref) => CompanionRepository(),
            ),
          ],
          child: const MaterialApp(home: WorldMapScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      // No narrator dialog shown (first launch skips tutorial)
      expect(find.text('EMERGE'), findsNothing);
      // Guide IS due (node unseen) — the narrator guide card appears.
      expect(find.text('COACH'), findsOneWidget);
    });
  });
}
