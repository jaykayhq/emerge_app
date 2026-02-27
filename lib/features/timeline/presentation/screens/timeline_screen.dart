import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/presentation/widgets/glassmorphism_card.dart';
import 'package:emerge_app/features/ai/domain/services/ai_personalization_service.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/insights/data/repositories/insights_repository.dart';
import 'package:emerge_app/features/insights/domain/entities/insights_entities.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/week_calendar_strip.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/daily_summary_card.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/ai_coach_card.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/current_mission_banner.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/habit_timeline_section.dart';
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
  final GlobalKey _summaryKey = GlobalKey();
  final GlobalKey _missionKey = GlobalKey();
  final GlobalKey _aiCoachKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadAiInsight();
    _checkTutorial();
  }

  void _checkTutorial() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tutorialState = ref.read(tutorialProvider);
      if (!tutorialState.isCompleted(TutorialStep.timeline)) {
        _showTutorial();
      }
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
            title: 'Daily Summary',
            description: 'See your XP gains and current streaks at a glance.',
            targetKey: _summaryKey,
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
      final habits = ref.read(habitsProvider).valueOrNull ?? [];

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
      final key = habit.timeOfDayPreference?.name ?? 'anytime';
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
            final now = DateTime.now();
            final completedToday = habits.where((h) {
              final lastCompleted = h.lastCompletedDate;
              if (lastCompleted == null) return false;
              return lastCompleted.year == now.year &&
                  lastCompleted.month == now.month &&
                  lastCompleted.day == now.day;
            }).toList();

            // Calculate total XP today
            final xpToday = completedToday.fold<int>(
              0,
              (sum, h) => sum + _calculateXp(h),
            );

            // Calculate best streak
            final bestStreak = habits.isEmpty
                ? 0
                : habits
                      .map((h) => h.currentStreak)
                      .reduce((a, b) => a > b ? a : b);

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

                // Current World Map Mission
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: CurrentMissionBanner(
                      key: _missionKey,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Daily Summary Card (glassmorphism)
                SliverToBoxAdapter(
                  child: DailySummaryCard(
                    key: _summaryKey,
                    completedHabits: completedToday.length,
                    totalHabits: habits.length,
                    xpToday: xpToday,
                    currentStreak: bestStreak,
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
                          "Today's Timeline",
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

                // AI Coach Card
                SliverToBoxAdapter(
                  child: ref.watch(isPremiumProvider).when(
                    data: (isPremium) => AiCoachCard(
                      key: _aiCoachKey,
                      insight: _aiInsight,
                      suggestedHabit: _suggestedHabit,
                      isLoading: _isLoadingInsight,
                      accentColor: EmergeColors.teal,
                      isPremiumLocked: !isPremium, // Unlocked when premium
                      onAddHabit: () => context.push('/timeline/create-habit'),
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
                              onPressed: () => context.push('/profile/paywall'),
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
                      isPremiumLocked: true, // Default to locked while loading
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
                    error: (_, __) => AiCoachCard(
                      key: _aiCoachKey,
                      insight: _aiInsight,
                      suggestedHabit: _suggestedHabit,
                      isLoading: _isLoadingInsight,
                      accentColor: EmergeColors.teal,
                      isPremiumLocked: false, // Unlock on error
                      onAddHabit: () => context.push('/timeline/create-habit'),
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
      // Mark as completed
      ref.read(completeHabitProvider(habit.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${habit.title} completed! +${_calculateXp(habit)} XP'),
          backgroundColor: EmergeColors.teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Undo completion
      ref.read(completeHabitProvider(habit.id));
    }
  }

  int _calculateXp(dynamic habit) {
    int base = 10;
    if (habit.difficulty.toString().contains('medium')) {
      base = 20;
    } else if (habit.difficulty.toString().contains('hard')) {
      base = 30;
    }
    final streakBonus = (habit.currentStreak * 0.1).clamp(0.0, 0.5);
    return (base * (1 + streakBonus)).toInt();
  }

  Future<void> _saveReflection(double moodValue, String? note) async {
    final user = ref.read(authStateChangesProvider).valueOrNull;
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
}
