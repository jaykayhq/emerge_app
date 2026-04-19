// lib/core/presentation/widgets/world_background.dart
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/core/presentation/providers/world_theme_provider.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_map_config.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/nebula_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-screen world background driven by the user's selected theme
/// and current world health state.
///
/// Drop-in replacement for [GrowthBackground] and [NebulaBackground].
/// Wraps [child] inside a [Scaffold] with the layered background behind it.
class WorldBackground extends ConsumerWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;

  const WorldBackground({
    super.key,
    required this.child,
    this.appBar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(worldThemeProvider);
    final healthAsync = ref.watch(worldHealthStreamProvider);
    final health = healthAsync.when(
      data: (h) => h,
      loading: () => 0.5,
      error: (e, st) => 0.5,
    );
    final healthState = WorldHealthState.fromHealth(health);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: appBar,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: World background (image or animated nebula)
          _WorldBackgroundLayer(theme: theme, healthState: healthState),

          // Layer 2: Gradient overlay for text legibility
          const _GradientOverlay(),

          // Layer 3: Screen content
          SafeArea(child: child),
        ],
      ),
    );
  }
}

// ─── Private Widgets ──────────────────────────────────────────────────────────

class _WorldBackgroundLayer extends StatelessWidget {
  final AppWorldTheme theme;
  final WorldHealthState healthState;

  const _WorldBackgroundLayer({
    required this.theme,
    required this.healthState,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = resolveBackgroundAsset(theme, healthState);

    if (assetPath == null) {
      // Nebula theme — code-driven animated background
      return const NebulaBackground(
        biome: BiomeType.valley,
        primaryColor: Color(0xFF00FFCC),
        accentColor: Color(0xFF6C63FF),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: Image.asset(
        assetPath,
        key: ValueKey(assetPath),
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (ctx, err, st) => _FallbackBackground(theme: theme),
      ),
    );
  }
}

class _GradientOverlay extends StatelessWidget {
  const _GradientOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.15, 0.60, 1.0],
          colors: [
            Color(0x33000000), // Top vignette — 20% dark
            Color(0x00000000), // Transparent mid-upper
            Color(0x66000000), // 40% dark mid-lower
            Color(0xCC000000), // 80% dark bottom for UI legibility
          ],
        ),
      ),
    );
  }
}

class _FallbackBackground extends StatelessWidget {
  final AppWorldTheme theme;

  const _FallbackBackground({required this.theme});

  static const _themeColors = <AppWorldTheme, Color>{
    AppWorldTheme.forest: Color(0xFF1B4332),
    AppWorldTheme.city: Color(0xFF1a0a3e),
    AppWorldTheme.mountain: Color(0xFF3D405B),
    AppWorldTheme.ocean: Color(0xFF0a1a3e),
    AppWorldTheme.volcanic: Color(0xFF3a0a0a),
    AppWorldTheme.nebula: Color(0xFF0A0A1A),
  };

  @override
  Widget build(BuildContext context) {
    final base = _themeColors[theme] ?? const Color(0xFF0A0A1A);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [base, const Color(0xFF0A0A1A)],
        ),
      ),
    );
  }
}
