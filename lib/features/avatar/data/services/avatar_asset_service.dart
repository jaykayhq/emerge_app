import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/profile/domain/models/silhouette_evolution.dart';

/// Service for resolving avatar asset paths.
///
/// Uses a silhouette-reveal progression model:
/// - Levels 1–49 (Phantom → Radiant): returns empty string from [getCharacterPath];
///   the renderer falls back to the code-painted [_FallbackSilhouettePainter].
/// - Level 50+ (Ascended): returns the archetype-specific `ascended.png` path
///   so the full character art reveal is displayed.
///
/// Rendering layers (back to front):
/// 1. Background glow   — phase intensity
/// 2. Character image   — ascended.png OR code-painted silhouette
/// 3. Evolution overlay — constructed/incarnate/radiant/ascended texture PNG
/// 4. Sparkles          — Ascended phase only
/// 5. Phase label text
class AvatarAssetService {
  static const String _basePath = 'assets/images/avatars';

  /// Returns character image path for the given archetype and phase.
  ///
  /// Returns the `ascended.png` path only at [EvolutionPhase.ascended].
  /// Returns empty string for all other phases — the renderer's fallback
  /// chain will engage the code-painted silhouette automatically.
  String getCharacterPath(UserArchetype archetype, EvolutionPhase phase) {
    if (phase == EvolutionPhase.ascended) {
      return '$_basePath/base/${archetype.name}/ascended.png';
    }
    return '';
  }

  /// Returns the evolved state overlay PNG path for a given phase.
  ///
  /// Returns empty string for [EvolutionPhase.phantom] — no overlay at that stage.
  String getEvolvedOverlayPath(EvolutionPhase phase) {
    if (phase == EvolutionPhase.phantom) return '';
    return '$_basePath/evolved/${phase.name}/overlay.png';
  }

  /// Returns the static archetype silhouette PNG path.
  ///
  /// Used as a mid-level fallback: if `ascended.png` is not yet generated,
  /// the renderer attempts this before falling back to the code painter.
  String getSilhouettePath(UserArchetype archetype) {
    return '$_basePath/${archetype.name}_silhouette.png';
  }

  /// Returns the archetype portrait asset path (onboarding / selection UI).
  String getArchetypePortraitPath(UserArchetype archetype) {
    return ArchetypeTheme.forArchetype(archetype).assetPath;
  }

  /// Returns the soft or strong glow effect PNG path.
  String getGlowEffectPath({bool strong = false}) {
    return strong
        ? '$_basePath/effects/glow_strong.png'
        : '$_basePath/effects/glow_soft.png';
  }

  /// Returns the sparkles effect PNG path (Ascended phase only).
  String getSparklesPath() {
    return '$_basePath/effects/sparkles.png';
  }
}
