import 'package:flutter/material.dart';

class StreakFlameWidget extends StatefulWidget {
  final int streakCount;
  final bool isActive;
  final double size;
  final VoidCallback? onTap;

  const StreakFlameWidget({
    super.key,
    required this.streakCount,
    required this.isActive,
    this.size = 48,
    this.onTap,
  });

  @override
  State<StreakFlameWidget> createState() => _StreakFlameWidgetState();
}

class _StreakFlameWidgetState extends State<StreakFlameWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.isActive && widget.streakCount > 0) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StreakFlameWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && widget.streakCount > 0 && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if ((!widget.isActive || widget.streakCount == 0) &&
        _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isActive
        ? const Color(0xFFFF7F50)
        : Colors.grey.shade600;
    final glowColor = widget.isActive
        ? const Color(0xFFFF4500).withValues(alpha: 0.5)
        : Colors.transparent;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isActive && widget.streakCount > 0
                ? _pulseAnimation.value
                : 1.0,
            child: SizedBox(
              width: widget.size,
              height: widget.size * 1.3,
              child: CustomPaint(
                painter: _FlamePainter(
                  color: baseColor,
                  glowColor: glowColor,
                  intensity: (widget.streakCount / 30).clamp(0.0, 1.0),
                ),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: widget.size * 0.3),
                    child: Text(
                      '${widget.streakCount}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.size * 0.35,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: baseColor.withValues(alpha: 0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FlamePainter extends CustomPainter {
  final Color color;
  final Color glowColor;
  final double intensity;

  _FlamePainter({
    required this.color,
    required this.glowColor,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.9);
    final baseRadius = size.width * 0.35;

    if (intensity > 0) {
      final glowPaint = Paint()
        ..color = glowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);
      canvas.drawCircle(center, baseRadius * 1.5, glowPaint);
    }

    final flamePath = Path();
    flamePath.moveTo(center.dx, size.height * 0.15);
    flamePath.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.4,
      center.dx + baseRadius * 0.6,
      size.height * 0.7,
    );
    flamePath.quadraticBezierTo(
      center.dx + baseRadius * 0.3,
      size.height,
      center.dx,
      size.height,
    );
    flamePath.quadraticBezierTo(
      center.dx - baseRadius * 0.3,
      size.height,
      center.dx - baseRadius * 0.6,
      size.height * 0.7,
    );
    flamePath.quadraticBezierTo(
      size.width * 0.1,
      size.height * 0.4,
      center.dx,
      size.height * 0.15,
    );
    flamePath.close();

    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 0.8,
      colors: [
        Colors.white.withValues(alpha: 0.9),
        color,
        color.withValues(alpha: 0.7),
        Colors.orange.withValues(alpha: 0.5),
      ],
      stops: const [0.0, 0.3, 0.6, 1.0],
    );

    final flamePaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: baseRadius),
      );

    canvas.drawPath(flamePath, flamePaint);

    final innerFlamePath = Path();
    innerFlamePath.moveTo(center.dx, size.height * 0.3);
    innerFlamePath.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.5,
      center.dx + baseRadius * 0.25,
      size.height * 0.65,
    );
    innerFlamePath.quadraticBezierTo(
      center.dx + baseRadius * 0.15,
      size.height * 0.8,
      center.dx,
      size.height * 0.85,
    );
    innerFlamePath.quadraticBezierTo(
      center.dx - baseRadius * 0.15,
      size.height * 0.8,
      center.dx - baseRadius * 0.25,
      size.height * 0.65,
    );
    innerFlamePath.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.5,
      center.dx,
      size.height * 0.3,
    );
    innerFlamePath.close();

    final innerPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawPath(innerFlamePath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _FlamePainter oldDelegate) {
    return color != oldDelegate.color ||
        glowColor != oldDelegate.glowColor ||
        intensity != oldDelegate.intensity;
  }
}
