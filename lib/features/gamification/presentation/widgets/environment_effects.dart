import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated environment effects (weather, particles, ambient)
class EnvironmentEffects extends StatefulWidget {
  final String theme;
  final String season; // spring, summer, autumn, winter
  final bool isNightMode;
  final double intensity; // 0.0 - 1.0

  const EnvironmentEffects({
    super.key,
    this.theme = 'city',
    this.season = 'summer',
    this.isNightMode = false,
    this.intensity = 0.5,
  });

  @override
  State<EnvironmentEffects> createState() => _EnvironmentEffectsState();
}

class _EnvironmentEffectsState extends State<EnvironmentEffects>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_updateParticles);

    _initializeParticles();
    _controller.repeat();
  }

  void _initializeParticles() {
    final random = math.Random();
    _particles.clear();

    final count = (widget.intensity * 60).toInt();

    for (int i = 0; i < count; i++) {
      _particles.add(_createParticle(random, randomY: true));
    }
  }

  _Particle _createParticle(math.Random random, {bool randomY = false}) {
    final type = _getParticleType();

    return _Particle(
      type: type,
      x: random.nextDouble(),
      y: randomY ? random.nextDouble() : -0.1,
      size: _getParticleSize(type, random),
      speed: _getParticleSpeed(type, random),
      angle: _getParticleAngle(type),
      opacity: 0.3 + random.nextDouble() * 0.5,
      rotation: random.nextDouble() * math.pi * 2,
      rotationSpeed: (random.nextDouble() - 0.5) * 0.1,
    );
  }

  _ParticleType _getParticleType() {
    if (widget.theme == 'city') {
      if (widget.isNightMode) {
        return _ParticleType.hologram;
      }
      return widget.season == 'winter'
          ? _ParticleType.snow
          : _ParticleType.rain;
    } else {
      switch (widget.season) {
        case 'spring':
          return _ParticleType.petal;
        case 'autumn':
          return _ParticleType.leaf;
        case 'winter':
          return _ParticleType.snow;
        default:
          return widget.isNightMode
              ? _ParticleType.firefly
              : _ParticleType.petal;
      }
    }
  }

  double _getParticleSize(_ParticleType type, math.Random random) {
    switch (type) {
      case _ParticleType.rain:
        return 10 + random.nextDouble() * 15;
      case _ParticleType.snow:
        return 3 + random.nextDouble() * 5;
      case _ParticleType.leaf:
        return 8 + random.nextDouble() * 6;
      case _ParticleType.petal:
        return 4 + random.nextDouble() * 4;
      case _ParticleType.firefly:
        return 2 + random.nextDouble() * 3;
      case _ParticleType.hologram:
        return 1 + random.nextDouble() * 2;
    }
  }

  double _getParticleSpeed(_ParticleType type, math.Random random) {
    switch (type) {
      case _ParticleType.rain:
        return 0.015 + random.nextDouble() * 0.01;
      case _ParticleType.snow:
        return 0.002 + random.nextDouble() * 0.002;
      case _ParticleType.leaf:
        return 0.003 + random.nextDouble() * 0.002;
      case _ParticleType.petal:
        return 0.002 + random.nextDouble() * 0.002;
      case _ParticleType.firefly:
        return 0.001 + random.nextDouble() * 0.001;
      case _ParticleType.hologram:
        return 0.003 + random.nextDouble() * 0.002;
    }
  }

  double _getParticleAngle(_ParticleType type) {
    switch (type) {
      case _ParticleType.rain:
        return 0.1; // Slight angle
      case _ParticleType.snow:
      case _ParticleType.leaf:
      case _ParticleType.petal:
        return 0; // Vertical fall
      case _ParticleType.firefly:
      case _ParticleType.hologram:
        return 0; // No angle, random movement
    }
  }

  void _updateParticles() {
    final random = math.Random();

    for (var particle in _particles) {
      // Update position based on type
      switch (particle.type) {
        case _ParticleType.rain:
          particle.y += particle.speed;
          particle.x += particle.angle * particle.speed;
          break;

        case _ParticleType.snow:
          particle.y += particle.speed;
          particle.x +=
              math.sin(_controller.value * 10 + particle.rotation) * 0.001;
          break;

        case _ParticleType.leaf:
        case _ParticleType.petal:
          particle.y += particle.speed;
          particle.x +=
              math.sin(_controller.value * 5 + particle.rotation) * 0.002;
          particle.rotation += particle.rotationSpeed;
          break;

        case _ParticleType.firefly:
          // Random floating movement
          particle.x +=
              math.sin(_controller.value * 3 + particle.rotation) * 0.003;
          particle.y +=
              math.cos(_controller.value * 2 + particle.rotation) * 0.002;
          particle.opacity =
              0.3 + math.sin(_controller.value * 5 + particle.rotation) * 0.4;
          break;

        case _ParticleType.hologram:
          // Float upward
          particle.y -= particle.speed;
          particle.x +=
              math.sin(_controller.value * 4 + particle.rotation) * 0.002;
          particle.opacity =
              0.2 + math.sin(_controller.value * 8 + particle.rotation) * 0.3;
          break;
      }

      // Reset particles that go off screen
      if (particle.y > 1.1 || particle.y < -0.1) {
        final newParticle = _createParticle(random);
        particle.x = newParticle.x;
        particle.y = particle.type == _ParticleType.hologram ? 1.1 : -0.1;
        particle.size = newParticle.size;
      }

      if (particle.x > 1.1) particle.x = -0.1;
      if (particle.x < -0.1) particle.x = 1.1;
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EnvironmentEffects oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.season != widget.season ||
        oldWidget.intensity != widget.intensity ||
        oldWidget.theme != widget.theme) {
      _initializeParticles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _EnvironmentPainter(
          particles: _particles,
          isNight: widget.isNightMode,
        ),
        size: Size.infinite,
      ),
    );
  }
}

