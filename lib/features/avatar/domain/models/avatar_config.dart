import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/profile/domain/models/silhouette_evolution.dart';

/// Skin tone options for avatar customization
enum SkinTone { lightOlive, mediumBrown, darkEbony }

/// Hair color options
enum HairColor { black, brown, blonde, red, gray, silver, rainbow, custom }

/// Complete configuration for a full-character avatar variant.
///
/// Each unique combination of (archetype × skinTone × hairStyle) maps to
/// a single pre-generated character image. The renderer simply displays
/// this image — no runtime composition of separate body parts.
class AvatarConfig {
  /// User's selected archetype
  final UserArchetype archetype;

  /// Skin tone selection
  final SkinTone skinTone;

  /// Hairstyle identifier
  final String hairStyle;

  /// Hair color selection
  final HairColor hairColor;

  /// Current evolution phase based on level
  final EvolutionPhase evolvedState;

  const AvatarConfig({
    required this.archetype,
    required this.skinTone,
    required this.hairStyle,
    required this.hairColor,
    this.evolvedState = EvolutionPhase.phantom,
  });

  /// Asset key used for file lookup:
  /// `assets/images/avatars/base/{archetype}/{assetKey}.png`
  String get assetKey => '${skinTone.name}_$hairStyle';

  /// Create default config for archetype
  factory AvatarConfig.defaultForArchetype(UserArchetype archetype) {
    return AvatarConfig(
      archetype: archetype,
      skinTone: SkinTone.mediumBrown,
      hairStyle: _defaultHairForArchetype(archetype),
      hairColor: _defaultHairColorForArchetype(archetype),
      evolvedState: EvolutionPhase.phantom,
    );
  }

  /// Create config from user stats
  factory AvatarConfig.fromUserStats({
    required UserArchetype archetype,
    required int level,
    SkinTone? skinTone,
    String? hairStyle,
    HairColor? hairColor,
  }) {
    final phase = SilhouetteEvolutionState.phaseFromLevel(level);

    return AvatarConfig(
      archetype: archetype,
      skinTone: skinTone ?? SkinTone.mediumBrown,
      hairStyle: hairStyle ?? _defaultHairForArchetype(archetype),
      hairColor: hairColor ?? _defaultHairColorForArchetype(archetype),
      evolvedState: phase,
    );
  }

  /// Check if evolved state overlay should be rendered
  bool get showEvolvedOverlay =>
      evolvedState != EvolutionPhase.phantom &&
      evolvedState != EvolutionPhase.construct;

  AvatarConfig copyWith({
    UserArchetype? archetype,
    SkinTone? skinTone,
    String? hairStyle,
    HairColor? hairColor,
    EvolutionPhase? evolvedState,
  }) {
    return AvatarConfig(
      archetype: archetype ?? this.archetype,
      skinTone: skinTone ?? this.skinTone,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      evolvedState: evolvedState ?? this.evolvedState,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvatarConfig &&
          runtimeType == other.runtimeType &&
          archetype == other.archetype &&
          skinTone == other.skinTone &&
          hairStyle == other.hairStyle &&
          hairColor == other.hairColor &&
          evolvedState == other.evolvedState;

  @override
  int get hashCode =>
      archetype.hashCode ^
      skinTone.hashCode ^
      hairStyle.hashCode ^
      hairColor.hashCode ^
      evolvedState.hashCode;
}

// Helper functions for default values

String _defaultHairForArchetype(UserArchetype archetype) {
  switch (archetype) {
    case UserArchetype.athlete:
      return 'short_spiky';
    case UserArchetype.creator:
      return 'messy_shag';
    case UserArchetype.scholar:
      return 'neat_part';
    case UserArchetype.stoic:
      return 'simple_crop';
    case UserArchetype.zealot:
      return 'flowing_long';
    case UserArchetype.none:
      return 'simple_crop';
  }
}

HairColor _defaultHairColorForArchetype(UserArchetype archetype) {
  switch (archetype) {
    case UserArchetype.athlete:
      return HairColor.black;
    case UserArchetype.creator:
      return HairColor.brown;
    case UserArchetype.scholar:
      return HairColor.brown;
    case UserArchetype.stoic:
      return HairColor.gray;
    case UserArchetype.zealot:
      return HairColor.silver;
    case UserArchetype.none:
      return HairColor.brown;
  }
}

/// Extension methods for enum display names
extension AvatarConfigExtensions on AvatarConfig {
  String get skinToneName {
    switch (skinTone) {
      case SkinTone.lightOlive:
        return 'Light Olive';
      case SkinTone.mediumBrown:
        return 'Medium Brown';
      case SkinTone.darkEbony:
        return 'Dark Ebony';
    }
  }

  String get hairColorName {
    switch (hairColor) {
      case HairColor.black:
        return 'Black';
      case HairColor.brown:
        return 'Brown';
      case HairColor.blonde:
        return 'Blonde';
      case HairColor.red:
        return 'Red';
      case HairColor.gray:
        return 'Gray';
      case HairColor.silver:
        return 'Silver';
      case HairColor.rainbow:
        return 'Rainbow';
      case HairColor.custom:
        return 'Custom';
    }
  }
}
