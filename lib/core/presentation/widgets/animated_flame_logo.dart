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
                  color: const Color(0xFF2BEE79).withValues(alpha: 0.3 * pulse),
                  blurRadius: 40 * pulse,
                  spreadRadius: 10 * pulse,
                ),
                BoxShadow(
                  color: const Color(0xFF8E44AD).withValues(alpha: 0.2 * pulse),
                  blurRadius: 60 * pulse,
                  spreadRadius: 20 * pulse,
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
    // We compose the flame from overlapping custom painted layers
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer aura/glow (Purple)
        CustomPaint(
          size: Size(widget.size, widget.size),
          painter: FlamePainter(
            color: const Color(0xFF8E44AD).withValues(alpha: 0.6),
            flicker: _flickerController.value,
            scaleY: 1.0,
            scaleX: 1.0,
            offsetY: 0.0,
          ),
        ),
        // Mid flame (Emerald Green)
        CustomPaint(
          size: Size(widget.size * 0.8, widget.size * 0.8),
          painter: FlamePainter(
            color: const Color(0xFF2BEE79).withValues(alpha: 0.8),
            flicker: _flickerController.value * 1.5, // slightly out of phase
            scaleY: 0.8,
            scaleX: 0.9,
            offsetY: widget.size * 0.1,
          ),
        ),
        // Inner core (Bright white/green)
        CustomPaint(
          size: Size(widget.size * 0.5, widget.size * 0.5),
          painter: FlamePainter(
            color: Colors.white.withValues(alpha: 0.9),
            flicker: _flickerController.value * 2.0,
            scaleY: 0.5,
            scaleX: 0.7,
            offsetY: widget.size * 0.25,
          ),
        ),
      ],
    );
  }
}

class FlamePainter extends CustomPainter {
  final Color color;
  final double flicker;
  final double scaleY;
  final double scaleX;
  final double offsetY;

  FlamePainter({
    required this.color,
    required this.flicker,
    required this.scaleY,
    required this.scaleX,
    required this.offsetY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        8.0,
      ); // Soften the edges

    final w = size.width;
    final h = size.height;

    // Simulate flame lick movement
    // Uses sine waves driven by the flicker value
    final lick1 = math.sin(flicker * 2 * math.pi) * w * 0.1;
    final lick2 = math.cos(flicker * 2 * math.pi + math.pi / 4) * w * 0.15;

    final path = Path();

    // Base of the flame (rounded)
    path.moveTo(w * 0.2, h);
    path.quadraticBezierTo(w * 0.5, h + (w * 0.2), w * 0.8, h);

    // Right side curving up
    path.quadraticBezierTo(w * 0.9 + lick1, h * 0.6, w * 0.6 + lick2, h * 0.3);

    // Top tip
    path.quadraticBezierTo(w * 0.5, 0 + lick1, w * 0.5, 0);

    // Left side curving down
    path.quadraticBezierTo(w * 0.4 + lick2, h * 0.3, w * 0.1 - lick1, h * 0.6);

    // Close back to base
    path.quadraticBezierTo(w * 0.1, h * 0.8, w * 0.2, h);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant FlamePainter oldDelegate) {
    return oldDelegate.flicker != flicker || oldDelegate.color != color;
  }
}
