import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';

/// A compact stats card showing the user's weekly progress.
/// Sits between the calendar strip and the habit list on the timeline.
/// Tapping navigates to the full recap screen.
class RecapSummaryCard extends StatelessWidget {
  final List<Habit> habits;
  final int streak;
  final int totalXp;
  final VoidCallback onTap;

  const RecapSummaryCard({
    super.key,
    required this.habits,
    required this.streak,
    required this.totalXp,
    required this.onTap,
  });

  /// Counts habits that have been completed at least once this week.
  /// Week starts on Sunday, matching the recap service's week boundary.
  int _weeklyCompletions() {
    final now = DateTime.now();
    final daysSinceSunday = now.weekday % 7;
    final weekStart = DateTime(now.year, now.month, now.day - daysSinceSunday);

    return habits
        .where(
          (h) =>
              h.lastCompletedDate != null &&
              h.lastCompletedDate!.isAfter(
                weekStart.subtract(const Duration(hours: 1)),
              ),
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final weeklyCount = _weeklyCompletions();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              EmergeColors.violet.withValues(alpha: 0.1),
              EmergeColors.teal.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: EmergeColors.violet.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Stat items
            _StatItem(
              value: '$weeklyCount',
              label: 'this week',
              color: EmergeColors.teal,
            ),
            const SizedBox(width: 24),
            _StatItem(
              value: '$streak',
              label: 'day streak',
              color: const Color(0xFFFFB74D),
            ),
            const SizedBox(width: 24),
            _StatItem(
              value:
                  '${totalXp >= 1000 ? '${(totalXp / 1000).toStringAsFixed(1)}k' : '$totalXp'}',
              label: 'total XP',
              color: const Color(0xFFE040FB),
            ),
            const Spacer(),
            // Forward arrow
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
