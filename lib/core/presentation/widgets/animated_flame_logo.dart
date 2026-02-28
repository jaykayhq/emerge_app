import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedFlameLogo extends StatefulWidget {
  final double size;

  const AnimatedFlameLogo({super.key, this.size = 140});

  @override
  State<AnimatedFlameLogo> createState() => _AnimatedFlameLogoState();
}

class _AnimatedFlameLogoState extends State<AnimatedFlameLogo>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _flickerController;

  @override
  void initState() {
    super.initState();

    // Core pulsing animation (breathing effect)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    // Faster flickering/displacement animation
    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _flickerController]),
      builder: (context, child) {
        final pulse = Tween<double>(begin: 0.95, end: 1.05).evaluate(
          CurvedAnimation(
            parent: _pulseController,
            curve: Curves.easeInOutSine,
          ),
        );

        return Transform.scale(
          scale: pulse,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2BEE79).withValues(alpha: 0.2 * pulse),
                  blurRadius: 50 * pulse,
                  spreadRadius: 5 * pulse,
                ),
                BoxShadow(
                  color: const Color(0xFF9D4EDD).withValues(alpha: 0.4 * pulse),
                  blurRadius: 80 * pulse,
                  spreadRadius: 15 * pulse,
                ),
              ],
            ),
            child: _buildFlameStack(),
          ),
        ).animate().fadeIn(duration: 800.ms, curve: Curves.easeOut);
      },
    );
  }

  Widget _buildFlameStack() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Outer aura/glow (Neon Purple)
        Padding(
          padding: EdgeInsets.only(bottom: widget.size * 0.05),
          child: CustomPaint(
            size: Size(widget.size, widget.size * 0.95),
            painter: FlamePainter(
              color: const Color(0xFF9D4EDD).withValues(alpha: 0.9),
              flicker: _flickerController.value,
            ),
          ),
        ),
        // Mid flame (Emerald Green)
        Padding(
          padding: EdgeInsets.only(bottom: widget.size * 0.05),
          child: CustomPaint(
            size: Size(widget.size * 0.75, widget.size * 0.70),
            painter: FlamePainter(
              color: const Color(0xFF2BEE79).withValues(alpha: 0.95),
              flicker: _flickerController.value + 0.33,
            ),
          ),
        ),
        // Inner core (Bright white)
        Padding(
          padding: EdgeInsets.only(bottom: widget.size * 0.05),
          child: CustomPaint(
            size: Size(widget.size * 0.45, widget.size * 0.40),
            painter: FlamePainter(
              color: Colors.white,
              flicker: _flickerController.value + 0.66,
            ),
          ),
        ),
      ],
    );
  }
}

class FlamePainter extends CustomPainter {
  final Color color;
  final double flicker;

  FlamePainter({required this.color, required this.flicker});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [color, color.withValues(alpha: 0.4)],
      ).createShader(rect)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);

    final w = size.width;
    final h = size.height;

    // Simulate elegant flame waving
    final time = flicker * math.pi * 2;
    // Sway the top horizontally
    final dX1 = math.sin(time) * w * 0.06;
    final dX2 = math.cos(time * 1.5) * w * 0.04;
    // Slight vertical bounce
    final dY = math.sin(time * 2) * h * 0.03;

    final path = Path();

    // Start at bottom center
    path.moveTo(w * 0.5, h);

    // Right side bulb to top tip
    path.cubicTo(
      w * 1.1 + dX2,
      h * 0.9, // Control 1: Pull out to the right
      w * 0.8 + dX1,
      h * 0.4, // Control 2: Smooth transition up
      w * 0.5 + dX1,
      0 + dY, // End: Taper at the top
    );

    // Top tip back down left side
    path.cubicTo(
      w * 0.2 + dX1,
      h * 0.4, // Control 1: Smooth transition down
      0.0 - dX2,
      h * 0.9, // Control 2: Pull out to the left
      w * 0.5,
      h, // End: Back to bottom center
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant FlamePainter oldDelegate) {
    return oldDelegate.flicker != flicker || oldDelegate.color != color;
  }
}