enum _ParticleType { rain, snow, leaf, petal, firefly, hologram }

class _Particle {
  _ParticleType type;
  double x;
  double y;
  double size;
  double speed;
  double angle;
  double opacity;
  double rotation;
  double rotationSpeed;

  _Particle({
    required this.type,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.angle,
    required this.opacity,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class _EnvironmentPainter extends CustomPainter {
  final List<_Particle> particles;
  final bool isNight;

  _EnvironmentPainter({required this.particles, required this.isNight});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final x = particle.x * size.width;
      final y = particle.y * size.height;

      switch (particle.type) {
        case _ParticleType.rain:
          _drawRain(canvas, Offset(x, y), particle);
          break;
        case _ParticleType.snow:
          _drawSnow(canvas, Offset(x, y), particle);
          break;
        case _ParticleType.leaf:
          _drawLeaf(canvas, Offset(x, y), particle);
          break;
        case _ParticleType.petal:
          _drawPetal(canvas, Offset(x, y), particle);
          break;
        case _ParticleType.firefly:
          _drawFirefly(canvas, Offset(x, y), particle);
          break;
        case _ParticleType.hologram:
          _drawHologram(canvas, Offset(x, y), particle);
          break;
      }
    }
  }

  void _drawRain(Canvas canvas, Offset pos, _Particle particle) {
    final paint = Paint()
      ..color = Colors.lightBlue.withValues(alpha: particle.opacity * 0.6)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      pos,
      pos + Offset(particle.size * 0.1, particle.size),
      paint,
    );
  }

  void _drawSnow(Canvas canvas, Offset pos, _Particle particle) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: particle.opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    canvas.drawCircle(pos, particle.size, paint);
  }

  void _drawLeaf(Canvas canvas, Offset pos, _Particle particle) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(particle.rotation);

    final paint = Paint()
      ..color = Colors.orange.shade700.withValues(alpha: particle.opacity);

    final path = Path()
      ..moveTo(0, -particle.size / 2)
      ..quadraticBezierTo(particle.size / 2, 0, 0, particle.size / 2)
      ..quadraticBezierTo(-particle.size / 2, 0, 0, -particle.size / 2);

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawPetal(Canvas canvas, Offset pos, _Particle particle) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(particle.rotation);

    final paint = Paint()
      ..color = Colors.pink.shade200.withValues(alpha: particle.opacity);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: particle.size,
        height: particle.size * 0.6,
      ),
      paint,
    );
    canvas.restore();
  }

  void _drawFirefly(Canvas canvas, Offset pos, _Particle particle) {
    final glowPaint = Paint()
      ..color = Colors.amber.withValues(alpha: particle.opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(pos, particle.size + 4, glowPaint);

    final corePaint = Paint()
      ..color = Colors.yellow.withValues(alpha: particle.opacity + 0.3);

    canvas.drawCircle(pos, particle.size, corePaint);
  }

  void _drawHologram(Canvas canvas, Offset pos, _Particle particle) {
    final paint = Paint()
      ..color = Colors.cyan.withValues(alpha: particle.opacity * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawCircle(pos, particle.size, paint);

    // Add a small bright core
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: particle.opacity * 0.8);

    canvas.drawCircle(pos, particle.size * 0.3, corePaint);
  }

  @override
  bool shouldRepaint(covariant _EnvironmentPainter oldDelegate) => true;
}
