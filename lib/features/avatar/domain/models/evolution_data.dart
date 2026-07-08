/// Evolution phase of an avatar figure.
///
/// Determines visual properties: opacity, glow intensity, core glow,
/// kintsugi cracks, and sparkle particles. The phase is derived from
/// the user's level.
enum EvolutionPhase {
  phantom,
  construct,
  incarnate,
  radiant,
  ascended;

  static EvolutionPhase fromLevel(int level) {
    if (level <= 5) return EvolutionPhase.phantom;
    if (level <= 15) return EvolutionPhase.construct;
    if (level <= 30) return EvolutionPhase.incarnate;
    if (level <= 50) return EvolutionPhase.radiant;
    return EvolutionPhase.ascended;
  }

  /// Opacity 0..1 for the figure body.
  double get alpha {
    switch (this) {
      case EvolutionPhase.phantom:
        return 0.3;
      case EvolutionPhase.construct:
        return 0.6;
      case EvolutionPhase.incarnate:
        return 0.9;
      case EvolutionPhase.radiant:
        return 1.0;
      case EvolutionPhase.ascended:
        return 1.0;
    }
  }

  /// Glow blur sigma for the evolution aura.
  double get glowIntensity {
    switch (this) {
      case EvolutionPhase.phantom:
        return 0.0;
      case EvolutionPhase.construct:
        return 2.0;
      case EvolutionPhase.incarnate:
        return 4.0;
      case EvolutionPhase.radiant:
        return 6.0;
      case EvolutionPhase.ascended:
        return 9.0;
    }
  }

  /// Whether the chest core glow is visible.
  bool get hasCoreGlow => index >= EvolutionPhase.incarnate.index;

  /// Whether golden kintsugi crack lines appear on the body.
  bool get hasKintsugi =>
      this == EvolutionPhase.radiant || this == EvolutionPhase.ascended;

  /// Whether floating sparkle particles render around the figure.
  bool get hasSparkles => this == EvolutionPhase.ascended;
}
