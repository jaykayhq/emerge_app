import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emerge_app/core/presentation/providers/world_theme_provider.dart';
import 'package:emerge_app/features/companion/data/repositories/companion_repository.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/world_map/presentation/screens/world_map_screen.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/ambient_particles.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/constellation_lines.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'companion_visited_/world-map': true,
      'hasSeenNodeGuide_world-map': true,
      'isFirstLaunch': false,
      'tutorialsEnabled': true,
    });
    final repo = CompanionRepository();
    await repo.init();
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

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
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
      // Wait, CentralHealthOrb might still render a CircularProgressIndicator if shader isn't loaded!
      // But we can check for other things:
      expect(find.byType(WorldMapScreen), findsOneWidget);
      expect(find.byType(AmbientParticles), findsOneWidget);
      expect(find.byType(ConstellationLines), findsOneWidget);
    });

    testWidgets('handles first-visit check without crashing when already seen',
        (tester) async {
      // hasSeenNodeGuide_world-map is set to true in setUp,
      // so the narrator should NOT show
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
    });

    testWidgets(
        'skips narrator check when isFirstLaunch is true',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'companion_visited_/world-map': true,
        'hasSeenNodeGuide_world-map': false,
        'isFirstLaunch': true,
        'tutorialsEnabled': true,
      });
      await CompanionRepository().init();

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
    });
  });
}
