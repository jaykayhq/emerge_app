import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';

/// Node state for progression calculation
/// Simplified states distinct from the visual NodeState in world_node.dart
enum ProgressionState {
  locked,
  active,
  completed,
}

/// Service to calculate node states based on user progress
class NodeStateService {
  /// Calculate the progression state of a node based on user progress
  static ProgressionState calculateState(
    WorldNode node,
    UserProfile userProfile,
    List<String> completedNodeIds,
  ) {
    // If mission is explicitly completed, it's done
    if (node.missionCompleted || completedNodeIds.contains(node.id)) {
      return ProgressionState.completed;
    }

    // Check if user level meets requirement
    final userLevel = userProfile.avatarStats.level;
    if (userLevel < node.requiredLevel) {
      return ProgressionState.locked;
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
    return ProgressionState.active;
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
    // worldState is non-nullable (has default const UserWorldState())
    return profile.worldState.claimedNodes.map((e) => e.toString()).toList();
  }
}
