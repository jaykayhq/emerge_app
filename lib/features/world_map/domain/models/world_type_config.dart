// lib/features/world_map/domain/models/world_type_config.dart
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';

/// Maps a HabitAttribute to its world-type visual identity.
class WorldTypeConfig {
  final HabitAttribute attribute;
  final String worldName;
  final Color primaryColor;
  final IconData fallbackIcon;
  final String iconAssetPath;

  // Stage names — 10 stages, each spanning 5 levels (1-5, 6-10, ... 46-50)
  final List<String> stageNames;

  const WorldTypeConfig({
    required this.attribute,
    required this.worldName,
    required this.primaryColor,
    required this.fallbackIcon,
    required this.iconAssetPath,
    required this.stageNames,
  });

  /// Returns the local asset path for this attribute at [level] (1–50).
  String backgroundAssetPath(int level) {
    final clamped = level.clamp(1, 50);
    return 'assets/worlds/${attribute.name}/level_$clamped.jpg';
  }

  /// Returns the stage name for [level] (1–50).
  String stageName(int level) {
    final idx = ((level - 1) ~/ 5).clamp(0, 9);
    return stageNames[idx];
  }

  /// Stage number (1–10) for [level].
  int stageNumber(int level) => ((level - 1) ~/ 5).clamp(0, 9) + 1;

  static WorldTypeConfig forAttribute(HabitAttribute attr) =>
      all.firstWhere((c) => c.attribute == attr);

  static const List<WorldTypeConfig> all = [
    WorldTypeConfig(
      attribute: HabitAttribute.strength,
      worldName: 'Forest',
      primaryColor: Color(0xFF4CAF50),
      fallbackIcon: Icons.park,
      iconAssetPath: 'assets/icons/attribute_strength.png',
      stageNames: [
        'Seedling',
        'Young Grove',
        'Woodland',
        'Deep Forest',
        'Ancient Canopy',
        'Mystical Thicket',
        'Verdant Sanctum',
        'Elder Grove',
        'Primordial Forest',
        'Legendary Wilderness',
      ],
    ),
    WorldTypeConfig(
      attribute: HabitAttribute.intellect,
      worldName: 'City',
      primaryColor: Color(0xFF2196F3),
      fallbackIcon: Icons.location_city,
      iconAssetPath: 'assets/icons/attribute_intellect.png',
      stageNames: [
        'Crossroads',
        'Township',
        'Borough',
        'Metropolis',
        'Grand City',
        'Tech Hub',
        'Arcology',
        'Nexus',
        'Singularity City',
        'Legendary Megacity',
      ],
    ),
    WorldTypeConfig(
      attribute: HabitAttribute.vitality,
      worldName: 'Volcanic',
      primaryColor: Color(0xFFFF5722),
      fallbackIcon: Icons.local_fire_department,
      iconAssetPath: 'assets/icons/attribute_vitality.png',
      stageNames: [
        'Dormant Caldera',
        'Ashen Slopes',
        'Lava Fields',
        'Fire Vents',
        'Eruption Zone',
        'Magma River',
        'Pyroclastic Wastes',
        'Inferno Peaks',
        'Hellfire Citadel',
        'Legendary Infernal Forge',
      ],
    ),
    WorldTypeConfig(
      attribute: HabitAttribute.creativity,
      worldName: 'Oceanic',
      primaryColor: Color(0xFF00BCD4),
      fallbackIcon: Icons.waves,
      iconAssetPath: 'assets/icons/attribute_creativity.png',
      stageNames: [
        'Tidal Pools',
        'Coastal Shallows',
        'Open Waters',
        'Reef Kingdom',
        'Deep Currents',
        'Abyssal Plains',
        'Bioluminescent Depths',
        'Hadal Zone',
        'Leviathan Trench',
        'Legendary Sunken Realm',
      ],
    ),
    WorldTypeConfig(
      attribute: HabitAttribute.focus,
      worldName: 'Lightning',
      primaryColor: Color(0xFFFFC107),
      fallbackIcon: Icons.flash_on,
      iconAssetPath: 'assets/icons/attribute_focus.png',
      stageNames: [
        'Still Air',
        'Rising Pressure',
        'Overcast Skies',
        'Stormfront',
        'Thunderhead',
        'Tempest Core',
        'Supercell',
        'Eye of the Vortex',
        'Perpetual Storm',
        'Legendary Thunder Throne',
      ],
    ),
    WorldTypeConfig(
      attribute: HabitAttribute.spirit,
      worldName: 'Celestial',
      primaryColor: Color(0xFF9C27B0),
      fallbackIcon: Icons.auto_awesome,
      iconAssetPath: 'assets/icons/attribute_spirit.png',
      stageNames: [
        'Bare Night Sky',
        'Starfield',
        'Constellation',
        'Nebula Birth',
        'Cosmic Dust',
        'Aurora Realm',
        'Galactic Edge',
        'Quasar Basin',
        'Cosmic Singularity',
        'Legendary Astral Plane',
      ],
    ),
  ];
}
