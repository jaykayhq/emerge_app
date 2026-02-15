import 'dart:math' as math;
import 'package:emerge_app/features/profile/domain/models/silhouette_evolution.dart';
import 'package:flutter/material.dart';

/// Renders body artifacts (equipment) on the silhouette at zone-specific anchor points
/// Artifacts appear when unlocked through habit completion votes
class BodyArtifactOverlay extends StatelessWidget {
  final List<BodyArtifact> artifacts;
  final double animationValue;
  final Size silhouetteSize;

  const BodyArtifactOverlay({
    super.key,
    required this.artifacts,
    required this.animationValue,
    required this.silhouetteSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: silhouetteSize,
      painter: _ArtifactPainter(
        artifacts: artifacts,
        animationValue: animationValue,
      ),
    );
  }
}

class _ArtifactPainter extends CustomPainter {
  final List<BodyArtifact> artifacts;
  final double animationValue;

  // Anchor points for each body zone (relative coordinates)
  static const Map<BodyZone, List<(double, double)>> _zoneAnchors = {
    BodyZone.ankles: [(0.38, 0.88), (0.62, 0.88)],
    BodyZone.head: [(0.5, 0.05)],
    BodyZone.eyes: [(0.5, 0.08)],
    BodyZone.chest: [(0.5, 0.28)],
    BodyZone.hands: [(0.15, 0.42), (0.85, 0.42)],
    BodyZone.core: [(0.5, 0.38)],
    BodyZone.spine: [(0.5, 0.45)],
  };

