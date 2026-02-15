import 'package:flutter/material.dart';

/// The 5-tier evolution system for the silhouette
enum EvolutionPhase {
  /// Level 1-5: Smoky, nebulous cloud
  phantom,

  /// Level 6-15: Wireframe mesh visible
  construct,

  /// Level 16-30: Solid matte silhouette
  incarnate,

  /// Level 31-50: Kintsugi cracks glowing
  radiant,

  /// Level 50+: Pure energy transcendence
  ascended,
}

/// Body zones where artifacts can attach
enum BodyZone {
  ankles, // Cardio habits
  head, // Mindfulness habits
  eyes, // Focus habits
  chest, // Strength habits
  hands, // Creativity habits
  core, // Vitality habits
  spine, // Resilience habits
}

/// Categories of habits that map to body zones
enum ArtifactCategory {
  cardio, // → Legs
  mindfulness, // → Head
  strength, // → Torso
  creativity, // → Hands
  hydration, // → Circulatory
}

/// An unlockable visual artifact that appears on the silhouette
class BodyArtifact {
  final String id;
  final String name;
  final String description;
  final ArtifactCategory category;
  final BodyZone zone;
  final int requiredVotes; // Habit completions to unlock
  final Color glowColor;
  final String? svgAsset; // Optional custom SVG

  const BodyArtifact({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.zone,
    required this.requiredVotes,
    required this.glowColor,
    this.svgAsset,
  });

  /// Predefined artifacts
  static const hermesWings = BodyArtifact(
    id: 'hermes_wings',
    name: 'Hermes Wings',
    description: 'Glowing trails on ankles from cardio mastery',
    category: ArtifactCategory.cardio,
    zone: BodyZone.ankles,
    requiredVotes: 50,
    glowColor: Color(0xFFf7768e), // Coral
  );

  static const goldenShoes = BodyArtifact(
    id: 'golden_shoes',
    name: 'Golden Shoes',
    description: 'Soles that spark with energy',
    category: ArtifactCategory.cardio,
    zone: BodyZone.ankles,
    requiredVotes: 100,
    glowColor: Color(0xFFe0af68), // Gold
  );

  static const halo = BodyArtifact(
    id: 'halo',
    name: 'The Halo',
    description: 'Floating ring of light from meditation',
    category: ArtifactCategory.mindfulness,
    zone: BodyZone.head,
    requiredVotes: 30,
    glowColor: Color(0xFFbb9af7), // Purple
  );

  static const thirdEye = BodyArtifact(
    id: 'third_eye',
    name: 'Third Eye',
    description: 'Gem on forehead that opens at high streaks',
    category: ArtifactCategory.mindfulness,
    zone: BodyZone.eyes,
    requiredVotes: 100,
    glowColor: Color(0xFF00F0FF), // Cyan
  );

  static const aegis = BodyArtifact(
    id: 'aegis',
    name: 'The Aegis',
    description: 'Spectral breastplate from strength training',
    category: ArtifactCategory.strength,
    zone: BodyZone.chest,
    requiredVotes: 50,
    glowColor: Color(0xFF7aa2f7), // Blue
  );

  static const coreGlow = BodyArtifact(
    id: 'core_glow',
    name: 'Core Glow',
    description: 'Pulsing center of power',
    category: ArtifactCategory.strength,
    zone: BodyZone.core,
    requiredVotes: 100,
    glowColor: Color(0xFF9ece6a), // Green
  );

  static const midasTouch = BodyArtifact(
    id: 'midas_touch',
    name: 'Midas Touch',
    description: 'Hands glow gold from creative work',
    category: ArtifactCategory.creativity,
    zone: BodyZone.hands,
    requiredVotes: 50,
    glowColor: Color(0xFFe0af68), // Gold
  );

  static const floatingTools = BodyArtifact(
    id: 'floating_tools',
    name: 'Floating Tools',
    description: 'Pen, brush, or orb floats near hands',
    category: ArtifactCategory.creativity,
    zone: BodyZone.hands,
    requiredVotes: 100,
    glowColor: Color(0xFFff9e64), // Orange
  );

  static const theFlow = BodyArtifact(
    id: 'the_flow',
    name: 'The Flow',
    description: 'Visible veins of light from hydration',
    category: ArtifactCategory.hydration,
    zone: BodyZone.core,
    requiredVotes: 30,
    glowColor: Color(0xFF73daca), // Aqua
  );

