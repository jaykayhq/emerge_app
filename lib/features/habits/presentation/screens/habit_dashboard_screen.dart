import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/presentation/widgets/responsive_layout.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/utils/app_toast.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';

import 'package:emerge_app/features/gamification/presentation/widgets/gamification_world_section.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/habits/presentation/widgets/onboarding_milestone_card.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/monetization/presentation/widgets/ad_banner_widget.dart';
import 'package:emerge_app/features/onboarding/domain/entities/onboarding_milestone.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class HabitDashboardScreen extends ConsumerWidget {
  const HabitDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Today',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textMainDark,
          ),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Gamification World View
          const GamificationWorldSection(),
          // AI Tools Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: _AiToolCard(
                    title: 'Goldilocks',
                    icon: Icons.auto_awesome,
                    color: EmergeColors.yellow,
                    onTap: () => context.push('/profile/goldilocks'),
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: _AiToolCard(
                    title: 'Reflections',
                    icon: Icons.psychology,
                    color: EmergeColors.violet,
                    onTap: () => context.push('/profile/reflections'),
                  ),
                ),
              ],
            ),
          ),
          const Gap(8),
          Expanded(
            child: habitsAsync.when(
              data: (habits) {
                // Watch for active onboarding milestones
                final milestones = ref.watch(activeMilestonesProvider);
                final hasMilestones = milestones.isNotEmpty;

                // If no habits and no milestones, show empty state
                if (habits.isEmpty && !hasMilestones) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.eco_outlined,
                          size: 64,
                          color: EmergeColors.teal,
                        ),
                        const Gap(16),
                        Text(
                          'No habits yet',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppTheme.textMainDark,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          'Start by adding a new habit',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Build list with milestones at top
                return ResponsiveLayout(
                  mobile: _buildMobileList(milestones, habits, ref),
                  tablet: _buildTabletGrid(milestones, habits, ref),
                  desktop: _buildDesktopGrid(milestones, habits, ref),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: EmergeColors.teal),
              ),
              error: (error, stack) => AppErrorWidget(
                message: error.toString(),
                onRetry: () => ref.refresh(habitsProvider),
              ),
            ),
          ),
          const AdBannerWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'habit_dashboard_fab',
        onPressed: () {
          // Check limits before navigating
          final isPremium = ref.read(isPremiumProvider).valueOrNull ?? false;
          final habitCount = habitsAsync.valueOrNull?.length ?? 0;

          if (!isPremium && habitCount >= 3) {
            context.push('/paywall');
          } else {
            context.push('/create-habit');
          }
        },
        label: Text(
          'New Habit',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: EmergeColors.coral,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Builds mobile list with milestones at top
  Widget _buildMobileList(
    List<OnboardingMilestone> milestones,
    List<Habit> habits,
    WidgetRef ref,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: milestones.length + habits.length,
      itemBuilder: (context, index) {
        // Render milestones first
        if (index < milestones.length) {
          final milestone = milestones[index];
          return OnboardingMilestoneCard(
            key: ValueKey('milestone_${milestone.order}'),
            milestone: milestone,
            onSkip: () async {
              await ref
                  .read(onboardingControllerProvider.notifier)
                  .skipMilestone(milestone.order - 1);
            },
          );
        }
        // Then render habits
        final habitIndex = index - milestones.length;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: _HabitCard(habit: habits[habitIndex]),
        );
      },
    );
  }

  /// Builds tablet grid with milestones spanning full width at top
  Widget _buildTabletGrid(
    List<OnboardingMilestone> milestones,
    List<Habit> habits,
    WidgetRef ref,
  ) {
    return CustomScrollView(
      slivers: [
        // Milestones section (if any)
        if (milestones.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return OnboardingMilestoneCard(
                  key: ValueKey('milestone_${milestones[index].order}'),
                  milestone: milestones[index],
                  onSkip: () async {
                    await ref
                        .read(onboardingControllerProvider.notifier)
                        .skipMilestone(milestones[index].order - 1);
                  },
                );
              }, childCount: milestones.length),
            ),
          ),

        // Habits grid
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 3,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              return _HabitCard(habit: habits[index]);
            }, childCount: habits.length),
          ),
        ),
      ],
    );
  }

  /// Builds desktop grid with milestones spanning full width at top
  Widget _buildDesktopGrid(
    List<OnboardingMilestone> milestones,
    List<Habit> habits,
    WidgetRef ref,
  ) {
    return CustomScrollView(
      slivers: [
        // Milestones section (if any)
        if (milestones.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return OnboardingMilestoneCard(
                  key: ValueKey('milestone_${milestones[index].order}'),
                  milestone: milestones[index],
                  onSkip: () async {
                    await ref
                        .read(onboardingControllerProvider.notifier)
                        .skipMilestone(milestones[index].order - 1);
                  },
                );
              }, childCount: milestones.length),
            ),
          ),

        // Habits grid
        SliverPadding(
          padding: const EdgeInsets.all(32),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 2.5,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              return _HabitCard(habit: habits[index]);
            }, childCount: habits.length),
          ),
        ),
      ],
    );
  }
}

class _HabitCard extends ConsumerWidget {
  final Habit habit;

  const _HabitCard({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCompletedToday =
        habit.lastCompletedDate != null &&
        habit.lastCompletedDate!.year == DateTime.now().year &&
        habit.lastCompletedDate!.month == DateTime.now().month &&
        habit.lastCompletedDate!.day == DateTime.now().day;

    return Card(
      margin: ResponsiveLayout.isMobile(context)
          ? const EdgeInsets.only(bottom: 12)
          : EdgeInsets.zero,
      elevation: 2,
      color: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: EmergeColors.hexLine),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Checkbox / Status
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCompletedToday
                    ? EmergeColors.teal.withValues(alpha: 0.2)
                    : EmergeColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCompletedToday
                      ? EmergeColors.teal
                      : AppTheme.textSecondaryDark.withValues(alpha: 0.5),
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.check,
                  color: isCompletedToday
                      ? EmergeColors.teal
                      : AppTheme.textSecondaryDark,
                ),
                onPressed: () {
                  ref.read(completeHabitProvider(habit.id));
                  if (!isCompletedToday) {
                    AppToast.show(
                      context,
                      'Habit completed! Keep it up!',
                      type: ToastType.success,
                    );
                  }
                },
              ),
            ),
            const Gap(16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    habit.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: isCompletedToday
                          ? TextDecoration.lineThrough
                          : null,
                      color: isCompletedToday
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textMainDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (habit.cue.isNotEmpty) ...[
                    const Gap(4),
                    Text(
                      habit.cue,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Streak
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: EmergeColors.coral,
                  size: 20,
                ),
                Text(
                  '${habit.currentStreak}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: EmergeColors.coral,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AiToolCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AiToolCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const Gap(8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
