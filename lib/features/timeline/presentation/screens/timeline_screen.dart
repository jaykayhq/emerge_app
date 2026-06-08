import 'package:emerge_app/core/presentation/widgets/glassmorphism_card.dart';
import 'package:emerge_app/core/theme/emerge_earthy_theme.dart';
import 'package:emerge_app/features/ai/domain/services/ai_personalization_service.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/dashboard_state_provider.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/habits/presentation/screens/streak_recovery_screen.dart';
import 'package:emerge_app/features/habits/presentation/widgets/miss_recovery_sheet.dart';
import 'package:emerge_app/features/insights/data/repositories/insights_repository.dart';
import 'package:emerge_app/features/insights/domain/entities/insights_entities.dart';
import 'package:emerge_app/features/monetization/domain/services/ad_manager_service.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/monetization/presentation/widgets/ad_banner_widget.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/month_calendar_strip.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/ai_coach_card.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/current_mission_banner.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/habit_timeline_section.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/timeline_share_preview.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/streak_flame_widget.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/completion_celebration.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/reflection_card.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:emerge_app/features/companion/domain/enums/companion_enums.dart';
import 'package:emerge_app/core/presentation/widgets/world_background.dart';
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/core/presentation/widgets/archetype_sliver_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:emerge_app/core/services/notification_service.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';

