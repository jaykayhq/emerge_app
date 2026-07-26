import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Gold shimmer premium badge (Von Restorff effect — makes premium status
/// visually distinctive). A small rotating sweep-gradient disc with a star.
class PremiumBadge extends StatefulWidget {
  final double size;
  final bool showShimmer;

  const PremiumBadge({super.key, this.size = 20, this.showShimmer = true});

  @override
  State<PremiumBadge> createState() => _PremiumBadgeState();
}

class _PremiumBadgeState extends State<PremiumBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.showShimmer) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PremiumBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showShimmer && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.showShimmer && _controller.isAnimating) {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: const [
              Color(0xFFFFD700),
              Color(0xFFFFA500),
              Color(0xFFFFD700),
              Colors.white,
              Color(0xFFFFD700),
            ],
            transform: GradientRotation(_controller.value * 2 * math.pi),
          ),
          boxShadow: widget.showShimmer
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700)
                        .withValues(alpha: 0.4 * _controller.value),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.star,
          color: Colors.black87,
          size: widget.size * 0.6,
        ),
      ),
    );
  }
}
