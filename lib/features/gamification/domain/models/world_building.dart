import 'package:equatable/equatable.dart';

/// Rarity levels for buildings
enum BuildingRarity { common, uncommon, rare, epic, legendary }

/// Types of world elements
enum WorldElementType { building, vegetation, decoration, landmark }

/// A building that can be unlocked and placed in the world
class WorldBuilding extends Equatable {
  final String id;
  final String name;
  final String description;
  final String zoneId;
  final int requiredZoneLevel;
  final BuildingRarity rarity;
  final WorldElementType type;
  final String previewAsset;

  const WorldBuilding({
    required this.id,
    required this.name,
    required this.description,
    required this.zoneId,
    required this.requiredZoneLevel,
    required this.rarity,
    this.type = WorldElementType.building,
    this.previewAsset = '',
  });

  @override
  List<Object?> get props => [id, zoneId, requiredZoneLevel, rarity];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'zoneId': zoneId,
      'requiredZoneLevel': requiredZoneLevel,
      'rarity': rarity.name,
      'type': type.name,
      'previewAsset': previewAsset,
    };
  }

  factory WorldBuilding.fromMap(Map<String, dynamic> map) {
    return WorldBuilding(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      zoneId: map['zoneId'] as String,
      requiredZoneLevel: map['requiredZoneLevel'] as int? ?? 1,
      rarity: BuildingRarity.values.firstWhere(
        (r) => r.name == map['rarity'],
        orElse: () => BuildingRarity.common,
      ),
      type: WorldElementType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => WorldElementType.building,
      ),
      previewAsset: map['previewAsset'] as String? ?? '',
    );
  }
}

/// Placement data for a building in the world
class BuildingPlacement extends Equatable {
  final String buildingId;
  final double x; // 0.0-1.0 relative position
  final double y;
  final DateTime placedAt;

  const BuildingPlacement({
    required this.buildingId,
    required this.x,
    required this.y,
    required this.placedAt,
  });

  @override
  List<Object?> get props => [buildingId, x, y];

  Map<String, dynamic> toMap() {
    return {
      'buildingId': buildingId,
      'x': x,
      'y': y,
      'placedAt': placedAt.toIso8601String(),
    };
  }

