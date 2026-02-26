import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/presentation/widgets/glassmorphism_card.dart';
import 'package:flutter/material.dart';

/// Card showing today's habit completion summary with XP and streak info.
/// Uses glassmorphism background matching the Stitch green design system.
class DailySummaryCard extends StatelessWidget {
  final int completedHabits;
  final int totalHabits;
  final int xpToday;
  final int currentStreak;

  const DailySummaryCard({
    super.key,
    required this.completedHabits,
    required this.totalHabits,
    required this.xpToday,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      glowColor: EmergeColors.teal,
      child: Row(
        children: [
          // Left side: completion stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: EmergeColors.teal,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Today\'s Summary',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: EmergeColors.tealMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Track your daily identity votes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: EmergeColors.tealMuted.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$completedHabits/$totalHabits habits complete',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '+$xpToday XP today',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: EmergeColors.teal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (currentStreak > 0) ...[
                      Icon(
                        Icons.local_fire_department,
                        color: EmergeColors.coral,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$currentStreak-day streak',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: EmergeColors.coral,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Right side: progress ring
          _buildProgressRing(context),
        ],
      ),
    );
  }

  Widget _buildProgressRing(BuildContext context) {
    final progress = totalHabits > 0 ? completedHabits / totalHabits : 0.0;

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 5,
              backgroundColor: EmergeColors.teal.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(EmergeColors.teal),
            ),
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
