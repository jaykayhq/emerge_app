import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';

class WorldStateHUD extends ConsumerWidget {
  const WorldStateHUD({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(worldHealthStreamProvider);
    final entropyAsync = ref.watch(worldEntropyStreamProvider);

    // Show loading shimmer while providers are initialising.
    if (healthAsync.isLoading || entropyAsync.isLoading) {
      return const _HudShell(child: _HudLoadingContent());
    }

    // Show dashes when either stream carries an error — visible signal,
    // no crash, no false data.
    if (healthAsync.hasError || entropyAsync.hasError) {
      return const _HudShell(child: _HudErrorContent());
    }

    final double health = healthAsync.requireValue;
    final double entropy = entropyAsync.requireValue;

    return _HudShell(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatColumn(
            label: 'VITALITY',
            value: health,
            color: Colors.cyanAccent,
            icon: Icons.favorite_border,
          ),
          const SizedBox(width: 24),
          Container(
            width: 1,
            height: 30,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 24),
          _StatColumn(
            label: 'ENTROPY',
            value: entropy,
            color: Colors.purpleAccent,
            icon: Icons.blur_on,
          ),
        ],
      ),
    );
  }
}

/// Shared glassmorphic container shell used by all HUD states.
class _HudShell extends StatelessWidget {
  const _HudShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Shown while providers are still loading.
class _HudLoadingContent extends StatelessWidget {
  const _HudLoadingContent();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 44,
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white54,
          ),
        ),
      ),
    );
  }
}

/// Shown when one or both providers carry an error.
class _HudErrorContent extends StatelessWidget {
  const _HudErrorContent();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DashColumn(label: 'VITALITY', color: Colors.cyanAccent),
        const SizedBox(width: 24),
        Container(
          width: 1,
          height: 30,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        const SizedBox(width: 24),
        _DashColumn(label: 'ENTROPY', color: Colors.purpleAccent),
      ],
    );
  }
}

class _DashColumn extends StatelessWidget {
  const _DashColumn({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '--',
          style: TextStyle(
            color: color.withValues(alpha: 0.6),
            fontSize: 20,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: color, blurRadius: 8)],
          ),
        ),
      ],
    );
  }
}

/// A single stat column showing label + percentage.
class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final percent = (value.clamp(0.0, 1.0) * 100).round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$percent%',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: color, blurRadius: 8)],
          ),
        ),
      ],
    );
  }
}
