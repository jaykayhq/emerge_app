import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/presentation/widgets/glassmorphism_card.dart';
import 'package:emerge_app/core/theme/emerge_earthy_theme.dart';
import 'package:emerge_app/features/ai/domain/services/ai_personalization_service.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/domain/services/gamification_service.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/insights/data/repositories/insights_repository.dart';
import 'package:emerge_app/features/insights/domain/entities/insights_entities.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/week_calendar_strip.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/ai_coach_card.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/current_mission_banner.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/habit_timeline_section.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/timeline_share_preview.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/streak_flame_widget.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/completion_celebration.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/reflection_card.dart';
import 'package:emerge_app/features/tutorial/presentation/providers/tutorial_provider.dart';
import 'package:emerge_app/features/tutorial/presentation/widgets/tutorial_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

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

  @override
  void initState() {
    super.initState();
    _loadAiInsight();
    _checkTutorial();
  }

  void _checkTutorial() {
    // Add delay to ensure screen has fully settled and navigation is complete
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final tutorialNotifier = ref.read(tutorialProvider.notifier);
        final tutorialState = ref.watch(tutorialProvider);
        // Re-enable auto-show when entering this screen (for one-time show per visit)
        tutorialNotifier.enableTutorialAutoShow();

        // Only show tutorial if not completed AND tutorials are enabled AND auto-show is active
        if (!tutorialState.isCompleted(TutorialStep.timeline) &&
            tutorialNotifier.shouldShowTutorial()) {
          _showTutorial();
        }
      });
    });
  }

  void _showTutorial() {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => TutorialOverlay(
        steps: [
          const TutorialStepInfo(
            title: 'Your Command Center',
            description:
                'This is your daily protocol. Everything you do here is a vote for who you want to become.',
          ),
          TutorialStepInfo(
            title: 'Identity Momentum',
            description:
                'Track your consistency across the week. Green dots represent days you kept your promises.',
            targetKey: _calendarKey,
          ),
          TutorialStepInfo(
            title: 'Current Mission',
            description:
                'Your progress in the World Map. Complete your focus habits to unlock new lands.',
            targetKey: _missionKey,
          ),
          TutorialStepInfo(
            title: 'AI Architect',
            description:
                'Our AI analyzes your behavior to provide hyper-personalized insights and habit suggestions.',
            targetKey: _aiCoachKey,
            alignment: Alignment.topCenter,
          ),
        ],
        onCompleted: () {
          ref
              .read(tutorialProvider.notifier)
              .completeStep(TutorialStep.timeline);
          entry.remove();
        },
      ),
    );
    Overlay.of(context).insert(entry);
  }

  Future<void> _loadAiInsight() async {
    try {
      final aiService = ref.read(aiPersonalizationServiceProvider);
      final habits = ref.read(habitsProvider).value ?? [];

      if (habits.isNotEmpty) {
        final insights = await aiService.generateIdentityInsights(habits);
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

  /// Group habits by time-of-day preference
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: habitsAsync.when(
          data: (habits) {
            // Calculate completed today
            final completedToday = habits.where((h) {
              final lastCompleted = h.lastCompletedDate;
              if (lastCompleted == null) return false;
              return lastCompleted.year == _selectedDate.year &&
                  lastCompleted.month == _selectedDate.month &&
                  lastCompleted.day == _selectedDate.day;
            }).toList();

            // Group habits by time of day (exclude 'anytime' from hierarchical timeline)
            final grouped = _groupHabitsByTimeOfDay(habits);
            // Remove 'anytime' key - those habits won't show in timeline
            final timelineGroups = Map<String, List<Habit>>.from(grouped);
            timelineGroups.remove('anytime');

            return CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  floating: true,
                  backgroundColor: Colors.transparent,
                  title: Column(
                    children: [
                      Text(
                        'TIMELINE',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'IDENTITY PROTOCOL',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: EmergeColors.teal,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.ios_share, color: Colors.white),
                      onPressed: () => _shareTimelineProgress(),
                      tooltip: 'Share Progress',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.analytics_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () => context.push('/recap'),
                      tooltip: 'Weekly Recap',
                    ),
                  ],
                ),

                // Calendar Strip
                SliverToBoxAdapter(
                  child: WeekCalendarStrip(
                    key: _calendarKey,
                    selectedDate: _selectedDate,
                    onDateSelected: (date) {
                      setState(() => _selectedDate = date);
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Current World Map Mission & Icons
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _buildVoteIcon(habits),
                                const SizedBox(width: 12),
                                _buildStreakIcon(habits),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Section header for habit timeline
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Spacer(),
                        Text(
                          '${completedToday.length}/${habits.length}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: EmergeColors.tealMuted),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // Habit Timeline - Hierarchical display with category anchors
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
                  ),
                ),

                // Empty state if no habits
                if (habits.isEmpty)
                  SliverToBoxAdapter(
                    child: GlassmorphismCard(
                      glowColor: EmergeColors.teal,
                      child: Column(
                        children: [
                          Icon(
                            Icons.add_task,
                            color: EmergeColors.teal,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No habits yet',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create your first habit to start building your identity',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: EmergeColors.tealMuted),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () =>
                                context.push('/timeline/create-habit'),
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

                // AI Coach Card
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
                          isPremiumLocked: !isPremium, // Unlocked when premium
                          onAddHabit: () =>
                              context.push('/timeline/create-habit'),
                          onLockedTap: () {
                            // Show premium message when locked Reflect button is tapped
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
                                  onPressed: () =>
                                      context.push('/profile/paywall'),
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
                          isPremiumLocked:
                              true, // Default to locked while loading
                          onAddHabit: () =>
                              context.push('/timeline/create-habit'),
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
                          isPremiumLocked: false, // Unlock on error
                          onAddHabit: () =>
                              context.push('/timeline/create-habit'),
                        ),
                      ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Reflection Card
                SliverToBoxAdapter(
                  child: ReflectionCard(
                    onLogReflection: (value, note) =>
                        _saveReflection(value, note),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF2BEE79)),
          ),
          error: (e, s) => Center(
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
                TextButton(
                  onPressed: () => ref.invalidate(habitsProvider),
                  child: Text(
                    'Retry',
                    style: TextStyle(color: EmergeColors.teal),
                  ),
                ),
              ],
            ),
          ),
        ),
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

  Future<void> _completeHabitWithCelebration(Habit habit) async {
    try {
      final result = await ref.read(completeHabitProvider(habit.id).future);

      if (!result.isUndo && result.xpEarned > 0) {
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
    // Count completed habits for today (NEW: reversed functionality)
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
      child: Semantics(
        button: true,
        label: 'Completed Habits: $completedToday',
        child: GestureDetector(
          onTap: () => _showDetailBottomSheet(context, 'completed', habits),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: EmergeEarthyColors.terracotta.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: EmergeEarthyColors.terracotta.withValues(alpha: 0.5),
              ),
            ),
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
        ),
      ),
    );
  }

  Widget _buildTotalStreakWidget(List<Habit> habits) {
    // Calculate the best streak across all habits
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

  Widget _buildStreakIcon(List<Habit> habits) {
    // Total created habits count (NEW: reversed functionality)
    final totalCreated = habits.length;

    return Tooltip(
      message: 'Created Habits: $totalCreated',
      child: Semantics(
        button: true,
        label: 'Created Habits: $totalCreated',
        child: GestureDetector(
          onTap: () => _showDetailBottomSheet(context, 'created', habits),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: EmergeEarthyColors.sienna.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: EmergeEarthyColors.sienna.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  '$totalCreated',
                  style: TextStyle(
                    color: EmergeEarthyColors.sienna,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _shareTimelineProgress() {
    final habits = ref.read(habitsProvider).value ?? [];
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

  IconData _getAttributeIcon(HabitAttribute attribute) {
    switch (attribute) {
      case HabitAttribute.vitality:
        return Icons.favorite;
      case HabitAttribute.intellect:
        return Icons.menu_book;
      case HabitAttribute.creativity:
        return Icons.palette;
      case HabitAttribute.focus:
        return Icons.center_focus_strong;
      case HabitAttribute.strength:
        return Icons.fitness_center;
      case HabitAttribute.spirit:
        return Icons.auto_awesome;
    }
  }

  void _showDetailBottomSheet(
    BuildContext context,
    String metricType,
    List<Habit> habits,
  ) {
    final isCompleted = metricType == 'completed';
    final primaryColor = isCompleted
        ? EmergeEarthyColors.terracotta
        : EmergeEarthyColors.sienna;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: EmergeEarthyColors.baseBackground.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: primaryColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Text(
              isCompleted ? 'Completed Habits' : 'Created Habits',
              style: TextStyle(
                color: primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCompleted ? 'Habits completed today' : 'Total active habits',
              style: TextStyle(
                color: EmergeEarthyColors.cream.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 24),

            // Content
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: habits.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final habit = habits[index];
                  final attrColor =
                      EmergeEarthyColors.attributeColors[habit.attribute] ??
                      primaryColor;
                  final gamificationService = GamificationService();
                  final xp = gamificationService.calculateXpGain(habit);

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: attrColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: attrColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getAttributeIcon(habit.attribute),
                          size: 28,
                          color: attrColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: attrColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      habit.attribute.name.toUpperCase(),
                                      style: TextStyle(
                                        color: attrColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (habit.currentStreak > 0) ...[
                                    const SizedBox(width: 8),
                                    Row(
                                      children: [
                                        const Text(
                                          '🔥',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${habit.currentStreak} day streak',
                                          style: TextStyle(
                                            color: EmergeEarthyColors.cream
                                                .withValues(alpha: 0.7),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '+$xp',
                              style: TextStyle(
                                color: attrColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'XP',
                              style: TextStyle(
                                color: attrColor.withValues(alpha: 0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Close button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '✕ CLOSE',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
