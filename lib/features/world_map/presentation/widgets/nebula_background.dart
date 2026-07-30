import 'dart:math' as math;

import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/features/world_map/domain/models/biome_type.dart';
import 'package:flutter/material.dart';

/// Animated nebula/space background for the World Map
/// Creates an immersive, living atmosphere with multiple parallax layers
class NebulaBackground extends StatefulWidget {
  final BiomeType? biome;
  final Color primaryColor;
  final Color accentColor;
  final int level;
  final WorldHealthState healthState;
  final double entropy;

  const NebulaBackground({
    super.key,
    this.biome,
    required this.primaryColor,
    required this.accentColor,
    this.level = 1,
    this.healthState = WorldHealthState.neutral,
    this.entropy = 0.0,
  });

  @override
  State<NebulaBackground> createState() => _NebulaBackgroundState();
}

class _NebulaBackgroundState extends State<NebulaBackground>
    with TickerProviderStateMixin {
  // Single controller drives all layers to minimise repaints.
  late AnimationController _controller;

  late List<_Star> _stars;
  late List<_NebulaCloud> _nebulaClouds;
  late List<_FloatingParticle> _particles;

  @override
  void initState() {
    super.initState();

    // One 60-second controller for all animated layers.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _generateElements();
  }

  void _generateElements() {
    final config = NebulaStateConfig.forState(
      widget.healthState,
      entropy: widget.entropy,
    );
    final random = math.Random((widget.biome?.index ?? 0) * 42 + widget.level);

    // Procedural evolution: every 5 levels increases the density/richness
    final evolutionPhase = ((widget.level - 1) ~/ 5).clamp(
      0,
      10,
    ); // 0 to 10 max

    // Generate stars - more stars as you evolve, scaled by health
    final starCount = ((60 + (evolutionPhase * 15)) * config.starDensityFactor)
        .toInt();
    _stars = List.generate(
      starCount,
      (i) => _Star.random(random, evolutionPhase),
    );

    // Generate nebula clouds - slightly denser and more clouds as you evolve
    final cloudCount = 4 + (evolutionPhase ~/ 2);
    _nebulaClouds = List.generate(
      cloudCount,
      (i) => _NebulaCloud.random(random, i, evolutionPhase),
    );

    // Generate floating particles - more particles as you evolve, scaled by health
    final particleCount =
        ((20 + (evolutionPhase * 8)) * config.particleCountFactor).toInt();
    _particles = List.generate(
      particleCount,
      (i) => _FloatingParticle.random(random, evolutionPhase),
    );
  }

  @override
  void didUpdateWidget(NebulaBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level ||
        oldWidget.biome != widget.biome ||
        oldWidget.healthState != widget.healthState ||
        oldWidget.entropy != widget.entropy) {
      _generateElements();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColors = _getBiomeColors(widget.biome);

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Deep space gradient (static — no animation)
          _buildDeepSpaceGradient(baseColors),

          // Layers 2-4: all driven by a single controller so only
          // one full-screen repaint per frame instead of three.
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final config = NebulaStateConfig.forState(
                widget.healthState,
                entropy: widget.entropy,
              );
              final t = _controller.value;
              return CustomPaint(
                painter: _CompositeNebulaPainter(
                  clouds: _nebulaClouds,
                  stars: _stars,
                  particles: _particles,
                  progress: t,
                  primaryColor: widget.primaryColor,
                  accentColor: widget.accentColor,
                  config: config,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Layer 5: Radial vignette (static — no animation)
          _buildVignette(),
        ],
      ),
    );
  }

  Widget _buildDeepSpaceGradient(List<Color> biomeColors) {
    return Container(
      decoration: BoxDecoration(
        // Stitch World Map cosmic gradient
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A0A1A), // Near-black void (top)
            Color(0xFF1A0A2A), // Rich purple center
            Color(0xFF0A0A1A), // Near-black void (bottom)
          ],
          stops: [0.0, 0.5, 1.0],
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

  List<Color> _getBiomeColors(BiomeType? biome) {
    if (biome == null) {
      switch (widget.healthState) {
        case WorldHealthState.thriving:
          return const [Color(0xFF0A2A1A), Color(0xFF1A3A2A)];
        case WorldHealthState.decaying:
          return const [Color(0xFF2A0A0A), Color(0xFF3A1A1A)];
        default:
          return const [Color(0xFF1A0A2A), Color(0xFF2A1A3A)];
      }
    }

    // All biomes now use the Stitch World Map cosmic palette
    // Colors: deep purple-black with nebula accents
    switch (biome) {
      case BiomeType.valley:
        return [
          const Color(0xFF2A1A3A),
          const Color(0xFF0A1A3A),
        ]; // Purple + Blue nebula
      case BiomeType.forest:
        return [
          const Color(0xFF1A0A3A),
          const Color(0xFF2A1A3A),
        ]; // Deep purple + Mid purple
      case BiomeType.cliffs:
        return [
          const Color(0xFF0A1A3A),
          const Color(0xFF1A0A2A),
        ]; // Blue + Purple
      case BiomeType.clouds:
        return [
          const Color(0xFF2A1A3A),
          const Color(0xFF0A1A3A),
        ]; // Purple + Blue
      case BiomeType.summit:
        return [
          const Color(0xFF1A0A2A),
          const Color(0xFF2A1A3A),
        ]; // Rich purple + Mid purple
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

  factory _Star.random(math.Random random, int phase) {
    // Brighter and larger stars at higher phases
    final sizeBoost = phase * 0.1;
    final brightnessBoost = phase * 0.05;
    return _Star(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: 0.5 + random.nextDouble() * 2.0 + sizeBoost,
      twinklePhase: random.nextDouble(),
      brightness: (0.3 + random.nextDouble() * 0.7 + brightnessBoost).clamp(
        0.0,
        1.0,
      ),
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

  factory _NebulaCloud.random(math.Random random, int index, int phase) {
    final opacityBoost = phase * 0.015;
    return _NebulaCloud(
      x: random.nextDouble(),
      y: random.nextDouble(),
      radius: 0.15 + random.nextDouble() * 0.25,
      opacity: (0.08 + random.nextDouble() * 0.12 + opacityBoost).clamp(
        0.0,
        0.5,
      ),
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

  factory _FloatingParticle.random(math.Random random, int phase) {
    final speedBoost = phase * 0.05;
    return _FloatingParticle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: 1.0 + random.nextDouble() * 2.0 + (phase * 0.2),
      speed: 0.3 + random.nextDouble() * 0.7 + speedBoost,
      phase: random.nextDouble(),
    );
  }
}

// ============ PAINTERS ============

/// Single painter that draws nebula clouds, stars, and particles in one
/// pass so the framework only triggers one full-screen repaint per frame.
class _CompositeNebulaPainter extends CustomPainter {
  final List<_NebulaCloud> clouds;
  final List<_Star> stars;
  final List<_FloatingParticle> particles;
  final double progress;
  final Color primaryColor;
  final Color accentColor;
  final NebulaStateConfig config;

  _CompositeNebulaPainter({
    required this.clouds,
    required this.stars,
    required this.particles,
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintNebula(canvas, size);
    _paintStars(canvas, size);
    _paintParticles(canvas, size);
  }

  void _paintNebula(Canvas canvas, Size size) {
    final desaturationColor = const Color(0xFF222222);
    final saturation = config.colorSaturation.clamp(0.0, 1.0);
    final paintPrimary =
        Color.lerp(desaturationColor, primaryColor, saturation) ?? primaryColor;
    final paintAccent =
        Color.lerp(desaturationColor, accentColor, saturation) ?? accentColor;

    for (final cloud in clouds) {
      final adjustedProgress = progress * config.driftSpeedFactor;
      final driftX =
          math.sin(adjustedProgress * math.pi * 2 + cloud.x * 10) * 0.02;
      final driftY =
          math.cos(adjustedProgress * math.pi * 2 + cloud.y * 10) * 0.01;

      final center = Offset(
        (cloud.x + driftX) * size.width,
        (cloud.y + driftY) * size.height,
      );

      final color = cloud.colorIndex == 0 ? paintPrimary : paintAccent;
      final radius = cloud.radius * size.shortestSide;

      final gradient = RadialGradient(
        colors: [
          color.withValues(alpha: cloud.opacity * config.nebulaOpacity / 0.12),
          color.withValues(
            alpha: cloud.opacity * 0.5 * config.nebulaOpacity / 0.12,
          ),
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

  void _paintStars(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final star in stars) {
      final twinkle = math.sin(
        (progress * config.twinkleSpeedFactor + star.twinklePhase) *
            math.pi *
            2,
      );
      final currentBrightness = star.brightness * (0.5 + 0.5 * twinkle);
      paint.color = Colors.white.withValues(alpha: currentBrightness);
      final position = Offset(star.x * size.width, star.y * size.height);

      if (star.size > 1.5) {
        final glowPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.white.withValues(alpha: currentBrightness * 0.3);
        canvas.drawCircle(position, star.size * 1.8, glowPaint);
      }
      canvas.drawCircle(position, star.size, paint);
    }
  }

  void _paintParticles(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      final adjustedProgress =
          (progress * config.driftSpeedFactor + particle.phase) % 1.0;
      final y = (particle.y - adjustedProgress * particle.speed) % 1.0;
      final x = particle.x +
          math.sin(adjustedProgress * math.pi * 4 + particle.phase * 10) * 0.02;

      final position = Offset(x * size.width, y * size.height);
      final fadeY = y < 0.1 ? y / 0.1 : (y > 0.9 ? (1.0 - y) / 0.1 : 1.0);
      final opacity = 0.3 * fadeY * config.colorSaturation;

      paint.color = primaryColor.withValues(alpha: opacity);
      canvas.drawCircle(position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompositeNebulaPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.config != config;
  }
}
