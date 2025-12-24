import 'package:equatable/equatable.dart';

/// Represents an expandable land plot in the world
class LandPlot extends Equatable {
  final String id;
  final String name;
  final String description;
  final int requiredWorldLevel; // Minimum world level to unlock
  final int cost; // Cost in "world points" (total milestones)
  final double sizeMultiplier; // How much this expands the world
  final List<String> unlocksZoneSlots; // Additional slots for zones

  const LandPlot({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredWorldLevel,
    required this.cost,
    this.sizeMultiplier = 1.0,
    this.unlocksZoneSlots = const [],
  });

  @override
  List<Object?> get props => [id, requiredWorldLevel, cost];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'requiredWorldLevel': requiredWorldLevel,
      'cost': cost,
      'sizeMultiplier': sizeMultiplier,
      'unlocksZoneSlots': unlocksZoneSlots,
    };
  }

  factory LandPlot.fromMap(Map<String, dynamic> map) {
    return LandPlot(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      requiredWorldLevel: map['requiredWorldLevel'] as int? ?? 1,
      cost: map['cost'] as int? ?? 0,
      sizeMultiplier: (map['sizeMultiplier'] as num?)?.toDouble() ?? 1.0,
      unlocksZoneSlots: List<String>.from(map['unlocksZoneSlots'] ?? []),
    );
  }
}

/// Catalog of all available land expansions
class LandExpansionCatalog {
  static const List<LandPlot> allPlots = [
    // Tier 1 - Starting expansions
    LandPlot(
      id: 'eastern_meadow',
      name: 'Eastern Meadow',
      description: 'A sunny meadow perfect for new gardens',
      requiredWorldLevel: 3,
      cost: 50,
      sizeMultiplier: 1.2,
      unlocksZoneSlots: ['garden_extension'],
    ),
    LandPlot(
      id: 'stone_quarry',
      name: 'Stone Quarry',
      description: 'Ancient stones for building foundations',
      requiredWorldLevel: 5,
      cost: 100,
      sizeMultiplier: 1.1,
      unlocksZoneSlots: ['forge_extension'],
    ),

    // Tier 2 - Mid-game expansions
    LandPlot(
      id: 'mystic_grove',
      name: 'Mystic Grove',
      description: 'A grove where knowledge flows like water',
      requiredWorldLevel: 8,
      cost: 200,
      sizeMultiplier: 1.3,
      unlocksZoneSlots: ['library_extension', 'shrine_extension'],
    ),
    LandPlot(
      id: 'artists_cliff',
      name: "Artist's Cliff",
      description: 'Inspiring views for creative souls',
      requiredWorldLevel: 10,
      cost: 300,
      sizeMultiplier: 1.2,
      unlocksZoneSlots: ['studio_extension'],
    ),

    // Tier 3 - Late-game expansions
    LandPlot(
      id: 'summit_peak',
      name: 'Summit Peak',
      description: 'The highest point in your world',
      requiredWorldLevel: 15,
      cost: 500,
      sizeMultiplier: 1.5,
      unlocksZoneSlots: ['shrine_tower', 'observatory'],
    ),
    LandPlot(
      id: 'legendary_realm',
      name: 'Legendary Realm',
      description: 'A dimension beyond ordinary expansion',
      requiredWorldLevel: 20,
      cost: 1000,
      sizeMultiplier: 2.0,
      unlocksZoneSlots: [
        'legendary_garden',
        'legendary_forge',
        'legendary_library',
      ],
    ),
  ];

  static LandPlot? getPlotById(String id) {
    return allPlots.cast<LandPlot?>().firstWhere(
      (p) => p?.id == id,
      orElse: () => null,
    );
  }

  static List<LandPlot> getAvailablePlots(
    int worldLevel,
    List<String> unlockedPlots,
  ) {
    return allPlots
        .where(
          (p) =>
              p.requiredWorldLevel <= worldLevel &&
              !unlockedPlots.contains(p.id),
        )
        .toList();
  }

  static List<LandPlot> getUnlockedPlots(List<String> plotIds) {
    return allPlots.where((p) => plotIds.contains(p.id)).toList();
  }
}

/// Represents a rare blueprint that can drop from activities
class RareBlueprint extends Equatable {
  final String id;
  final String buildingId;
  final double dropRate; // 0.0-1.0 probability
  final String triggerCondition; // What triggers the drop
  final String description;

  const RareBlueprint({
    required this.id,
    required this.buildingId,
    required this.dropRate,
    required this.triggerCondition,
    this.description = '',
  });

