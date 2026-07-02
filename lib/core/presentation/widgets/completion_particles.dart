import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A particle burst animation that plays when a habit is completed.
///
/// Renders 30 particles that burst outward from center with gravity,
/// fade out over 800ms, then remove themselves from the widget tree.
class CompletionParticles extends StatefulWidget {
  final Color color;

  const CompletionParticles({
    super.key,
    required this.color,
  });

  @override
  State<CompletionParticles> createState() => _CompletionParticlesState();
}

class _CompletionParticlesState extends State<CompletionParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller.addStatusListener(_onAnimationEnd);
    _controller.forward();
  }

  void _onAnimationEnd(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() {
        // No-op: widget will be rebuilt out of tree
      });
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationEnd);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Once the animation completes, remove this widget from the tree
    if (_controller.isCompleted) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(100, 100),
          painter: ParticleBurstPainter(
            color: widget.color,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

/// Custom painter that draws the particle burst.
class ParticleBurstPainter extends CustomPainter {
  final Color color;
  final double progress;

  /// 30 pre-generated particles with random offsets, angles, and speeds.
  final List<ParticleData> particles;

  ParticleBurstPainter({
    required this.color,
    required this.progress,
  }) : particles = List.generate(30, (_) => ParticleData._random());

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint();

    for (final particle in particles) {
      // Position = center + offset + velocity * progress
      final dx = particle.offsetDx +
          math.cos(particle.angle) * particle.speed * progress * 60;
      final dy = particle.offsetDy +
          math.sin(particle.angle) * particle.speed * progress * 60 +
          // Gravity pulls particles downward
          120 * progress * progress;

      final fadeProgress = (1.0 - progress).clamp(0.0, 1.0);
      paint.color = color.withValues(alpha: fadeProgress * 0.9);

      // Particles shrink slightly as they fade
      final size_ = (3 + particle.size * (1.0 - progress * 0.5))
          .clamp(1.0, 8.0);

      canvas.drawCircle(
        Offset(center.dx + dx, center.dy + dy),
        size_,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticleBurstPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

/// Data for a single particle in the burst.
class ParticleData {
  final double offsetDx;
  final double offsetDy;
  final double angle;
  final double speed;
  final double size;

  ParticleData({
    required this.offsetDx,
    required this.offsetDy,
    required this.angle,
    required this.speed,
    required this.size,
  });

  factory ParticleData._random() {
    final random = math.Random();
    return ParticleData(
      offsetDx: (random.nextDouble() - 0.5) * 20,
      offsetDy: (random.nextDouble() - 0.5) * 20,
      angle: random.nextDouble() * 2 * math.pi,
      speed: 0.5 + random.nextDouble() * 1.0,
      size: 1.0 + random.nextDouble() * 4.0,
    );
  }
}