  factory BuildingPlacement.fromMap(Map<String, dynamic> map) {
    return BuildingPlacement(
      buildingId: map['buildingId'] as String,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      placedAt: DateTime.parse(
        map['placedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

/// Catalog of all available buildings in the game
class WorldBuildingCatalog {
  // Garden Zone Buildings (Vitality)
  static const List<WorldBuilding> gardenBuildings = [
    WorldBuilding(
      id: 'flower_patch',
      name: 'Flower Patch',
      description: 'A colorful patch of wildflowers',
      zoneId: 'garden',
      requiredZoneLevel: 1,
      rarity: BuildingRarity.common,
      type: WorldElementType.vegetation,
    ),
    WorldBuilding(
      id: 'herb_garden',
      name: 'Herb Garden',
      description: 'Fragrant herbs for health and cooking',
      zoneId: 'garden',
      requiredZoneLevel: 2,
      rarity: BuildingRarity.common,
      type: WorldElementType.vegetation,
    ),
    WorldBuilding(
      id: 'greenhouse',
      name: 'Greenhouse',
      description: 'A glass structure nurturing exotic plants',
      zoneId: 'garden',
      requiredZoneLevel: 3,
      rarity: BuildingRarity.uncommon,
    ),
    WorldBuilding(
      id: 'meditation_pond',
      name: 'Meditation Pond',
      description: 'A tranquil pond with koi fish',
      zoneId: 'garden',
      requiredZoneLevel: 4,
      rarity: BuildingRarity.rare,
    ),
    WorldBuilding(
      id: 'ancient_tree',
      name: 'Ancient Tree',
      description: 'A millennia-old tree radiating life energy',
      zoneId: 'garden',
      requiredZoneLevel: 5,
      rarity: BuildingRarity.legendary,
      type: WorldElementType.landmark,
    ),
  ];

  // Library Zone Buildings (Intellect)
  static const List<WorldBuilding> libraryBuildings = [
    WorldBuilding(
      id: 'small_bookshelf',
      name: 'Small Bookshelf',
      description: 'A modest collection of essential tomes',
      zoneId: 'library',
      requiredZoneLevel: 1,
      rarity: BuildingRarity.common,
    ),
    WorldBuilding(
      id: 'reading_nook',
      name: 'Reading Nook',
      description: 'A cozy corner for deep study',
      zoneId: 'library',
      requiredZoneLevel: 2,
      rarity: BuildingRarity.common,
    ),
    WorldBuilding(
      id: 'scroll_archive',
      name: 'Scroll Archive',
      description: 'Ancient scrolls of forgotten knowledge',
      zoneId: 'library',
      requiredZoneLevel: 3,
      rarity: BuildingRarity.uncommon,
    ),
    WorldBuilding(
      id: 'observatory_tower',
      name: 'Observatory Tower',
      description: 'A tower to study the stars and cosmos',
      zoneId: 'library',
      requiredZoneLevel: 4,
      rarity: BuildingRarity.rare,
    ),
    WorldBuilding(
      id: 'grand_library',
      name: 'Grand Library',
      description: 'A magnificent repository of all knowledge',
      zoneId: 'library',
      requiredZoneLevel: 5,
      rarity: BuildingRarity.legendary,
      type: WorldElementType.landmark,
    ),
  ];

  // Forge Zone Buildings (Strength)
  static const List<WorldBuilding> forgeBuildings = [
    WorldBuilding(
      id: 'training_dummy',
      name: 'Training Dummy',
      description: 'A practice target for combat training',
      zoneId: 'forge',
      requiredZoneLevel: 1,
      rarity: BuildingRarity.common,
    ),
    WorldBuilding(
      id: 'weapon_rack',
      name: 'Weapon Rack',
      description: 'Displays of martial prowess',
      zoneId: 'forge',
      requiredZoneLevel: 2,
      rarity: BuildingRarity.common,
    ),
    WorldBuilding(
      id: 'smithy',
      name: 'Smithy',
      description: 'Where iron becomes legend',
      zoneId: 'forge',
      requiredZoneLevel: 3,
      rarity: BuildingRarity.uncommon,
    ),
    WorldBuilding(
      id: 'arena',
      name: 'Training Arena',
      description: 'A proving ground for warriors',
      zoneId: 'forge',
      requiredZoneLevel: 4,
      rarity: BuildingRarity.rare,
    ),
    WorldBuilding(
      id: 'titan_statue',
      name: 'Titan Statue',
      description: 'A monument to supreme physical achievement',
      zoneId: 'forge',
      requiredZoneLevel: 5,
      rarity: BuildingRarity.legendary,
      type: WorldElementType.landmark,
    ),
  ];

  // Studio Zone Buildings (Creativity)
  static const List<WorldBuilding> studioBuildings = [
    WorldBuilding(
      id: 'easel',
      name: 'Painting Easel',
      description: 'Canvas awaiting inspiration',
      zoneId: 'studio',
      requiredZoneLevel: 1,
      rarity: BuildingRarity.common,
    ),
    WorldBuilding(
      id: 'sculpture_stand',
      name: 'Sculpture Stand',
      description: 'Where raw materials become art',
      zoneId: 'studio',
      requiredZoneLevel: 2,
      rarity: BuildingRarity.common,
    ),
    WorldBuilding(
      id: 'music_corner',
      name: 'Music Corner',
      description: 'Instruments for creative expression',
      zoneId: 'studio',
      requiredZoneLevel: 3,
      rarity: BuildingRarity.uncommon,
    ),
    WorldBuilding(
      id: 'gallery_wall',
      name: 'Gallery Wall',
      description: 'Showcase of your masterpieces',
      zoneId: 'studio',
      requiredZoneLevel: 4,
      rarity: BuildingRarity.rare,
    ),
    WorldBuilding(
      id: 'inspiration_fountain',
      name: 'Inspiration Fountain',
      description: 'A fountain flowing with pure creativity',
      zoneId: 'studio',
      requiredZoneLevel: 5,
      rarity: BuildingRarity.legendary,
      type: WorldElementType.landmark,
    ),
  ];

  // Shrine Zone Buildings (Focus)
  static const List<WorldBuilding> shrineBuildings = [
    WorldBuilding(
      id: 'meditation_stone',
      name: 'Meditation Stone',
      description: 'A simple stone for centering the mind',
      zoneId: 'shrine',
      requiredZoneLevel: 1,
      rarity: BuildingRarity.common,
    ),
    WorldBuilding(
      id: 'incense_altar',
      name: 'Incense Altar',
      description: 'Fragrant smoke to calm the spirit',
      zoneId: 'shrine',
      requiredZoneLevel: 2,
      rarity: BuildingRarity.common,
    ),
    WorldBuilding(
      id: 'zen_garden',
      name: 'Zen Garden',
      description: 'Raked sand and stones for contemplation',
      zoneId: 'shrine',
      requiredZoneLevel: 3,
      rarity: BuildingRarity.uncommon,
    ),
    WorldBuilding(
      id: 'bell_tower',
      name: 'Bell Tower',
      description: 'Clear tones to sharpen the mind',
      zoneId: 'shrine',
      requiredZoneLevel: 4,
      rarity: BuildingRarity.rare,
    ),
    WorldBuilding(
      id: 'enlightenment_pagoda',
      name: 'Enlightenment Pagoda',
      description: 'A sacred structure of ultimate clarity',
      zoneId: 'shrine',
      requiredZoneLevel: 5,
      rarity: BuildingRarity.legendary,
      type: WorldElementType.landmark,
    ),
  ];

  /// Get all buildings for a specific zone
  static List<WorldBuilding> getBuildingsForZone(String zoneId) {
    switch (zoneId) {
      case 'garden':
        return gardenBuildings;
      case 'library':
        return libraryBuildings;
      case 'forge':
        return forgeBuildings;
      case 'studio':
        return studioBuildings;
      case 'shrine':
        return shrineBuildings;
      default:
        return [];
    }
  }

  /// Get all buildings across all zones
  static List<WorldBuilding> get allBuildings => [
    ...gardenBuildings,
    ...libraryBuildings,
    ...forgeBuildings,
    ...studioBuildings,
    ...shrineBuildings,
  ];

  /// Get a building by ID
  static WorldBuilding? getBuildingById(String id) {
    return allBuildings.cast<WorldBuilding?>().firstWhere(
      (b) => b?.id == id,
      orElse: () => null,
    );
  }

  /// Get unlockable buildings for a zone at a given level
  static List<WorldBuilding> getUnlockableBuildings(String zoneId, int level) {
    return getBuildingsForZone(
      zoneId,
    ).where((b) => b.requiredZoneLevel <= level).toList();
  }
}
