import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated world inhabitants (NPCs, pets, drones)
class WorldInhabitants extends StatefulWidget {
  final String theme;
  final int populationCount;
  final bool isNightMode;

  const WorldInhabitants({
    super.key,
    this.theme = 'city',
    this.populationCount = 8,
    this.isNightMode = false,
  });

  @override
  State<WorldInhabitants> createState() => _WorldInhabitantsState();
}

class _WorldInhabitantsState extends State<WorldInhabitants>
    with TickerProviderStateMixin {
  final List<_Inhabitant> _inhabitants = [];
  late AnimationController _masterController;

  @override
  void initState() {
    super.initState();
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_updatePositions);

    _initializeInhabitants();
    _masterController.repeat();
  }

  void _initializeInhabitants() {
    final random = math.Random();
    _inhabitants.clear();

    for (int i = 0; i < widget.populationCount; i++) {
      final type = _getRandomType(random, widget.theme);
      _inhabitants.add(
        _Inhabitant(
          type: type,
          x: random.nextDouble(),
          y: 0.75 + random.nextDouble() * 0.15,
          speed: 0.0002 + random.nextDouble() * 0.0003,
          direction: random.nextBool() ? 1 : -1,
          frame: 0,
          animationOffset: random.nextDouble(),
        ),
      );
    }
  }

  _InhabitantType _getRandomType(math.Random random, String theme) {
    if (theme == 'city') {
      final types = [
        _InhabitantType.citizen,
        _InhabitantType.citizen,
        _InhabitantType.drone,
        _InhabitantType.pet,
      ];
      return types[random.nextInt(types.length)];
    } else {
      final types = [
        _InhabitantType.villager,
        _InhabitantType.pet,
        _InhabitantType.bird,
      ];
      return types[random.nextInt(types.length)];
    }
  }

  void _updatePositions() {
    for (final inhabitant in _inhabitants) {
      inhabitant.x += inhabitant.speed * inhabitant.direction;

      // Wrap around
      if (inhabitant.x > 1.1) {
        inhabitant.x = -0.1;
      } else if (inhabitant.x < -0.1) {
        inhabitant.x = 1.1;
      }

      // Update animation frame
      inhabitant.frame = (inhabitant.frame + 1) % 60;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _masterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _InhabitantsPainter(
          inhabitants: _inhabitants,
          isNight: widget.isNightMode,
          theme: widget.theme,
        ),
        size: Size.infinite,
      ),
    );
  }
}

enum _InhabitantType { citizen, villager, pet, drone, bird }

class _Inhabitant {
  _InhabitantType type;
  double x;
  double y;
  double speed;
  int direction;
  int frame;
  double animationOffset;

  _Inhabitant({
    required this.type,
    required this.x,
    required this.y,
    required this.speed,
    required this.direction,
    required this.frame,
    required this.animationOffset,
  });
}

class _InhabitantsPainter extends CustomPainter {
  final List<_Inhabitant> inhabitants;
  final bool isNight;
  final String theme;

  _InhabitantsPainter({
    required this.inhabitants,
    required this.isNight,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final inhabitant in inhabitants) {
      final x = inhabitant.x * size.width;
      final y = inhabitant.y * size.height;

      switch (inhabitant.type) {
        case _InhabitantType.citizen:
          _drawCitizen(canvas, Offset(x, y), inhabitant);
          break;
        case _InhabitantType.villager:
          _drawVillager(canvas, Offset(x, y), inhabitant);
          break;
        case _InhabitantType.pet:
          _drawPet(canvas, Offset(x, y), inhabitant);
          break;
        case _InhabitantType.drone:
          _drawDrone(canvas, Offset(x, y), inhabitant);
          break;
        case _InhabitantType.bird:
          _drawBird(canvas, Offset(x, y), inhabitant);
          break;
      }
    }
  }

