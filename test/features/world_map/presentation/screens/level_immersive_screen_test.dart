import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/companion/data/repositories/companion_repository.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_map_config.dart';
import 'package:emerge_app/features/world_map/domain/models/hex_location.dart';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:emerge_app/features/world_map/presentation/screens/level_immersive_screen.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';

final _testNode = WorldNode(
  id: 'test-node',
  name: 'Test Node',
  description: 'A test node',
  targetedAttributes: [HabitAttribute.vitality],
  xpBoosts: const {},
  requiredLevel: 1,
  type: NodeType.waypoint,
  hexLocation: const HexLocation(0, 0),
);

final _testConfig = ArchetypeMapConfig(
  archetype: UserArchetype.none,
  mapName: 'Test Map',
  mapDescription: 'A test map',
  primaryColor: Colors.blue,
  accentColor: Colors.cyan,
  backgroundGradient: [Colors.black, Colors.grey],
  nodes: [_testNode],
  journeyIcon: Icons.star,
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'companion_visited_/world-map/immersive': true,
    });
    final repo = CompanionRepository();
    await repo.init();
  });

  group('LevelImmersiveScreen', () {
    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userStatsStreamProvider.overrideWith(
              (ref) => const Stream.empty(),
            ),
            worldHealthStreamProvider.overrideWith(
              (ref) => Stream.value(0.5),
            ),
            companionRepositoryProvider.overrideWith(
              (ref) => CompanionRepository(),
            ),
          ],
          child: MaterialApp(
            home: LevelImmersiveScreen(node: _testNode, config: _testConfig),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
