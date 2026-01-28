import 'dart:math' as math;
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:flutter/material.dart';

/// Full-body evolving silhouette that changes based on archetype, level, and consistency.
/// Simpler than the old ProceduralAvatar - just shapes with glow effects.
class EvolvingSilhouette extends StatelessWidget {
  final UserArchetype archetype;
  final int level;
  final double consistency; // 0.0 - 1.0
  final double size;
  final bool isAnimated;

  const EvolvingSilhouette({
    super.key,
    required this.archetype,
    this.level = 1,
    this.consistency = 0.5,
    this.size = 200,
    this.isAnimated = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.5, // Taller for full body
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow based on level
          if (level > 5)
            Container(
              width: size * 0.8,
              height: size * 1.2,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(size * 0.4),
                boxShadow: [
                  BoxShadow(
                    color: _getArchetypeColor().withValues(alpha: 0.3),
                    blurRadius: level * 4.0,
                    spreadRadius: level * 1.0,
                  ),
                ],
              ),
            ),

          // Main silhouette
          CustomPaint(
            size: Size(size, size * 1.5),
            painter: _SilhouettePainter(
              archetype: archetype,
              level: level,
              consistency: consistency,
              color: _getArchetypeColor(),
            ),
          ),

          // Aura particles for high levels
          if (level >= 10) ..._buildAuraParticles(),
        ],
      ),
    );
  }

  Color _getArchetypeColor() {
    switch (archetype) {
      case UserArchetype.athlete:
        return EmergeColors.coral;
      case UserArchetype.scholar:
        return EmergeColors.violet;
      case UserArchetype.creator:
        return EmergeColors.yellow;
      case UserArchetype.stoic:
        return EmergeColors.teal;
      case UserArchetype.mystic:
        return Colors.purpleAccent;
      case UserArchetype.none:
        return EmergeColors.teal;
    }
  }

  List<Widget> _buildAuraParticles() {
    return List.generate(6, (index) {
      final angle = (index * 60.0) * (math.pi / 180);
      final distance = size * 0.35;
      final x = math.cos(angle) * distance;
      final y = math.sin(angle) * distance;

      return Positioned(
        left: size / 2 + x - 4,
        top: size * 0.75 + y - 4,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _getArchetypeColor().withValues(alpha: 0.6),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getArchetypeColor().withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _SilhouettePainter extends CustomPainter {
  final UserArchetype archetype;
  final int level;
  final double consistency;
  final Color color;

  _SilhouettePainter({
    required this.archetype,
    required this.level,
    required this.consistency,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final centerX = size.width / 2;

    // Adjust body proportions based on archetype
    double shoulderWidth, headRadius, bodyHeight;
    switch (archetype) {
      case UserArchetype.athlete:
        shoulderWidth = size.width * 0.45; // Broader
        headRadius = size.width * 0.12;
        bodyHeight = size.height * 0.7;
        break;
      case UserArchetype.scholar:
        shoulderWidth = size.width * 0.35;
        headRadius = size.width * 0.14; // Larger head
        bodyHeight = size.height * 0.75;
        break;
      case UserArchetype.creator:
        shoulderWidth = size.width * 0.4;
        headRadius = size.width * 0.13;
        bodyHeight = size.height * 0.72;
        break;
      default:
        shoulderWidth = size.width * 0.38;
        headRadius = size.width * 0.13;
        bodyHeight = size.height * 0.72;
    }

    // Posture modifier based on consistency
    final postureOffset = (1 - consistency) * 10; // Slouch when low consistency

    // Draw head
    final headY = size.height * 0.15 + postureOffset * 0.5;
    canvas.drawCircle(Offset(centerX, headY), headRadius, paint);
    canvas.drawCircle(Offset(centerX, headY), headRadius, glowPaint);

    // Draw body (torso)
    final bodyPath = Path();
    final neckY = headY + headRadius;
    final bodyBottom = neckY + bodyHeight * 0.5;

    bodyPath.moveTo(centerX, neckY);
    bodyPath.lineTo(centerX - shoulderWidth / 2, neckY + size.height * 0.1);
    bodyPath.lineTo(centerX - size.width * 0.2, bodyBottom);
    bodyPath.lineTo(centerX + size.width * 0.2, bodyBottom);
    bodyPath.lineTo(centerX + shoulderWidth / 2, neckY + size.height * 0.1);
    bodyPath.close();

    canvas.drawPath(bodyPath, paint);
    canvas.drawPath(bodyPath, glowPaint);

    // Draw arms (simplified lines)
    final armPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;

    // Left arm
    canvas.drawLine(
      Offset(centerX - shoulderWidth / 2, neckY + size.height * 0.1),
      Offset(
        centerX - size.width * 0.35,
        neckY + size.height * 0.3 + postureOffset,
      ),
      armPaint,
    );

    // Right arm
    canvas.drawLine(
      Offset(centerX + shoulderWidth / 2, neckY + size.height * 0.1),
      Offset(
        centerX + size.width * 0.35,
        neckY + size.height * 0.3 + postureOffset,
      ),
      armPaint,
    );

    // Draw legs
    final legTop = bodyBottom;
    final legBottom = size.height * 0.95;

    // Left leg
    canvas.drawLine(
      Offset(centerX - size.width * 0.1, legTop),
      Offset(centerX - size.width * 0.15, legBottom),
      armPaint,
    );

    // Right leg
    canvas.drawLine(
      Offset(centerX + size.width * 0.1, legTop),
      Offset(centerX + size.width * 0.15, legBottom),
      armPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
