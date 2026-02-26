import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_config.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/profile/domain/models/silhouette_evolution.dart';

/// Service for resolving avatar asset paths.
///
/// Each avatar is a single pre-generated character image keyed by
/// (archetype × skinTone × hairStyle). No separate body-part images
/// are needed — everything is baked into one cohesive PNG.
class AvatarAssetService {
  /// Base asset path for all avatar assets
  static const String _basePath = 'assets/images/avatars';

  /// Get the full character image path for a given config.
  ///
  /// The image is a complete full-body character on transparent background,
  /// generated via Pollinations.ai gptimage model.
  String getCharacterPath(
    UserArchetype archetype,
    SkinTone skinTone,
    String hairStyle,
  ) {
    final archetypeName = archetype.name;
    final skinToneName = skinTone.name;
    return '$_basePath/base/$archetypeName/${skinToneName}_$hairStyle.png';
  }

  /// Convenience method using an AvatarConfig directly.
  String getCharacterPathFromConfig(AvatarConfig config) {
    return getCharacterPath(
      config.archetype,
      config.skinTone,
      config.hairStyle,
    );
  }

  /// Get the silhouette asset for archetype (fallback when character image missing)
  String getSilhouettePath(UserArchetype archetype) {
    final archetypeName = archetype.name;
    return '$_basePath/${archetypeName}_silhouette.png';
  }

  /// Get the archetype portrait asset (for onboarding / selection UI)
  String getArchetypePortraitPath(UserArchetype archetype) {
    return ArchetypeTheme.forArchetype(archetype).assetPath;
  }

  /// Get the glow effect asset path
  String getGlowEffectPath({bool strong = false}) {
    return strong
        ? '$_basePath/effects/glow_strong.png'
        : '$_basePath/effects/glow_soft.png';
  }

  /// Get sparkles effect asset path
  String getSparklesPath() {
    return '$_basePath/effects/sparkles.png';
  }

  /// Get the evolved state overlay asset path
  String getEvolvedOverlayPath(EvolutionPhase phase) {
    final phaseName = phase.name;
    return '$_basePath/evolved/$phaseName/overlay.png';
  }

  /// Get available hairstyles for archetype
  List<String> getAvailableHairstyles(UserArchetype archetype) {
    switch (archetype) {
      case UserArchetype.athlete:
        return const [
          'buzz_cut',
          'short_spiky',
          'swept_back',
          'pompadour',
          'undercut',
        ];
      case UserArchetype.creator:
        return const [
          'messy_shag',
          'man_bun',
          'side_swept',
          'curly_afro',
          'dreadlocks',
        ];
      case UserArchetype.scholar:
        return const [
          'neat_part',
          'slicked_back',
          'bob_cut',
          'wispy_bangs',
          'gray_academic',
        ];
      case UserArchetype.stoic:
        return const [
          'monk_shave',
          'simple_crop',
          'center_part',
          'low_bun',
          'bald_with_beard',
        ];
      case UserArchetype.zealot:
        return const [
          'flowing_long',
          'space_buns',
          'ethereal_wisps',
          'silver_vibrant',
          'cosmic_halos',
        ];
      case UserArchetype.none:
        return const ['simple_crop'];
    }
  }

  /// Get available skin tones
  List<SkinTone> getAvailableSkinTones() {
    return SkinTone.values;
  }

  /// Get prompt for generating a full character via Pollinations.ai
  ///
  /// Uses style-locked 2D flat vector prompt template for consistency
  /// across all generated characters.
  String getGenerationPrompt({
    required UserArchetype archetype,
    required SkinTone skinTone,
    required String hairStyle,
  }) {
    final archetypeDesc = _getArchetypeDescriptor(archetype);
    final skinToneDesc = _getSkinToneDescriptor(skinTone);
    final hairDesc = hairStyle.replaceAll('_', ' ');

    return '''
2D flat vector character, full body front-facing standing pose,
$archetypeDesc build, $skinToneDesc skin, $hairDesc hairstyle,
wearing ${_getDefaultOutfitDescriptor(archetype)},
thick clean black outlines, cell-shaded coloring, no gradients,
pastel color palette, minimalist design, character sheet style,
centered in frame, professional game character art,
no text, no watermark, no other objects
''';
  }

  /// Get negative prompt to exclude unwanted elements
  String getNegativePrompt() {
    return 'background, scenery, environment, text, watermark, '
        'border, frame, multiple characters, realistic, 3D, '
        'photorealistic, blurry, low quality';
  }

  String _getArchetypeDescriptor(UserArchetype archetype) {
    switch (archetype) {
      case UserArchetype.athlete:
        return 'athletic sporty dynamic';
      case UserArchetype.creator:
        return 'artistic creative slender';
      case UserArchetype.scholar:
        return 'lean intellectual studious';
      case UserArchetype.stoic:
        return 'balanced strong meditative';
      case UserArchetype.zealot:
        return 'passionate spiritual fire focused';
      case UserArchetype.none:
        return 'balanced average';
    }
  }

  String _getSkinToneDescriptor(SkinTone tone) {
    switch (tone) {
      case SkinTone.lightOlive:
        return 'light olive';
      case SkinTone.mediumBrown:
        return 'medium brown';
      case SkinTone.darkEbony:
        return 'dark ebony';
    }
  }

  String _getDefaultOutfitDescriptor(UserArchetype archetype) {
    switch (archetype) {
      case UserArchetype.athlete:
        return 'modern athletic sportswear tracksuit';
      case UserArchetype.creator:
        return 'casual bohemian artist apron';
      case UserArchetype.scholar:
        return 'smart tweed jacket with glasses';
      case UserArchetype.stoic:
        return 'simple minimalist linen tunic';
      case UserArchetype.zealot:
        return 'layered monastic robes with crimson accents';
      case UserArchetype.none:
        return 'simple casual clothing';
    }
  }
}
