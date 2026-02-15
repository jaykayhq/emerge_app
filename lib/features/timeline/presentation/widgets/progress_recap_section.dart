import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Section with tabs for Progress and Recaps
/// Progress tab shows identity votes (habit completions), streaks
/// Recaps tab shows daily and weekly recap cards
class ProgressRecapSection extends StatefulWidget {
  final List<Habit> habits;
  final List<Habit> completedToday;
  final int totalVotes;

  const ProgressRecapSection({
    super.key,
    required this.habits,
    required this.completedToday,
    required this.totalVotes,
  });

  @override
  State<ProgressRecapSection> createState() => _ProgressRecapSectionState();
}

class _ProgressRecapSectionState extends State<ProgressRecapSection> {
  bool _showProgress = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _TabButton(
                label: 'Progress',
                isSelected: _showProgress,
                onTap: () => setState(() => _showProgress = true),
              ),
              const SizedBox(width: 12),
              _TabButton(
                label: 'Recaps',
                isSelected: !_showProgress,
                onTap: () => setState(() => _showProgress = false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Content
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _showProgress
              ? _buildProgressContent(context)
              : _buildRecapsContent(context),
        ),
      ],
    );
  }

  Widget _buildProgressContent(BuildContext context) {
    return Column(
      key: const ValueKey('progress'),
      children: [
        // Identity Votes card
        _buildIdentityVotesCard(context),
        const SizedBox(height: 12),
        // Streaks card
        _buildStreaksCard(context),
      ],
    );
  }

  Widget _buildIdentityVotesCard(BuildContext context) {
    // Group habits by longest streak (as a proxy for "votes")
    final habitCompletions = <String, int>{};
    for (final habit in widget.habits) {
      habitCompletions[habit.title] = habit.longestStreak;
    }
    final sortedHabits = habitCompletions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Handle empty state gracefully
    if (habitCompletions.isEmpty) {
      return _buildEmptyVotesCard(context);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmergeColors.hexLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.how_to_vote, color: EmergeColors.teal, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Identity Votes',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.textMainDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.share,
                  color: AppTheme.textSecondaryDark,
                  size: 20,
                ),
                onPressed: () {
                  // Share functionality
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total: ${widget.totalVotes} votes cast',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondaryDark),
          ),
          const SizedBox(height: 12),
          // Top habits
          ...sortedHabits
              .take(3)
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: EmergeColors.teal,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textMainDark),
                        ),
                      ),
                      Text(
                        '${entry.value}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: EmergeColors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildStreaksCard(BuildContext context) {
    // Find best streak - with safe empty state handling
    int bestStreak = 0;
    Habit? bestHabit;

    if (widget.habits.isNotEmpty) {
      // Safe reduce that won't throw on empty (already checked above)
      final streaks = widget.habits.map((h) => h.currentStreak).toList();
      bestStreak = streaks.reduce((a, b) => a > b ? a : b);

      if (bestStreak > 0) {
        // Safe firstWhere with proper orElse handling
        try {
          bestHabit = widget.habits.firstWhere(
            (h) => h.currentStreak == bestStreak,
          );
        } catch (_) {
          // Fallback to first habit if no match found
          bestHabit = widget.habits.first;
        }
      }
    }

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
          Icon(
            Icons.local_fire_department,
            color: EmergeColors.coral,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streaks',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textMainDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (bestStreak > 0 && bestHabit != null)
                  Text(
                    'Best: $bestStreak days on "${bestHabit.title}"',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryDark,
                    ),
                  )
                else
                  Text(
                    'Start your first streak today!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryDark,
                    ),
                  ),
              ],
            ),
          ),
          if (bestStreak > 0)
            Text(
              '🔥 $bestStreak',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: EmergeColors.coral,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecapsContent(BuildContext context) {
    // Calculate daily stats from completedToday
    final dailyCompleted = widget.completedToday.length;
    final dailyTotal = widget.habits.length;
    // Estimate XP based on completions (10 base + streak bonus approximation)
    final dailyXp = dailyCompleted * 13; // Rough avg with small streak bonus

    // Calculate weekly stats - sum up all completions from habit data
    // Using totalVotes as a proxy for weekly completions
    final weeklyCompleted = widget.totalVotes;
    final weeklyXp =
        weeklyCompleted * 11; // Slightly lower avg XP per completion

    return Column(
      key: const ValueKey('recaps'),
      children: [
        // Daily Recap card
        _buildRecapCard(
          context,
          icon: Icons.today,
          title: 'Daily Recap',
          subtitle: 'Today: $dailyCompleted/$dailyTotal habits • +$dailyXp XP',
          onTap: () => context.push('/profile/recap'),
        ),
        const SizedBox(height: 12),
        // Weekly Recap card
        _buildRecapCard(
          context,
          icon: Icons.date_range,
          title: 'Weekly Recap',
          subtitle: 'This week: $weeklyCompleted habits • +$weeklyXp XP',
          onTap: () => context.push('/recap'),
        ),
      ],
    );
  }

  Widget _buildRecapCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EmergeColors.hexLine),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: EmergeColors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: EmergeColors.teal, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.textMainDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textSecondaryDark),
          ],
        ),
      ),
    );
  }

  /// Empty state card for when user has no habits yet
  Widget _buildEmptyVotesCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmergeColors.hexLine),
      ),
      child: Column(
        children: [
          Icon(
            Icons.how_to_vote,
            color: AppTheme.textSecondaryDark.withValues(alpha: 0.5),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No Identity Votes Yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textMainDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first habit to start casting votes for who you want to become.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondaryDark),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.push('/timeline/create-habit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: EmergeColors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Create First Habit'),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? EmergeColors.teal
              : EmergeColors.teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected ? Colors.white : EmergeColors.teal,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
