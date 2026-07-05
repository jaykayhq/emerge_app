import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

class DashedCirclePainter extends CustomPainter {
  final Color color;

  const DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final double radius = (size.width - paint.strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    const int dashCount = 8;
    const double dashAngle = math.pi / 8;
    const double gapAngle = math.pi / 8;

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = i * (dashAngle + gapAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

class HabitRuneIndicator extends StatefulWidget {
  final Habit habit;

  const HabitRuneIndicator({
    super.key,
    required this.habit,
  });

  @override
  State<HabitRuneIndicator> createState() => _HabitRuneIndicatorState();
}

class _HabitRuneIndicatorState extends State<HabitRuneIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (!_isForged) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant HabitRuneIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isForged) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    } else {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isForged {
    final h = widget.habit;
    return (h.twoMinuteVersion != null && h.twoMinuteVersion!.isNotEmpty) ||
        h.reward.isNotEmpty ||
        h.environmentPriming.isNotEmpty ||
        h.integrationType != HabitIntegrationType.none ||
        (h.anchorHabitId != null && h.anchorHabitId!.isNotEmpty);
  }

  Color _getAttributeColor(HabitAttribute attr) {
    switch (attr) {
      case HabitAttribute.strength:
        return const Color(0xFFFF6B6B);
      case HabitAttribute.intellect:
        return const Color(0xFF6C63FF);
      case HabitAttribute.vitality:
        return const Color(0xFF2BEE79);
      case HabitAttribute.creativity:
        return const Color(0xFFE040FB);
      case HabitAttribute.focus:
        return const Color(0xFFFFB74D);
      case HabitAttribute.spirit:
        return const Color(0xFF4DD0E1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getAttributeColor(widget.habit.attribute);
    final forged = _isForged;

    if (forged) {
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.8),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      );
    } else {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Opacity(
            opacity: _animation.value,
            child: SizedBox(
              width: 14,
              height: 14,
              child: CustomPaint(
                painter: DashedCirclePainter(color: color),
              ),
            ),
          );
        },
      );
    }
  }
}