  /// All predefined artifacts
  static const List<BodyArtifact> all = [
    hermesWings,
    goldenShoes,
    halo,
    thirdEye,
    aegis,
    coreGlow,
    midasTouch,
    floatingTools,
    theFlow,
  ];
}

/// Complete evolution state for rendering the silhouette
class SilhouetteEvolutionState {
  final EvolutionPhase phase;
  final int level;
  final double phaseProgress; // 0.0-1.0 progress within current phase
  final List<BodyArtifact> unlockedArtifacts;
  final double entropyLevel; // 0.0 = perfect, 1.0 = full decay
  final int currentStreak;
  final int daysMissed;

  const SilhouetteEvolutionState({
    required this.phase,
    required this.level,
    this.phaseProgress = 0.0,
    this.unlockedArtifacts = const [],
    this.entropyLevel = 0.0,
    this.currentStreak = 0,
    this.daysMissed = 0,
  });

  /// Calculate evolution phase from level
  static EvolutionPhase phaseFromLevel(int level) {
    if (level >= 50) return EvolutionPhase.ascended;
    if (level >= 31) return EvolutionPhase.radiant;
    if (level >= 16) return EvolutionPhase.incarnate;
    if (level >= 6) return EvolutionPhase.construct;
    return EvolutionPhase.phantom;
  }

  /// Calculate progress within current phase
  static double progressInPhase(int level) {
    if (level >= 50) return 1.0;
    if (level >= 31) return (level - 31) / 19; // 31-50
    if (level >= 16) return (level - 16) / 15; // 16-30
    if (level >= 6) return (level - 6) / 10; // 6-15
    return (level - 1) / 5; // 1-5
  }

  /// Factory to create state from user stats
  factory SilhouetteEvolutionState.fromUserStats({
    required int level,
    required int currentStreak,
    required int daysMissed,
    required Map<String, int> habitVotes, // category -> vote count
  }) {
    final phase = phaseFromLevel(level);
    final progress = progressInPhase(level);

    // Calculate entropy based on days missed
    final entropy = (daysMissed / 3.0).clamp(0.0, 1.0);

    // Determine unlocked artifacts
    final unlocked = <BodyArtifact>[];
    for (final artifact in BodyArtifact.all) {
      final categoryVotes = habitVotes[artifact.category.name] ?? 0;
      if (categoryVotes >= artifact.requiredVotes) {
        unlocked.add(artifact);
      }
    }

    return SilhouetteEvolutionState(
      phase: phase,
      level: level,
      phaseProgress: progress,
      unlockedArtifacts: unlocked,
      entropyLevel: entropy,
      currentStreak: currentStreak,
      daysMissed: daysMissed,
    );
  }

  /// Check if should trigger evolution animation
  bool shouldEvolve(SilhouetteEvolutionState previous) {
    return phase.index > previous.phase.index;
  }

  /// Phase display name
  String get phaseName {
    switch (phase) {
      case EvolutionPhase.phantom:
        return 'The Phantom';
      case EvolutionPhase.construct:
        return 'The Construct';
      case EvolutionPhase.incarnate:
        return 'The Incarnate';
      case EvolutionPhase.radiant:
        return 'The Radiant';
      case EvolutionPhase.ascended:
        return 'The Ascended';
    }
  }

  /// Phase description
  String get phaseDescription {
    switch (phase) {
      case EvolutionPhase.phantom:
        return 'I am potential, but undefined.';
      case EvolutionPhase.construct:
        return 'I am building the framework.';
      case EvolutionPhase.incarnate:
        return 'I am here. I am consistent.';
      case EvolutionPhase.radiant:
        return 'I am powerful. My habits are fueling me.';
      case EvolutionPhase.ascended:
        return 'I have transcended. The habit is my identity.';
    }
  }

  SilhouetteEvolutionState copyWith({
    EvolutionPhase? phase,
    int? level,
    double? phaseProgress,
    List<BodyArtifact>? unlockedArtifacts,
    double? entropyLevel,
    int? currentStreak,
    int? daysMissed,
  }) {
    return SilhouetteEvolutionState(
      phase: phase ?? this.phase,
      level: level ?? this.level,
      phaseProgress: phaseProgress ?? this.phaseProgress,
      unlockedArtifacts: unlockedArtifacts ?? this.unlockedArtifacts,
      entropyLevel: entropyLevel ?? this.entropyLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      daysMissed: daysMissed ?? this.daysMissed,
    );
  }
}
