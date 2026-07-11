import 'dart:math';
import 'package:flutter/material.dart';

class AmbientParticles extends StatefulWidget {
  final int particleCount;

  const AmbientParticles({super.key, this.particleCount = 50});

  @override
  State<AmbientParticles> createState() => _AmbientParticlesState();
}

class _AmbientParticlesState extends State<AmbientParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    final random = Random();
    _particles = List.generate(
      widget.particleCount,
      (index) => _Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        speedX: (random.nextDouble() - 0.5) * 0.2,
        speedY: (random.nextDouble() - 0.5) * 0.2,
        size: random.nextDouble() * 2 + 1,
        opacity: random.nextDouble() * 0.5 + 0.1,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(_particles, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double speedX;
  final double speedY;
  final double size;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var p in particles) {
      final currentX = (p.x + p.speedX * progress) % 1.0;
      final currentY = (p.y + p.speedY * progress) % 1.0;
      
      // Handle negative modulo wrapper
      final px = currentX < 0 ? currentX + 1.0 : currentX;
      final py = currentY < 0 ? currentY + 1.0 : currentY;

      paint.color = Colors.white.withOpacity(p.opacity);
      canvas.drawCircle(
        Offset(px * size.width, py * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
