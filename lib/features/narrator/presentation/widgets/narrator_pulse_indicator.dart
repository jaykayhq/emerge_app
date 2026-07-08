import 'package:flutter/material.dart';

/// An animated pulse indicator that shows the ◐ symbol pulsing
/// in the user's archetype color.
///
/// Used as the visual cue for the Narrator's presence.
class NarratorPulseIndicator extends StatefulWidget {
  /// The color to pulse with. Defaults to teal.
  final Color color;

  /// The size of the indicator.
  final double size;

  const NarratorPulseIndicator({
    super.key,
    this.color = const Color(0xFF2BEE79),
    this.size = 24,
  });

  @override
  State<NarratorPulseIndicator> createState() =>
      _NarratorPulseIndicatorState();
}

class _NarratorPulseIndicatorState extends State<NarratorPulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
      animation: _pulseAnim,
      builder: (context, child) {
        return Opacity(
          opacity: _pulseAnim.value,
          child: Transform.scale(
            scale: _pulseAnim.value,
            child: Text(
              '◐',
              style: TextStyle(
                color: widget.color,
                fontSize: widget.size,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
