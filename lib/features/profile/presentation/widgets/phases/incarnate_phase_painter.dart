import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Phase 3: The Incarnate — Solid heroic silhouette with inner gradient
/// Confident wide stance, inner gradient illumination, rim lighting,
/// subtle musculature, ground shadow, and micro-particle energy dust.
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
    final cx = size.width / 2;
    final t = animationValue * math.pi * 2;

    // Subtle breathing scale
    final breathScale = 1.0 + math.sin(t) * 0.012;

    // Layer 1: Ground shadow
    _drawGroundShadow(canvas, size, cx);

    // Layer 2: Solid silhouette with inner gradient
    _drawGradientSilhouette(canvas, size, cx, breathScale);

    // Layer 3: Rim lighting (backlit edge highlight on right side)
    _drawRimLighting(canvas, size, cx, breathScale);

    // Layer 4: Inner chest light source
    _drawInnerLight(canvas, size, cx, breathScale, t);

    // Layer 5: Detailed musculature definition
    _drawMusculature(canvas, size, cx, breathScale);

    // Layer 6: Micro-particle energy dust
    _drawMicroParticles(canvas, size, cx, t);
  }

  /// Soft elliptical shadow at the feet for grounding
  void _drawGroundShadow(Canvas canvas, Size size, double cx) {
    final shadowCenter = Offset(cx, size.height * 0.90);

    final gradient = RadialGradient(
      colors: [
        primaryColor.withValues(alpha: 0.12),
        primaryColor.withValues(alpha: 0.04),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final shadowRect = Rect.fromCenter(
      center: shadowCenter,
      width: size.width * 0.45,
      height: size.height * 0.05,
    );

    final paint = Paint()
      ..shader = gradient.createShader(shadowRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawOval(shadowRect, paint);
  }

  /// Heroic silhouette filled with archetype-colored gradient instead of flat black
  void _drawGradientSilhouette(
    Canvas canvas,
    Size size,
    double cx,
    double breathScale,
  ) {
    final path = _createHeroicBodyPath(size, cx, breathScale);

    // Inner gradient: deep archetype color at top → darker at bottom
    final bodyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(
          primaryColor,
          Colors.black,
          0.65,
        )!.withValues(alpha: opacity),
        Color.lerp(
          primaryColor,
          Colors.black,
          0.80,
        )!.withValues(alpha: opacity),
        Color.lerp(
          primaryColor,
          Colors.black,
          0.90,
        )!.withValues(alpha: opacity * 0.95),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final fillPaint = Paint()
      ..shader = bodyGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);
  }

  /// Rim lighting — bright edge highlight on one side (as if backlit by energy)
  void _drawRimLighting(
    Canvas canvas,
    Size size,
    double cx,
    double breathScale,
  ) {
    final path = _createHeroicBodyPath(size, cx, breathScale);

    // Right-side rim light
    final rimPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(path, rimPaint);

    // Stronger glow on right edge only (using clipping)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(cx, 0, size.width / 2, size.height));

    final brightRimPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawPath(path, brightRimPaint);
    canvas.restore();
  }

  /// Radial gradient from the heart area creating an inner light source
  void _drawInnerLight(
    Canvas canvas,
    Size size,
    double cx,
    double breathScale,
    double t,
  ) {
    final heartCenter = Offset(cx, size.height * 0.26 * breathScale);
    final pulse = 0.7 + math.sin(t * 0.8) * 0.3;

    final gradient = RadialGradient(
      colors: [
        primaryColor.withValues(alpha: 0.25 * pulse),
        primaryColor.withValues(alpha: 0.10 * pulse),
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 1.0],
    );

    final lightRadius = size.width * 0.14;
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: heartCenter, radius: lightRadius),
      );

    // Clip to body silhouette so light doesn't bleed outside
    canvas.save();
    canvas.clipPath(_createHeroicBodyPath(size, cx, breathScale));
    canvas.drawCircle(heartCenter, lightRadius, paint);
    canvas.restore();
  }

  /// Anatomically-suggestive muscle definition lines
  void _drawMusculature(
    Canvas canvas,
    Size size,
    double cx,
    double breathScale,
  ) {
    final linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // Clip to body
    canvas.save();
    canvas.clipPath(_createHeroicBodyPath(size, cx, breathScale));

    // Center chest line (sternum)
    canvas.drawLine(
      Offset(cx, size.height * 0.18),
      Offset(cx, size.height * 0.40),
      linePaint,
    );

    // Pectoral lines
    final pectPath = Path();
    pectPath.moveTo(cx - size.width * 0.12, size.height * 0.20);
    pectPath.quadraticBezierTo(
      cx - size.width * 0.02,
      size.height * 0.24,
      cx,
      size.height * 0.22,
    );
    canvas.drawPath(pectPath, linePaint);

    final pectPathR = Path();
    pectPathR.moveTo(cx + size.width * 0.12, size.height * 0.20);
    pectPathR.quadraticBezierTo(
      cx + size.width * 0.02,
      size.height * 0.24,
      cx,
      size.height * 0.22,
    );
    canvas.drawPath(pectPathR, linePaint);

    // Ab definition lines
    for (int i = 0; i < 4; i++) {
      final y = size.height * (0.28 + i * 0.035);
      canvas.drawLine(
        Offset(cx - size.width * 0.04, y),
        Offset(cx + size.width * 0.04, y),
        linePaint,
      );
    }

    // Oblique curves
    final obliqueL = Path();
    obliqueL.moveTo(cx - size.width * 0.10, size.height * 0.24);
    obliqueL.quadraticBezierTo(
      cx - size.width * 0.08,
      size.height * 0.34,
      cx - size.width * 0.06,
      size.height * 0.42,
    );
    canvas.drawPath(obliqueL, linePaint);

    final obliqueR = Path();
    obliqueR.moveTo(cx + size.width * 0.10, size.height * 0.24);
    obliqueR.quadraticBezierTo(
      cx + size.width * 0.08,
      size.height * 0.34,
      cx + size.width * 0.06,
      size.height * 0.42,
    );
    canvas.drawPath(obliqueR, linePaint);

    // Shoulder deltoid curves
    final deltL = Path();
    deltL.moveTo(cx - size.width * 0.16, size.height * 0.16);
    deltL.quadraticBezierTo(
      cx - size.width * 0.22,
      size.height * 0.20,
      cx - size.width * 0.18,
      size.height * 0.26,
    );
    canvas.drawPath(deltL, linePaint);

    final deltR = Path();
    deltR.moveTo(cx + size.width * 0.16, size.height * 0.16);
    deltR.quadraticBezierTo(
      cx + size.width * 0.22,
      size.height * 0.20,
      cx + size.width * 0.18,
      size.height * 0.26,
    );
    canvas.drawPath(deltR, linePaint);

    // Thigh lines
    canvas.drawLine(
      Offset(cx - size.width * 0.06, size.height * 0.50),
      Offset(cx - size.width * 0.07, size.height * 0.65),
      linePaint,
    );
    canvas.drawLine(
      Offset(cx + size.width * 0.06, size.height * 0.50),
      Offset(cx + size.width * 0.07, size.height * 0.65),
      linePaint,
    );

    canvas.restore();
  }

  /// Micro-particles floating off the silhouette surface
  void _drawMicroParticles(Canvas canvas, Size size, double cx, double t) {
    final rng = math.Random(77);
    final particlePaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (int i = 0; i < 15; i++) {
      final baseX = cx + (rng.nextDouble() - 0.5) * size.width * 0.35;
      final baseY = size.height * 0.10 + rng.nextDouble() * size.height * 0.70;
      final pSize = 1.0 + rng.nextDouble() * 2.0;

      final rise = (animationValue + i * 0.06) % 1.0;
      final x = baseX + math.sin(t + i * 0.8) * 6;
      final y = baseY - rise * size.height * 0.08;

      final alpha = 0.3 * (1 - rise);
      particlePaint.color = i % 3 == 0
          ? Colors.white.withValues(alpha: alpha * 0.7)
          : primaryColor.withValues(alpha: alpha);

      canvas.drawCircle(Offset(x, y), pSize, particlePaint);
    }
  }

  /// Heroic body path — wide confident stance, arms slightly away
  Path _createHeroicBodyPath(Size size, double cx, double breathScale) {
    final path = Path();

    // Head
    final headY = size.height * 0.07;
    final headR = size.width * 0.088;
    path.addOval(Rect.fromCircle(center: Offset(cx, headY), radius: headR));

    // Torso — heroic proportions
    final neckTop = headY + headR * 0.75;
    final neckW = size.width * 0.045;
    final shoulderY = size.height * 0.165;
    final shoulderW = size.width * 0.24 * breathScale;
    final waistY = size.height * 0.40;
    final waistW = size.width * 0.11;
    final hipY = size.height * 0.46;
    final hipW = size.width * 0.135;

    final torso = Path();
    torso.moveTo(cx - neckW, neckTop);

    // Left shoulder — smooth curve
    torso.cubicTo(
      cx - neckW * 2,
      shoulderY - size.height * 0.025,
      cx - shoulderW * 0.8,
      shoulderY - size.height * 0.01,
      cx - shoulderW,
      shoulderY,
    );

    // Left arm (slightly away from body, not dangling)
    torso.cubicTo(
      cx - shoulderW - size.width * 0.04,
      shoulderY + size.height * 0.06,
      cx - shoulderW - size.width * 0.03,
      shoulderY + size.height * 0.14,
      cx - shoulderW * 0.85,
      shoulderY + size.height * 0.20,
    );

    // Arm returns to torso
    torso.cubicTo(
      cx - shoulderW * 0.6,
      shoulderY + size.height * 0.16,
      cx - waistW * 1.3,
      waistY - size.height * 0.06,
      cx - waistW,
      waistY,
    );

    // Left hip
    torso.lineTo(cx - hipW, hipY);

    // Left leg — slightly wider stance
    torso.cubicTo(
      cx - hipW - size.width * 0.01,
      size.height * 0.56,
      cx - hipW - size.width * 0.015,
      size.height * 0.68,
      cx - size.width * 0.10,
      size.height * 0.86,
    );

    // Left foot
    torso.lineTo(cx - size.width * 0.04, size.height * 0.87);

    // Inner left leg to crotch
    torso.lineTo(cx - size.width * 0.025, hipY + size.height * 0.14);

    // Crotch
    torso.quadraticBezierTo(
      cx,
      hipY + size.height * 0.08,
      cx + size.width * 0.025,
      hipY + size.height * 0.14,
    );

    // Right foot
    torso.lineTo(cx + size.width * 0.04, size.height * 0.87);
    torso.lineTo(cx + size.width * 0.10, size.height * 0.86);

    // Right leg
    torso.cubicTo(
      cx + hipW + size.width * 0.015,
      size.height * 0.68,
      cx + hipW + size.width * 0.01,
      size.height * 0.56,
      cx + hipW,
      hipY,
    );

    // Right waist
    torso.lineTo(cx + waistW, waistY);

    // Right arm return
    torso.cubicTo(
      cx + waistW * 1.3,
      waistY - size.height * 0.06,
      cx + shoulderW * 0.6,
      shoulderY + size.height * 0.16,
      cx + shoulderW * 0.85,
      shoulderY + size.height * 0.20,
    );

    // Right arm
    torso.cubicTo(
      cx + shoulderW + size.width * 0.03,
      shoulderY + size.height * 0.14,
      cx + shoulderW + size.width * 0.04,
      shoulderY + size.height * 0.06,
      cx + shoulderW,
      shoulderY,
    );

    // Right shoulder to neck
    torso.cubicTo(
      cx + shoulderW * 0.8,
      shoulderY - size.height * 0.01,
      cx + neckW * 2,
      shoulderY - size.height * 0.025,
      cx + neckW,
      neckTop,
    );

    torso.close();
    path.addPath(torso, Offset.zero);

    return path;
  }

  @override
  bool shouldRepaint(covariant IncarnatePhasePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.primaryColor != primaryColor;
  }
}