/// Main Timeline screen - the daily command center
/// Shows calendar, daily summary, habit timeline grouped by time-of-day,
/// AI coach insights, and daily reflection
class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _aiInsight;
  String? _suggestedHabit;
  bool _isLoadingInsight = true;
  final GlobalKey _calendarKey = GlobalKey();
  final GlobalKey _missionKey = GlobalKey();
  final GlobalKey _aiCoachKey = GlobalKey();
  bool _hasCheckedMisses = false;

  @override
  void initState() {
    super.initState();
    _loadAiInsight();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final repo = ref.read(companionRepositoryProvider);
      if (!repo.hasVisited('/timeline')) {
        repo.markVisited('/timeline');
        ref.read(companionEngineProvider.notifier).triggerEvent(
          eventType: CompanionEventType.firstFeatureVisit,
          userContext: {'route': '/timeline'},
        );
      }
    });
  }

  Future<void> _loadAiInsight() async {
    try {
      final aiService = ref.read(aiPersonalizationServiceProvider);
      final habits = ref.read(dashboardStateProvider).habits;

      if (habits.isNotEmpty) {
        final insights = await aiService.generateIdentityInsights(
          habits,
          dominantMotive: ref
              .read(userStatsStreamProvider)
              .value
              ?.dominantMotive,
        );
        if (insights.isNotEmpty && mounted) {
          setState(() {
            _aiInsight = insights.first.description;
            if (insights.length > 1) {
              _suggestedHabit = insights[1].action;
            }
            _isLoadingInsight = false;
          });
        } else if (mounted) {
          setState(() {
            _aiInsight = "Keep building consistency! Every vote counts.";
            _isLoadingInsight = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _aiInsight =
                "Create your first habit to start your identity journey!";
            _isLoadingInsight = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiInsight = "Focus on one small win today.";
          _isLoadingInsight = false;
        });
      }
    }
  }

  Map<String, List<Habit>> _groupHabitsByTimeOfDay(List<Habit> habits) {
    final groups = <String, List<Habit>>{
      'morning': [],
      'afternoon': [],
      'evening': [],
      'anytime': [],
    };

    for (final habit in habits) {
      final key = habit.timelineSection ?? 'anytime';
      groups[key]!.add(habit);
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final dashboardState = ref.watch(dashboardStateProvider);
    final habits = dashboardState.habits;
    final statsAsync = ref.watch(userStatsStreamProvider);

    ref.listen<AsyncValue<List<Habit>>>(habitsProvider, (previous, next) {
      if (next.hasValue && !_hasCheckedMisses) {
        final missed = next.value
            ?.where((h) => h.consecutiveMisses > 0)
            .toList();
        if (missed != null && missed.isNotEmpty) {
          _hasCheckedMisses = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showMissRecoverySheet(missed);
          });
        }
      }
    });

    return WorldBackground(
      useSafeArea: false,
      themeOverride: AppWorldTheme.nebula,
      child: SafeArea(
        child: habits.isNotEmpty
            ? _buildTimelineList(context, habits, statsAsync)
            : habitsAsync.when(
                data: (_) => _buildTimelineList(context, habits, statsAsync),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2BEE79)),
                ),
                error: (e, s) => _buildErrorView(context, e),
              ),
      ),
    );
  }

  Widget _buildTimelineList(
    BuildContext context,
    List<Habit> habits,
    AsyncValue<UserProfile> statsAsync,
  ) {
    final completedCount = habits.where((h) {
      final lastCompleted = h.lastCompletedDate;
      if (lastCompleted == null) return false;
      return lastCompleted.year == _selectedDate.year &&
          lastCompleted.month == _selectedDate.month &&
          lastCompleted.day == _selectedDate.day;
    }).length;

    final grouped = _groupHabitsByTimeOfDay(habits);
    final timelineGroups = Map<String, List<Habit>>.from(grouped);

    return CustomScrollView(
      slivers: [
        ArchetypeSliverAppBar(
          title: 'TIMELINE',
          syncIndicator: null,
          badge: Consumer(
            builder: (context, ref, _) {
              final isPremium = ref.watch(isPremiumProvider).value ?? false;
              if (!isPremium) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.ios_share, color: Colors.white),
              onPressed: () => _shareTimelineProgress(),
              tooltip: 'Share Progress',
            ),
            IconButton(
              icon: const Icon(Icons.analytics_outlined, color: Colors.white),
              onPressed: () => context.push('/recap'),
              tooltip: 'Weekly Recap',
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.white),
              onPressed: () => context.push('/profile'),
              tooltip: 'Future Self Studio',
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: MonthCalendarStrip(
            key: _calendarKey,
            selectedDate: _selectedDate,
            onDateSelected: (date) {
              setState(() => _selectedDate = date);
            },
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                CurrentMissionBanner(key: _missionKey),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTotalStreakWidget(habits),
                    _buildVoteIcon(habits),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  _selectedDate.day == DateTime.now().day &&
                          _selectedDate.month == DateTime.now().month &&
                          _selectedDate.year == DateTime.now().year
                      ? "Today's Timeline"
                      : "${_selectedDate.month}/${_selectedDate.day} Timeline",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '$completedCount/${habits.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: EmergeColors.tealMuted,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        SliverToBoxAdapter(
          child: HierarchicalHabitTimeline(
            groupedHabits: timelineGroups,
            selectedDate: _selectedDate,
            onHabitTap: (habit) {
              context.push('/timeline/detail/${habit.id}');
            },
            onHabitToggle: (habit) {
              _toggleHabitCompletion(habit);
            },
            onHabitDelete: (habit) {
              _deleteHabit(habit);
            },
          ),
        ),

        if (habits.isEmpty)
          SliverToBoxAdapter(
            child: GlassmorphismCard(
              glowColor: EmergeColors.teal,
              child: Column(
                children: [
                  Icon(Icons.add_task, color: EmergeColors.teal, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'No habits yet',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create your first habit to start your identity journey',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: EmergeColors.tealMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/timeline/create-habit'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Habit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EmergeColors.teal,
                      foregroundColor: EmergeColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Identity-first banner ad (premium users auto-hide)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [const AdBannerWidget(), const SizedBox(height: 16)],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        SliverToBoxAdapter(
          child: ref
              .watch(isPremiumProvider)
              .when(
                data: (isPremium) => AiCoachCard(
                  key: _aiCoachKey,
                  insight: _aiInsight,
                  suggestedHabit: _suggestedHabit,
                  isLoading: _isLoadingInsight,
                  accentColor: EmergeColors.teal,
                  isPremiumLocked: !isPremium,
                  onReflect: () => context.push('/profile/reflections'),
                  onAddHabit: () => context.push('/timeline/create-habit'),
                  onLockedTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'AI Reflections is a premium feature. Upgrade to unlock!',
                        ),
                        backgroundColor: EmergeColors.warmGold,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 3),
                        action: SnackBarAction(
                          label: 'UPGRADE',
                          textColor: Colors.black,
                          onPressed: () => context.push('/paywall'),
                        ),
                      ),
                    );
                  },
                ),
                loading: () => AiCoachCard(
                  key: _aiCoachKey,
                  insight: _aiInsight,
                  suggestedHabit: _suggestedHabit,
                  isLoading: _isLoadingInsight,
                  accentColor: EmergeColors.teal,
                  isPremiumLocked: true,
                  onReflect: () => context.push('/profile/reflections'),
                  onAddHabit: () => context.push('/timeline/create-habit'),
                  onLockedTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Loading subscription status...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                error: (_, _) => AiCoachCard(
                  key: _aiCoachKey,
                  insight: _aiInsight,
                  suggestedHabit: _suggestedHabit,
                  isLoading: _isLoadingInsight,
                  accentColor: EmergeColors.teal,
                  isPremiumLocked: false,
                  onReflect: () => context.push('/profile/reflections'),
                  onAddHabit: () => context.push('/timeline/create-habit'),
                ),
              ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        SliverToBoxAdapter(
          child: ReflectionCard(
            onLogReflection: (value, note) => _saveReflection(value, note),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Rewarded ad: Watch ad for bonus XP
        SliverToBoxAdapter(
          child: Consumer(
            builder: (context, ref, _) {
              final isPremium = ref.watch(isPremiumProvider).value ?? false;
              if (isPremium) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassmorphismCard(
                  glowColor: EmergeColors.warmGold,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: EmergeColors.warmGold.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.play_circle_outline,
                            color: EmergeColors.warmGold,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bonus XP Boost',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Watch a short ad to earn bonus XP',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ref
                                .read(adManagerProvider)
                                .showRewardedAd(
                                  onRewarded: () {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('+25 Bonus XP earned!'),
                                          backgroundColor:
                                              EmergeColors.warmGold,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  onFailed: () {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Ad not available. Try again later.',
                                          ),
                                          backgroundColor: Colors.grey,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                );
                          },
                          child: const Text(
                            'WATCH',
                            style: TextStyle(
                              color: EmergeColors.warmGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, Object e) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: EmergeColors.coral, size: 48),
          const SizedBox(height: 16),
          Text(
            'Error loading timeline',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            e.toString(),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.refresh(habitsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _toggleHabitCompletion(Habit habit) {
    final now = DateTime.now();
    final isCompleted =
        habit.lastCompletedDate != null &&
        habit.lastCompletedDate!.year == now.year &&
        habit.lastCompletedDate!.month == now.month &&
        habit.lastCompletedDate!.day == now.day;

    if (!isCompleted) {
      _completeHabitWithCelebration(habit);
    } else {
      ref.read(completeHabitProvider(habit.id));
    }
  }

  Future<void> _deleteHabit(Habit habit) async {
    try {
      final result = await ref
          .read(habitRepositoryProvider)
          .deleteHabit(habit.id);
      await ref
          .read(notificationServiceProvider)
          .cancelHabitNotifications(habit.id);
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${failure.message}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Habit deleted'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting habit'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _completeHabitWithCelebration(Habit habit) async {
    try {
      final result = await ref.read(completeHabitProvider(habit.id).future);

      if (!result.isUndo && result.wasRecovery) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StreakRecoveryScreen(
                habit: habit,
                xpEarned: result.xpEarned,
              ),
            ),
          );
        }
      } else if (!result.isUndo && result.xpEarned > 0) {
        _showCompletionCelebration(
          xpEarned: result.xpEarned,
          newStreak: result.newStreak,
          isMilestone: result.isStreakMilestone,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${habit.title} completed! +${result.xpEarned} XP'),
            backgroundColor: EmergeColors.teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }

      // Show interstitial ad after habit completion (rate-limited to 12h)
      if (!result.isUndo && mounted) {
        ref.read(adManagerProvider).showInterstitialAd();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${habit.title} completed!'),
            backgroundColor: EmergeColors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showCompletionCelebration({
    required int xpEarned,
    required int newStreak,
    required bool isMilestone,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      barrierDismissible: true,
      builder: (context) => CompletionCelebration(
        xpEarned: xpEarned,
        newStreak: newStreak,
        isStreakMilestone: isMilestone,
        accentColor: EmergeColors.teal,
        onComplete: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showMissRecoverySheet(List<Habit> missedHabits) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MissRecoverySheet(missedHabits: missedHabits),
    );
  }

  Future<void> _saveReflection(double moodValue, String? note) async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    final now = DateTime.now();
    final reflection = Reflection(
      id: const Uuid().v4(),
      date:
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      title: _getMoodTitle(moodValue),
      content: (note == null || note.isEmpty)
          ? 'Daily reflection logged'
          : note,
      type: 'daily',
      moodValue: moodValue,
      createdAt: now,
    );

    try {
      await ref
          .read(insightsRepositoryProvider)
          .saveReflection(user.id, reflection);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reflection saved!'),
            backgroundColor: EmergeColors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save reflection. Tap to retry.'),
            backgroundColor: EmergeColors.coral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getMoodTitle(double value) {
    if (value >= 0.8) return 'Feeling Great';
    if (value >= 0.6) return 'Feeling Good';
    if (value >= 0.4) return 'Feeling Okay';
    if (value >= 0.2) return 'Feeling Low';
    return 'Struggling';
  }

  Widget _buildVoteIcon(List<Habit> habits) {
    final now = DateTime.now();
    final completedToday = habits.where((h) {
      final lastCompleted = h.lastCompletedDate;
      if (lastCompleted == null) return false;
      return lastCompleted.year == now.year &&
          lastCompleted.month == now.month &&
          lastCompleted.day == now.day;
    }).length;

    return Tooltip(
      message: 'Completed Habits: $completedToday',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🗳️', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              '$completedToday',
              style: TextStyle(
                color: EmergeEarthyColors.terracotta,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalStreakWidget(List<Habit> habits) {
    int maxStreak = 0;
    for (final habit in habits) {
      if (habit.currentStreak > maxStreak) {
        maxStreak = habit.currentStreak;
      }
    }

    return Row(
      children: [
        StreakFlameWidget(
          streakCount: maxStreak,
          isActive: maxStreak > 0,
          size: 40,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              maxStreak > 0 ? 'Best Streak' : 'Start Streak',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
            Text(
              '$maxStreak days',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _shareTimelineProgress() {
    final habits = ref.read(dashboardStateProvider).habits;
    final now = DateTime.now();
    final completedToday = habits.where((h) {
      final lastCompleted = h.lastCompletedDate;
      if (lastCompleted == null) return false;
      return lastCompleted.year == now.year &&
          lastCompleted.month == now.month &&
          lastCompleted.day == now.day;
    }).toList();

    final totalStreaks = habits.fold<int>(0, (sum, h) => sum + h.currentStreak);

    final userProfileAsync = ref.read(userStatsStreamProvider);
    final userProfile = userProfileAsync.value;
    int totalVotes = 0;
    userProfile?.identityVotes.forEach((key, value) {
      totalVotes += value;
    });

    showDialog(
      context: context,
      builder: (context) => TimelineSharePreviewDialog(
        completedHabits: completedToday.length,
        totalHabits: habits.length,
        totalStreaks: totalStreaks,
        totalVotes: totalVotes,
      ),
    );
  }
}
