import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Phase 5: The Ascended — Transcendent energy being
/// Pure light/energy silhouette with ethereal wings, mandala halo,
/// aurora dissolution at edges, starfield within body, orbital energy rings,
/// solar corona rays, and rich particle streams.
/// User Feeling: "I have transcended. The habit is my identity."
class AscendedPhasePainter extends CustomPainter {
  final double animationValue; // 0.0-1.0 for floating + particles
  final Color primaryColor;
  final double opacity;

  AscendedPhasePainter({
    required this.animationValue,
    required this.primaryColor,
    this.opacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final t = animationValue * math.pi * 2;

    // Floating offset (more pronounced than other phases)
    final floatY = math.sin(t) * 10;

    // Layer 1: Cosmic background glow (multi-layered)
    _drawCosmicGlow(canvas, size, cx, floatY);

    // Layer 2: Levitation shadow (dimming to show flight)
    _drawLevitationShadow(canvas, size, cx, floatY);

    // Layer 3: Ethereal energy wings
    _drawEnergyWings(canvas, size, cx, floatY, t);

    // Layer 4: Mandala halo behind head
    _drawMandalaHalo(canvas, size, cx, floatY, t);

    // Layer 5: Energy silhouette body
    _drawEnergySilhouette(canvas, size, cx, floatY);

    // Layer 6: Starfield within body
    _drawInternalStarfield(canvas, size, cx, floatY, t);

    // Layer 7: Solar corona rays from head
    _drawSolarCorona(canvas, size, cx, floatY, t);

    // Layer 8: Orbital energy rings at different angles
    _drawOrbitalRings(canvas, size, cx, floatY, t);

    // Layer 9: Aurora dissolution particles at edges
    _drawAuroraDissolution(canvas, size, cx, floatY, t);

    // Layer 10: Rich orbiting particle streams
    _drawOrbitingParticles(canvas, size, cx, floatY, t);
  }

  /// Multi-layered radial cosmic glow
  void _drawCosmicGlow(Canvas canvas, Size size, double cx, double floatY) {
    final center = Offset(cx, size.height * 0.38 + floatY);

    for (int i = 3; i >= 0; i--) {
      final radius = size.width * (0.28 + i * 0.14);
      final alpha = (0.12 - i * 0.025).clamp(0.02, 0.12);

      final gradient = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: alpha),
          primaryColor.withValues(alpha: alpha * 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        );

      canvas.drawCircle(center, radius, paint);
    }
  }

