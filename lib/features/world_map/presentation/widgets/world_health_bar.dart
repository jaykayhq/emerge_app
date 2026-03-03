import 'package:flutter/material.dart';

/// World Health Bar showing growth vs decay visualization
/// Green (growth/thriving) ↔ Red (decay/neglect)
class WorldHealthBar extends StatelessWidget {
  /// Health percentage 0.0 - 1.0
  final double healthPercent;

  /// Current streak for label calculation
  final int streak;

  /// Days missed for decay calculation
  final int daysMissed;

  /// Accent color for theming
  final Color accentColor;

  const WorldHealthBar({
    super.key,
    required this.healthPercent,
    this.streak = 0,
    this.daysMissed = 0,
    this.accentColor = const Color(0xFF00FFCC),
  });

  String get _stateLabel {
    if (healthPercent >= 0.85) return 'THRIVING';
    if (healthPercent >= 0.60) return 'HEALTHY';
    if (healthPercent >= 0.35) return 'UNSTABLE';
    return 'DECAYING';
  }

  Color get _stateColor {
    if (healthPercent >= 0.85) return const Color(0xFF00E676);
    if (healthPercent >= 0.60) return const Color(0xFF66BB6A);
    if (healthPercent >= 0.35) return const Color(0xFFFFAB00);
    return const Color(0xFFFF5252);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('🌍 ', style: TextStyle(fontSize: 14)),
                Text(
                  'WORLD HEALTH: $_stateLabel',
                  style: TextStyle(
                    color: _stateColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            Text(
              '${(healthPercent * 100).round()}%',
              style: TextStyle(
                color: _stateColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Health bar
        SizedBox(
          height: 12,
          child: Stack(
            children: [
              // Background track
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // Fill
              FractionallySizedBox(
                widthFactor: healthPercent.clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF00E676), _stateColor],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: _stateColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Growth/Decay icons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🌱 Growth',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 9,
              ),
            ),
            Text(
              'Decay 💀',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