  void _drawCitizen(Canvas canvas, Offset pos, _Inhabitant inhabitant) {
    // Walking animation - bob up/down
    final walkOffset = math.sin(inhabitant.frame * 0.3) * 2;
    final bodyPos = pos + Offset(0, walkOffset);

    // Body colors for city
    final bodyPaint = Paint()
      ..color = _getCitizenColor(inhabitant.animationOffset);
    final skinPaint = Paint()..color = const Color(0xFFDEB887);
    final hairPaint = Paint()..color = Colors.brown.shade800;

    // Head
    canvas.drawCircle(bodyPos - const Offset(0, 20), 6, skinPaint);
    // Hair
    canvas.drawArc(
      Rect.fromCenter(
        center: bodyPos - const Offset(0, 22),
        width: 14,
        height: 10,
      ),
      math.pi,
      math.pi,
      true,
      hairPaint,
    );

    // Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: bodyPos - const Offset(0, 8),
        width: 12,
        height: 16,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Legs with walking animation
    final legOffset = math.sin(inhabitant.frame * 0.5) * 4;
    final legPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      bodyPos + Offset(-3, 0),
      bodyPos + Offset(-3 + legOffset, 10),
      legPaint,
    );
    canvas.drawLine(
      bodyPos + Offset(3, 0),
      bodyPos + Offset(3 - legOffset, 10),
      legPaint,
    );

    // Arms
    final armOffset = math.sin(inhabitant.frame * 0.5 + 1.5) * 3;
    canvas.drawLine(
      bodyPos - const Offset(6, 12),
      bodyPos + Offset(-8 + armOffset, -2),
      legPaint,
    );
    canvas.drawLine(
      bodyPos - const Offset(-6, 12),
      bodyPos + Offset(8 - armOffset, -2),
      legPaint,
    );

