import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';

/// Type of node in the world map
enum NodeType {
  /// Regular progression node
  waypoint,

  /// Milestone/boss node at biome boundaries
  milestone,

  /// Special challenge node
  challenge,

  /// Resource gathering node (bonus XP)
  resource,

  /// Landmark node (aesthetic, no gameplay)
  landmark,
}

/// Visual state of a node
enum NodeState {
  /// Not yet visible/unlocked
  locked,

  /// Available to work on
  available,

  /// Currently has progress
  inProgress,

  /// Fully completed
  completed,

  /// Mastered (all habits maxed)
  mastered,
}

/// Tier level of a node (progression within the node)
enum NodeTier {
  dormant, // 0%
  awakened, // 25%
  thriving, // 50%
  radiant, // 75%
  legendary, // 100%
}

/// A single node on the archetype world map
/// Represents a progression point that targets specific attributes
class WorldNode {
  final String id;
  final String name;
  final String description;

  /// Which habit attributes this node boosts when completed
  final List<HabitAttribute> targetedAttributes;

  /// XP bonus per targeted attribute
  final Map<HabitAttribute, int> xpBoosts;

  /// Level required to unlock this node
  final int requiredLevel;

  /// Type of node (waypoint, milestone, challenge, etc.)
  final NodeType type;

  /// Relative position on map (0.0-1.0 for both x and y)
  /// Y increases upward (bottom = 0, top = 1)
  final Offset position;

  /// IDs of nodes this connects to (for drawing paths)
  final List<String> connectedNodeIds;

  /// Current state of the node
  final NodeState state;

  /// Progress within the node (0-100)
  final int progress;

  /// Current tier based on progress
  NodeTier get tier {
    if (progress >= 100) return NodeTier.legendary;
    if (progress >= 75) return NodeTier.radiant;
    if (progress >= 50) return NodeTier.thriving;
    if (progress >= 25) return NodeTier.awakened;
    return NodeTier.dormant;
  }

  /// Biome this node belongs to (determined by Y position)
  int get biome => (position.dy * 5).floor().clamp(0, 4);

  /// Icon for this node type
  IconData get icon {
    switch (type) {
      case NodeType.waypoint:
        return Icons.circle;
      case NodeType.milestone:
        return Icons.emoji_events;
      case NodeType.challenge:
        return Icons.flash_on;
      case NodeType.resource:
        return Icons.stars;
      case NodeType.landmark:
        return Icons.flag;
    }
  }

  const WorldNode({
    required this.id,
    required this.name,
    required this.description,
    required this.targetedAttributes,
    required this.xpBoosts,
    required this.requiredLevel,
    required this.type,
    required this.position,
    this.connectedNodeIds = const [],
    this.state = NodeState.locked,
    this.progress = 0,
  });

  WorldNode copyWith({
    String? id,
    String? name,
    String? description,
    List<HabitAttribute>? targetedAttributes,
    Map<HabitAttribute, int>? xpBoosts,
    int? requiredLevel,
    NodeType? type,
    Offset? position,
    List<String>? connectedNodeIds,
    NodeState? state,
    int? progress,
  }) {
    return WorldNode(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetedAttributes: targetedAttributes ?? this.targetedAttributes,
      xpBoosts: xpBoosts ?? this.xpBoosts,
      requiredLevel: requiredLevel ?? this.requiredLevel,
      type: type ?? this.type,
      position: position ?? this.position,
      connectedNodeIds: connectedNodeIds ?? this.connectedNodeIds,
      state: state ?? this.state,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'targetedAttributes': targetedAttributes.map((a) => a.name).toList(),
      'xpBoosts': xpBoosts.map((k, v) => MapEntry(k.name, v)),
      'requiredLevel': requiredLevel,
      'type': type.name,
      'positionX': position.dx,
      'positionY': position.dy,
      'connectedNodeIds': connectedNodeIds,
      'state': state.name,
      'progress': progress,
    };
  }

  factory WorldNode.fromMap(Map<String, dynamic> map) {
    return WorldNode(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      targetedAttributes:
          (map['targetedAttributes'] as List<dynamic>?)
              ?.map((a) => HabitAttribute.values.firstWhere((e) => e.name == a))
              .toList() ??
          [],
      xpBoosts:
          (map['xpBoosts'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              HabitAttribute.values.firstWhere((e) => e.name == k),
              v as int,
            ),
          ) ??
          {},
      requiredLevel: map['requiredLevel'] as int? ?? 1,
      type: NodeType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NodeType.waypoint,
      ),
      position: Offset(
        (map['positionX'] as num?)?.toDouble() ?? 0.5,
        (map['positionY'] as num?)?.toDouble() ?? 0.0,
      ),
      connectedNodeIds: List<String>.from(map['connectedNodeIds'] ?? []),
      state: NodeState.values.firstWhere(
        (e) => e.name == map['state'],
        orElse: () => NodeState.locked,
      ),
      progress: map['progress'] as int? ?? 0,
    );
  }
}
