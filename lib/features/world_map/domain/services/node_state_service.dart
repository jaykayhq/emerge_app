import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';

/// Node states for UI rendering
enum NodeState {
  locked,
  active,
  completed,
}

/// Service to calculate node states based on user progress
class NodeStateService {
  /// Calculate the state of a node based on user progress
  static NodeState calculateState(
    WorldNode node,
    UserProfile userProfile,
    List<String> completedNodeIds,
  ) {
    // If mission is explicitly completed, it's done
    if (node.missionCompleted || completedNodeIds.contains(node.id)) {
      return NodeState.completed;
    }

    // Check if user level meets requirement
    final userLevel = userProfile.avatarStats.level;
    if (userLevel < node.requiredLevel) {
      return NodeState.locked;
    }

    // Check if previous node in sequence is complete
    // For linear progression, find the node with lower level in same stage
    // This is a simplified check - in practice, you'd traverse the node graph
    if (node.levelInStage > 1) {
      // Assuming nodes are ordered by levelInStage in the stage
      // Previous node would have levelInStage - 1
      // This requires the node list to check against
    }

    // If we pass all checks, node is active
    return NodeState.active;
  }

  /// Get lock reason for display
  static String getLockReason(
    WorldNode node,
    UserProfile userProfile,
  ) {
    final userLevel = userProfile.avatarStats.level;

    if (userLevel < node.requiredLevel) {
      return 'Reach level ${node.requiredLevel} to unlock this node';
    }

    return 'Complete the previous mission to unlock this node';
  }

  /// Get completed node IDs from user profile
  static List<String> getCompletedNodeIds(UserProfile profile) {
    return profile.worldState?.claimedNodes as List<dynamic>? ??
            [];
  }
}
