import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:flutter/material.dart';

/// Biome type for different map sections
enum BiomeType {
  valley, // Levels 1-10
  forest, // Levels 11-20
  cliffs, // Levels 21-30
  clouds, // Levels 31-40
  summit, // Levels 41-50
}

/// Configuration for an archetype-specific world map
class ArchetypeMapConfig {
  /// Which archetype this map is for
  final UserArchetype archetype;

  /// Display name of this map
  final String mapName;

  /// Description of the journey
  final String mapDescription;

  /// Primary theme color for this archetype
  final Color primaryColor;

  /// Accent/secondary color
  final Color accentColor;

  /// Background gradient colors
  final List<Color> backgroundGradient;

  /// All nodes on this map
  final List<WorldNode> nodes;

  /// Icon representing this archetype's journey
  final IconData journeyIcon;

  const ArchetypeMapConfig({
    required this.archetype,
    required this.mapName,
    required this.mapDescription,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundGradient,
    required this.nodes,
    required this.journeyIcon,
  });

  /// Get biome info for a given level
  static BiomeType getBiomeForLevel(int level) {
    if (level <= 10) return BiomeType.valley;
    if (level <= 20) return BiomeType.forest;
    if (level <= 30) return BiomeType.cliffs;
    if (level <= 40) return BiomeType.clouds;
    return BiomeType.summit;
  }

  /// Get biome colors
  static List<Color> getBiomeColors(BiomeType biome) {
    switch (biome) {
      case BiomeType.valley:
        return [const Color(0xFF2D5016), const Color(0xFF4A7023)];
      case BiomeType.forest:
        return [const Color(0xFF1B4332), const Color(0xFF2D6A4F)];
      case BiomeType.cliffs:
        return [const Color(0xFF3D405B), const Color(0xFF5C6378)];
      case BiomeType.clouds:
        return [const Color(0xFF4A4E69), const Color(0xFF9A8C98)];
      case BiomeType.summit:
        return [const Color(0xFF22223B), const Color(0xFF4A4E69)];
    }
  }

  /// Get biome name
  static String getBiomeName(BiomeType biome) {
    switch (biome) {
      case BiomeType.valley:
        return 'Valley of Beginnings';
      case BiomeType.forest:
        return 'Forest of Growth';
      case BiomeType.cliffs:
        return 'Cliffs of Challenge';
      case BiomeType.clouds:
        return 'Realm of Clouds';
      case BiomeType.summit:
        return 'The Summit';
    }
  }
}
