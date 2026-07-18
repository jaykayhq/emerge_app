import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AmbientParticles extends StatefulWidget {
  final int particleCount;

  const AmbientParticles({super.key, this.particleCount = 50});

  @override
  State<AmbientParticles> createState() => _AmbientParticlesState();
}

class _AmbientParticlesState extends State<AmbientParticles>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _time = 0.0;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() {
        _time = elapsed.inMilliseconds / 1000.0;
      });
    })..start();

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
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParticlePainter(_particles, _time),
      size: Size.infinite,
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
  final double time;

  _ParticlePainter(this.particles, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var p in particles) {
      final currentX = ((p.x + p.speedX * time) % 1.0 + 1.0) % 1.0;
      final currentY = ((p.y + p.speedY * time) % 1.0 + 1.0) % 1.0;
      
      paint.color = Colors.white.withValues(alpha: p.opacity);
      canvas.drawCircle(
        Offset(currentX * size.width, currentY * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
