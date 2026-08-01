import 'dart:async';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
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

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'companion_visited_/world-map': true,
      // Node-id key (underscore) — the legacy hyphenated key is ignored by
      // getHasSeenNodeGuide and would let the guide render unasserted.
      'hasSeenNodeGuide_world_map': true,
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
            userStatsStreamProvider.overrideWith(
              (ref) => const Stream.empty(),
            ),
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

    testWidgets('shows loaded data state with background and layout elements', (tester) async {
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
      expect(find.byType(AmbientParticles), findsOneWidget);
      expect(find.byType(ConstellationLines), findsOneWidget);
    });

    testWidgets('handles first-visit check without crashing when already seen',
        (tester) async {
      // hasSeenNodeGuide_world_map is set to true in setUp,
      // so neither the narrator nor the node guide should show
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
      // ...and without the node-guide overlay (node marked seen in setUp).
      expect(find.text('Your Living World'), findsNothing);
    });

    testWidgets(
        'skips narrator check when isFirstLaunch is true',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'companion_visited_/world-map': true,
        // Node unseen — the node guide IS due here (positive branch).
        'hasSeenNodeGuide_world_map': false,
        'isFirstLaunch': true,
        'tutorialsEnabled': true,
      });
      await CompanionRepository().init();
      await LocalSettingsRepository().init();

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
      // Node guide IS due (node unseen) — the overlay appears.
      expect(find.text('Your Living World'), findsOneWidget);
    });
  });
}
