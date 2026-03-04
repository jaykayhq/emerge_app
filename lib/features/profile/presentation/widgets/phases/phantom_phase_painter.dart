import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Phase 1: The Phantom — Ethereal spectral mist in humanoid form
/// Multi-layered spectral fog, DNA-helix particle streams, glowing eyes,
/// wisp tendrils curling from extremities.
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
    final cx = size.width / 2;
    final cy = size.height * 0.42;

    // Turbulence offsets
    final t = animationValue * math.pi * 2;
    final turbX = math.sin(t) * 3;
    final turbY = math.cos(t * 1.5) * 2;

    // Decay chaos offset
    final decayOff = entropyLevel * 6;

    // Layer 1: Deep outer spectral mist (5 gradient layers for depth)
    _drawSpectralMistLayers(canvas, size, cx, cy, turbX, turbY, decayOff);

    // Layer 2: Humanoid silhouette suggestion (smooth beziers)
    _drawSmokyHumanoid(canvas, size, cx, cy, turbX, turbY);

    // Layer 3: Wisp tendrils from shoulders & hands
    _drawWispTendrils(canvas, size, cx, cy, t);

    // Layer 4: DNA-helix particle streams
    _drawHelixParticles(canvas, size, cx, cy, t);

    // Layer 5: Subtle eye glow
    _drawEyeGlow(canvas, size, cx, t);

    // Layer 6: Ambient floating particles
    _drawAmbientParticles(canvas, size, cx, cy, t);
  }

  /// Five concentric oval mist layers — outer wispy → inner concentrated
  void _drawSpectralMistLayers(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    double turbX,
    double turbY,
    double decayOff,
  ) {
    final decayFade = 1 - entropyLevel * 0.5;

    const layerCount = 5;
    for (int i = 0; i < layerCount; i++) {
      final t = i / (layerCount - 1); // 0→1
      final layerWidth = size.width * (0.42 - t * 0.22);
      final layerHeight = size.height * (0.62 - t * 0.20);
      final alpha = opacity * (0.08 + t * 0.12) * decayFade;
      final blur = 45.0 - t * 28;

      // Each layer drifts differently
      final driftX = turbX * (1 - t * 0.6) + decayOff * (1 - t);
      final driftY = turbY * (1 - t * 0.5);

      final gradient = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: alpha),
          primaryColor.withValues(alpha: alpha * 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      );

      final center = Offset(cx + driftX, cy + driftY);
      final rect = Rect.fromCenter(
        center: center,
        width: layerWidth,
        height: layerHeight,
      );

      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

      canvas.drawOval(rect, paint);
    }
  }

  /// Smooth cubic bezier humanoid body suggestion
  void _drawSmokyHumanoid(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    double turbX,
    double turbY,
  ) {
    final fillPaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.35)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    // Head
    final headY = size.height * 0.10;
    final headR =
        size.width * 0.085 + math.sin(animationValue * math.pi * 2) * 1.5;
    canvas.drawCircle(
      Offset(cx + turbX * 0.4, headY + turbY * 0.2),
      headR,
      fillPaint,
    );

    // Inner head glow
    final innerHead = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(
      Offset(cx + turbX * 0.4, headY + turbY * 0.2),
      headR * 0.55,
      innerHead,
    );

    // Neck + torso (smooth cubic path)
    final neckY = headY + headR * 0.9;
    final shoulderW = size.width * 0.28;
    final bodyPath = Path();

    bodyPath.moveTo(cx - size.width * 0.04, neckY);

    // Left shoulder curve
    bodyPath.cubicTo(
      cx - size.width * 0.08,
      neckY + size.height * 0.02,
      cx - shoulderW * 0.8,
      size.height * 0.16 + turbY,
      cx - shoulderW * 0.55,
      size.height * 0.19 + turbY * 0.5,
    );

    // Left arm hint
    bodyPath.cubicTo(
      cx - shoulderW * 0.65,
      size.height * 0.28,
      cx - shoulderW * 0.55,
      size.height * 0.38,
      cx - size.width * 0.12,
      size.height * 0.44,
    );

    // Left side waist
    bodyPath.cubicTo(
      cx - size.width * 0.10,
      size.height * 0.50,
      cx - size.width * 0.12,
      size.height * 0.56,
      cx - size.width * 0.10,
      size.height * 0.70,
    );

    // Left foot
    bodyPath.lineTo(cx - size.width * 0.06, size.height * 0.78);

    // Center crotch
    bodyPath.quadraticBezierTo(
      cx,
      size.height * 0.58,
      cx + size.width * 0.06,
      size.height * 0.78,
    );

    // Right side
    bodyPath.lineTo(cx + size.width * 0.10, size.height * 0.70);
    bodyPath.cubicTo(
      cx + size.width * 0.12,
      size.height * 0.56,
      cx + size.width * 0.10,
      size.height * 0.50,
      cx + size.width * 0.12,
      size.height * 0.44,
    );

    // Right arm hint
    bodyPath.cubicTo(
      cx + shoulderW * 0.55,
      size.height * 0.38,
      cx + shoulderW * 0.65,
      size.height * 0.28,
      cx + shoulderW * 0.55,
      size.height * 0.19 - turbY * 0.5,
    );

    // Right shoulder
    bodyPath.cubicTo(
      cx + shoulderW * 0.8,
      size.height * 0.16 - turbY,
      cx + size.width * 0.08,
      neckY + size.height * 0.02,
      cx + size.width * 0.04,
      neckY,
    );

    bodyPath.close();
    canvas.drawPath(bodyPath, fillPaint);
  }

  /// Wisp tendrils curling upward from shoulders & hands
  void _drawWispTendrils(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    double t,
  ) {
    final origins = [
      Offset(cx - size.width * 0.22, size.height * 0.20), // Left shoulder
      Offset(cx + size.width * 0.22, size.height * 0.20), // Right shoulder
      Offset(cx - size.width * 0.14, size.height * 0.46), // Left hand
      Offset(cx + size.width * 0.14, size.height * 0.46), // Right hand
      Offset(cx, size.height * 0.06), // Top of head
    ];

    for (int i = 0; i < origins.length; i++) {
      final origin = origins[i];
      final wispPaint = Paint()
        ..color = primaryColor.withValues(alpha: opacity * 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final wispPath = Path();
      wispPath.moveTo(origin.dx, origin.dy);

      // Each tendril has 3 segments curling upward with a unique phase
      final phase = t + i * 1.2;
      for (int seg = 1; seg <= 3; seg++) {
        final segLen = size.height * 0.06 * seg;
        final curlX = math.sin(phase + seg * 0.8) * size.width * 0.05 * seg;
        final curlY = -segLen;
        wispPath.quadraticBezierTo(
          origin.dx + curlX * 0.5,
          origin.dy + curlY * 0.6,
          origin.dx + curlX,
          origin.dy + curlY,
        );
      }

      canvas.drawPath(wispPath, wispPaint);

      // Glow version
      final glowPaint = Paint()
        ..color = primaryColor.withValues(alpha: opacity * 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawPath(wispPath, glowPaint);
    }
  }

  /// DNA double-helix particle streams spiraling around the body
  void _drawHelixParticles(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    double t,
  ) {
    final particlePaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    const particleCount = 24;
    final helixRadius = size.width * 0.18;
    final helixHeight = size.height * 0.55;

    for (int i = 0; i < particleCount; i++) {
      final frac = i / particleCount;
      final angle = frac * math.pi * 4 + t * 2; // Double helix = 2 full turns

      // Strand A
      final xA = cx + math.cos(angle) * helixRadius * (0.5 + frac * 0.5);
      final yA = size.height * 0.08 + frac * helixHeight;
      final alphaA = opacity * 0.35 * (1 - frac * 0.4);
      particlePaint.color = primaryColor.withValues(alpha: alphaA);
      canvas.drawCircle(Offset(xA, yA), 2.0 + frac * 1.5, particlePaint);

      // Strand B (opposite phase)
      final xB =
          cx + math.cos(angle + math.pi) * helixRadius * (0.5 + frac * 0.5);
      particlePaint.color = primaryColor.withValues(alpha: alphaA * 0.6);
      canvas.drawCircle(Offset(xB, yA), 1.5 + frac, particlePaint);
    }
  }

  /// Two faint eye points suggesting awareness within the mist
  void _drawEyeGlow(Canvas canvas, Size size, double cx, double t) {
    final eyeY = size.height * 0.095;
    final eyeSpacing = size.width * 0.032;
    final blink = (math.sin(t * 3) * 0.5 + 0.5).clamp(0.3, 1.0);

    for (final sign in [-1.0, 1.0]) {
      final eyeX = cx + sign * eyeSpacing;

      // Outer glow
      final outerPaint = Paint()
        ..color = primaryColor.withValues(alpha: opacity * 0.3 * blink)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(eyeX, eyeY), size.width * 0.025, outerPaint);

      // Bright core
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.5 * blink)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(eyeX, eyeY), size.width * 0.008, corePaint);
    }
  }

  /// Ambient floating particles rising off the spectral form
  void _drawAmbientParticles(
    Canvas canvas,
    Size size,
    double cx,
    double cy,
    double t,
  ) {
    final rng = math.Random(42);
    final particlePaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (int i = 0; i < 20; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final dist = size.width * 0.15 + rng.nextDouble() * size.width * 0.25;
      final pSize = 2.0 + rng.nextDouble() * 3.5;

      final animOff = math.sin(t + i * 0.6) * 12;
      final rise = (animationValue + i * 0.05) % 1.0;

      final x = cx + math.cos(angle) * (dist + animOff);
      final y = cy + math.sin(angle) * (dist * 0.6) - rise * size.height * 0.15;

      if (y > 0 && y < size.height) {
        final alpha = opacity * 0.3 * (1 - rise * 0.6);
        particlePaint.color = i % 4 == 0
            ? Colors.white.withValues(alpha: alpha * 0.5)
            : primaryColor.withValues(alpha: alpha);
        canvas.drawCircle(Offset(x, y), pSize, particlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PhantomPhasePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.entropyLevel != entropyLevel ||
        oldDelegate.primaryColor != primaryColor;
  }
}
