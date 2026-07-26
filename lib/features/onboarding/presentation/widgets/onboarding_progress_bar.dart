import 'package:flutter/material.dart';

/// A compact progress indicator shown atop onboarding screens.
///
/// Displays the percentage, a [LinearProgressIndicator] tinted with
/// [Colors.cyanAccent], and a milestone [label] below it.
class OnboardingProgressBar extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final String label;

  const OnboardingProgressBar({
    super.key,
    required this.progress,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.cyanAccent,
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
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
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

/// Milestone label shown for each onboarding progress checkpoint.
/// (Not `const`: Dart forbids const maps keyed by `double`.)
final onboardingProgressLabels = {
  0.2: "You've begun. Now define yourself.",
  0.4: "Your archetype is set. What shapes you?",
  0.6: "Good. Your interests give texture.",
  0.8: "Almost forged. Choose your company.",
  1.0: "Ready to emerge.",
};

/// Returns the milestone label for [progress], picking the nearest
/// checkpoint at or below the given value (defaults to the 0.2 label).
String onboardingLabelFor(double progress) {
  final keys = onboardingProgressLabels.keys.toList()..sort();
  double best = keys.first;
  for (final k in keys) {
    if (progress >= k) best = k;
  }
  return onboardingProgressLabels[best]!;
}
