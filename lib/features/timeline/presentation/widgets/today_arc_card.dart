import 'dart:math' as math;

import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:flutter/material.dart';

/// Single hero progress card. Replaces CurrentMissionBanner + best streak + vote icon.
class TodayArcCard extends StatelessWidget {
  final int completed;
  final int total;
  final int streakDays;
  final VoidCallback? onTap;

  const TodayArcCard({
    super.key,
    required this.completed,
    required this.total,
    required this.streakDays,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : completed / total;
    final remaining = math.max(0, total - completed);
    final onTrack = remaining == 0 && total > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      value: pct,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation(EmergeColors.teal),
                    ),
                  ),
                  Text(
                    '${(pct * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    onTrack
                        ? 'All done · $streakDays-day streak'
                        : (total == 0
                            ? 'Start your streak'
                            : '$remaining habit${remaining == 1 ? '' : 's'} left today'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    total == 0
                        ? 'Add your first habit'
                        : (onTrack ? 'Come back tomorrow' : 'Tap to jump to your next habit'),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
