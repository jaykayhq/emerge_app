import 'package:emerge_app/features/avatar/data/services/avatar_asset_service.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_config.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/profile/domain/models/silhouette_evolution.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the avatar asset service
final avatarAssetServiceProvider = Provider<AvatarAssetService>((ref) {
  return AvatarAssetService();
});

/// Avatar configuration state
class AvatarState {
  final AvatarConfig config;
  final bool isLoading;
  final String? error;

  const AvatarState({required this.config, this.isLoading = false, this.error});

  AvatarState copyWith({AvatarConfig? config, bool? isLoading, String? error}) {
    return AvatarState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Avatar state controller for managing avatar configuration.
///
/// Handles avatar customization (archetype, skin tone, hairstyle) and
/// evolution state updates. Each config change maps to a different
/// pre-generated character image.
final avatarControllerProvider =
    StateNotifierProvider<AvatarController, AvatarState>((ref) {
      return AvatarController();
    });

/// Avatar state notifier
class AvatarController extends StateNotifier<AvatarState> {
  AvatarController()
    : super(
        AvatarState(
          config: AvatarConfig.defaultForArchetype(UserArchetype.none),
        ),
      );

  /// Update avatar configuration
  void updateConfig(AvatarConfig newConfig) {
    state = state.copyWith(config: newConfig);
    _persistToProfile();
  }

  /// Update archetype and regenerate default config
  void updateArchetype(UserArchetype archetype) {
    final newConfig = AvatarConfig.defaultForArchetype(archetype);
    updateConfig(newConfig);
  }

  /// Update skin tone
  void updateSkinTone(SkinTone skinTone) {
    updateConfig(state.config.copyWith(skinTone: skinTone));
  }

  /// Update hairstyle
  void updateHairstyle(String hairStyle) {
    updateConfig(state.config.copyWith(hairStyle: hairStyle));
  }

  /// Update hair color
  void updateHairColor(HairColor hairColor) {
    updateConfig(state.config.copyWith(hairColor: hairColor));
  }

  /// Update evolved state based on level
  void updateEvolvedState(int level) {
    final phase = _getPhaseForLevel(level);
    if (phase != state.config.evolvedState) {
      updateConfig(state.config.copyWith(evolvedState: phase));
    }
  }

  /// Reset to default config for current archetype
  void resetToDefault() {
    final defaultConfig = AvatarConfig.defaultForArchetype(
      state.config.archetype,
    );
    updateConfig(defaultConfig);
  }

  /// Load avatar configuration from user stats
  void loadFromUserStats({
    required UserArchetype archetype,
    required int level,
    SkinTone? skinTone,
    String? hairStyle,
    HairColor? hairColor,
  }) {
    final config = AvatarConfig.fromUserStats(
      archetype: archetype,
      level: level,
      skinTone: skinTone,
      hairStyle: hairStyle,
      hairColor: hairColor,
    );
    state = state.copyWith(config: config);
  }

  /// Get available options for archetype
  AvatarOptions getAvailableOptions() {
    final service = AvatarAssetService();
    return AvatarOptions(
      hairstyles: service.getAvailableHairstyles(state.config.archetype),
      skinTones: service.getAvailableSkinTones(),
    );
  }

  /// Persist configuration to user profile
  void _persistToProfile() {
    // In a real implementation, this would update the user profile
    // via the gamification repository
  }

  /// Get evolution phase for level
  EvolutionPhase _getPhaseForLevel(int level) {
    if (level >= 50) return EvolutionPhase.ascended;
    if (level >= 31) return EvolutionPhase.radiant;
    if (level >= 16) return EvolutionPhase.incarnate;
    if (level >= 6) return EvolutionPhase.construct;
    return EvolutionPhase.phantom;
  }
}

/// Available options for avatar customization
class AvatarOptions {
  final List<String> hairstyles;
  final List<SkinTone> skinTones;

  const AvatarOptions({required this.hairstyles, required this.skinTones});
}
