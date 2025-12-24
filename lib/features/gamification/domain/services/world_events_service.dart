import 'dart:math';

import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/domain/models/world_building.dart';
import 'package:emerge_app/features/gamification/domain/models/world_expansion.dart';

/// Service for handling rare blueprint drops and seasonal events
class WorldEventsService {
  static final _random = Random();

  /// Check if user qualifies for any rare blueprint drops
  static List<RareBlueprint> checkForBlueprintDrops({
    required UserWorldState worldState,
    required int currentStreak,
    required bool isPerfectDay,
    required double previousEntropy,
  }) {
    final drops = <RareBlueprint>[];
    final alreadyUnlocked = worldState.unlockedBuildings;

    // Check streak milestones
    if (currentStreak == 30) {
      final blueprints = RareBlueprintCatalog.getBlueprintsForCondition(
        'streak_30',
      );
      for (final bp in blueprints) {
        if (!alreadyUnlocked.contains(bp.buildingId) &&
            _rollDrop(bp.dropRate)) {
          drops.add(bp);
        }
      }
    }

    // Check for recovery (came back from >50% entropy)
    if (previousEntropy > 0.5 && worldState.entropy < 0.3) {
      final blueprints = RareBlueprintCatalog.getBlueprintsForCondition(
        'recovery',
      );
      for (final bp in blueprints) {
        if (!alreadyUnlocked.contains(bp.buildingId) &&
            _rollDrop(bp.dropRate)) {
          drops.add(bp);
        }
      }
    }

    // Check zone level milestones
    for (final entry in worldState.zones.entries) {
      final zoneId = entry.key;
      final level = (entry.value['level'] as int?) ?? 1;

      if (level >= 5) {
        final condition = '${zoneId}_level_5';
        final blueprints = RareBlueprintCatalog.getBlueprintsForCondition(
          condition,
        );
        for (final bp in blueprints) {
          if (!alreadyUnlocked.contains(bp.buildingId) &&
              _rollDrop(bp.dropRate)) {
            drops.add(bp);
          }
        }
      }
    }

    // Check if all zones are at max level
    bool allZonesMax = true;
    for (final zone in worldState.zones.values) {
      final zoneLevel = (zone['level'] as int?) ?? 1;
      if (zoneLevel < 10) {
        allZonesMax = false;
        break;
      }
    }
    if (allZonesMax) {
      final blueprints = RareBlueprintCatalog.getBlueprintsForCondition(
        'all_zones_max',
      );
      for (final bp in blueprints) {
        if (!alreadyUnlocked.contains(bp.buildingId) &&
            _rollDrop(bp.dropRate)) {
          drops.add(bp);
        }
      }
    }

    return drops;
  }

  /// Check for perfect week achievement
  static bool checkPerfectWeek(List<bool> lastSevenDays) {
    return lastSevenDays.length >= 7 && lastSevenDays.every((day) => day);
  }

  /// Roll for a drop based on probability
  static bool _rollDrop(double rate) {
    return _random.nextDouble() < rate;
  }

  /// Get current seasonal event if any
  static SeasonalEvent? getCurrentEvent() {
    return SeasonalEventCalendar.getCurrentEvent();
  }

  /// Get next upcoming event
  static SeasonalEvent? getNextEvent() {
    return SeasonalEventCalendar.getNextEvent();
  }

  /// Calculate XP multiplier including event bonuses
  static double calculateXpMultiplier() {
    final event = getCurrentEvent();
    return event?.bonusXpMultiplier ?? 1.0;
  }

  /// Get exclusive buildings available during current event
  static List<WorldBuilding> getEventExclusiveBuildings() {
    final event = getCurrentEvent();
    if (event == null) return [];

    // Map event exclusive building IDs to WorldBuilding objects
    // In a real app, these would be in the WorldBuildingCatalog
    return event.exclusiveBuildings.map((id) {
      return WorldBuilding(
        id: id,
        name: _formatBuildingName(id),
        description: 'Exclusive to ${event.name}',
        zoneId: 'special',
        requiredZoneLevel: 1,
        rarity: BuildingRarity.epic,
        type: WorldElementType.decoration,
      );
    }).toList();
  }

  static String _formatBuildingName(String id) {
    return id
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Get countdown to next event
  static Duration? getTimeToNextEvent() {
    final next = getNextEvent();
    if (next == null) return null;
    return next.startDate.difference(DateTime.now());
  }
}

/// Mixin for adding event-awareness to screens
mixin SeasonalEventMixin {
  SeasonalEvent? get currentEvent => WorldEventsService.getCurrentEvent();

  bool get hasActiveEvent => currentEvent != null;

  double get xpMultiplier => WorldEventsService.calculateXpMultiplier();

  List<WorldBuilding> get eventBuildings =>
      WorldEventsService.getEventExclusiveBuildings();
}
