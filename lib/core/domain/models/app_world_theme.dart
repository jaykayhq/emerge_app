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
    if (health >= 0.70) return WorldHealthState.thriving;
    if (health >= 0.30) return WorldHealthState.neutral;
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
