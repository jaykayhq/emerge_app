import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Phase 2: The Construct — Sacred geometry wireframe with energy circuits
/// Geometric mesh body with glowing rune nodes, holographic scanlines,
/// circuit-board energy pulses, and a triangulated face.
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
    final cx = size.width / 2;
    final t = animationValue * math.pi * 2;

    // Heartbeat pulse
    final pulse = 0.85 + math.sin(t) * 0.15;

    // Layer 1: Fading residual smoke
    _drawResidualSmoke(canvas, size, cx, 1 - phaseProgress * 0.8);

    // Layer 2: Sacred geometry background circles
    _drawSacredGeometry(canvas, size, cx, t, pulse);

    // Layer 3: Wireframe body with depth
    _drawWireframeBody(canvas, size, cx, pulse);

    // Layer 4: Animated circuit energy flowing through wireframe
    _drawCircuitEnergy(canvas, size, cx, t);

    // Layer 5: Glowing rune nodes at joints
    _drawRuneNodes(canvas, size, cx, pulse, t);

    // Layer 6: Holographic scanline sweep
    _drawScanlines(canvas, size, t);
  }

  void _drawResidualSmoke(
    Canvas canvas,
    Size size,
    double cx,
    double smokeAlpha,
  ) {
    if (smokeAlpha < 0.05) return;

    final gradient = RadialGradient(
      colors: [
        primaryColor.withValues(alpha: opacity * 0.12 * smokeAlpha),
        primaryColor.withValues(alpha: opacity * 0.04 * smokeAlpha),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final center = Offset(cx, size.height * 0.42);
    final rect = Rect.fromCenter(
      center: center,
      width: size.width * 0.55,
      height: size.height * 0.65,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);

    canvas.drawOval(rect, paint);
  }

  /// Concentric sacred geometry circles behind the body
  void _drawSacredGeometry(
    Canvas canvas,
    Size size,
    double cx,
    double t,
    double pulse,
  ) {
    final center = Offset(cx, size.height * 0.32);

    for (int i = 0; i < 3; i++) {
      final radius = size.width * (0.22 + i * 0.1);
      final rotation = t * (0.3 + i * 0.1) * (i.isEven ? 1 : -1);
      final alpha = opacity * (0.12 - i * 0.03) * pulse;

      final ringPaint = Paint()
        ..color = primaryColor.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      // Draw circle
      canvas.drawCircle(center, radius, ringPaint);

      // Draw polygon inscribed in circle (triangle, square, pentagon)
      final sides = 3 + i;
      final polyPath = Path();
      for (int v = 0; v <= sides; v++) {
        final angle = rotation + (v * math.pi * 2 / sides) - math.pi / 2;
        final px = center.dx + math.cos(angle) * radius;
        final py = center.dy + math.sin(angle) * radius;
        if (v == 0) {
          polyPath.moveTo(px, py);
        } else {
          polyPath.lineTo(px, py);
        }
      }
      polyPath.close();
      canvas.drawPath(polyPath, ringPaint);
    }
  }

  /// Wireframe skeleton body with double-stroke (glow + core) for 3D depth
  void _drawWireframeBody(Canvas canvas, Size size, double cx, double pulse) {
    // Define joints
    final joints = _getJointPositions(size, cx);

    // Glow layer (wide, blurred)
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.25 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Core layer (thin, bright)
    final wirePaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.75 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    // Body connections
    final connections = _getBodyConnections();

    // Draw only connections based on phaseProgress
    final visibleCount = (connections.length * (0.4 + phaseProgress * 0.6))
        .ceil();

    for (int i = 0; i < visibleCount && i < connections.length; i++) {
      final from = joints[connections[i][0]];
      final to = joints[connections[i][1]];
      if (from == null || to == null) continue;

      canvas.drawLine(from, to, glowPaint);
      canvas.drawLine(from, to, wirePaint);
    }

    // Draw triangulated head
    _drawTriangulatedHead(canvas, size, cx, pulse);
  }

  /// Triangulated geometric head with more vertices than a simple hexagon
  void _drawTriangulatedHead(
    Canvas canvas,
    Size size,
    double cx,
    double pulse,
  ) {
    final headCenter = Offset(cx, size.height * 0.09);
    final r = size.width * 0.08 * pulse;

    final wirePaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.7 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.2 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // 8-sided polygon for more detailed head
    final vertices = <Offset>[];
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45 - 90) * math.pi / 180;
      vertices.add(
        Offset(
          headCenter.dx + r * math.cos(angle),
          headCenter.dy + r * math.sin(angle) * 1.1,
        ),
      );
    }

    // Outer shape
    final outerPath = Path()..moveTo(vertices[0].dx, vertices[0].dy);
    for (int i = 1; i < vertices.length; i++) {
      outerPath.lineTo(vertices[i].dx, vertices[i].dy);
    }
    outerPath.close();

    canvas.drawPath(outerPath, glowPaint);
    canvas.drawPath(outerPath, wirePaint);

    // Internal triangulation lines radiating from center
    for (int i = 0; i < vertices.length; i += 2) {
      canvas.drawLine(headCenter, vertices[i], wirePaint);
    }
  }

  /// Animated energy dashes flowing through the spine and limbs
  void _drawCircuitEnergy(Canvas canvas, Size size, double cx, double t) {
    final joints = _getJointPositions(size, cx);

    // Energy paths (spine, arms, legs)
    final energyPaths = [
      ['head', 'neck', 'chest', 'waist'], // Spine
      ['leftShoulder', 'leftElbow', 'leftHand'], // Left arm
      ['rightShoulder', 'rightElbow', 'rightHand'], // Right arm
      ['leftHip', 'leftKnee', 'leftFoot'], // Left leg
      ['rightHip', 'rightKnee', 'rightFoot'], // Right leg
    ];

    for (int pathIdx = 0; pathIdx < energyPaths.length; pathIdx++) {
      final pathKeys = energyPaths[pathIdx];
      final points = pathKeys
          .map((k) => joints[k])
          .where((p) => p != null)
          .cast<Offset>()
          .toList();
      if (points.length < 2) continue;

      // Compute total length
      double totalLen = 0;
      for (int i = 1; i < points.length; i++) {
        totalLen += (points[i] - points[i - 1]).distance;
      }

      // Draw a traveling bright dot along this path
      final dashPos = ((animationValue + pathIdx * 0.2) % 1.0) * totalLen;
      double cumLen = 0;

      for (int i = 1; i < points.length; i++) {
        final segLen = (points[i] - points[i - 1]).distance;
        if (cumLen + segLen >= dashPos && cumLen <= dashPos) {
          final segT = (dashPos - cumLen) / segLen;
          final pos = Offset.lerp(points[i - 1], points[i], segT)!;

          final dotPaint = Paint()
            ..color = Colors.white.withValues(alpha: opacity * 0.8)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawCircle(pos, 3.5, dotPaint);

          final glowPaint = Paint()
            ..color = primaryColor.withValues(alpha: opacity * 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
          canvas.drawCircle(pos, 8, glowPaint);
          break;
        }
        cumLen += segLen;
      }
    }
  }

  /// Glowing rune symbols at joint positions
  void _drawRuneNodes(
    Canvas canvas,
    Size size,
    double cx,
    double pulse,
    double t,
  ) {
    final joints = _getJointPositions(size, cx);

    // Primary node paint
    final nodePaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.9 * pulse)
      ..style = PaintingStyle.fill;

    final nodeGlow = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.35 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    int idx = 0;
    for (final entry in joints.entries) {
      final pos = entry.value;

      // Glow ring
      canvas.drawCircle(pos, 5 * pulse, nodeGlow);

      // Core dot
      canvas.drawCircle(pos, 2.5 * pulse, nodePaint);

      // Small rotating rune mark (simple cross that rotates)
      final runeAngle = t * 1.5 + idx * 0.7;
      final runeR = 4.5 * pulse;
      final runePaint = Paint()
        ..color = primaryColor.withValues(alpha: opacity * 0.5 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;

      canvas.drawLine(
        Offset(
          pos.dx + math.cos(runeAngle) * runeR,
          pos.dy + math.sin(runeAngle) * runeR,
        ),
        Offset(
          pos.dx - math.cos(runeAngle) * runeR,
          pos.dy - math.sin(runeAngle) * runeR,
        ),
        runePaint,
      );
      canvas.drawLine(
        Offset(
          pos.dx + math.cos(runeAngle + math.pi / 2) * runeR,
          pos.dy + math.sin(runeAngle + math.pi / 2) * runeR,
        ),
        Offset(
          pos.dx - math.cos(runeAngle + math.pi / 2) * runeR,
          pos.dy - math.sin(runeAngle + math.pi / 2) * runeR,
        ),
        runePaint,
      );

      idx++;
    }
  }

  /// Horizontal holographic scanline sweep
  void _drawScanlines(Canvas canvas, Size size, double t) {
    final scanY = (animationValue % 1.0) * size.height;

    // Thin bright scanline
    final scanPaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.15)
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), scanPaint);

    // Wide glow trail behind scanline
    final trailGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        primaryColor.withValues(alpha: opacity * 0.06),
        primaryColor.withValues(alpha: opacity * 0.12),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.5, 1.0],
    );

    final trailHeight = size.height * 0.08;
    final trailRect = Rect.fromLTWH(
      0,
      scanY - trailHeight,
      size.width,
      trailHeight * 2,
    );

    final trailPaint = Paint()..shader = trailGradient.createShader(trailRect);

    canvas.drawRect(trailRect, trailPaint);
  }

  /// Joint positions map
  Map<String, Offset> _getJointPositions(Size size, double cx) {
    return {
      'head': Offset(cx, size.height * 0.09),
      'neck': Offset(cx, size.height * 0.17),
      'leftShoulder': Offset(cx - size.width * 0.19, size.height * 0.21),
      'rightShoulder': Offset(cx + size.width * 0.19, size.height * 0.21),
      'leftElbow': Offset(cx - size.width * 0.23, size.height * 0.34),
      'rightElbow': Offset(cx + size.width * 0.23, size.height * 0.34),
      'leftHand': Offset(cx - size.width * 0.19, size.height * 0.47),
      'rightHand': Offset(cx + size.width * 0.19, size.height * 0.47),
      'chest': Offset(cx, size.height * 0.30),
      'waist': Offset(cx, size.height * 0.43),
      'leftHip': Offset(cx - size.width * 0.09, size.height * 0.47),
      'rightHip': Offset(cx + size.width * 0.09, size.height * 0.47),
      'leftKnee': Offset(cx - size.width * 0.11, size.height * 0.64),
      'rightKnee': Offset(cx + size.width * 0.11, size.height * 0.64),
      'leftFoot': Offset(cx - size.width * 0.13, size.height * 0.84),
      'rightFoot': Offset(cx + size.width * 0.13, size.height * 0.84),
    };
  }

  /// Body wireframe connections (joint name index pairs)
  List<List<String>> _getBodyConnections() {
    return [
      ['neck', 'chest'],
      ['chest', 'waist'],
      ['neck', 'leftShoulder'],
      ['neck', 'rightShoulder'],
      ['leftShoulder', 'leftElbow'],
      ['rightShoulder', 'rightElbow'],
      ['leftElbow', 'leftHand'],
      ['rightElbow', 'rightHand'],
      ['waist', 'leftHip'],
      ['waist', 'rightHip'],
      ['leftHip', 'leftKnee'],
      ['rightHip', 'rightKnee'],
      ['leftKnee', 'leftFoot'],
      ['rightKnee', 'rightFoot'],
      // Cross braces
      ['leftShoulder', 'chest'],
      ['rightShoulder', 'chest'],
      ['leftHip', 'rightHip'],
      // Rib cage
      ['leftShoulder', 'waist'],
      ['rightShoulder', 'waist'],
    ];
  }

  @override
  bool shouldRepaint(covariant ConstructPhasePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.phaseProgress != phaseProgress ||
        oldDelegate.primaryColor != primaryColor;
  }
}
