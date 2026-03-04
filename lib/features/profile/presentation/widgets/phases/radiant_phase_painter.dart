import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Phase 4: The Radiant — Kintsugi warrior with golden veins of light
/// Powerful silhouette with animated branching golden cracks, pulsing core,
/// crown/halo aura, ember particles rising, and ground-plane light cracks.
/// User Feeling: "I am powerful. My habits are fueling me."
class RadiantPhasePainter extends CustomPainter {
  final double animationValue; // 0.0-1.0 for glow pulse
  final Color primaryColor;
  final double opacity;
  final double phaseProgress; // 0.0-1.0 for crack intensity

  RadiantPhasePainter({
    required this.animationValue,
    required this.primaryColor,
    this.opacity = 0.9,
    this.phaseProgress = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final t = animationValue * math.pi * 2;
    final pulse = 0.7 + math.sin(t) * 0.3;

    // Layer 1: Wide aura glow
    _drawAura(canvas, size, cx, pulse);

    // Layer 2: Ground energy cracks
    _drawGroundEnergy(canvas, size, cx, pulse);

    // Layer 3: Gradient body silhouette (obsidian → indigo)
    _drawBodySilhouette(canvas, size, cx);

    // Layer 4: Branching kintsugi crack system with traveling light
    _drawKintsugiCracks(canvas, size, cx, pulse, t);

    // Layer 5: Pulsing heart core
    _drawPulsingCore(canvas, size, cx, pulse, t);

    // Layer 6: Crown / halo aura above head
    _drawCrownAura(canvas, size, cx, pulse, t);

    // Layer 7: Ember particles rising from cracks
    _drawEmberParticles(canvas, size, cx, t);
  }

  /// Multi-layered aura radiating from the figure
  void _drawAura(Canvas canvas, Size size, double cx, double pulse) {
    for (int i = 0; i < 3; i++) {
      final radius = size.width * (0.30 + i * 0.12);
      final alpha = (0.10 - i * 0.025) * pulse;

      final gradient = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: alpha),
          primaryColor.withValues(alpha: alpha * 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      final center = Offset(cx, size.height * 0.38);
      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        );

      canvas.drawCircle(center, radius, paint);
    }
  }

  /// Cracks of light extending into the ground beneath feet
  void _drawGroundEnergy(Canvas canvas, Size size, double cx, double pulse) {
    final groundY = size.height * 0.88;
    final crackPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.35 * pulse * phaseProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.12 * pulse * phaseProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Crack patterns radiating from each foot
    final rng = math.Random(99);
    for (int foot = 0; foot < 2; foot++) {
      final footX = cx + (foot == 0 ? -1 : 1) * size.width * 0.08;

      for (int c = 0; c < 4; c++) {
        final angle =
            (foot == 0 ? math.pi * 0.7 : math.pi * 0.3) +
            rng.nextDouble() * math.pi * 0.3;
        final len = size.width * 0.08 + rng.nextDouble() * size.width * 0.12;

        final endX = footX + math.cos(angle) * len;
        final endY = groundY + math.sin(angle) * len * 0.3;

        final midX = (footX + endX) / 2 + (rng.nextDouble() - 0.5) * 10;
        final midY = groundY + (endY - groundY) * 0.5;

        final path = Path()
          ..moveTo(footX, groundY)
          ..quadraticBezierTo(midX, midY, endX, endY);

        canvas.drawPath(path, glowPaint);
        canvas.drawPath(path, crackPaint);
      }
    }
  }

  /// Powerful silhouette with gradient from obsidian to dark indigo
  void _drawBodySilhouette(Canvas canvas, Size size, double cx) {
    final path = _createPowerBodyPath(size, cx);

    final bodyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF1a1a2e).withValues(alpha: opacity),
        const Color(0xFF16162a).withValues(alpha: opacity),
        const Color(0xFF0f0f1e).withValues(alpha: opacity * 0.95),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final fillPaint = Paint()
      ..shader = bodyGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

