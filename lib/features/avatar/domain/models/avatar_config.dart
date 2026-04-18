import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/profile/domain/models/silhouette_evolution.dart';

// Kept for Firestore serialisation in the Avatar entity — not used in rendering.
enum SkinTone { lightOlive, mediumBrown, darkEbony }

// Kept for Firestore serialisation in the Avatar entity — not used in rendering.
enum HairColor { black, brown, blonde, red, gray, silver, rainbow, custom }

/// Rendering configuration for the avatar widget.
///
/// The avatar is fully defined by [archetype] and [evolvedState].
/// Skin tone and hairstyle are stored in the Firestore [Avatar] entity for
/// data purposes but are NOT used in rendering — the silhouette system is
/// archetype-defined and visually gender-neutral across all phases.
class AvatarConfig {
  final UserArchetype archetype;
  final EvolutionPhase evolvedState;

  const AvatarConfig({
    required this.archetype,
    this.evolvedState = EvolutionPhase.phantom,
  });

  /// Create default config for an archetype.
  factory AvatarConfig.defaultForArchetype(UserArchetype archetype) {
    return AvatarConfig(
      archetype: archetype,
      evolvedState: EvolutionPhase.phantom,
    );
  }

  /// Create config from user stats (archetype + level).
  factory AvatarConfig.fromUserStats({
    required UserArchetype archetype,
    required int level,
  }) {
    final phase = SilhouetteEvolutionState.phaseFromLevel(level);
    return AvatarConfig(
      archetype: archetype,
      evolvedState: phase,
    );
  }

  /// Whether the evolution overlay should be rendered.
  /// All phases except phantom show the overlay.
  bool get showEvolvedOverlay => evolvedState != EvolutionPhase.phantom;

  AvatarConfig copyWith({
    UserArchetype? archetype,
    EvolutionPhase? evolvedState,
  }) {
    return AvatarConfig(
      archetype: archetype ?? this.archetype,
      evolvedState: evolvedState ?? this.evolvedState,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvatarConfig &&
          runtimeType == other.runtimeType &&
          archetype == other.archetype &&
          evolvedState == other.evolvedState;

  @override
  int get hashCode => archetype.hashCode ^ evolvedState.hashCode;
}
