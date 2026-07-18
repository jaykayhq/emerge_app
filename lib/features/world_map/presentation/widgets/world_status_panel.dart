import 'dart:ui' as ui;

import 'package:emerge_app/core/presentation/widgets/glassmorphism_card.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';

/// A glassmorphic panel revealing the world's current status.
/// Toggled by tapping the central orb on the World Map.
class WorldStatusPanel extends ConsumerWidget {
  const WorldStatusPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(worldHealthStreamProvider);
    final entropyAsync = ref.watch(worldEntropyStreamProvider);

    final double? health = healthAsync.asData?.value;
    final double? entropy = entropyAsync.asData?.value;

    return Semantics(
      label: 'World status',
      child: GlassmorphismCard(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        glowColor: EmergeColors.teal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatColumn(
                  label: 'VITALITY',
                  value: health,
                  color: EmergeColors.teal,
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
            const SizedBox(height: 12),
            Text(
              _statusLine(health),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _statusLine(double? health) {
    if (health == null) {
      return 'Checking your world…';
    }
    if (health >= 0.7) return 'Your world is thriving.';
    if (health >= 0.4) return 'Your world is steady — keep your habits going.';
    return 'Your world needs attention. Complete a habit to restore it.';
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;
  final IconData icon;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final percent = hasValue ? (value!.clamp(0.0, 1.0) * 100).round() : null;

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
          hasValue ? '$percent%' : '--',
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
