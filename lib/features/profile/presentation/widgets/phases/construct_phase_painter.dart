import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Phase 2: The Construct - Wireframe mesh appears within smoke
/// A geometric mesh structure is visible, pulsing with faint heartbeat
/// User Feeling: "I am building the framework."
class ConstructPhasePainter extends CustomPainter {
  final double animationValue; // 0.0-1.0 for pulse
  final Color primaryColor;
  final double opacity;
  final double phaseProgress; // 0.0-1.0 how far into this phase

  ConstructPhasePainter({
    required this.animationValue,
    required this.primaryColor,
    this.opacity = 0.6,
    this.phaseProgress = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    // Heartbeat pulse effect
    final pulse = 0.9 + math.sin(animationValue * math.pi * 2) * 0.1;

    // Draw remaining smoke (fading as phase progresses)
    _drawBackgroundSmoke(canvas, size, centerX, 1 - phaseProgress * 0.7);

    // Draw wireframe body
    _drawWireframeBody(canvas, size, centerX, pulse);

    // Draw connecting energy lines
    _drawEnergyLines(canvas, size, centerX, pulse);
  }

  void _drawBackgroundSmoke(
    Canvas canvas,
    Size size,
    double centerX,
    double smokeOpacity,
  ) {
    final smokePaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.2 * smokeOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, size.height * 0.45),
        width: size.width * 0.5,
        height: size.height * 0.6,
      ),
      smokePaint,
    );
  }

  void _drawWireframeBody(
    Canvas canvas,
    Size size,
    double centerX,
    double pulse,
  ) {
    final wirePaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.7 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.3 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Define body vertices
    final headCenter = Offset(centerX, size.height * 0.1);
    final headRadius = size.width * 0.08 * pulse;
    final neckPoint = Offset(centerX, size.height * 0.18);
    final leftShoulder = Offset(
      centerX - size.width * 0.18,
      size.height * 0.22,
    );
    final rightShoulder = Offset(
      centerX + size.width * 0.18,
      size.height * 0.22,
    );
    final leftElbow = Offset(centerX - size.width * 0.22, size.height * 0.35);
    final rightElbow = Offset(centerX + size.width * 0.22, size.height * 0.35);
    final leftHand = Offset(centerX - size.width * 0.18, size.height * 0.48);
    final rightHand = Offset(centerX + size.width * 0.18, size.height * 0.48);
    final chest = Offset(centerX, size.height * 0.32);
    final waist = Offset(centerX, size.height * 0.45);
    final leftHip = Offset(centerX - size.width * 0.08, size.height * 0.48);
    final rightHip = Offset(centerX + size.width * 0.08, size.height * 0.48);
    final leftKnee = Offset(centerX - size.width * 0.1, size.height * 0.65);
    final rightKnee = Offset(centerX + size.width * 0.1, size.height * 0.65);
    final leftFoot = Offset(centerX - size.width * 0.12, size.height * 0.85);
    final rightFoot = Offset(centerX + size.width * 0.12, size.height * 0.85);

    // Draw head (hexagonal)
    _drawHexagon(canvas, headCenter, headRadius, wirePaint, glowPaint);

    // Draw body lines with glow
    final bodyLines = [
      [neckPoint, chest],
      [chest, waist],
      [neckPoint, leftShoulder],
      [neckPoint, rightShoulder],
      [leftShoulder, leftElbow],
      [rightShoulder, rightElbow],
      [leftElbow, leftHand],
      [rightElbow, rightHand],
      [waist, leftHip],
      [waist, rightHip],
      [leftHip, leftKnee],
      [rightHip, rightKnee],
      [leftKnee, leftFoot],
      [rightKnee, rightFoot],
      // Cross braces for structure
      [leftShoulder, chest],
      [rightShoulder, chest],
      [leftHip, rightHip],
    ];

    for (final line in bodyLines) {
      canvas.drawLine(line[0], line[1], glowPaint);
      canvas.drawLine(line[0], line[1], wirePaint);
    }

    // Draw joint nodes
    final joints = [
      neckPoint,
      leftShoulder,
      rightShoulder,
      leftElbow,
      rightElbow,
      leftHand,
      rightHand,
      chest,
      waist,
      leftHip,
      rightHip,
      leftKnee,
      rightKnee,
      leftFoot,
      rightFoot,
    ];

    final nodePaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.8 * pulse)
      ..style = PaintingStyle.fill;

    for (final joint in joints) {
      canvas.drawCircle(joint, 3, nodePaint);
    }
  }

  void _drawHexagon(
    Canvas canvas,
    Offset center,
    double radius,
    Paint wirePaint,
    Paint glowPaint,
  ) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * math.pi / 180;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, wirePaint);
  }

  void _drawEnergyLines(
    Canvas canvas,
    Size size,
    double centerX,
    double pulse,
  ) {
    // Draw pulsing energy flowing through the wireframe
    final energyPaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.5 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Spine energy line
    final spinePath = Path();
    spinePath.moveTo(centerX, size.height * 0.1);
    spinePath.lineTo(centerX, size.height * 0.45);

    // Animate dash offset
    final dashOffset = animationValue * 20;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, dashOffset % 10, size.width, size.height));
    canvas.drawPath(spinePath, energyPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ConstructPhasePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.phaseProgress != phaseProgress ||
        oldDelegate.primaryColor != primaryColor;
  }
}
