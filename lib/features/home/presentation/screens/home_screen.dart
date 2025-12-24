import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/services/sound_service.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/world_view.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/monetization/presentation/widgets/ad_banner_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:confetti/confetti.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _playConfetti() {
    _confettiController.play();
    ref.read(soundServiceProvider).playCompletionSound();
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final userStatsAsync = ref.watch(userStatsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // App Bar / Header
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  floating: true,
                  title: Text(
                    'Today',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMainDark,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.person_outline),
                      onPressed: () => context.push('/profile'),
                    ),
                  ],
                ),

                // World View / Hero Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: userStatsAsync.when(
                      data: (profile) {
                        final isCity = profile.worldTheme == 'city'
                            ? true
                            : profile.worldTheme == 'forest'
                            ? false
                            : (profile.archetype == UserArchetype.creator ||
                                  profile.archetype == UserArchetype.scholar);
                        return WorldView(
                          worldState: profile.worldState,
                          isCity: isCity,
                        );
                      },
                      loading: () => const SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: EmergeColors.teal,
                          ),
                        ),
                      ),
                      error: (err, stack) => const SizedBox.shrink(),
                    ),
                  ),
                ),

                // Next Action Hero
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _NextActionHero(
                      habitsAsync: habitsAsync,
                      onComplete: _playConfetti,
                    ),
                  ),
                ),

                const SliverGap(24),

                // Timeline Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Your Timeline',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondaryDark,
                      ),
                    ),
                  ),
                ),

                const SliverGap(16),

                // Habits Timeline
                habitsAsync.when(
                  data: (habits) {
                    if (habits.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.eco_outlined,
                                  size: 48,
                                  color: AppTheme.textSecondaryDark.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                const Gap(16),
                                Text(
                                  'No habits yet. Start your journey!',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textSecondaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final habit = habits[index];
                        return _TimelineItem(
                          habit: habit,
                          isLast: index == habits.length - 1,
                        );
                      }, childCount: habits.length),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: EmergeColors.teal,
                      ),
                    ),
                  ),
                  error: (error, stack) => SliverToBoxAdapter(
                    child: AppErrorWidget(message: error.toString()),
                  ),
                ),

                const SliverGap(80), // Bottom padding for FAB
                // Ad Banner
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: AdBannerWidget(),
                  ),
                ),
              ],
            ),
          ),
          // Confetti Widget
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                EmergeColors.teal,
                EmergeColors.violet,
                EmergeColors.coral,
                EmergeColors.yellow,
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home_fab',
        onPressed: () => context.push('/create-habit'),
        label: Text(
          'New Quest',
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
}

class _NextActionHero extends ConsumerWidget {
  final AsyncValue<List<Habit>> habitsAsync;
  final VoidCallback? onComplete;

  const _NextActionHero({required this.habitsAsync, this.onComplete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return habitsAsync.when(
      data: (habits) {
        // Simple logic: Find first incomplete habit
        final nextHabit = habits.cast<Habit?>().firstWhere((h) {
          if (h == null) return false;
          final isCompletedToday =
              h.lastCompletedDate != null &&
              h.lastCompletedDate!.year == DateTime.now().year &&
              h.lastCompletedDate!.month == DateTime.now().month &&
              h.lastCompletedDate!.day == DateTime.now().day;
          return !isCompletedToday;
        }, orElse: () => null);

        if (nextHabit == null) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  EmergeColors.violet,
                  EmergeColors.violet.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: EmergeColors.violet.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Colors.white,
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Quests Complete!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Rest and recover for tomorrow.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                EmergeColors.teal,
                EmergeColors.teal.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: EmergeColors.teal.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: EmergeColors.teal.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'NEXT ACTION',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.bolt, color: Colors.white),
                ],
              ),
              const Gap(16),
              Text(
                nextHabit.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.backgroundDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (nextHabit.cue.isNotEmpty) ...[
                const Gap(16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_filled,
                        color: AppTheme.backgroundDark.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WHEN',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppTheme.backgroundDark.withValues(
                                      alpha: 0.6,
                                    ),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                            ),
                            const Gap(2),
                            Text(
                              nextHabit.cue,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.backgroundDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Gap(24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      // Mark as complete
                      await ref.read(
                        completeHabitProvider(nextHabit.id).future,
                      );
                      onComplete?.call();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Completed ${nextHabit.title}!'),
                            backgroundColor: EmergeColors.teal,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: EmergeColors.coral,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: EmergeColors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Complete Now',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: EmergeColors.teal,
                    ),
                  ),
                ),
              ),
              const Gap(12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/two-minute-timer'),
                      icon: const Icon(Icons.timer, size: 16),
                      label: const Text('2-Min Rule'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/gatekeeper'),
                      icon: const Icon(Icons.lock, size: 16),
                      label: const Text('Gatekeeper'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final Habit habit;
  final bool isLast;

  const _TimelineItem({required this.habit, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isCompletedToday =
        habit.lastCompletedDate != null &&
        habit.lastCompletedDate!.year == DateTime.now().year &&
        habit.lastCompletedDate!.month == DateTime.now().month &&
        habit.lastCompletedDate!.day == DateTime.now().day;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time/Status Column
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompletedToday
                        ? EmergeColors.teal
                        : AppTheme.surfaceDark,
                    border: Border.all(
                      color: isCompletedToday
                          ? EmergeColors.teal
                          : AppTheme.textSecondaryDark,
                      width: 2,
                    ),
                  ),
                  child: isCompletedToday
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: AppTheme.backgroundDark,
                        )
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppTheme.textSecondaryDark.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),

          // Content Column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0, right: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.textSecondaryDark.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: isCompletedToday
                            ? TextDecoration.lineThrough
                            : null,
                        color: isCompletedToday
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textMainDark,
                      ),
                    ),
                    if (habit.cue.isNotEmpty) ...[
                      const Gap(6),
                      Row(
                        children: [
                          Icon(
                            Icons.subdirectory_arrow_right,
                            size: 14,
                            color: AppTheme.textSecondaryDark.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          const Gap(4),
                          Expanded(
                            child: Text(
                              habit.cue,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textSecondaryDark,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