    // Flip based on direction
    if (inhabitant.direction < 0) {
      // Could add flip transform here for more realism
    }
  }

  void _drawVillager(Canvas canvas, Offset pos, _Inhabitant inhabitant) {
    // Similar to citizen but with different colors/style
    final walkOffset = math.sin(inhabitant.frame * 0.3) * 2;
    final bodyPos = pos + Offset(0, walkOffset);

    final bodyPaint = Paint()..color = Colors.brown.shade600;
    final skinPaint = Paint()..color = const Color(0xFFDEB887);

    canvas.drawCircle(bodyPos - const Offset(0, 18), 5, skinPaint);

    // Simple robe body
    final path = Path()
      ..moveTo(bodyPos.dx - 8, bodyPos.dy - 12)
      ..lineTo(bodyPos.dx - 6, bodyPos.dy + 8)
      ..lineTo(bodyPos.dx + 6, bodyPos.dy + 8)
      ..lineTo(bodyPos.dx + 8, bodyPos.dy - 12)
      ..close();

    canvas.drawPath(path, bodyPaint);
  }

  void _drawPet(Canvas canvas, Offset pos, _Inhabitant inhabitant) {
    final walkOffset = math.sin(inhabitant.frame * 0.4) * 1.5;
    final tailWag = math.sin(inhabitant.frame * 0.6) * 0.5;

    final bodyPaint = Paint()..color = Colors.brown.shade400;
    final eyePaint = Paint()..color = Colors.black;

    // Body (oval)
    canvas.drawOval(
      Rect.fromCenter(
        center: pos + Offset(0, walkOffset),
        width: 16,
        height: 10,
      ),
      bodyPaint,
    );

    // Head
    canvas.drawCircle(
      pos + Offset(inhabitant.direction * 8, -3 + walkOffset),
      5,
      bodyPaint,
    );

    // Eyes
    canvas.drawCircle(
      pos + Offset(inhabitant.direction * 10, -4 + walkOffset),
      1.5,
      eyePaint,
    );

    // Ears
    canvas.drawCircle(
      pos + Offset(inhabitant.direction * 6, -7 + walkOffset),
      3,
      bodyPaint,
    );

    // Tail
    final tailPaint = Paint()
      ..color = bodyPaint.color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      pos + Offset(-inhabitant.direction * 7, 0 + walkOffset),
      pos + Offset(-inhabitant.direction * 14, -5 + tailWag * 8 + walkOffset),
      tailPaint,
    );

    // Legs
    final legPaint = Paint()
      ..color = Colors.brown.shade600
      ..strokeWidth = 2;

    final legAnim = math.sin(inhabitant.frame * 0.5) * 3;
    canvas.drawLine(
      pos + Offset(-4, 4),
      pos + Offset(-4 + legAnim, 10),
      legPaint,
    );
    canvas.drawLine(
      pos + Offset(4, 4),
      pos + Offset(4 - legAnim, 10),
      legPaint,
    );
  }

  void _drawDrone(Canvas canvas, Offset pos, _Inhabitant inhabitant) {
    // Floating drone for city theme
    final floatOffset = math.sin(inhabitant.frame * 0.15) * 8;
    final dronePos = pos - Offset(0, 60 + floatOffset);

    // Body
    final bodyPaint = Paint()..color = Colors.grey.shade700;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: dronePos, width: 20, height: 8),
        const Radius.circular(4),
      ),
      bodyPaint,
    );

    // Propellers (spinning effect)
    final propPaint = Paint()
      ..color = Colors.grey.shade400.withValues(alpha: 0.7)
      ..strokeWidth = 2;

    final spin = inhabitant.frame * 0.5;
    for (int i = 0; i < 4; i++) {
      final angle = spin + i * math.pi / 2;
      final propX = dronePos.dx + math.cos(angle) * 12;
      final propY = dronePos.dy + math.sin(angle) * 2 - 2;
      canvas.drawCircle(Offset(propX, propY), 6, propPaint);
    }

    // Light
    final lightPaint = Paint()
      ..color = isNight ? Colors.cyan : Colors.red
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawCircle(dronePos + const Offset(0, 4), 2, lightPaint);

    // Light beam (at night)
    if (isNight) {
      final beamPaint = Paint()
        ..color = Colors.cyan.withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      final path = Path()
        ..moveTo(dronePos.dx - 5, dronePos.dy + 5)
        ..lineTo(dronePos.dx - 15, pos.dy)
        ..lineTo(dronePos.dx + 15, pos.dy)
        ..lineTo(dronePos.dx + 5, dronePos.dy + 5)
        ..close();

      canvas.drawPath(path, beamPaint);
    }
  }

  void _drawBird(Canvas canvas, Offset pos, _Inhabitant inhabitant) {
    // Flying bird
    final wingFlap = math.sin(inhabitant.frame * 0.4) * 10;
    final flyPos = pos - Offset(0, 100 + math.sin(inhabitant.frame * 0.1) * 10);

    final birdPaint = Paint()..color = Colors.grey.shade800;

    // Body
    canvas.drawOval(
      Rect.fromCenter(center: flyPos, width: 10, height: 6),
      birdPaint,
    );

    // Wings
    final wingPath = Path()
      ..moveTo(flyPos.dx, flyPos.dy)
      ..quadraticBezierTo(
        flyPos.dx - 15,
        flyPos.dy - wingFlap,
        flyPos.dx - 8,
        flyPos.dy,
      )
      ..quadraticBezierTo(
        flyPos.dx + 15,
        flyPos.dy - wingFlap,
        flyPos.dx + 8,
        flyPos.dy,
      );

    canvas.drawPath(wingPath, birdPaint);
  }

  Color _getCitizenColor(double offset) {
    final colors = [
      Colors.blue.shade700,
      Colors.grey.shade600,
      Colors.purple.shade700,
      Colors.teal.shade700,
      Colors.indigo.shade600,
    ];
    return colors[(offset * colors.length).floor() % colors.length];
  }

  @override
  bool shouldRepaint(covariant _InhabitantsPainter oldDelegate) => true;
}