  /// Dimming ground shadow to emphasize floating
  void _drawLevitationShadow(
    Canvas canvas,
    Size size,
    double cx,
    double floatY,
  ) {
    // Shadow gets smaller/dimmer as figure floats higher
    final shadowIntensity = (0.08 - (floatY.abs() / size.height * 0.3)).clamp(
      0.02,
      0.08,
    );
    final shadowSize = size.width * (0.25 - floatY.abs() / size.height * 0.1);

    final gradient = RadialGradient(
      colors: [
        primaryColor.withValues(alpha: shadowIntensity),
        Colors.transparent,
      ],
    );

    final shadowCenter = Offset(cx, size.height * 0.92);
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCenter(
          center: shadowCenter,
          width: shadowSize * 2,
          height: size.height * 0.03,
        ),
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: shadowCenter,
        width: shadowSize * 2,
        height: size.height * 0.03,
      ),
      paint,
    );
  }

  /// Massive ethereal wings extending from the back
  void _drawEnergyWings(
    Canvas canvas,
    Size size,
    double cx,
    double floatY,
    double t,
  ) {
    // Wing flap animation
    final flapAngle = math.sin(t * 0.4) * 0.08;
    final wingAlpha = opacity * 0.18;

    for (int side = -1; side <= 1; side += 2) {
      // Each wing has 3 layered feather tiers
      for (int tier = 0; tier < 3; tier++) {
        final wingPath = Path();
        final shoulderX = cx + side * size.width * 0.08;
        final shoulderY = size.height * 0.20 + floatY;

        wingPath.moveTo(shoulderX, shoulderY);

        // Wing spread
        final spread = size.width * (0.30 + tier * 0.08);
        final droop = size.height * (0.05 + tier * 0.04);
        final tipX = cx + side * spread;
        final tipY = shoulderY + droop + flapAngle * size.height * (tier + 1);

        // Control points for organic wing curve
        final cp1x = cx + side * spread * 0.45;
        final cp1y = shoulderY - size.height * 0.06 * (3 - tier);
        final cp2x = cx + side * spread * 0.85;
        final cp2y = tipY - size.height * 0.04;

        wingPath.cubicTo(cp1x, cp1y, cp2x, cp2y, tipX, tipY);

        // Lower wing edge back to shoulder
        final lowerCp1x = cx + side * spread * 0.7;
        final lowerCp1y = tipY + size.height * 0.08;
        final lowerCp2x = cx + side * spread * 0.25;
        final lowerCp2y = shoulderY + size.height * 0.12;

        wingPath.cubicTo(
          lowerCp1x,
          lowerCp1y,
          lowerCp2x,
          lowerCp2y,
          shoulderX,
          shoulderY + size.height * 0.08,
        );
        wingPath.close();

        // Gradient fill — transparent at tips
        final wingGradient = RadialGradient(
          center: Alignment(side * -0.5, -0.3),
          radius: 1.2,
          colors: [
            primaryColor.withValues(alpha: wingAlpha - tier * 0.04),
            primaryColor.withValues(alpha: wingAlpha * 0.3 - tier * 0.02),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        );

        final wingPaint = Paint()
          ..shader = wingGradient.createShader(wingPath.getBounds())
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 + tier * 2);

        canvas.drawPath(wingPath, wingPaint);
      }
    }
  }

  /// Intricate rotating mandala pattern behind the head/upper body
  void _drawMandalaHalo(
    Canvas canvas,
    Size size,
    double cx,
    double floatY,
    double t,
  ) {
    final center = Offset(cx, size.height * 0.10 + floatY);
    final mandalaR = size.width * 0.22;

    // Rotation
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(t * 0.15);
    canvas.translate(-center.dx, -center.dy);

    final mandalaPaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    // Outer ring
    canvas.drawCircle(center, mandalaR, mandalaPaint);
    canvas.drawCircle(center, mandalaR * 0.75, mandalaPaint);
    canvas.drawCircle(center, mandalaR * 0.5, mandalaPaint);

    // Petal pattern (8 petals)
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final innerR = mandalaR * 0.35;
      final outerR = mandalaR * 0.9;

      // Draw petal using bezier
      final petalPath = Path();
      final startX = center.dx + math.cos(angle) * innerR;
      final startY = center.dy + math.sin(angle) * innerR;
      final endX = center.dx + math.cos(angle) * outerR;
      final endY = center.dy + math.sin(angle) * outerR;

      final cpAngle1 = angle + math.pi / 12;
      final cpAngle2 = angle - math.pi / 12;
      final cpR = mandalaR * 0.7;

      petalPath.moveTo(startX, startY);
      petalPath.quadraticBezierTo(
        center.dx + math.cos(cpAngle1) * cpR,
        center.dy + math.sin(cpAngle1) * cpR,
        endX,
        endY,
      );
      petalPath.quadraticBezierTo(
        center.dx + math.cos(cpAngle2) * cpR,
        center.dy + math.sin(cpAngle2) * cpR,
        startX,
        startY,
      );

      canvas.drawPath(petalPath, mandalaPaint);
    }

    // Dotted ring
    final dotPaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.2)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 16; i++) {
      final angle = i * math.pi / 8;
      final x = center.dx + math.cos(angle) * mandalaR * 0.62;
      final y = center.dy + math.sin(angle) * mandalaR * 0.62;
      canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
    }

    canvas.restore();
  }

  /// Energy silhouette body with gradient from bright to transparent
  void _drawEnergySilhouette(
    Canvas canvas,
    Size size,
    double cx,
    double floatY,
  ) {
    final bodyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primaryColor.withValues(alpha: 0.85),
        primaryColor.withValues(alpha: 0.65),
        primaryColor.withValues(alpha: 0.30),
        primaryColor.withValues(alpha: 0.08),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.55, 0.8, 1.0],
    );

    final headY = size.height * 0.05 + floatY;
    final headR = size.width * 0.10;

    // Head with inner white core
    final headGradient = RadialGradient(
      colors: [
        Colors.white.withValues(alpha: 0.85),
        primaryColor.withValues(alpha: 0.75),
        primaryColor.withValues(alpha: 0.35),
      ],
      stops: const [0.0, 0.35, 1.0],
    );

    canvas.drawCircle(
      Offset(cx, headY),
      headR,
      Paint()
        ..shader = headGradient.createShader(
          Rect.fromCircle(center: Offset(cx, headY), radius: headR),
        ),
    );

    // Ascending body form — ethereal, dissolving at lower edges
    final bodyPath = Path();
    final neckY = headY + headR * 0.65;

    bodyPath.moveTo(cx, neckY);

    // Broad shoulders
    bodyPath.cubicTo(
      cx - size.width * 0.12,
      neckY + size.height * 0.03,
      cx - size.width * 0.22,
      size.height * 0.17 + floatY,
      cx - size.width * 0.26,
      size.height * 0.30 + floatY,
    );

    // Dissolving lower body
    bodyPath.cubicTo(
      cx - size.width * 0.18,
      size.height * 0.50 + floatY,
      cx - size.width * 0.08,
      size.height * 0.65 + floatY,
      cx,
      size.height * 0.78 + floatY,
    );

    // Right side (mirror)
    bodyPath.cubicTo(
      cx + size.width * 0.08,
      size.height * 0.65 + floatY,
      cx + size.width * 0.18,
      size.height * 0.50 + floatY,
      cx + size.width * 0.26,
      size.height * 0.30 + floatY,
    );

    bodyPath.cubicTo(
      cx + size.width * 0.22,
      size.height * 0.17 + floatY,
      cx + size.width * 0.12,
      neckY + size.height * 0.03,
      cx,
      neckY,
    );
    bodyPath.close();

    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = bodyGradient.createShader(
          Rect.fromLTWH(0, floatY, size.width, size.height * 0.85),
        ),
    );

    // Inner white core light
    final coreCenter = Offset(cx, size.height * 0.26 + floatY);
    final coreGradient = RadialGradient(
      colors: [
        Colors.white.withValues(alpha: 0.65),
        Colors.white.withValues(alpha: 0.2),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 1.0],
    );

    canvas.drawCircle(
      coreCenter,
      size.width * 0.09,
      Paint()
        ..shader = coreGradient.createShader(
          Rect.fromCircle(center: coreCenter, radius: size.width * 0.09),
        ),
    );
  }

  /// Tiny stars and nebula within the body silhouette
  void _drawInternalStarfield(
    Canvas canvas,
    Size size,
    double cx,
    double floatY,
    double t,
  ) {
    // Clip to body shape
    final bodyPath = _getBodyClipPath(size, cx, floatY);
    canvas.save();
    canvas.clipPath(bodyPath);

    final rng = math.Random(888);
    final starPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 35; i++) {
      final x = cx + (rng.nextDouble() - 0.5) * size.width * 0.40;
      final y =
          size.height * 0.08 + rng.nextDouble() * size.height * 0.60 + floatY;
      final starSize = 0.5 + rng.nextDouble() * 1.8;
      final twinkle = (0.4 + 0.6 * math.sin(t * 2 + i * 0.5).abs()).clamp(
        0.2,
        1.0,
      );

      starPaint.color = i % 5 == 0
          ? const Color(0xFFFFD700).withValues(alpha: 0.6 * twinkle)
          : Colors.white.withValues(alpha: 0.5 * twinkle);

      canvas.drawCircle(Offset(x, y), starSize, starPaint);
    }

    // Mini nebula swirl inside body
    final nebulaPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawCircle(
      Offset(cx - size.width * 0.05, size.height * 0.30 + floatY),
      size.width * 0.08,
      nebulaPaint,
    );
    canvas.drawCircle(
      Offset(cx + size.width * 0.04, size.height * 0.38 + floatY),
      size.width * 0.06,
      nebulaPaint,
    );

    canvas.restore();
  }

  /// Solar corona sharp rays from the head
  void _drawSolarCorona(
    Canvas canvas,
    Size size,
    double cx,
    double floatY,
    double t,
  ) {
    final headCenter = Offset(cx, size.height * 0.05 + floatY);
    final rayCount = 16;

    for (int i = 0; i < rayCount; i++) {
      final angle = (i * math.pi * 2 / rayCount) + t * 0.2;
      final innerR = size.width * 0.12;
      final outerR = size.width * (0.18 + math.sin(t * 1.5 + i * 0.9) * 0.06);

      final rayPaint = Paint()
        ..color = primaryColor.withValues(
          alpha: opacity * 0.22 * (0.6 + math.sin(t + i) * 0.4),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawLine(
        Offset(
          headCenter.dx + math.cos(angle) * innerR,
          headCenter.dy + math.sin(angle) * innerR,
        ),
        Offset(
          headCenter.dx + math.cos(angle) * outerR,
          headCenter.dy + math.sin(angle) * outerR,
        ),
        rayPaint,
      );
    }
  }

  /// Orbital energy rings at different tilted angles
  void _drawOrbitalRings(
    Canvas canvas,
    Size size,
    double cx,
    double floatY,
    double t,
  ) {
    final bodyCenter = Offset(cx, size.height * 0.32 + floatY);

    for (int i = 0; i < 3; i++) {
      final orbitRadius = size.width * (0.22 + i * 0.06);
      final tilt = 0.3 + i * 0.15; // Vertical squash factor
      final rotation = t * (0.5 + i * 0.2);
      final ringAlpha = opacity * (0.15 - i * 0.03);

      final ringPaint = Paint()
        ..color = primaryColor.withValues(alpha: ringAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      // Draw tilted ellipse using canvas transform
      canvas.save();
      canvas.translate(bodyCenter.dx, bodyCenter.dy);
      canvas.rotate(rotation);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: orbitRadius * 2,
          height: orbitRadius * 2 * tilt,
        ),
        ringPaint,
      );

      canvas.restore();
    }
  }

  /// Aurora-style colored streaming dissolution at body edges
  void _drawAuroraDissolution(
    Canvas canvas,
    Size size,
    double cx,
    double floatY,
    double t,
  ) {
    final rng = math.Random(333);

    // Aurora colors (blue, pink, green, gold — tied to archetype but varied)
    final auroraColors = [
      primaryColor,
      Color.lerp(primaryColor, const Color(0xFF00FFCC), 0.5)!,
      Color.lerp(primaryColor, const Color(0xFFFF6EFF), 0.4)!,
      Color.lerp(primaryColor, const Color(0xFFFFD700), 0.3)!,
    ];

    for (int i = 0; i < 45; i++) {
      final baseAngle = rng.nextDouble() * math.pi * 2;
      final baseDist = size.width * 0.06 + rng.nextDouble() * size.width * 0.22;
      final pSize = 1.5 + rng.nextDouble() * 3.5;

      final animOff = (animationValue + i * 0.022) % 1.0;
      final dist = baseDist + animOff * size.width * 0.28;
      final yOff = -animOff * size.height * 0.28;

      final x = cx + math.cos(baseAngle) * dist;
      final y =
          size.height * 0.38 + floatY + math.sin(baseAngle) * dist * 0.4 + yOff;

      if (y > -10 && y < size.height) {
        final alpha = (1 - animOff) * 0.65;
        final color = auroraColors[i % auroraColors.length];

        // Trail effect — stretched vertically
        final trailPaint = Paint()
          ..color = color.withValues(alpha: alpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, y),
            width: pSize * 1.2,
            height: pSize * 3,
          ),
          trailPaint,
        );

        // Core particle
        final particlePaint = Paint()
          ..color = color.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
        canvas.drawCircle(Offset(x, y), pSize * 0.6, particlePaint);
      }
    }
  }

  /// Orbiting energy orbs with varied sizes and trails
  void _drawOrbitingParticles(
    Canvas canvas,
    Size size,
    double cx,
    double floatY,
    double t,
  ) {
    final rng = math.Random(123);
    final center = Offset(cx, size.height * 0.32 + floatY);

    for (int i = 0; i < 7; i++) {
      final orbitR = size.width * (0.18 + i * 0.06);
      final speed = 0.8 + i * 0.25;
      final angle = t * speed + i * (math.pi * 2 / 7);
      final tilt = 0.3 + (i % 3) * 0.15;

      final x = center.dx + math.cos(angle) * orbitR;
      final y = center.dy + math.sin(angle) * orbitR * tilt;

      final orbSize = 3.0 + rng.nextDouble() * 3.5;
      final orbAlpha = 0.5 + rng.nextDouble() * 0.35;

      // Orb glow
      final orbGradient = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: orbAlpha * 0.8),
          primaryColor.withValues(alpha: orbAlpha * 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      );

      final orbPaint = Paint()
        ..shader = orbGradient.createShader(
          Rect.fromCircle(center: Offset(x, y), radius: orbSize * 2),
        );

      canvas.drawCircle(Offset(x, y), orbSize, orbPaint);

      // Trail
      final trailAngle = angle - 0.3;
      final trailX = center.dx + math.cos(trailAngle) * orbitR;
      final trailY = center.dy + math.sin(trailAngle) * orbitR * tilt;

      final trailPaint = Paint()
        ..color = primaryColor.withValues(alpha: orbAlpha * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = orbSize * 0.6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawLine(Offset(trailX, trailY), Offset(x, y), trailPaint);
    }
  }

  /// Body clip path for internal effects
  Path _getBodyClipPath(Size size, double cx, double floatY) {
    final headY = size.height * 0.05 + floatY;
    final headR = size.width * 0.10;

    final path = Path();

    // Head
    path.addOval(Rect.fromCircle(center: Offset(cx, headY), radius: headR));

    // Body
    final bodyPath = Path();
    final neckY = headY + headR * 0.65;

    bodyPath.moveTo(cx, neckY);
    bodyPath.cubicTo(
      cx - size.width * 0.12,
      neckY + size.height * 0.03,
      cx - size.width * 0.22,
      size.height * 0.17 + floatY,
      cx - size.width * 0.26,
      size.height * 0.30 + floatY,
    );
    bodyPath.cubicTo(
      cx - size.width * 0.18,
      size.height * 0.50 + floatY,
      cx - size.width * 0.08,
      size.height * 0.65 + floatY,
      cx,
      size.height * 0.78 + floatY,
    );
    bodyPath.cubicTo(
      cx + size.width * 0.08,
      size.height * 0.65 + floatY,
      cx + size.width * 0.18,
      size.height * 0.50 + floatY,
      cx + size.width * 0.26,
      size.height * 0.30 + floatY,
    );
    bodyPath.cubicTo(
      cx + size.width * 0.22,
      size.height * 0.17 + floatY,
      cx + size.width * 0.12,
      neckY + size.height * 0.03,
      cx,
      neckY,
    );
    bodyPath.close();
    path.addPath(bodyPath, Offset.zero);

    return path;
  }

  @override
  bool shouldRepaint(covariant AscendedPhasePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.primaryColor != primaryColor;
  }
}
