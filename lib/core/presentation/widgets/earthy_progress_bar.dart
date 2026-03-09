import 'package:flutter/material.dart';
import 'package:emerge_app/core/theme/emerge_earthy_theme.dart';

/// Animated progress bar with earthy color scheme
///
/// Features:
/// - Smooth 300ms animation using TweenAnimationBuilder
/// - Shows XP count and percentage
/// - Uses earthy attribute colors
/// - Unique key per attribute for independent animations (handles rapid completions)
class EarthyProgressBar extends StatelessWidget {
  /// Current XP earned in this level
  final int currentXp;

  /// XP required to reach next level (default 500)
  final int xpForNextLevel;

  /// Habit attribute for color theming
  final String attribute;

  /// Optional height override (default 8)
  final double? height;

  /// Optional custom key for animation (auto-generated from attribute if not provided)
  final Key? widgetKey;

  const EarthyProgressBar({
    super.key,
    required this.currentXp,
    required this.xpForNextLevel,
    required this.attribute,
    this.height,
    this.widgetKey,
  });

  @override
  Widget build(BuildContext context) {
    // Get color for attribute
    final color = EmergeEarthyColors.getAttributeColorByName(attribute);

    // Clamp progress between 0.0 and 1.0
    final progress = (currentXp / xpForNextLevel).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Animated progress bar
        TweenAnimationBuilder<double>(
          key: widgetKey ?? Key('attribute_progress_$attribute'),
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 0, end: progress),
          builder: (context, value, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: height ?? 8,
              ),
            );
          },
        ),

        const SizedBox(height: 4),

        // XP and percentage labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$currentXp / $xpForNextLevel XP',
              style: TextStyle(
                color: EmergeEarthyColors.cream,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Compact version of EarthyProgressBar with minimal styling
///
/// Useful for tight spaces where full labels aren't needed
class EarthyProgressBarCompact extends StatelessWidget {
  final int currentXp;
  final int xpForNextLevel;
  final String attribute;
  final double? height;

  const EarthyProgressBarCompact({
    super.key,
    required this.currentXp,
    required this.xpForNextLevel,
    required this.attribute,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final color = EmergeEarthyColors.getAttributeColorByName(attribute);
    final progress = (currentXp / xpForNextLevel).clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0, end: progress),
      builder: (context, value, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: height ?? 6,
          ),
        );
      },
    );
  }
}

/// Circular progress indicator with earthy colors
///
/// Alternative to linear progress for visual variety
class EarthyProgressCircle extends StatelessWidget {
  final int currentXp;
  final int xpForNextLevel;
  final String attribute;
  final double size;

  const EarthyProgressCircle({
    super.key,
    required this.currentXp,
    required this.xpForNextLevel,
    required this.attribute,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final color = EmergeEarthyColors.getAttributeColorByName(attribute);
    final progress = (currentXp / xpForNextLevel).clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0, end: progress),
      builder: (context, value, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              CircularProgressIndicator(
                value: 1,
                strokeWidth: 6,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(
                  color.withValues(alpha: 0.15),
                ),
              ),
              // Progress circle
              CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(color),
              ),
              // Center text
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  color: color,
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
