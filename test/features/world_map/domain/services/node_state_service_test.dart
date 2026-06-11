import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_maps_catalog.dart';
import 'package:emerge_app/features/world_map/domain/models/hex_location.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/services/node_state_service.dart';

void main() {
  group('ArchetypeMapsCatalog', () {
    test('getMapForArchetype returns valid config for all archetypes', () {
      for (final archetype in UserArchetype.values) {
        if (archetype == UserArchetype.none) continue;
        final config = ArchetypeMapsCatalog.getMapForArchetype(archetype);
        expect(config.mapName, isNotEmpty);
        expect(config.nodes, isNotEmpty);
        expect(config.primaryColor, isNotNull);
      }
    });

    test('all archetype maps have unique IDs per node', () {
      for (final archetype in UserArchetype.values) {
        if (archetype == UserArchetype.none) continue;
        final config = ArchetypeMapsCatalog.getMapForArchetype(archetype);
        final ids = config.nodes.map((n) => n.id).toList();
        expect(
          ids.toSet().length,
          ids.length,
          reason: '${config.mapName} has duplicate node IDs',
        );
      }
    });

    test('nodes are ordered by requiredLevel', () {
      final config = ArchetypeMapsCatalog.getMapForArchetype(
        UserArchetype.scholar,
      );
      for (int i = 1; i < config.nodes.length; i++) {
        expect(
          config.nodes[i].requiredLevel,
          greaterThanOrEqualTo(config.nodes[i - 1].requiredLevel),
        );
      }
    });
  });

  group('WorldNode', () {
    final defaultNode = WorldNode(
      id: 'test_1',
      name: 'Test Node',
      description: 'A test node',
      targetedAttributes: [HabitAttribute.vitality],
      xpBoosts: {HabitAttribute.vitality: 50},
      requiredLevel: 1,
      type: NodeType.waypoint,
      hexLocation: const HexLocation(0, 0),
    );

    test('copyWith updates state correctly', () {
      final updated = defaultNode.copyWith(state: NodeState.available);
      expect(updated.state, NodeState.available);
      expect(updated.id, 'test_1');
    });

    test('tier returns dormant when progress is 0', () {
      expect(defaultNode.tier, NodeTier.dormant);
    });

    test('tier returns legendary when progress is 100', () {
      final node = defaultNode.copyWith(progress: 100);
      expect(node.tier, NodeTier.legendary);
    });

    test('isComplete returns true when nodeXp >= nodeXpRequired', () {
      final node = defaultNode.copyWith(nodeXp: 100, nodeXpRequired: 100);
      expect(node.isComplete, isTrue);
    });

    test('isComplete returns false when nodeXp < nodeXpRequired', () {
      expect(defaultNode.isComplete, isFalse);
    });
  });

  group('NodeStateService', () {
    final testNode = WorldNode(
      id: 'node_1',
      name: 'Test Node',
      description: 'A test node',
      targetedAttributes: [HabitAttribute.vitality],
      xpBoosts: {HabitAttribute.vitality: 50},
      requiredLevel: 3,
      type: NodeType.waypoint,
      hexLocation: HexLocation(0, 0),
    );

    test('calculateState returns active when level meets requirement', () {
      final profile = UserProfile(
        uid: 'user1',
        displayName: 'Test',
        avatarStats: const UserAvatarStats(level: 5),
      );
      final state = NodeStateService.calculateState(testNode, profile, []);
      expect(state, ProgressionState.active);
    });

    test('calculateState returns locked when level is too low', () {
      final profile = UserProfile(
        uid: 'user1',
        displayName: 'Test',
        avatarStats: const UserAvatarStats(level: 1),
      );
      final state = NodeStateService.calculateState(testNode, profile, []);
      expect(state, ProgressionState.locked);
    });

    test('calculateState returns completed when in completedNodeIds', () {
      final profile = UserProfile(
        uid: 'user1',
        displayName: 'Test',
        avatarStats: const UserAvatarStats(level: 5),
      );
      final state = NodeStateService.calculateState(testNode, profile, [
        'node_1',
      ]);
      expect(state, ProgressionState.completed);
    });

    test('getLockReason returns level message when level is too low', () {
      final profile = UserProfile(
        uid: 'user1',
        displayName: 'Test',
        avatarStats: const UserAvatarStats(level: 1),
      );
      final reason = NodeStateService.getLockReason(testNode, profile);
      expect(reason, contains('level ${testNode.requiredLevel}'));
    });
  });

  group('ArchetypeMapConfig', () {
    test('config has journeyIcon defined', () {
      final config = ArchetypeMapsCatalog.getMapForArchetype(
        UserArchetype.athlete,
      );
      expect(config.journeyIcon, isNotNull);
    });

    test('config has mapDescription', () {
      final config = ArchetypeMapsCatalog.getMapForArchetype(
        UserArchetype.scholar,
      );
      expect(config.mapDescription, isNotEmpty);
    });
  });

  group('HexLocation', () {
    test('can be constructed with q and r', () {
      final loc = const HexLocation(2, 3);
      expect(loc.q, 2);
      expect(loc.r, 3);
    });

    test('toMap and fromMap roundtrip', () {
      final loc = const HexLocation(1, -2);
      final map = loc.toMap();
      final restored = HexLocation.fromMap(map);
      expect(restored.q, loc.q);
      expect(restored.r, loc.r);
    });
  });
}