  _ArtifactPainter({required this.artifacts, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = 0.8 + math.sin(animationValue * math.pi * 2) * 0.2;

    for (final artifact in artifacts) {
      final anchors = _zoneAnchors[artifact.zone] ?? [];

      for (final anchor in anchors) {
        final position = Offset(
          anchor.$1 * size.width,
          anchor.$2 * size.height,
        );
        _drawArtifact(canvas, artifact, position, size, pulse);
      }
    }
  }

  void _drawArtifact(
    Canvas canvas,
    BodyArtifact artifact,
    Offset position,
    Size size,
    double pulse,
  ) {
    switch (artifact.id) {
      case 'hermes_wings':
        _drawHermesWings(canvas, position, size, artifact.glowColor, pulse);
        break;
      case 'golden_shoes':
        _drawGoldenShoes(canvas, position, size, artifact.glowColor, pulse);
        break;
      case 'halo':
        _drawHalo(canvas, position, size, artifact.glowColor, pulse);
        break;
      case 'third_eye':
        _drawThirdEye(canvas, position, size, artifact.glowColor, pulse);
        break;
      case 'aegis':
        _drawAegis(canvas, position, size, artifact.glowColor, pulse);
        break;
      case 'core_glow':
        _drawCoreGlow(canvas, position, size, artifact.glowColor, pulse);
        break;
      case 'midas_touch':
        _drawMidasTouch(canvas, position, size, artifact.glowColor, pulse);
        break;
      case 'floating_tools':
        _drawFloatingTools(canvas, position, size, artifact.glowColor, pulse);
        break;
      case 'the_flow':
        _drawTheFlow(canvas, position, size, artifact.glowColor, pulse);
        break;
      default:
        _drawGenericGlow(canvas, position, size, artifact.glowColor, pulse);
    }
  }

  void _drawHermesWings(
    Canvas canvas,
    Offset position,
    Size size,
    Color color,
    double pulse,
  ) {
    final wingPaint = Paint()
      ..color = color.withValues(alpha: 0.7 * pulse)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Small wing shape
    final wingSize = size.width * 0.06;

    // Left wing
    final leftWing = Path();
    leftWing.moveTo(position.dx, position.dy);
    leftWing.quadraticBezierTo(
      position.dx - wingSize * 1.5,
      position.dy - wingSize * 0.5,
      position.dx - wingSize * 0.5,
      position.dy - wingSize,
    );
    leftWing.quadraticBezierTo(
      position.dx - wingSize * 0.3,
      position.dy - wingSize * 0.3,
      position.dx,
      position.dy,
    );
    canvas.drawPath(leftWing, wingPaint);

    // Glow trail effect
    final trailPaint = Paint()
      ..color = color.withValues(alpha: 0.3 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final trailLength = wingSize * 2 * pulse;
    canvas.drawLine(
      position,
      Offset(position.dx, position.dy + trailLength),
      trailPaint,
    );
  }

  void _drawGoldenShoes(
    Canvas canvas,
    Offset position,
    Size size,
    Color color,
    double pulse,
  ) {
    final shoePaint = Paint()
      ..color = color.withValues(alpha: 0.8 * pulse)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final shoeSize = size.width * 0.04;

    // Draw shoe glow
    canvas.drawOval(
      Rect.fromCenter(center: position, width: shoeSize * 2, height: shoeSize),
      shoePaint,
    );

    // Spark effect
    final sparkPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6 * pulse)
      ..style = PaintingStyle.fill;

    final sparkOffset = math.sin(animationValue * math.pi * 4) * 3;
    canvas.drawCircle(
      Offset(position.dx + sparkOffset, position.dy - shoeSize * 0.5),
      2,
      sparkPaint,
    );
  }

  void _drawHalo(
    Canvas canvas,
    Offset position,
    Size size,
    Color color,
    double pulse,
  ) {
    final haloPaint = Paint()
      ..color = color.withValues(alpha: 0.6 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.2 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final radius = size.width * 0.08;
    final haloPosition = Offset(position.dx, position.dy - radius * 0.5);

    // Draw glow first
    canvas.drawOval(
      Rect.fromCenter(
        center: haloPosition,
        width: radius * 2,
        height: radius * 0.5,
      ),
      glowPaint,
    );

    // Draw halo ring
    canvas.drawOval(
      Rect.fromCenter(
        center: haloPosition,
        width: radius * 2,
        height: radius * 0.5,
      ),
      haloPaint,
    );
  }

  void _drawThirdEye(
    Canvas canvas,
    Offset position,
    Size size,
    Color color,
    double pulse,
  ) {
    final eyePaint = Paint()
      ..color = color.withValues(alpha: 0.8 * pulse)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final eyeSize = size.width * 0.025;

    // Glow
    canvas.drawCircle(position, eyeSize * 2, glowPaint);

    // Eye gem (diamond shape)
    final eyePath = Path();
    eyePath.moveTo(position.dx, position.dy - eyeSize);
    eyePath.lineTo(position.dx + eyeSize * 0.6, position.dy);
    eyePath.lineTo(position.dx, position.dy + eyeSize);
    eyePath.lineTo(position.dx - eyeSize * 0.6, position.dy);
    eyePath.close();

    canvas.drawPath(eyePath, eyePaint);

    // Inner light
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6 * pulse);
    canvas.drawCircle(position, eyeSize * 0.3, innerPaint);
  }

  void _drawAegis(
    Canvas canvas,
    Offset position,
    Size size,
    Color color,
    double pulse,
  ) {
    final aegisPaint = Paint()
      ..color = color.withValues(alpha: 0.4 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.15 * pulse)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final aegisWidth = size.width * 0.25;
    final aegisHeight = size.height * 0.15;

    // Shield shape
    final shieldPath = Path();
    shieldPath.moveTo(position.dx, position.dy - aegisHeight * 0.3);
    shieldPath.quadraticBezierTo(
      position.dx + aegisWidth * 0.5,
      position.dy - aegisHeight * 0.2,
      position.dx + aegisWidth * 0.4,
      position.dy + aegisHeight * 0.3,
    );
    shieldPath.quadraticBezierTo(
      position.dx,
      position.dy + aegisHeight * 0.5,
      position.dx - aegisWidth * 0.4,
      position.dy + aegisHeight * 0.3,
    );
    shieldPath.quadraticBezierTo(
      position.dx - aegisWidth * 0.5,
      position.dy - aegisHeight * 0.2,
      position.dx,
      position.dy - aegisHeight * 0.3,
    );

    canvas.drawPath(shieldPath, glowPaint);
    canvas.drawPath(shieldPath, aegisPaint);
  }

  void _drawCoreGlow(
    Canvas canvas,
    Offset position,
    Size size,
    Color color,
    double pulse,
  ) {
    final gradient = RadialGradient(
      colors: [
        color.withValues(alpha: 0.6 * pulse),
        color.withValues(alpha: 0.2 * pulse),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final radius = size.width * 0.12;
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: position, radius: radius),
      );

    canvas.drawCircle(position, radius, paint);

    // Inner bright core
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(position, radius * 0.2, innerPaint);
  }

  void _drawMidasTouch(
    Canvas canvas,
    Offset position,
    Size size,
    Color color,
    double pulse,
  ) {
    final handGlow = Paint()
      ..color = color.withValues(alpha: 0.5 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final handSize = size.width * 0.05;
    canvas.drawCircle(position, handSize, handGlow);

    // Sparkles
    final sparklePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7 * pulse);

    for (int i = 0; i < 3; i++) {
      final angle = animationValue * math.pi * 2 + i * (math.pi * 2 / 3);
      final sparkleX = position.dx + math.cos(angle) * handSize * 1.5;
      final sparkleY = position.dy + math.sin(angle) * handSize * 1.5;
      canvas.drawCircle(Offset(sparkleX, sparkleY), 2, sparklePaint);
    }
  }

  void _drawFloatingTools(
    Canvas canvas,
    Offset position,
    Size size,
    Color color,
    double pulse,
  ) {
    final floatOffset = math.sin(animationValue * math.pi * 2) * 5;
    final rotationAngle = animationValue * math.pi * 0.5;

    final toolPaint = Paint()
      ..color = color.withValues(alpha: 0.7 * pulse)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // Floating orb
    final orbPosition = Offset(
      position.dx + math.cos(rotationAngle) * 15,
      position.dy - 15 + floatOffset,
    );

    canvas.drawCircle(orbPosition, 6, glowPaint);
    canvas.drawCircle(orbPosition, 4, toolPaint);
  }

  void _drawTheFlow(
    Canvas canvas,
    Offset position,
    Size size,
    Color color,
    double pulse,
  ) {
    final flowPaint = Paint()
      ..color = color.withValues(alpha: 0.4 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Flowing vein lines
    final flowPath = Path();
    flowPath.moveTo(position.dx, position.dy - size.height * 0.1);

    // Central flow
    for (int i = 0; i < 5; i++) {
      final y = position.dy - size.height * 0.1 + i * size.height * 0.08;
      final xOffset = math.sin(animationValue * math.pi * 2 + i) * 5;
      flowPath.lineTo(position.dx + xOffset, y);
    }

    canvas.drawPath(flowPath, flowPaint);

    // Branching flows
    _drawFlowBranch(canvas, position, size, color, pulse, -1);
    _drawFlowBranch(canvas, position, size, color, pulse, 1);
  }

  void _drawFlowBranch(
    Canvas canvas,
    Offset position,
    Size size,
    Color color,
    double pulse,
    int direction,
  ) {
    final branchPaint = Paint()
      ..color = color.withValues(alpha: 0.25 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final branchPath = Path();
    branchPath.moveTo(position.dx, position.dy);
    branchPath.quadraticBezierTo(
      position.dx + direction * size.width * 0.08,
      position.dy + size.height * 0.05,
      position.dx + direction * size.width * 0.12,
      position.dy + size.height * 0.1,
    );

    canvas.drawPath(branchPath, branchPaint);
  }

  void _drawGenericGlow(
    Canvas canvas,
    Offset position,
    Size size,
    Color color,
    double pulse,
  ) {
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.4 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(position, size.width * 0.05, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _ArtifactPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.artifacts != artifacts;
  }
}
