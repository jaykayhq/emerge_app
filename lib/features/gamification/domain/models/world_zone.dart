import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:equatable/equatable.dart';

/// Represents a zone in the user's growing world
/// Each zone is tied to a specific habit attribute
class WorldZone extends Equatable {
  final String id;
  final String name;
  final String description;
  final HabitAttribute linkedAttribute;
  final String iconAsset;

  const WorldZone({
    required this.id,
    required this.name,
    required this.description,
    required this.linkedAttribute,
    required this.iconAsset,
  });

  @override
  List<Object?> get props => [id, name, linkedAttribute];

  /// Predefined zones for the Growing World
  static const List<WorldZone> predefinedZones = [
    WorldZone(
      id: 'garden',
      name: 'The Garden',
      description: 'A flourishing garden that grows with your vitality habits',
      linkedAttribute: HabitAttribute.vitality,
      iconAsset: 'assets/icons/zone_garden.png',
    ),
    WorldZone(
      id: 'library',
      name: 'The Library',
      description: 'An ancient library that expands with your knowledge',
      linkedAttribute: HabitAttribute.intellect,
      iconAsset: 'assets/icons/zone_library.png',
    ),
    WorldZone(
      id: 'forge',
      name: 'The Forge',
      description: 'A mighty forge powered by your strength',
      linkedAttribute: HabitAttribute.strength,
      iconAsset: 'assets/icons/zone_forge.png',
    ),
    WorldZone(
      id: 'studio',
      name: 'The Studio',
      description: 'A vibrant studio filled with your creative works',
      linkedAttribute: HabitAttribute.creativity,
      iconAsset: 'assets/icons/zone_studio.png',
    ),
    WorldZone(
      id: 'shrine',
      name: 'The Shrine',
      description: 'A serene shrine that radiates with your focus',
      linkedAttribute: HabitAttribute.focus,
      iconAsset: 'assets/icons/zone_shrine.png',
    ),
  ];

  static WorldZone? getZoneForAttribute(HabitAttribute attribute) {
    return predefinedZones.cast<WorldZone?>().firstWhere(
      (zone) => zone?.linkedAttribute == attribute,
      orElse: () => null,
    );
  }
}

/// State of a specific zone in the user's world
class ZoneState extends Equatable {
  final String zoneId;
  final int level;
  final double health; // 0.0-1.0 (1.0 = thriving, 0.0 = withered)
  final int milestone; // Progress toward next level
  final List<String> activeElements; // Placed buildings/decorations
  final DateTime? lastUpdated;

  const ZoneState({
    required this.zoneId,
    this.level = 1,
    this.health = 1.0,
    this.milestone = 0,
    this.activeElements = const [],
    this.lastUpdated,
  });

  @override
  List<Object?> get props => [zoneId, level, health, milestone, activeElements];

  /// Milestones required to reach the next level
  int get milestonesForNextLevel => level * 10;

  /// Progress percentage toward next level
  double get levelProgress =>
      (milestone / milestonesForNextLevel).clamp(0.0, 1.0);

  /// Visual state based on health
  ZoneVisualState get visualState {
    if (health >= 0.8) return ZoneVisualState.thriving;
    if (health >= 0.6) return ZoneVisualState.healthy;
    if (health >= 0.4) return ZoneVisualState.neutral;
    if (health >= 0.2) return ZoneVisualState.decaying;
    return ZoneVisualState.withered;
  }

  Map<String, dynamic> toMap() {
    return {
      'zoneId': zoneId,
      'level': level,
      'health': health,
      'milestone': milestone,
      'activeElements': activeElements,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory ZoneState.fromMap(Map<String, dynamic> map) {
    return ZoneState(
      zoneId: map['zoneId'] as String? ?? '',
      level: map['level'] as int? ?? 1,
      health: (map['health'] as num?)?.toDouble() ?? 1.0,
      milestone: map['milestone'] as int? ?? 0,
      activeElements: List<String>.from(map['activeElements'] ?? []),
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.tryParse(map['lastUpdated'] as String)
          : null,
    );
  }

  ZoneState copyWith({
    String? zoneId,
    int? level,
    double? health,
    int? milestone,
    List<String>? activeElements,
    DateTime? lastUpdated,
  }) {
    return ZoneState(
      zoneId: zoneId ?? this.zoneId,
      level: level ?? this.level,
      health: health ?? this.health,
      milestone: milestone ?? this.milestone,
      activeElements: activeElements ?? this.activeElements,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Create initial zone states for all predefined zones
  static Map<String, ZoneState> createInitialZones() {
    return {
      for (final zone in WorldZone.predefinedZones)
        zone.id: ZoneState(zoneId: zone.id),
    };
  }
}

/// Visual state of a zone based on health
enum ZoneVisualState {
  thriving, // health >= 0.8
  healthy, // health >= 0.6
  neutral, // health >= 0.4
  decaying, // health >= 0.2
  withered, // health < 0.2
}
