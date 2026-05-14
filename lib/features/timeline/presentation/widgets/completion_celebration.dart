import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CompletionCelebration extends StatefulWidget {
  final int xpEarned;
  final int newStreak;
  final bool isStreakMilestone;
  final VoidCallback onComplete;
  final Color accentColor;

  const CompletionCelebration({
    super.key,
    required this.xpEarned,
    required this.newStreak,
    this.isStreakMilestone = false,
    required this.onComplete,
    this.accentColor = const Color(0xFF00FFCC),
  });

  @override
  State<CompletionCelebration> createState() => _CompletionCelebrationState();
}

class _CompletionCelebrationState extends State<CompletionCelebration>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _xpController;
  late AnimationController _confettiController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _xpAnimation;
  late Animation<double> _confettiAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _xpController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _xpAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _xpController, curve: Curves.easeOutCubic),
    );

    _confettiAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.linear),
    );

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    HapticFeedback.mediumImpact();
    _scaleController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _xpController.forward();

    if (widget.isStreakMilestone) {
      await Future.delayed(const Duration(milliseconds: 300));
      HapticFeedback.heavyImpact();
      _confettiController.forward();
    }

    await Future.delayed(const Duration(milliseconds: 1500));
    widget.onComplete();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _xpController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.isStreakMilestone)
            AnimatedBuilder(
              animation: _confettiAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(300, 300),
                  painter: _ConfettiPainter(
                    progress: _confettiAnimation.value,
                    colors: [
                      widget.accentColor,
                      Colors.purple,
                      Colors.orange,
                      Colors.yellow,
                      Colors.pink,
                    ],
                  ),
                );
              },
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _xpAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _xpAnimation.value,
                    child: Column(
                      children: [
                        Text(
                          '+${(widget.xpEarned * _xpAnimation.value).toInt()} XP',
                          style: TextStyle(
                            color: widget.accentColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: widget.accentColor.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        if (widget.newStreak > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.newStreak} day streak',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (widget.isStreakMilestone) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: Text(
                              _getMilestoneText(),
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMilestoneText() {
    switch (widget.newStreak) {
      case 7:
        return 'ONE WEEK! 🎉';
      case 14:
        return 'TWO WEEKS! 🌟';
      case 30:
        return 'ONE MONTH! 🔥';
      case 60:
        return 'TWO MONTHS! 💪';
      case 90:
        return 'QUARTER YEAR! 🏆';
      case 180:
        return 'HALF YEAR! 👑';
      case 365:
        return 'ONE YEAR! 🎊';
      default:
        return 'MILESTONE! 🎉';
    }
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;

  _ConfettiPainter({required this.progress, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = math.Random(42);

    for (int i = 0; i < 50; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 50 + random.nextDouble() * 100;
      final distance = progress * speed;

      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;

      final paint = Paint()
        ..color = colors[i % colors.length].withValues(
          alpha: (1.0 - progress).clamp(0.0, 1.0),
        );

      final confettiSize = 4 + random.nextDouble() * 4;
      canvas.drawCircle(Offset(x, y), confettiSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
