import 'package:emerge_app/core/presentation/widgets/glassmorphism_card.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';

/// A compact "RECAP" card sitting between the calendar strip and the habit
/// list on the timeline. Tapping navigates to the full recap screen.
///
/// Emphasizes real completed-habit counts: today's completions vs total,
/// this week's completions, and the best current streak.
class RecapSummaryCard extends StatelessWidget {
  final List<Habit> habits;
  final int streak;
  final VoidCallback onTap;

  const RecapSummaryCard({
    super.key,
    required this.habits,
    required this.streak,
    required this.onTap,
  });

  /// Number of habits completed at least once today.
  int _todayCompletions() {
    final now = DateTime.now();
    return habits.where((h) => h.isCompletedOn(now)).length;
  }

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
    final today = _todayCompletions();
    final weekly = _weeklyCompletions();

    return Semantics(
      label: 'Open weekly recap',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: EmergeGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RECAP',
                style: TextStyle(
                  color: EmergeColors.tealMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatItem(
                    value: '$today/${habits.length}',
                    label: 'today done',
                    color: EmergeColors.teal,
                  ),
                  const SizedBox(width: 24),
                  _StatItem(
                    value: '$weekly',
                    label: 'this week',
                    color: EmergeColors.neonGreenBright,
                  ),
                  const SizedBox(width: 24),
                  _StatItem(
                    value: '$streak',
                    label: 'day streak',
                    color: const Color(0xFFFFB74D),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
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
