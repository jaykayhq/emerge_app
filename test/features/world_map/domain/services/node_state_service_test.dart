import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:emerge_app/features/world_map/domain/models/hex_location.dart';
import 'package:emerge_app/features/world_map/domain/services/node_state_service.dart';

WorldNode _buildNode({
  String id = 'node_1',
  int requiredLevel = 1,
  bool missionCompleted = false,
}) {
  return WorldNode(
    id: id,
    name: 'Test Node',
    description: 'A test node',
    targetedAttributes: [],
    xpBoosts: {},
    requiredLevel: requiredLevel,
    type: NodeType.waypoint,
    hexLocation: const HexLocation(0, 0),
    missionCompleted: missionCompleted,
  );
}

UserProfile _buildProfile({int level = 1, List<String> claimedNodes = const []}) {
  return UserProfile(
    uid: 'test_uid',
    avatarStats: UserAvatarStats(level: level),
    worldState: UserWorldState(
      claimedNodes: claimedNodes,
    ),
  );
}

void main() {
  group('ProgressionState enum', () {
    test('has locked value', () {
      expect(ProgressionState.values, contains(ProgressionState.locked));
    });

    test('has active value', () {
      expect(ProgressionState.values, contains(ProgressionState.active));
    });

    test('has completed value', () {
      expect(ProgressionState.values, contains(ProgressionState.completed));
    });
  });

  group('NodeStateService.calculateState', () {
    test('returns completed when missionCompleted is true', () {
      final node = _buildNode(missionCompleted: true);
      final profile = _buildProfile();
      final result = NodeStateService.calculateState(node, profile, []);
      expect(result, ProgressionState.completed);
    });

    test('returns completed when node id is in completedNodeIds', () {
      final node = _buildNode(id: 'node_42');
      final profile = _buildProfile();
      final result = NodeStateService.calculateState(node, profile, ['node_42', 'node_99']);
      expect(result, ProgressionState.completed);
    });

    test('returns locked when user level < node requiredLevel', () {
      final node = _buildNode(requiredLevel: 5);
      final profile = _buildProfile(level: 3);
      final result = NodeStateService.calculateState(node, profile, []);
      expect(result, ProgressionState.locked);
    });

    test('returns active when user level >= node requiredLevel', () {
      final node = _buildNode(requiredLevel: 3);
      final profile = _buildProfile(level: 5);
      final result = NodeStateService.calculateState(node, profile, []);
      expect(result, ProgressionState.active);
    });

    test('returns active when level equals required level', () {
      final node = _buildNode(requiredLevel: 4);
      final profile = _buildProfile(level: 4);
      final result = NodeStateService.calculateState(node, profile, []);
      expect(result, ProgressionState.active);
    });
  });

  group('NodeStateService.getLockReason', () {
    test('returns level requirement string when level is insufficient', () {
      final node = _buildNode(requiredLevel: 7);
      final profile = _buildProfile(level: 3);
      final result = NodeStateService.getLockReason(node, profile);
      expect(result, 'Reach level 7 to unlock this node');
    });

    test('returns previous mission string when level is sufficient', () {
      final node = _buildNode(requiredLevel: 2);
      final profile = _buildProfile(level: 5);
      final result = NodeStateService.getLockReason(node, profile);
      expect(result, 'Complete the previous mission to unlock this node');
    });
  });

  group('NodeStateService.getCompletedNodeIds', () {
    test('extracts claimedNodes from world state', () {
      final profile = _buildProfile(claimedNodes: ['node_a', 'node_b', 'node_c']);
      final result = NodeStateService.getCompletedNodeIds(profile);
      expect(result, ['node_a', 'node_b', 'node_c']);
    });

    test('returns empty list when no claimed nodes', () {
      final profile = _buildProfile(claimedNodes: []);
      final result = NodeStateService.getCompletedNodeIds(profile);
      expect(result, isEmpty);
    });
  });
}
