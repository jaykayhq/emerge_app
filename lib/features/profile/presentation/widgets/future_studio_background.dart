import 'dart:math' as math;

import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:flutter/material.dart';

/// Animated background for the Future Self Studio
/// Creates an immersive, living atmosphere with nebula clouds and floating particles
class FutureStudioBackground extends StatefulWidget {
  final UserArchetype archetype;

  const FutureStudioBackground({super.key, required this.archetype});

  @override
  State<FutureStudioBackground> createState() => _FutureStudioBackgroundState();
}

class _FutureStudioBackgroundState extends State<FutureStudioBackground>
    with TickerProviderStateMixin {
  late AnimationController _nebulaController;
  late AnimationController _particleController;

  late List<_FloatingParticle> _particles;
  late List<_NebulaCloud> _nebulaClouds;

  @override
  void initState() {
    super.initState();

    // Slow nebula drift - 45 second cycle
    _nebulaController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45),
    )..repeat();

    // Particle float - 25 second cycle
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    _generateElements();
  }

  void _generateElements() {
    final random = math.Random(widget.archetype.index * 42);

    // Generate nebula clouds
    _nebulaClouds = List.generate(4, (i) => _NebulaCloud.random(random, i));

    // Generate floating particles
    _particles = List.generate(25, (i) => _FloatingParticle.random(random));
  }

  @override
  void didUpdateWidget(FutureStudioBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.archetype != widget.archetype) {
      _generateElements();
    }
  }

  @override
  void dispose() {
    _nebulaController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ArchetypeTheme.forArchetype(widget.archetype);
    final primaryColor = theme.primaryColor;
    final accentColor = theme.accentColor;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Deep gradient background
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -0.5),
                radius: 1.8,
                colors: [
                  primaryColor.withValues(alpha: 0.15),
                  const Color(0xFF0D0D1A),
                  const Color(0xFF050510),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Layer 2: Nebula clouds
          AnimatedBuilder(
            animation: _nebulaController,
            builder: (context, child) {
              return CustomPaint(
                painter: _NebulaPainter(
                  clouds: _nebulaClouds,
                  progress: _nebulaController.value,
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Layer 3: Floating particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                  color: primaryColor,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Layer 4: Vignette overlay
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.8),
                ],
                stops: const [0.3, 0.7, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ DATA CLASSES ============

class _NebulaCloud {
  final double x;
  final double y;
  final double radius;
  final double opacity;
  final int colorIndex;

  _NebulaCloud({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
    required this.colorIndex,
  });

  factory _NebulaCloud.random(math.Random random, int index) {
    return _NebulaCloud(
      x: random.nextDouble(),
      y: random.nextDouble(),
      radius: 0.2 + random.nextDouble() * 0.3,
      opacity: 0.06 + random.nextDouble() * 0.08,
      colorIndex: index % 2,
    );
  }
}

class _FloatingParticle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double phase;

  _FloatingParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
  });

  factory _FloatingParticle.random(math.Random random) {
    return _FloatingParticle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: 1.5 + random.nextDouble() * 2.5,
      speed: 0.2 + random.nextDouble() * 0.5,
      phase: random.nextDouble(),
    );
  }
}

// ============ PAINTERS ============

class _NebulaPainter extends CustomPainter {
  final List<_NebulaCloud> clouds;
  final double progress;
  final Color primaryColor;
  final Color accentColor;

  _NebulaPainter({
    required this.clouds,
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final cloud in clouds) {
      // Slow drift movement
      final driftX = math.sin(progress * math.pi * 2 + cloud.x * 8) * 0.03;
      final driftY = math.cos(progress * math.pi * 2 + cloud.y * 8) * 0.02;

      final center = Offset(
        (cloud.x + driftX) * size.width,
        (cloud.y + driftY) * size.height,
      );

      final color = cloud.colorIndex == 0 ? primaryColor : accentColor;
      final radius = cloud.radius * size.shortestSide;

      // Draw soft gradient cloud
      final gradient = RadialGradient(
        colors: [
          color.withValues(alpha: cloud.opacity),
          color.withValues(alpha: cloud.opacity * 0.4),
          color.withValues(alpha: 0),
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

  @override
  bool shouldRepaint(covariant _NebulaPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_FloatingParticle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (final particle in particles) {
      // Float upward with drift
      final adjustedProgress = (progress + particle.phase) % 1.0;
      final y = (particle.y - adjustedProgress * particle.speed) % 1.0;
      final x =
          particle.x +
          math.sin(adjustedProgress * math.pi * 3 + particle.phase * 8) * 0.03;

      final position = Offset(x * size.width, y * size.height);

      // Fade at edges
      final fadeY = y < 0.15 ? y / 0.15 : (y > 0.85 ? (1.0 - y) / 0.15 : 1.0);
      final opacity = 0.4 * fadeY;

      paint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
