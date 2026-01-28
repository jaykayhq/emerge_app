import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:flutter/material.dart';

/// Card showing today's habit completion summary with XP and streak info
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmergeColors.hexLine),
      ),
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
                        color: AppTheme.textSecondaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '$completedHabits/$totalHabits habits complete',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textMainDark,
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
              color: AppTheme.textMainDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
