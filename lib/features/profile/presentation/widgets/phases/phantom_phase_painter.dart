import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Phase 1: The Phantom - Smoky, nebulous cloud in rough human shape
/// Turbulent, shifting like smoke with low opacity (50%), blurry edges
/// User Feeling: "I am potential, but undefined."
class PhantomPhasePainter extends CustomPainter {
  final double animationValue; // 0.0-1.0 for turbulence
  final Color primaryColor;
  final double opacity;
  final double entropyLevel; // 0.0-1.0 for decay effects

  PhantomPhasePainter({
    required this.animationValue,
    required this.primaryColor,
    this.opacity = 0.5,
    this.entropyLevel = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.45;

    // Turbulence offset based on animation
    final turbulenceX = math.sin(animationValue * math.pi * 2) * 3;
    final turbulenceY = math.cos(animationValue * math.pi * 3) * 2;

    // Decay effect - more chaotic when entropy is high
    final decayOffset = entropyLevel * 5;

    // Layer 1: Outer smoke cloud (most diffuse)
    _drawSmokeLayer(
      canvas,
      size,
      Offset(centerX + turbulenceX + decayOffset, centerY + turbulenceY),
      size.width * 0.35,
      size.height * 0.55,
      primaryColor.withValues(alpha: opacity * 0.2 * (1 - entropyLevel * 0.5)),
      blur: 40,
    );

    // Layer 2: Mid smoke layer
    _drawSmokeLayer(
      canvas,
      size,
      Offset(centerX - turbulenceX * 0.5, centerY - turbulenceY * 0.5),
      size.width * 0.28,
      size.height * 0.48,
      primaryColor.withValues(alpha: opacity * 0.35),
      blur: 25,
    );

    // Layer 3: Inner core (most defined)
    _drawSmokeLayer(
      canvas,
      size,
      Offset(centerX + turbulenceX * 0.3, centerY),
      size.width * 0.2,
      size.height * 0.4,
      primaryColor.withValues(alpha: opacity * 0.5),
      blur: 15,
    );

    // Draw humanoid suggestion with smoke particles
    _drawSmokyHumanoid(
      canvas,
      size,
      centerX,
      centerY,
      turbulenceX,
      turbulenceY,
    );

    // Floating particles effect
    _drawSmokeParticles(canvas, size, centerX, centerY);
  }

  void _drawSmokeLayer(
    Canvas canvas,
    Size size,
    Offset center,
    double width,
    double height,
    Color color, {
    double blur = 20,
  }) {
    final paint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    // Draw as oval for body-like shape
    final rect = Rect.fromCenter(center: center, width: width, height: height);
    canvas.drawOval(rect, paint);
  }

  void _drawSmokyHumanoid(
    Canvas canvas,
    Size size,
    double centerX,
    double centerY,
    double turbX,
    double turbY,
  ) {
    final smokePaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.4)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    // Head suggestion (smoky circle)
    final headY = size.height * 0.12;
    final headRadius =
        size.width * 0.09 + math.sin(animationValue * math.pi) * 2;
    canvas.drawCircle(
      Offset(centerX + turbX * 0.5, headY + turbY * 0.3),
      headRadius,
      smokePaint,
    );

    // Shoulders/upper body suggestion
    final shoulderPath = Path();
    final neckY = headY + headRadius;
    final shoulderWidth = size.width * 0.3;

    shoulderPath.moveTo(centerX, neckY);
    shoulderPath.quadraticBezierTo(
      centerX - shoulderWidth * 0.3 + turbX,
      neckY + size.height * 0.05,
      centerX - shoulderWidth * 0.5,
      neckY + size.height * 0.1 + turbY,
    );
    shoulderPath.quadraticBezierTo(
      centerX - size.width * 0.15,
      size.height * 0.5,
      centerX - size.width * 0.1,
      size.height * 0.7,
    );
    shoulderPath.lineTo(centerX + size.width * 0.1, size.height * 0.7);
    shoulderPath.quadraticBezierTo(
      centerX + size.width * 0.15,
      size.height * 0.5,
      centerX + shoulderWidth * 0.5,
      neckY + size.height * 0.1 - turbY,
    );
    shoulderPath.quadraticBezierTo(
      centerX + shoulderWidth * 0.3 - turbX,
      neckY + size.height * 0.05,
      centerX,
      neckY,
    );
    shoulderPath.close();

    canvas.drawPath(shoulderPath, smokePaint);
  }

  void _drawSmokeParticles(
    Canvas canvas,
    Size size,
    double centerX,
    double centerY,
  ) {
    final random = math.Random(42); // Fixed seed for consistent pattern
    final particlePaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (int i = 0; i < 15; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final distance =
          size.width * 0.2 + random.nextDouble() * size.width * 0.25;
      final particleSize = 3.0 + random.nextDouble() * 5;

      // Animate particles outward
      final animOffset = math.sin(animationValue * math.pi * 2 + i * 0.5) * 10;

      final x = centerX + math.cos(angle) * (distance + animOffset);
      final y = centerY + math.sin(angle) * (distance * 0.8 + animOffset * 0.5);

      canvas.drawCircle(Offset(x, y), particleSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant PhantomPhasePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.entropyLevel != entropyLevel ||
        oldDelegate.primaryColor != primaryColor;
  }
}
