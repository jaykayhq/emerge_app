import 'package:emerge_app/features/avatar/data/services/avatar_asset_service.dart';
import 'package:emerge_app/features/avatar/domain/models/avatar_config.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/profile/domain/models/silhouette_evolution.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'avatar_provider.g.dart';

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

/// Avatar state controller.
///
/// Manages avatar archetype and evolution phase. Skin tone and hairstyle
/// selection is no longer part of the rendering pipeline — the avatar is
/// fully defined by archetype and evolution phase in the silhouette-reveal model.
@riverpod
class AvatarController extends _$AvatarController {
  @override
  AvatarState build() {
    return AvatarState(
      config: AvatarConfig.defaultForArchetype(UserArchetype.none),
    );
  }

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

  /// Update evolved state based on level
  void updateEvolvedState(int level) {
    final phase = _getPhaseForLevel(level);
    if (phase != state.config.evolvedState) {
      updateConfig(state.config.copyWith(evolvedState: phase));
    }
  }

  /// Load avatar configuration from user stats (archetype + level only)
  void loadFromUserStats({
    required UserArchetype archetype,
    required int level,
  }) {
    final config = AvatarConfig.fromUserStats(
      archetype: archetype,
      level: level,
    );
    state = state.copyWith(config: config);
  }

  /// Reset to default config for current archetype
  void resetToDefault() {
    updateConfig(AvatarConfig.defaultForArchetype(state.config.archetype));
  }

  /// Persist configuration to user profile
  void _persistToProfile() {
    // Persistence via gamification repository when wired in production.
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
