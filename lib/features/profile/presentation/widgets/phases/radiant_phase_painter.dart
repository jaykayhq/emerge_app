import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Phase 4: The Radiant - Solid silhouette with Kintsugi-style glowing cracks
/// Golden/archetype-colored cracks run through surface, glowing with energy
/// A subtle aura radiates from the figure.
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
    final centerX = size.width / 2;

    // Glow pulse
    final pulse = 0.7 + math.sin(animationValue * math.pi * 2) * 0.3;

    // Draw outer aura
    _drawAura(canvas, size, centerX, pulse);

    // Draw solid base silhouette
    _drawBaseSilhouette(canvas, size, centerX);

    // Draw Kintsugi cracks
    _drawKintsugiCracks(canvas, size, centerX, pulse);

    // Draw internal core glow
    _drawCoreGlow(canvas, size, centerX, pulse);
  }

  void _drawAura(Canvas canvas, Size size, double centerX, double pulse) {
    final auraPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15 * pulse)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30 * pulse);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, size.height * 0.4),
        width: size.width * 0.7,
        height: size.height * 0.8,
      ),
      auraPaint,
    );
  }

  void _drawBaseSilhouette(Canvas canvas, Size size, double centerX) {
    final fillPaint = Paint()
      ..color = const Color(0xFF1a1a2e).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final path = _createBodyPath(size, centerX);
    canvas.drawPath(path, fillPaint);

    // Dark edge
    final edgePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, edgePaint);
  }

  Path _createBodyPath(Size size, double centerX) {
    final path = Path();

    // Simplified powerful silhouette
    final headY = size.height * 0.08;
    final headRadius = size.width * 0.1;

    // Head
    path.addOval(
      Rect.fromCircle(center: Offset(centerX, headY), radius: headRadius),
    );

    // Strong torso
    final torsoPath = Path();
    final neckY = headY + headRadius * 0.8;
    final shoulderY = size.height * 0.17;
    final shoulderWidth = size.width * 0.28;
    final waistWidth = size.width * 0.14;
    final hipY = size.height * 0.45;

    torsoPath.moveTo(centerX, neckY);
    torsoPath.lineTo(centerX - shoulderWidth, shoulderY);
    torsoPath.lineTo(
      centerX - shoulderWidth - size.width * 0.08,
      size.height * 0.4,
    );
    torsoPath.lineTo(centerX - waistWidth, hipY);
    torsoPath.lineTo(centerX - size.width * 0.1, size.height * 0.88);
    torsoPath.lineTo(centerX - size.width * 0.02, size.height * 0.88);
    torsoPath.lineTo(centerX, hipY + size.height * 0.1);
    torsoPath.lineTo(centerX + size.width * 0.02, size.height * 0.88);
    torsoPath.lineTo(centerX + size.width * 0.1, size.height * 0.88);
    torsoPath.lineTo(centerX + waistWidth, hipY);
    torsoPath.lineTo(
      centerX + shoulderWidth + size.width * 0.08,
      size.height * 0.4,
    );
    torsoPath.lineTo(centerX + shoulderWidth, shoulderY);
    torsoPath.close();

    path.addPath(torsoPath, Offset.zero);
    return path;
  }

  void _drawKintsugiCracks(
    Canvas canvas,
    Size size,
    double centerX,
    double pulse,
  ) {
    final crackPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.9 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Define Kintsugi crack patterns
    final cracks = [
      // Chest cracks (healed heart)
      [
        Offset(centerX - size.width * 0.08, size.height * 0.22),
        Offset(centerX - size.width * 0.02, size.height * 0.28),
        Offset(centerX + size.width * 0.05, size.height * 0.25),
      ],
      [
        Offset(centerX + size.width * 0.08, size.height * 0.22),
        Offset(centerX + size.width * 0.03, size.height * 0.26),
        Offset(centerX, size.height * 0.30),
      ],
      // Shoulder cracks (burden carried)
      [
        Offset(centerX - size.width * 0.2, size.height * 0.18),
        Offset(centerX - size.width * 0.15, size.height * 0.22),
        Offset(centerX - size.width * 0.12, size.height * 0.28),
      ],
      [
        Offset(centerX + size.width * 0.2, size.height * 0.18),
        Offset(centerX + size.width * 0.15, size.height * 0.22),
        Offset(centerX + size.width * 0.12, size.height * 0.28),
      ],
      // Torso cracks (core strength)
      [
        Offset(centerX, size.height * 0.32),
        Offset(centerX - size.width * 0.03, size.height * 0.38),
        Offset(centerX + size.width * 0.02, size.height * 0.42),
      ],
      // Leg cracks (journeys taken)
      [
        Offset(centerX - size.width * 0.08, size.height * 0.55),
        Offset(centerX - size.width * 0.06, size.height * 0.65),
        Offset(centerX - size.width * 0.09, size.height * 0.75),
      ],
      [
        Offset(centerX + size.width * 0.08, size.height * 0.55),
        Offset(centerX + size.width * 0.06, size.height * 0.65),
        Offset(centerX + size.width * 0.09, size.height * 0.75),
      ],
    ];

    // Only draw cracks based on phase progress
    final cracksToShow = (cracks.length * phaseProgress).ceil();

    for (int i = 0; i < cracksToShow && i < cracks.length; i++) {
      final crack = cracks[i];
      final crackPath = Path();
      crackPath.moveTo(crack[0].dx, crack[0].dy);
      for (int j = 1; j < crack.length; j++) {
        crackPath.lineTo(crack[j].dx, crack[j].dy);
      }

      // Draw glow first, then crack
      canvas.drawPath(crackPath, glowPaint);
      canvas.drawPath(crackPath, crackPaint);
    }

    // Draw golden dots at crack intersections
    final dotPaint = Paint()
      ..color = primaryColor.withValues(alpha: pulse)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < cracksToShow && i < cracks.length; i++) {
      for (final point in cracks[i]) {
        canvas.drawCircle(point, 3 * pulse, dotPaint);
      }
    }
  }

  void _drawCoreGlow(Canvas canvas, Size size, double centerX, double pulse) {
    // Heart/core center glow
    final coreCenter = Offset(centerX, size.height * 0.28);
    final gradient = RadialGradient(
      colors: [
        primaryColor.withValues(alpha: 0.4 * pulse),
        primaryColor.withValues(alpha: 0.1 * pulse),
        primaryColor.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final corePaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: coreCenter, radius: size.width * 0.15),
      );

    canvas.drawCircle(coreCenter, size.width * 0.15, corePaint);
  }

  @override
  bool shouldRepaint(covariant RadiantPhasePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.phaseProgress != phaseProgress ||
        oldDelegate.primaryColor != primaryColor;
  }
}