  @override
  List<Object?> get props => [id, buildingId, dropRate];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'buildingId': buildingId,
      'dropRate': dropRate,
      'triggerCondition': triggerCondition,
      'description': description,
    };
  }

  factory RareBlueprint.fromMap(Map<String, dynamic> map) {
    return RareBlueprint(
      id: map['id'] as String,
      buildingId: map['buildingId'] as String,
      dropRate: (map['dropRate'] as num?)?.toDouble() ?? 0.01,
      triggerCondition: map['triggerCondition'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }
}

/// Catalog of rare blueprint drops
class RareBlueprintCatalog {
  static const List<RareBlueprint> allBlueprints = [
    // Perfect week drops
    RareBlueprint(
      id: 'golden_tree_bp',
      buildingId: 'golden_tree',
      dropRate: 0.15,
      triggerCondition: 'perfect_week', // 7 days 100% completion
      description: 'A golden tree that never withers',
    ),
    RareBlueprint(
      id: 'crystal_fountain_bp',
      buildingId: 'crystal_fountain',
      dropRate: 0.10,
      triggerCondition: 'streak_30', // 30-day streak
      description: 'A fountain of pure clarity',
    ),

    // Zone mastery drops
    RareBlueprint(
      id: 'master_garden_bp',
      buildingId: 'master_garden',
      dropRate: 0.20,
      triggerCondition: 'garden_level_5',
      description: 'The ultimate garden centerpiece',
    ),
    RareBlueprint(
      id: 'arcane_library_bp',
      buildingId: 'arcane_library',
      dropRate: 0.20,
      triggerCondition: 'library_level_5',
      description: 'Ancient knowledge made manifest',
    ),
    RareBlueprint(
      id: 'legendary_forge_bp',
      buildingId: 'legendary_forge',
      dropRate: 0.20,
      triggerCondition: 'forge_level_5',
      description: 'Create items of legend',
    ),
    RareBlueprint(
      id: 'grand_gallery_bp',
      buildingId: 'grand_gallery',
      dropRate: 0.20,
      triggerCondition: 'studio_level_5',
      description: 'Showcase your greatest works',
    ),
    RareBlueprint(
      id: 'eternal_shrine_bp',
      buildingId: 'eternal_shrine',
      dropRate: 0.20,
      triggerCondition: 'shrine_level_5',
      description: 'A shrine of infinite peace',
    ),

    // Special milestone drops
    RareBlueprint(
      id: 'phoenix_statue_bp',
      buildingId: 'phoenix_statue',
      dropRate: 0.05,
      triggerCondition: 'recovery', // Come back from >50% entropy
      description: 'Rise from the ashes of decay',
    ),
    RareBlueprint(
      id: 'world_tree_bp',
      buildingId: 'world_tree',
      dropRate: 0.01,
      triggerCondition: 'all_zones_max', // All zones at level 10
      description: 'The legendary World Tree',
    ),
  ];

  static RareBlueprint? getBlueprintById(String id) {
    return allBlueprints.cast<RareBlueprint?>().firstWhere(
      (b) => b?.id == id,
      orElse: () => null,
    );
  }

  static List<RareBlueprint> getBlueprintsForCondition(String condition) {
    return allBlueprints.where((b) => b.triggerCondition == condition).toList();
  }
}

/// Seasonal event definition
class SeasonalEvent extends Equatable {
  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final List<String>
  exclusiveBuildings; // Buildings only available during event
  final double bonusXpMultiplier;
  final String themeOverride; // Optional world theme during event

  const SeasonalEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.exclusiveBuildings = const [],
    this.bonusXpMultiplier = 1.0,
    this.themeOverride = '',
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  @override
  List<Object?> get props => [id, startDate, endDate];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'exclusiveBuildings': exclusiveBuildings,
      'bonusXpMultiplier': bonusXpMultiplier,
      'themeOverride': themeOverride,
    };
  }

  factory SeasonalEvent.fromMap(Map<String, dynamic> map) {
    return SeasonalEvent(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      exclusiveBuildings: List<String>.from(map['exclusiveBuildings'] ?? []),
      bonusXpMultiplier: (map['bonusXpMultiplier'] as num?)?.toDouble() ?? 1.0,
      themeOverride: map['themeOverride'] as String? ?? '',
    );
  }
}

/// Seasonal events calendar
class SeasonalEventCalendar {
  /// Get recurring seasonal events (generated based on current year)
  static List<SeasonalEvent> getEventsForYear(int year) {
    return [
      SeasonalEvent(
        id: 'spring_bloom_$year',
        name: 'Spring Bloom Festival',
        description: 'Gardens flourish with extra vigor!',
        startDate: DateTime(year, 3, 20),
        endDate: DateTime(year, 4, 3),
        exclusiveBuildings: ['cherry_blossom_tree', 'spring_fountain'],
        bonusXpMultiplier: 1.25,
      ),
      SeasonalEvent(
        id: 'summer_solstice_$year',
        name: 'Summer Solstice',
        description: 'The longest day brings abundant energy!',
        startDate: DateTime(year, 6, 20),
        endDate: DateTime(year, 7, 4),
        exclusiveBuildings: ['sunstone_monument', 'solar_garden'],
        bonusXpMultiplier: 1.5,
      ),
      SeasonalEvent(
        id: 'harvest_festival_$year',
        name: 'Harvest Festival',
        description: 'Reap the rewards of your efforts!',
        startDate: DateTime(year, 9, 22),
        endDate: DateTime(year, 10, 6),
        exclusiveBuildings: ['harvest_altar', 'golden_fields'],
        bonusXpMultiplier: 1.25,
      ),
      SeasonalEvent(
        id: 'winter_wonder_$year',
        name: 'Winter Wonderland',
        description: 'Snow blankets your world in peace!',
        startDate: DateTime(year, 12, 21),
        endDate: DateTime(year + 1, 1, 4),
        exclusiveBuildings: ['ice_palace', 'snow_garden', 'northern_lights'],
        bonusXpMultiplier: 1.3,
        themeOverride: 'winter',
      ),
    ];
  }

  static SeasonalEvent? getCurrentEvent() {
    final now = DateTime.now();
    final events = getEventsForYear(now.year);
    return events.cast<SeasonalEvent?>().firstWhere(
      (e) => e?.isActive ?? false,
      orElse: () => null,
    );
  }

  static SeasonalEvent? getNextEvent() {
    final now = DateTime.now();
    final events = getEventsForYear(now.year);
    final futureEvents = events.where((e) => e.startDate.isAfter(now)).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return futureEvents.isNotEmpty ? futureEvents.first : null;
  }
}