    // Subtle dark edge
    final edgePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(path, edgePaint);
  }

  /// Branching kintsugi cracks with traveling light animation
  void _drawKintsugiCracks(
    Canvas canvas,
    Size size,
    double cx,
    double pulse,
    double t,
  ) {
    // Glow under cracks
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Core crack line
    final crackPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.85 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    // Gold dot paint for intersections
    final dotPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.95 * pulse)
      ..style = PaintingStyle.fill;

    // Define crack trees (main crack + sub-branches)
    final crackTrees = _getCrackTrees(size, cx);
    final cracksToShow = (crackTrees.length * (0.3 + phaseProgress * 0.7))
        .ceil();

    for (int i = 0; i < cracksToShow && i < crackTrees.length; i++) {
      final tree = crackTrees[i];
      final mainCrack = tree['main'] as List<Offset>;
      final branches = tree['branches'] as List<List<Offset>>;

      // Draw main crack
      final mainPath = Path()..moveTo(mainCrack[0].dx, mainCrack[0].dy);
      for (int j = 1; j < mainCrack.length; j++) {
        mainPath.lineTo(mainCrack[j].dx, mainCrack[j].dy);
      }
      canvas.drawPath(mainPath, glowPaint);
      canvas.drawPath(mainPath, crackPaint);

      // Draw branch cracks (thinner)
      final branchGlow = Paint()
        ..color = primaryColor.withValues(alpha: 0.2 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      final branchCrack = Paint()
        ..color = primaryColor.withValues(alpha: 0.6 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;

      for (final branch in branches) {
        if (branch.length < 2) continue;
        final bPath = Path()..moveTo(branch[0].dx, branch[0].dy);
        for (int k = 1; k < branch.length; k++) {
          bPath.lineTo(branch[k].dx, branch[k].dy);
        }
        canvas.drawPath(bPath, branchGlow);
        canvas.drawPath(bPath, branchCrack);
      }

      // Intersection dots
      for (final pt in mainCrack) {
        canvas.drawCircle(pt, 2.5 * pulse, dotPaint);
      }

      // Traveling light dot along main crack
      final totalLen = _pathLength(mainCrack);
      final lightPos = ((animationValue + i * 0.15) % 1.0) * totalLen;
      final lightPoint = _pointAlongPath(mainCrack, lightPos);
      if (lightPoint != null) {
        final lightPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.9 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        canvas.drawCircle(lightPoint, 3.5, lightPaint);

        final lightGlow = Paint()
          ..color = primaryColor.withValues(alpha: 0.45 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawCircle(lightPoint, 8, lightGlow);
      }
    }
  }

  /// Beating heart core with warm glow
  void _drawPulsingCore(
    Canvas canvas,
    Size size,
    double cx,
    double pulse,
    double t,
  ) {
    final heartCenter = Offset(cx, size.height * 0.27);

    // Slow heartbeat rhythm: two quick pulses then pause
    final heartbeat = (math.sin(t * 1.5).abs() * math.sin(t * 1.5 + 0.3).abs())
        .clamp(0.0, 1.0);
    final beatPulse = 0.6 + heartbeat * 0.4;

    // Wide glow
    final outerGlow = RadialGradient(
      colors: [
        primaryColor.withValues(alpha: 0.35 * beatPulse),
        primaryColor.withValues(alpha: 0.10 * beatPulse),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final outerRadius = size.width * 0.16 * beatPulse;
    canvas.drawCircle(
      heartCenter,
      outerRadius,
      Paint()
        ..shader = outerGlow.createShader(
          Rect.fromCircle(center: heartCenter, radius: outerRadius),
        ),
    );

    // Bright inner core
    final innerGlow = RadialGradient(
      colors: [
        Colors.white.withValues(alpha: 0.5 * beatPulse),
        primaryColor.withValues(alpha: 0.4 * beatPulse),
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 1.0],
    );

    final innerRadius = size.width * 0.06 * beatPulse;
    canvas.drawCircle(
      heartCenter,
      innerRadius,
      Paint()
        ..shader = innerGlow.createShader(
          Rect.fromCircle(center: heartCenter, radius: innerRadius),
        ),
    );
  }

  /// Blazing crown/halo energy formation above the head
  void _drawCrownAura(
    Canvas canvas,
    Size size,
    double cx,
    double pulse,
    double t,
  ) {
    final crownCenter = Offset(cx, size.height * 0.03);
    final crownRadius = size.width * 0.12;

    // Crown rays
    final rayPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4 * pulse * phaseProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final rayCount = 12;
    for (int i = 0; i < rayCount; i++) {
      final angle = (i * math.pi * 2 / rayCount) + t * 0.3;
      final innerR = crownRadius * 0.5;
      final outerR = crownRadius * (0.8 + math.sin(t * 2 + i * 0.7) * 0.3);

      canvas.drawLine(
        Offset(
          crownCenter.dx + math.cos(angle) * innerR,
          crownCenter.dy + math.sin(angle) * innerR,
        ),
        Offset(
          crownCenter.dx + math.cos(angle) * outerR,
          crownCenter.dy + math.sin(angle) * outerR,
        ),
        rayPaint,
      );
    }

    // Central crown glow
    final crownGlow = RadialGradient(
      colors: [
        primaryColor.withValues(alpha: 0.25 * pulse * phaseProgress),
        primaryColor.withValues(alpha: 0.08 * pulse * phaseProgress),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    canvas.drawCircle(
      crownCenter,
      crownRadius,
      Paint()
        ..shader = crownGlow.createShader(
          Rect.fromCircle(center: crownCenter, radius: crownRadius),
        ),
    );
  }

  /// Golden ember sparks rising from the kintsugi cracks
  void _drawEmberParticles(Canvas canvas, Size size, double cx, double t) {
    final rng = math.Random(555);

    for (int i = 0; i < 25; i++) {
      final startX = cx + (rng.nextDouble() - 0.5) * size.width * 0.4;
      final startY = size.height * 0.15 + rng.nextDouble() * size.height * 0.65;
      final pSize = 1.0 + rng.nextDouble() * 2.5;

      final rise = (animationValue + i * 0.04) % 1.0;
      final drift = math.sin(t + i * 1.3) * 8;

      final x = startX + drift;
      final y = startY - rise * size.height * 0.20;

      if (y > 0 && y < size.height) {
        final alpha = (1 - rise) * 0.6 * phaseProgress;

        // Warm ember colors
        final isGold = i % 3 == 0;
        final color = isGold
            ? Color.lerp(primaryColor, const Color(0xFFFFD700), 0.6)!
            : primaryColor;

        final emberPaint = Paint()
          ..color = color.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

        canvas.drawCircle(Offset(x, y), pSize, emberPaint);

        // Bright core for larger embers
        if (pSize > 2) {
          final corePaint = Paint()
            ..color = Colors.white.withValues(alpha: alpha * 0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
          canvas.drawCircle(Offset(x, y), pSize * 0.4, corePaint);
        }
      }
    }
  }

  /// Power body path — commanding stance, wider than Incarnate
  Path _createPowerBodyPath(Size size, double cx) {
    final path = Path();

    final headY = size.height * 0.07;
    final headR = size.width * 0.10;

    // Head
    path.addOval(Rect.fromCircle(center: Offset(cx, headY), radius: headR));

    // Power torso
    final torso = Path();
    final neckY = headY + headR * 0.75;
    final shoulderY = size.height * 0.16;
    final shoulderW = size.width * 0.28;
    final waistW = size.width * 0.13;
    final hipY = size.height * 0.44;

    torso.moveTo(cx, neckY);
    torso.lineTo(cx - shoulderW, shoulderY);

    // Left arm
    torso.lineTo(cx - shoulderW - size.width * 0.09, size.height * 0.38);

    // Left waist
    torso.lineTo(cx - waistW, hipY);

    // Left leg
    torso.lineTo(cx - size.width * 0.11, size.height * 0.87);
    torso.lineTo(cx - size.width * 0.03, size.height * 0.87);

    // Inner leg
    torso.lineTo(cx, hipY + size.height * 0.10);

    // Right inner leg
    torso.lineTo(cx + size.width * 0.03, size.height * 0.87);
    torso.lineTo(cx + size.width * 0.11, size.height * 0.87);

    // Right side
    torso.lineTo(cx + waistW, hipY);
    torso.lineTo(cx + shoulderW + size.width * 0.09, size.height * 0.38);
    torso.lineTo(cx + shoulderW, shoulderY);

    torso.close();
    path.addPath(torso, Offset.zero);

    return path;
  }

  /// Define crack trees with main path + sub-branches
  List<Map<String, dynamic>> _getCrackTrees(Size size, double cx) {
    return [
      // Chest: healed heart
      {
        'main': [
          Offset(cx - size.width * 0.10, size.height * 0.20),
          Offset(cx - size.width * 0.04, size.height * 0.25),
          Offset(cx + size.width * 0.02, size.height * 0.23),
          Offset(cx + size.width * 0.06, size.height * 0.27),
        ],
        'branches': [
          [
            Offset(cx - size.width * 0.04, size.height * 0.25),
            Offset(cx - size.width * 0.06, size.height * 0.30),
          ],
          [
            Offset(cx + size.width * 0.02, size.height * 0.23),
            Offset(cx + size.width * 0.04, size.height * 0.19),
          ],
        ],
      },
      // Right chest
      {
        'main': [
          Offset(cx + size.width * 0.10, size.height * 0.20),
          Offset(cx + size.width * 0.05, size.height * 0.25),
          Offset(cx + size.width * 0.02, size.height * 0.30),
        ],
        'branches': [
          [
            Offset(cx + size.width * 0.05, size.height * 0.25),
            Offset(cx + size.width * 0.08, size.height * 0.28),
            Offset(cx + size.width * 0.10, size.height * 0.32),
          ],
        ],
      },
      // Left shoulder
      {
        'main': [
          Offset(cx - size.width * 0.22, size.height * 0.17),
          Offset(cx - size.width * 0.16, size.height * 0.21),
          Offset(cx - size.width * 0.12, size.height * 0.27),
        ],
        'branches': [
          [
            Offset(cx - size.width * 0.16, size.height * 0.21),
            Offset(cx - size.width * 0.19, size.height * 0.24),
          ],
        ],
      },
      // Right shoulder
      {
        'main': [
          Offset(cx + size.width * 0.22, size.height * 0.17),
          Offset(cx + size.width * 0.16, size.height * 0.21),
          Offset(cx + size.width * 0.12, size.height * 0.27),
        ],
        'branches': [
          [
            Offset(cx + size.width * 0.16, size.height * 0.21),
            Offset(cx + size.width * 0.19, size.height * 0.24),
          ],
        ],
      },
      // Central torso
      {
        'main': [
          Offset(cx, size.height * 0.30),
          Offset(cx - size.width * 0.03, size.height * 0.36),
          Offset(cx + size.width * 0.02, size.height * 0.42),
        ],
        'branches': [
          [
            Offset(cx - size.width * 0.03, size.height * 0.36),
            Offset(cx - size.width * 0.06, size.height * 0.38),
          ],
          [
            Offset(cx + size.width * 0.02, size.height * 0.42),
            Offset(cx + size.width * 0.05, size.height * 0.44),
          ],
        ],
      },
      // Left leg
      {
        'main': [
          Offset(cx - size.width * 0.08, size.height * 0.52),
          Offset(cx - size.width * 0.07, size.height * 0.62),
          Offset(cx - size.width * 0.09, size.height * 0.72),
          Offset(cx - size.width * 0.08, size.height * 0.80),
        ],
        'branches': [
          [
            Offset(cx - size.width * 0.07, size.height * 0.62),
            Offset(cx - size.width * 0.10, size.height * 0.64),
          ],
        ],
      },
      // Right leg
      {
        'main': [
          Offset(cx + size.width * 0.08, size.height * 0.52),
          Offset(cx + size.width * 0.07, size.height * 0.62),
          Offset(cx + size.width * 0.09, size.height * 0.72),
          Offset(cx + size.width * 0.08, size.height * 0.80),
        ],
        'branches': [
          [
            Offset(cx + size.width * 0.07, size.height * 0.62),
            Offset(cx + size.width * 0.10, size.height * 0.64),
          ],
        ],
      },
    ];
  }

  /// Length of a polyline
  double _pathLength(List<Offset> points) {
    double len = 0;
    for (int i = 1; i < points.length; i++) {
      len += (points[i] - points[i - 1]).distance;
    }
    return len;
  }

  /// Find a point at a given distance along a polyline
  Offset? _pointAlongPath(List<Offset> points, double distance) {
    double cum = 0;
    for (int i = 1; i < points.length; i++) {
      final segLen = (points[i] - points[i - 1]).distance;
      if (cum + segLen >= distance) {
        final t = (distance - cum) / segLen;
        return Offset.lerp(points[i - 1], points[i], t);
      }
      cum += segLen;
    }
    return points.isNotEmpty ? points.last : null;
  }

  @override
  bool shouldRepaint(covariant RadiantPhasePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.phaseProgress != phaseProgress ||
        oldDelegate.primaryColor != primaryColor;
  }
}
