import 'package:emerge_app/core/presentation/widgets/growth_background.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class RecapScreen extends ConsumerWidget {
  const RecapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final userStatsAsync = ref.watch(userStatsStreamProvider);

    return GrowthBackground(
      appBar: AppBar(
        title: const Text('Daily Recap'),
        backgroundColor: Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: habitsAsync.when(
          data: (habits) {
            // Calculate today's data
            final today = DateTime.now();
            final todayStart = DateTime(today.year, today.month, today.day);

            // Count habits completed today
            final completedToday = habits.where((habit) {
              final lastCompleted = habit.lastCompletedDate;
              if (lastCompleted == null) return false;
              return lastCompleted.isAfter(todayStart);
            }).toList();

            final totalHabits = habits.length;
            final completedCount = completedToday.length;

            // Calculate XP from user stats
            final userStats = userStatsAsync.valueOrNull;
            final totalXp = userStats?.avatarStats.totalXp ?? 0;

            // Calculate streaks for "perfect days" approximation
            final perfectDays = habits.isEmpty
                ? 0
                : habits
                      .map((h) => h.currentStreak)
                      .reduce((a, b) => a > b ? a : b);

            // Calculate daily XP estimate (13 XP per completion avg)
            final dailyXp = completedCount * 13;

            return Column(
              children: [
                _buildSummaryCard(context, completedCount, totalHabits),
                const Gap(24),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _StatBox(
                        label: 'Habits Completed',
                        value: '$completedCount / $totalHabits',
                        icon: Icons.check_circle,
                        color: EmergeColors.teal,
                      ),
                      _StatBox(
                        label: 'Current Streak',
                        value: '$perfectDays days',
                        icon: Icons.local_fire_department,
                        color: EmergeColors.coral,
                      ),
                      _StatBox(
                        label: 'XP Today',
                        value: '+$dailyXp',
                        icon: Icons.bolt,
                        color: EmergeColors.yellow,
                      ),
                      _StatBox(
                        label: 'Total XP',
                        value: '$totalXp',
                        icon: Icons.stars,
                        color: EmergeColors.violet,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: EmergeColors.teal),
          ),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: EmergeColors.coral, size: 48),
                const Gap(16),
                Text(
                  'Could not load recap',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textMainDark,
                  ),
                ),
                const Gap(8),
                Text(
                  'Please try again later',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, int completed, int total) {
    final percent = total > 0 ? (completed / total * 100).toInt() : 0;
    final message = _getSummaryMessage(percent);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EmergeColors.hexLine),
      ),
      child: Column(
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: EmergeColors.teal,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(12),
          Text(
            "You've completed $completed out of $total habits today ($percent%)",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondaryDark),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getSummaryMessage(int percent) {
    if (percent == 100) return '🎉 Perfect Day!';
    if (percent >= 75) return '🔥 Almost There!';
    if (percent >= 50) return '💪 Great Progress!';
    if (percent >= 25) return '🌱 Getting Started';
    return '✨ Time to Build!';
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const Gap(8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Gap(4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondaryDark),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
