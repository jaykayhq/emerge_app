import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Phase 3: The Incarnate - Solid, matte silhouette with defined posture
/// The fog is gone. Distinct body parts visible with idle breathing animation.
/// User Feeling: "I am here. I am consistent."
class IncarnatePhasePainter extends CustomPainter {
  final double animationValue; // 0.0-1.0 for breathing
  final Color primaryColor;
  final double opacity;

  IncarnatePhasePainter({
    required this.animationValue,
    required this.primaryColor,
    this.opacity = 0.85,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    // Subtle breathing scale
    final breathScale = 1.0 + math.sin(animationValue * math.pi * 2) * 0.015;

    // Draw solid silhouette
    _drawSolidSilhouette(canvas, size, centerX, breathScale);

    // Draw subtle edge glow
    _drawEdgeGlow(canvas, size, centerX, breathScale);

    // Draw muscle definition hints
    _drawMuscleDefinition(canvas, size, centerX, breathScale);
  }

  void _drawSolidSilhouette(
    Canvas canvas,
    Size size,
    double centerX,
    double breathScale,
  ) {
    final fillPaint = Paint()
      ..color = Colors.black.withValues(alpha: opacity * 0.9)
      ..style = PaintingStyle.fill;

    final path = _createBodyPath(size, centerX, breathScale);
    canvas.drawPath(path, fillPaint);
  }

  Path _createBodyPath(Size size, double centerX, double breathScale) {
    final path = Path();

    // Head
    final headY = size.height * 0.08;
    final headRadius = size.width * 0.09;

    path.addOval(
      Rect.fromCircle(center: Offset(centerX, headY), radius: headRadius),
    );

    // Neck
    final neckTop = headY + headRadius * 0.8;
    final neckWidth = size.width * 0.05;

    // Shoulders and torso
    final shoulderY = size.height * 0.18;
    final shoulderWidth = size.width * 0.22 * breathScale;
    final waistY = size.height * 0.42;
    final waistWidth = size.width * 0.12;
    final hipY = size.height * 0.48;
    final hipWidth = size.width * 0.14;

    // Create torso path
    final torsoPath = Path();
    torsoPath.moveTo(centerX - neckWidth, neckTop);

    // Left shoulder curve
    torsoPath.quadraticBezierTo(
      centerX - neckWidth * 1.5,
      shoulderY - size.height * 0.02,
      centerX - shoulderWidth,
      shoulderY,
    );

    // Left arm
    torsoPath.lineTo(
      centerX - shoulderWidth - size.width * 0.03,
      shoulderY + size.height * 0.18,
    );
    torsoPath.lineTo(
      centerX - shoulderWidth + size.width * 0.02,
      shoulderY + size.height * 0.20,
    );

    // Left side body
    torsoPath.lineTo(centerX - waistWidth, waistY);
    torsoPath.lineTo(centerX - hipWidth, hipY);

    // Left leg
    torsoPath.lineTo(
      centerX - hipWidth - size.width * 0.02,
      size.height * 0.75,
    );
    torsoPath.lineTo(centerX - size.width * 0.08, size.height * 0.88);
    torsoPath.lineTo(centerX - size.width * 0.04, size.height * 0.88);
    torsoPath.lineTo(centerX - size.width * 0.02, hipY + size.height * 0.15);

    // Crotch
    torsoPath.lineTo(centerX, hipY + size.height * 0.08);
    torsoPath.lineTo(centerX + size.width * 0.02, hipY + size.height * 0.15);

    // Right leg
    torsoPath.lineTo(centerX + size.width * 0.04, size.height * 0.88);
    torsoPath.lineTo(centerX + size.width * 0.08, size.height * 0.88);
    torsoPath.lineTo(
      centerX + hipWidth + size.width * 0.02,
      size.height * 0.75,
    );

    // Right side body
    torsoPath.lineTo(centerX + hipWidth, hipY);
    torsoPath.lineTo(centerX + waistWidth, waistY);

    // Right arm
    torsoPath.lineTo(
      centerX + shoulderWidth - size.width * 0.02,
      shoulderY + size.height * 0.20,
    );
    torsoPath.lineTo(
      centerX + shoulderWidth + size.width * 0.03,
      shoulderY + size.height * 0.18,
    );

    // Right shoulder
    torsoPath.lineTo(centerX + shoulderWidth, shoulderY);

    // Right shoulder curve to neck
    torsoPath.quadraticBezierTo(
      centerX + neckWidth * 1.5,
      shoulderY - size.height * 0.02,
      centerX + neckWidth,
      neckTop,
    );

    torsoPath.close();
    path.addPath(torsoPath, Offset.zero);

    return path;
  }

  void _drawEdgeGlow(
    Canvas canvas,
    Size size,
    double centerX,
    double breathScale,
  ) {
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final path = _createBodyPath(size, centerX, breathScale);
    canvas.drawPath(path, glowPaint);
  }

  void _drawMuscleDefinition(
    Canvas canvas,
    Size size,
    double centerX,
    double breathScale,
  ) {
    final linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // Chest line
    final chestY = size.height * 0.25 * breathScale;
    canvas.drawLine(
      Offset(centerX - size.width * 0.08, chestY),
      Offset(centerX + size.width * 0.08, chestY),
      linePaint,
    );

    // Ab lines
    for (int i = 0; i < 3; i++) {
      final y = size.height * (0.30 + i * 0.04);
      canvas.drawLine(
        Offset(centerX - size.width * 0.05, y),
        Offset(centerX + size.width * 0.05, y),
        linePaint,
      );
    }

    // Center line
    canvas.drawLine(
      Offset(centerX, size.height * 0.22),
      Offset(centerX, size.height * 0.42),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant IncarnatePhasePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.primaryColor != primaryColor;
  }
}
