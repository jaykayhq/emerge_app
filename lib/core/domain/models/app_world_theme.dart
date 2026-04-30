// lib/core/domain/models/app_world_theme.dart

/// The six selectable world background themes.
/// Named AppWorldTheme to avoid collision with the existing
/// WorldTheme enum in user_extension.dart (which is a Firestore model field).
enum AppWorldTheme {
  nebula,
  forest,
  city,
  mountain,
  ocean,
  volcanic;

  String get displayName {
    switch (this) {
      case AppWorldTheme.nebula:
        return 'Cosmic Nebula';
      case AppWorldTheme.forest:
        return 'Living Forest';
      case AppWorldTheme.city:
        return 'Neon City';
      case AppWorldTheme.mountain:
        return 'Sacred Mountain';
      case AppWorldTheme.ocean:
        return 'Ocean Abyss';
      case AppWorldTheme.volcanic:
        return 'Volcanic Realm';
    }
  }

  String get emoji {
    switch (this) {
      case AppWorldTheme.nebula:
        return '🌌';
      case AppWorldTheme.forest:
        return '🌲';
      case AppWorldTheme.city:
        return '🏙️';
      case AppWorldTheme.mountain:
        return '🌅';
      case AppWorldTheme.ocean:
        return '🌊';
      case AppWorldTheme.volcanic:
        return '🌋';
    }
  }

  /// Returns null for the nebula theme (it uses a code-driven widget).
  /// Returns the folder name for image-based themes.
  String? get assetFolder {
    if (this == AppWorldTheme.nebula) return null;
    return name; // 'forest', 'city', 'mountain', 'ocean', 'volcanic'
  }
}

/// Three visual states derived from world health percentage.
enum WorldHealthState {
  thriving, // 0.70–1.0
  neutral, // 0.30–0.69
  decaying; // 0.0–0.29

  static WorldHealthState fromHealth(double health) {
    if (health >= 0.75) return WorldHealthState.thriving;
    if (health >= 0.40) return WorldHealthState.neutral;
    return WorldHealthState.decaying;
  }

  String get assetName => name; // 'thriving', 'neutral', 'decaying'
}

/// Resolves the asset path for a given theme and health state.
/// Returns null when the theme is [AppWorldTheme.nebula].
String? resolveBackgroundAsset(AppWorldTheme theme, WorldHealthState state) {
  final folder = theme.assetFolder;
  if (folder == null) return null;
  return 'assets/images/backgrounds/$folder/${state.assetName}.png';
}

/// Configuration for the procedural Nebula background based on health.
class NebulaStateConfig {
  final double starDensityFactor;
  final double driftSpeedFactor;
  final double nebulaOpacity;
  final double colorSaturation;
  final double twinkleSpeedFactor;
  final double particleCountFactor;

  const NebulaStateConfig({
    required this.starDensityFactor,
    required this.driftSpeedFactor,
    required this.nebulaOpacity,
    required this.colorSaturation,
    required this.twinkleSpeedFactor,
    required this.particleCountFactor,
  });

  static NebulaStateConfig forState(WorldHealthState state, {double entropy = 0.0}) {
    final baseConfig = _getBaseConfig(state);
    
    // Entropy reduces saturation and speed significantly
    final entropyFactor = (1.0 - entropy).clamp(0.0, 1.0);
    
    return NebulaStateConfig(
      starDensityFactor: baseConfig.starDensityFactor * (1.0 - (entropy * 0.5)),
      driftSpeedFactor: baseConfig.driftSpeedFactor * entropyFactor,
      nebulaOpacity: baseConfig.nebulaOpacity * (1.0 + (entropy * 0.5)), // Entropy makes it cloudier/foggier
      colorSaturation: baseConfig.colorSaturation * entropyFactor,
      twinkleSpeedFactor: baseConfig.twinkleSpeedFactor * entropyFactor,
      particleCountFactor: baseConfig.particleCountFactor * (1.0 - (entropy * 0.7)),
    );
  }

  static NebulaStateConfig _getBaseConfig(WorldHealthState state) {
    switch (state) {
      case WorldHealthState.thriving:
        return const NebulaStateConfig(
          starDensityFactor: 1.5,
          driftSpeedFactor: 1.2,
          nebulaOpacity: 0.20,
          colorSaturation: 1.3,
          twinkleSpeedFactor: 1.5,
          particleCountFactor: 2.0,
        );
      case WorldHealthState.neutral:
        return const NebulaStateConfig(
          starDensityFactor: 1.0,
          driftSpeedFactor: 1.0,
          nebulaOpacity: 0.12,
          colorSaturation: 1.0,
          twinkleSpeedFactor: 1.0,
          particleCountFactor: 1.0,
        );
      case WorldHealthState.decaying:
        return const NebulaStateConfig(
          starDensityFactor: 0.4,
          driftSpeedFactor: 0.5,
          nebulaOpacity: 0.05,
          colorSaturation: 0.3,
          twinkleSpeedFactor: 0.4,
          particleCountFactor: 0.3,
        );
    }
  }
}
