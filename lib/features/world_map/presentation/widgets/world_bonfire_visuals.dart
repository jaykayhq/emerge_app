import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:flutter/material.dart';

/// Continuous visual parameters for the world-map bonfire.
///
/// The map exposes health as a score, so the fire should not jump between the
/// three categorical world states while the score changes within a range.
class WorldBonfireVisualState {
  final double health;
  final double flameScale;
  final double flameWidth;
  final double glowOpacity;
  final double outerOpacity;
  final double flickerAmplitude;
  final int emberCount;
  final Color outerFlameColor;
  final Color emberColor;

  const WorldBonfireVisualState({
    required this.health,
    required this.flameScale,
    required this.flameWidth,
    required this.glowOpacity,
    required this.outerOpacity,
    required this.flickerAmplitude,
    required this.emberCount,
    required this.outerFlameColor,
    required this.emberColor,
  });

  static WorldBonfireVisualState fromHealth(double rawHealth) {
    final health = rawHealth.isFinite
        ? rawHealth.clamp(0.0, 1.0).toDouble()
        : 0.5;

    return WorldBonfireVisualState(
      health: health,
      flameScale: 0.48 + (health * 0.64),
      flameWidth: 0.50 + (health * 0.50),
      glowOpacity: 0.10 + (health * 0.70),
      outerOpacity: 0.38 + (health * 0.54),
      flickerAmplitude: 0.012 + (health * 0.088),
      emberCount: (1 + (health * 4).round()).clamp(1, 5),
      outerFlameColor:
          Color.lerp(const Color(0xFFC23A28), EmergeColors.warmGold, health) ??
          EmergeColors.warmGold,
      emberColor:
          Color.lerp(
            const Color(0xFFE85A26),
            const Color(0xFFFFF0A1),
            health,
          ) ??
          const Color(0xFFE85A26),
    );
  }
}

class WorldBonfireGeometry {
  final double canvasSize;
  final double unit;
  final double centerX;
  final double baseY;
  final double flameHeight;
  final double halfWidth;
  final Rect visibleBounds;
  final Rect coreRect;

  const WorldBonfireGeometry({
    required this.canvasSize,
    required this.unit,
    required this.centerX,
    required this.baseY,
    required this.flameHeight,
    required this.halfWidth,
    required this.visibleBounds,
    required this.coreRect,
  });

  static double footprintFor(double availableExtent) {
    if (!availableExtent.isFinite) return 216;
    final compactProgress = ((availableExtent - 320) / 70).clamp(0.0, 1.0);
    return 200 + (compactProgress * 24);
  }

  static WorldBonfireGeometry fromVisualState({
    required WorldBonfireVisualState visualState,
    required double size,
  }) {
    final canvasSize = size.isFinite && size > 0 ? size : 216.0;
    final unit = canvasSize / 216.0;
    final centerX = canvasSize / 2;
    final hearthBottomOffset = 53 * unit;
    final flameHeight = 92 * visualState.flameScale * unit;
    final halfWidth = 58 * visualState.flameWidth * unit;
    final hearthHalfWidth = 85 * unit;
    final visibleHalfWidth = halfWidth > hearthHalfWidth
        ? halfWidth
        : hearthHalfWidth;
    final coreSize = Size(112 * unit, 132 * unit);

    // Move the baseline down as the flame grows so the visible fire bounds,
    // rather than the transparent paint box, stay anchored at center.
    final baseY = (canvasSize / 2) + ((flameHeight - hearthBottomOffset) / 2);
    final visibleBounds = Rect.fromLTRB(
      centerX - visibleHalfWidth,
      baseY - flameHeight,
      centerX + visibleHalfWidth,
      baseY + hearthBottomOffset,
    );
    final coreRect = Rect.fromLTWH(
      centerX - (coreSize.width / 2),
      baseY - (coreSize.height * 0.86),
      coreSize.width,
      coreSize.height,
    );

    return WorldBonfireGeometry(
      canvasSize: canvasSize,
      unit: unit,
      centerX: centerX,
      baseY: baseY,
      flameHeight: flameHeight,
      halfWidth: halfWidth,
      visibleBounds: visibleBounds,
      coreRect: coreRect,
    );
  }
}
