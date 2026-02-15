import 'dart:math' as math;

import 'package:emerge_app/features/world_map/domain/models/archetype_map_config.dart';
import 'package:flutter/material.dart';

/// Animated nebula/space background for the World Map
/// Creates an immersive, living atmosphere with multiple parallax layers
class NebulaBackground extends StatefulWidget {
  final BiomeType biome;
  final Color primaryColor;
  final Color accentColor;

  const NebulaBackground({
    super.key,
    required this.biome,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  State<NebulaBackground> createState() => _NebulaBackgroundState();
}

class _NebulaBackgroundState extends State<NebulaBackground>
    with TickerProviderStateMixin {
  late AnimationController _nebulaController;
  late AnimationController _starController;
  late AnimationController _particleController;

  late List<_Star> _stars;
  late List<_NebulaCloud> _nebulaClouds;
  late List<_FloatingParticle> _particles;

  @override
  void initState() {
    super.initState();

    // Slow nebula drift - 60 second cycle
    _nebulaController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    // Star twinkle - 8 second cycle
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Particle float - 20 second cycle
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _generateElements();
  }

  void _generateElements() {
    final random = math.Random(widget.biome.index * 42);

    // Generate stars
    _stars = List.generate(80, (i) => _Star.random(random));

    // Generate nebula clouds
    _nebulaClouds = List.generate(5, (i) => _NebulaCloud.random(random, i));

    // Generate floating particles
    _particles = List.generate(30, (i) => _FloatingParticle.random(random));
  }

  @override
  void dispose() {
    _nebulaController.dispose();
    _starController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColors = _getBiomeColors(widget.biome);

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Deep space gradient
          _buildDeepSpaceGradient(baseColors),

          // Layer 2: Nebula clouds
          AnimatedBuilder(
            animation: _nebulaController,
            builder: (context, child) {
              return CustomPaint(
                painter: _NebulaPainter(
                  clouds: _nebulaClouds,
                  progress: _nebulaController.value,
                  primaryColor: widget.primaryColor,
                  accentColor: widget.accentColor,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Layer 3: Star field
          AnimatedBuilder(
            animation: _starController,
            builder: (context, child) {
              return CustomPaint(
                painter: _StarFieldPainter(
                  stars: _stars,
                  twinkleProgress: _starController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Layer 4: Floating particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticleFieldPainter(
                  particles: _particles,
                  progress: _particleController.value,
                  color: widget.primaryColor,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Layer 5: Radial vignette
          _buildVignette(),
        ],
      ),
    );
  }

  Widget _buildDeepSpaceGradient(List<Color> biomeColors) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.0, -0.3),
          radius: 1.5,
          colors: [
            biomeColors[0].withValues(alpha: 0.8),
            biomeColors[1],
            const Color(0xFF050510),
            const Color(0xFF020208),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildVignette() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.7),
          ],
          stops: const [0.4, 0.8, 1.0],
        ),
      ),
    );
  }

  List<Color> _getBiomeColors(BiomeType biome) {
    switch (biome) {
      case BiomeType.valley:
        return [const Color(0xFF1A3A2F), const Color(0xFF0D1F1A)];
      case BiomeType.forest:
        return [const Color(0xFF1B4332), const Color(0xFF0D2818)];
      case BiomeType.cliffs:
        return [const Color(0xFF2D3A4F), const Color(0xFF151C28)];
      case BiomeType.clouds:
        return [const Color(0xFF3A3A5C), const Color(0xFF1A1A2E)];
      case BiomeType.summit:
        return [const Color(0xFF2E1A4A), const Color(0xFF150D25)];
    }
  }
}

// ============ DATA CLASSES ============

class _Star {
  final double x;
  final double y;
  final double size;
  final double twinklePhase;
  final double brightness;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.twinklePhase,
    required this.brightness,
  });

  factory _Star.random(math.Random random) {
    return _Star(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: 0.5 + random.nextDouble() * 2.0,
      twinklePhase: random.nextDouble(),
      brightness: 0.3 + random.nextDouble() * 0.7,
    );
  }
}

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
      radius: 0.15 + random.nextDouble() * 0.25,
      opacity: 0.08 + random.nextDouble() * 0.12,
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
      size: 1.0 + random.nextDouble() * 2.0,
      speed: 0.3 + random.nextDouble() * 0.7,
      phase: random.nextDouble(),
    );
  }
}

// ============ PAINTERS ============

class _StarFieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double twinkleProgress;

  _StarFieldPainter({required this.stars, required this.twinkleProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final star in stars) {
      // Calculate twinkle
      final twinkle = math.sin(
        (twinkleProgress + star.twinklePhase) * math.pi * 2,
      );
      final currentBrightness = star.brightness * (0.5 + 0.5 * twinkle);

      paint.color = Colors.white.withValues(alpha: currentBrightness);

      final position = Offset(star.x * size.width, star.y * size.height);

      // Draw star with glow
      if (star.size > 1.5) {
        // Larger stars get a glow
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(position, star.size * 1.5, paint);
        paint.maskFilter = null;
      }

      canvas.drawCircle(position, star.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) {
    return oldDelegate.twinkleProgress != twinkleProgress;
  }
}

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
      final driftX = math.sin(progress * math.pi * 2 + cloud.x * 10) * 0.02;
      final driftY = math.cos(progress * math.pi * 2 + cloud.y * 10) * 0.01;

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
          color.withValues(alpha: cloud.opacity * 0.5),
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

class _ParticleFieldPainter extends CustomPainter {
  final List<_FloatingParticle> particles;
  final double progress;
  final Color color;

  _ParticleFieldPainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    for (final particle in particles) {
      // Float upward with slight horizontal drift
      final adjustedProgress = (progress + particle.phase) % 1.0;
      final y = (particle.y - adjustedProgress * particle.speed) % 1.0;
      final x =
          particle.x +
          math.sin(adjustedProgress * math.pi * 4 + particle.phase * 10) * 0.02;

      final position = Offset(x * size.width, y * size.height);

      // Fade in/out at edges
      final fadeY = y < 0.1 ? y / 0.1 : (y > 0.9 ? (1.0 - y) / 0.1 : 1.0);
      final opacity = 0.3 * fadeY;

      paint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleFieldPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
