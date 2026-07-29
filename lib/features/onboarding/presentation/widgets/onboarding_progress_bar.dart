import 'package:flutter/material.dart';

class AnimatedOnboardingProgressBar extends StatefulWidget {
  final double targetProgress;
  final String label;
  final Color? accentColor;

  const AnimatedOnboardingProgressBar({
    super.key,
    required this.targetProgress,
    required this.label,
    this.accentColor,
  });

  @override
  State<AnimatedOnboardingProgressBar> createState() =>
      _AnimatedOnboardingProgressBarState();
}

class _AnimatedOnboardingProgressBarState
    extends State<AnimatedOnboardingProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.value = widget.targetProgress;
  }

  @override
  void didUpdateWidget(AnimatedOnboardingProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetProgress != widget.targetProgress) {
      _controller.animateTo(widget.targetProgress);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = widget.targetProgress >= 1.0;
    final showRemaining = !isComplete && widget.targetProgress >= 0.5;
    final percentageText = isComplete
        ? '100%'
        : showRemaining
            ? '${((1 - widget.targetProgress) * 100).round()}% to go'
            : '${(widget.targetProgress * 100).round()}%';
    final barColor = widget.accentColor ?? Colors.cyanAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                percentageText,
                style: TextStyle(
                  color: barColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) => LinearProgressIndicator(
                value: _animation.value,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

final onboardingProgressLabels = {
  0.2: "You've begun. Now define yourself.",
  0.4: "Your archetype is set. What shapes you?",
  0.6: "40% to go. Your interests give texture.",
  0.8: "20% to go. Almost forged. Choose your company.",
  1.0: "Ready to emerge.",
};

String onboardingLabelFor(double progress) {
  final keys = onboardingProgressLabels.keys.toList()..sort();
  double best = keys.first;
  for (final k in keys) {
    if (progress >= k) best = k;
  }
  return onboardingProgressLabels[best]!;
}
