import 'dart:math' as math;
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:flutter/material.dart';

/// Animated cosmic background for the Future Self Studio screen
/// Features floating particles, nebula gradients, and subtle energy flows
class FutureSelfCosmicBackground extends StatefulWidget {
  final UserArchetype archetype;
  final int level;

  const FutureSelfCosmicBackground({
    super.key,
    required this.archetype,
    this.level = 1,
  });

  @override
  State<FutureSelfCosmicBackground> createState() =>
      _FutureSelfCosmicBackgroundState();
}

class _FutureSelfCosmicBackgroundState extends State<FutureSelfCosmicBackground>
    with TickerProviderStateMixin {
  late AnimationController _nebulaController;
  late AnimationController _particleController;
  late AnimationController _energyController;

  @override
  void initState() {
    super.initState();

    // Slow nebula movement (20 second cycle)
    _nebulaController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Particle floating (8 second cycle)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Energy flow (12 second cycle)
    _energyController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _nebulaController.dispose();
    _particleController.dispose();
    _energyController.dispose();
    super.dispose();
  }

  Color get _primaryColor {
    return ArchetypeTheme.forArchetype(widget.archetype).primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _nebulaController,
        _particleController,
        _energyController,
      ]),
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _CosmicBackgroundPainter(
            primaryColor: _primaryColor,
            nebulaPhase: _nebulaController.value,
            particlePhase: _particleController.value,
            energyPhase: _energyController.value,
            level: widget.level,
          ),
        );
      },
    );
  }
}

class _CosmicBackgroundPainter extends CustomPainter {
  final Color primaryColor;
  final double nebulaPhase;
  final double particlePhase;
  final double energyPhase;
  final int level;

  _CosmicBackgroundPainter({
    required this.primaryColor,
    required this.nebulaPhase,
    required this.particlePhase,
    required this.energyPhase,
    required this.level,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Layer 1: Deep space gradient
    _drawBaseGradient(canvas, size);

    // Layer 2: Nebula clouds
    _drawNebulaClouds(canvas, size);

    // Layer 3: Distant stars
    _drawDistantStars(canvas, size);

    // Layer 4: Floating particles
    _drawFloatingParticles(canvas, size);

    // Layer 5: Energy flows (higher levels only)
    if (level >= 10) {
      _drawEnergyFlows(canvas, size);
    }

    // Layer 6: Vignette overlay
    _drawVignette(canvas, size);
  }

  void _drawBaseGradient(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0a0a14),
        const Color(0xFF0d0d1a),
        Color.lerp(const Color(0xFF0d0d1a), primaryColor, 0.05)!,
        const Color(0xFF0a0a14),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawNebulaClouds(Canvas canvas, Size size) {
    final random = math.Random(42);

    // Multiple nebula layers
    for (int i = 0; i < 3; i++) {
      final baseX = size.width * (0.2 + random.nextDouble() * 0.6);
      final baseY = size.height * (0.1 + random.nextDouble() * 0.8);

      // Animate position
      final offsetX = math.sin(nebulaPhase * math.pi * 2 + i) * 30;
      final offsetY = math.cos(nebulaPhase * math.pi * 2 + i * 0.7) * 20;

      final nebulaGradient = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: 0.08 - i * 0.02),
          primaryColor.withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      final nebulaRadius = size.width * (0.3 + i * 0.1);
      final center = Offset(baseX + offsetX, baseY + offsetY);

      final paint = Paint()
        ..shader = nebulaGradient.createShader(
          Rect.fromCircle(center: center, radius: nebulaRadius),
        );

      canvas.drawCircle(center, nebulaRadius, paint);
    }
  }

  void _drawDistantStars(Canvas canvas, Size size) {
    final random = math.Random(123);
    final starPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 80; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final starSize = 0.5 + random.nextDouble() * 1.5;
      final twinkle =
          0.3 + 0.7 * math.sin(particlePhase * math.pi * 2 + i * 0.3).abs();

      starPaint.color = Colors.white.withValues(alpha: 0.3 * twinkle);
      canvas.drawCircle(Offset(x, y), starSize, starPaint);
    }
  }

  void _drawFloatingParticles(Canvas canvas, Size size) {
    final random = math.Random(456);

    for (int i = 0; i < 25; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final particleSize = 1.0 + random.nextDouble() * 3;

      // Animate floating upward
      final phase = (particlePhase + i * 0.04) % 1.0;
      final y = baseY - phase * size.height * 0.3;
      final x = baseX + math.sin(phase * math.pi * 4 + i) * 15;

      if (y > 0 && y < size.height) {
        final alpha = 0.4 * (1 - (phase * 0.5));

        final particlePaint = Paint()
          ..color = primaryColor.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

        canvas.drawCircle(Offset(x, y), particleSize, particlePaint);
      }
    }
  }

  void _drawEnergyFlows(Canvas canvas, Size size) {
    final flowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Vertical energy streams
    for (int i = 0; i < 3; i++) {
      final x = size.width * (0.2 + i * 0.3);
      final phaseOffset = i * 0.33;

      final flowPath = Path();
      flowPath.moveTo(x, 0);

      for (double y = 0; y < size.height; y += 20) {
        final xOffset =
            math.sin((energyPhase + phaseOffset) * math.pi * 2 + y * 0.01) * 20;
        flowPath.lineTo(x + xOffset, y);
      }

      canvas.drawPath(flowPath, flowPaint);
    }
  }

  void _drawVignette(Canvas canvas, Size size) {
    final vignetteGradient = RadialGradient(
      center: Alignment.center,
      radius: 0.8,
      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
      stops: const [0.5, 1.0],
    );

    final vignettePaint = Paint()
      ..shader = vignetteGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      vignettePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CosmicBackgroundPainter oldDelegate) {
    return oldDelegate.nebulaPhase != nebulaPhase ||
        oldDelegate.particlePhase != particlePhase ||
        oldDelegate.energyPhase != energyPhase ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.level != level;
  }
}
