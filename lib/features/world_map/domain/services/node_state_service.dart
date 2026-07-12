import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

/// Node state for progression calculation
/// Simplified states distinct from the old visual NodeState (world_node.dart removed).
enum ProgressionState { locked, active, completed }

/// Service to calculate node states based on user progress.
/// WorldNode references removed — kept for any callers that reference ProgressionState.
class NodeStateService {
  /// Get completed node IDs from user profile
  static List<String> getCompletedNodeIds(UserProfile profile) {
    // worldState is non-nullable (has default const UserWorldState())
    return profile.worldState.claimedNodes.map((e) => e.toString()).toList();
  }
}
