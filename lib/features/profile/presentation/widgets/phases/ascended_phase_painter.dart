import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Phase 5: The Ascended - Pure energy transcendence
/// The silhouette becomes pure light/energy, dissolving at edges into particles.
/// Floating, defying gravity. Particle effects surround the user.
/// User Feeling: "I have transcended. The habit is now part of my soul."
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
    final centerX = size.width / 2;

    // Floating offset
    final floatY = math.sin(animationValue * math.pi * 2) * 8;

    // Draw cosmic background glow
    _drawCosmicGlow(canvas, size, centerX, floatY);

    // Draw energy silhouette
    _drawEnergySilhouette(canvas, size, centerX, floatY);

    // Draw dissolution particles
    _drawDissolutionParticles(canvas, size, centerX, floatY);

    // Draw energy waves
    _drawEnergyWaves(canvas, size, centerX);

    // Draw floating orbs
    _drawFloatingOrbs(canvas, size, centerX);
  }

  void _drawCosmicGlow(
    Canvas canvas,
    Size size,
    double centerX,
    double floatY,
  ) {
    // Multiple layers of cosmic glow
    for (int i = 3; i >= 0; i--) {
      final radius = size.width * (0.3 + i * 0.15);
      final alpha = 0.1 - i * 0.02;

      final gradient = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: alpha),
          primaryColor.withValues(alpha: alpha * 0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(
            center: Offset(centerX, size.height * 0.4 + floatY),
            radius: radius,
          ),
        );

      canvas.drawCircle(
        Offset(centerX, size.height * 0.4 + floatY),
        radius,
        paint,
      );
    }
  }

  void _drawEnergySilhouette(
    Canvas canvas,
    Size size,
    double centerX,
    double floatY,
  ) {
    // Energy gradient for the body
    final bodyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primaryColor.withValues(alpha: 0.9),
        primaryColor.withValues(alpha: 0.7),
        primaryColor.withValues(alpha: 0.3),
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 0.7, 1.0],
    );

    final headY = size.height * 0.06 + floatY;
    final headRadius = size.width * 0.1;

    // Energy head with inner glow
    final headGradient = RadialGradient(
      colors: [
        Colors.white.withValues(alpha: 0.9),
        primaryColor.withValues(alpha: 0.8),
        primaryColor.withValues(alpha: 0.4),
      ],
      stops: const [0.0, 0.4, 1.0],
    );

    final headPaint = Paint()
      ..shader = headGradient.createShader(
        Rect.fromCircle(center: Offset(centerX, headY), radius: headRadius),
      );

    canvas.drawCircle(Offset(centerX, headY), headRadius, headPaint);

    // Energy body (simplified ascending form)
    final bodyPath = Path();
    final neckY = headY + headRadius * 0.7;

    bodyPath.moveTo(centerX, neckY);
    bodyPath.quadraticBezierTo(
      centerX - size.width * 0.2,
      size.height * 0.2 + floatY,
      centerX - size.width * 0.25,
      size.height * 0.35 + floatY,
    );
    bodyPath.quadraticBezierTo(
      centerX - size.width * 0.15,
      size.height * 0.55 + floatY,
      centerX,
      size.height * 0.75 + floatY,
    );
    bodyPath.quadraticBezierTo(
      centerX + size.width * 0.15,
      size.height * 0.55 + floatY,
      centerX + size.width * 0.25,
      size.height * 0.35 + floatY,
    );
    bodyPath.quadraticBezierTo(
      centerX + size.width * 0.2,
      size.height * 0.2 + floatY,
      centerX,
      neckY,
    );
    bodyPath.close();

    final bodyPaint = Paint()
      ..shader = bodyGradient.createShader(
        Rect.fromLTWH(0, floatY, size.width, size.height * 0.8),
      );

    canvas.drawPath(bodyPath, bodyPaint);

    // Inner core light
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawCircle(
      Offset(centerX, size.height * 0.28 + floatY),
      size.width * 0.08,
      corePaint,
    );
  }

  void _drawDissolutionParticles(
    Canvas canvas,
    Size size,
    double centerX,
    double floatY,
  ) {
    final random = math.Random(42);

    for (int i = 0; i < 40; i++) {
      // Particles emanate from body edges and float upward
      final baseAngle = random.nextDouble() * math.pi * 2;
      final baseDistance =
          size.width * 0.08 + random.nextDouble() * size.width * 0.25;

      // Animate outward and upward
      final animOffset = (animationValue + i * 0.025) % 1.0;
      final distance = baseDistance + animOffset * size.width * 0.3;
      final yOffset = -animOffset * size.height * 0.3;

      final x = centerX + math.cos(baseAngle) * distance;
      final y =
          size.height * 0.4 +
          floatY +
          math.sin(baseAngle) * distance * 0.5 +
          yOffset;

      // Fade out as they move away
      final particleAlpha = (1 - animOffset) * 0.8;
      final particleSize = (1 - animOffset) * 4 + 1;

      if (y > 0 && y < size.height) {
        final particlePaint = Paint()
          ..color = primaryColor.withValues(alpha: particleAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

        canvas.drawCircle(Offset(x, y), particleSize, particlePaint);
      }
    }
  }

  void _drawEnergyWaves(Canvas canvas, Size size, double centerX) {
    // Expanding energy rings
    for (int i = 0; i < 3; i++) {
      final waveProgress = (animationValue + i * 0.33) % 1.0;
      final radius = size.width * 0.15 + waveProgress * size.width * 0.4;
      final alpha = (1 - waveProgress) * 0.3;

      final wavePaint = Paint()
        ..color = primaryColor.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(Offset(centerX, size.height * 0.35), radius, wavePaint);
    }
  }

  void _drawFloatingOrbs(Canvas canvas, Size size, double centerX) {
    final random = math.Random(123);

    // Orbiting energy orbs
    for (int i = 0; i < 5; i++) {
      final orbitRadius = size.width * 0.2 + i * size.width * 0.08;
      final orbitSpeed = 1.0 + i * 0.3;
      final angle =
          animationValue * math.pi * 2 * orbitSpeed + i * (math.pi * 2 / 5);

      final x = centerX + math.cos(angle) * orbitRadius;
      final y = size.height * 0.35 + math.sin(angle) * orbitRadius * 0.4;

      final orbSize = 4.0 + random.nextDouble() * 4;
      final orbAlpha = 0.5 + random.nextDouble() * 0.4;

      final orbGradient = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: orbAlpha),
          primaryColor.withValues(alpha: orbAlpha * 0.5),
          Colors.transparent,
        ],
      );

      final orbPaint = Paint()
        ..shader = orbGradient.createShader(
          Rect.fromCircle(center: Offset(x, y), radius: orbSize),
        );

      canvas.drawCircle(Offset(x, y), orbSize, orbPaint);
    }
  }

  @override
  bool shouldRepaint(covariant AscendedPhasePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.primaryColor != primaryColor;
  }
}
