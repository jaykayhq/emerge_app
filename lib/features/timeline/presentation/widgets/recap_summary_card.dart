import 'package:flutter/material.dart';

/// A compact recap card with a circular momentum arc (left) and streak flame
/// (right), plus a narrative line below. Tapping navigates to the full recap
/// screen.
class RecapSummaryCard extends StatelessWidget {
  /// Today's completion fraction (0.0–1.0).
  final double completionFraction;

  /// The user's current streak.
  final int currentStreak;

  /// What percentile of the user's tribe they're ahead of today.
  /// Null hides the tribe narrative line.
  final int? tribePercentile;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  const RecapSummaryCard({
    super.key,
    required this.completionFraction,
    required this.currentStreak,
    this.tribePercentile,
    this.onTap,
  });

  Color _arcColor(double fraction) {
    if (fraction >= 0.5) return const Color(0xFF2BEE79); // green
    if (fraction >= 0.25) return const Color(0xFFFFC107); // amber
    return const Color(0xFFFF6B6B); // coral
  }

  String _flameEmoji(int streak) {
    if (streak >= 21) return '🔥🔥';
    return '🔥';
  }

  String _narrativeText() {
    if (completionFraction >= 1.0) {
      if (tribePercentile != null) {
        return "All done today! You're in the top $tribePercentile% of your tribe.";
      }
      return 'All done today! Great work.';
    }
    if (completionFraction >= 0.5) {
      if (tribePercentile != null) {
        return "You're ahead of $tribePercentile% of your tribe today.";
      }
      return "You're making great progress today.";
    }
    if (completionFraction > 0) {
      return "Every habit counts — you're at ${(completionFraction * 100).toInt()}%.";
    }
    return "Your day hasn't started yet.";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Left: Circular progress arc
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: completionFraction,
                        strokeWidth: 4,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _arcColor(completionFraction),
                        ),
                      ),
                      Text(
                        '${(completionFraction * 100).toInt()}%',
                        style: TextStyle(
                          color: _arcColor(completionFraction),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Right: Streak flame
                Row(
                  children: [
                    Text(
                      _flameEmoji(currentStreak),
                      style: TextStyle(fontSize: currentStreak >= 7 ? 24 : 20),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$currentStreak',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: currentStreak >= 7 ? 22 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'day streak',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Narrative line
            Text(
              _narrativeText(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
