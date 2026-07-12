import 'package:emerge_app/core/presentation/widgets/glassmorphism_card.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/dashboard_state_provider.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/habits/presentation/screens/streak_recovery_screen.dart';
import 'package:emerge_app/features/habits/presentation/widgets/miss_recovery_sheet.dart';
import 'package:emerge_app/features/monetization/domain/services/ad_manager_service.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/monetization/presentation/widgets/ad_banner_widget.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/month_calendar_strip.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/recap_summary_card.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/habit_timeline_section.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/completion_celebration.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/timeline_share_preview.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/core/presentation/widgets/world_background.dart';
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/core/presentation/widgets/archetype_sliver_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/habits/presentation/widgets/habit_timer_dialog.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/reflections/presentation/widgets/habit_options_sheet.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_note.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_milestone_card.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_summary_card.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_sheet.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_appearance.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Main daily screen - the habit command center
/// Shows calendar, daily summary, habits grouped by time-of-day,
/// and AI coach insights
class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  DateTime _selectedDate = DateTime.now();
  final GlobalKey _calendarKey = GlobalKey();
  bool _hasCheckedMisses = false;
  bool _showOverlay = false;
  NarratorLine? _pendingOverlayLine;

  static const _eveningAppearance = NarratorAppearance(
    trigger: NarratorTrigger.eveningReflection,
    shellText:
        'Evening check-in. How did your habits serve you today? Take a moment to reflect on what worked and what you\'ll adjust tomorrow.',
    buttonA: 'Log Reflection',
    buttonB: 'Skip',
    line: GenericLine(
      'Evening check-in. How did your habits serve you today? Take a moment to reflect on what worked and what you\'ll adjust tomorrow.',
    ),
  );

  @override
  void initState() {
    super.initState();
    _checkEveningReflection();
  }

  int _bestStreak(List<Habit> habits) {
    int max = 0;
    for (final h in habits) {
      if (h.currentStreak > max) max = h.currentStreak;
    }
    return max;
  }

  void _onPendingMilestoneChange(NarratorLine? prev, NarratorLine? next) {
    if (prev == null && next != null) {
      setState(() {
        _pendingOverlayLine = next;
        _showOverlay = true;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _checkEveningReflection() {
    final now = DateTime.now();
    if (now.hour < 18) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final habits = ref.read(dashboardStateProvider).habits;
      final completedToday = habits.where((h) => h.isCompletedOn(now)).length;
      final totalHabits = habits.length;

      // Only trigger if at least 1 habit completed OR all habits done,
      // per the plan: "≥1 habit completed today AND time ≥ 18:00
      // OR all habits completed (any time)"
      if (completedToday == 0 && totalHabits > 0) return;

      final prefs = await SharedPreferences.getInstance();
      final key = 'evening_reflection_${now.year}_${now.month}_${now.day}';
      final alreadyShown = prefs.getBool(key) ?? false;
      if (alreadyShown) return;

      await prefs.setBool(key, true);
      if (!mounted) return;

      NarratorSheet.show(
        context,
        _eveningAppearance,
        onResponse: (buttonLabel, typedText) {
          ref
              .read(narratorLocalDatasourceProvider)
              .recordNote(
                type: NarratorNoteType.reflectionLogged,
                data: {
                  'completedCount': completedToday,
                  'totalHabits': totalHabits,
                  'response': buttonLabel,
                  if (typedText != null && typedText.isNotEmpty)
                    'typedNote': typedText,
                },
              );
        },
      );
    });
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

    ref.listen<NarratorLine?>(
      pendingMilestoneProvider,
      _onPendingMilestoneChange,
    );

    return WorldBackground(
      useSafeArea: false,
      themeOverride: AppWorldTheme.nebula,
      child: Stack(
        children: [
          SafeArea(
            child: habits.isNotEmpty
                ? _buildTimelineList(context, habits, statsAsync)
                : habitsAsync.when(
                    data: (_) =>
                        _buildTimelineList(context, habits, statsAsync),
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2BEE79),
                      ),
                    ),
                    error: (e, s) => _buildErrorView(context, e),
                  ),
          ),
          // Floating Action Button to create new habits
          Positioned(
            right: 16,
            bottom: 16 + MediaQuery.paddingOf(context).bottom,
            child: FloatingActionButton.extended(
              heroTag: 'timeline_create_habit',
              backgroundColor: EmergeColors.teal,
              onPressed: () => context.push('/timeline/create-habit'),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Log Habit',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Milestone slide-up overlay
          if (_showOverlay && _pendingOverlayLine != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 100 + MediaQuery.paddingOf(context).bottom,
              child: NarratorMilestoneCard(
                line: _pendingOverlayLine!,
                trigger: NarratorTrigger.askNarrator,
                onDismissed: () {
                  setState(() {
                    _showOverlay = false;
                    _pendingOverlayLine = null;
                  });
                  ref.read(pendingMilestoneProvider.notifier).clear();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineList(
    BuildContext context,
    List<Habit> habits,
    AsyncValue<UserProfile> statsAsync,
  ) {
    final completedCount = habits
        .where((h) => h.isCompletedOn(_selectedDate))
        .length;

    final grouped = _groupHabitsByTimeOfDay(habits);
    final timelineGroups = Map<String, List<Habit>>.from(grouped);

    return CustomScrollView(
      slivers: [
        ArchetypeSliverAppBar(
          title: 'Today',
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
            // Polished profile icon
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [EmergeColors.violet, EmergeColors.teal],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: EmergeColors.violet.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
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
            child: RecapSummaryCard(
              habits: habits,
              streak: _bestStreak(habits),
              totalXp: statsAsync.value?.avatarStats.totalXp ?? 0,
              onTap: () => context.push('/world-map/recap'),
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
                      ? "Today's Habits"
                      : "${_selectedDate.month}/${_selectedDate.day}",
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
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Share progress',
                  child: GestureDetector(
                    onTap: _shareTimelineProgress,
                    child: Icon(
                      Icons.share_outlined,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 18,
                    ),
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
              context.go('/world-map', extra: habit.attribute.name);
            },
            onHabitToggle: (habit) {
              _toggleHabitCompletion(habit);
            },
            onTimerTap: (habit) {
              _openTimerDialog(habit);
            },
            onMenuTap: (habit) {
              HabitOptionsSheet.show(context, habit, _selectedDate);
            },
          ),
        ),

        if (habits.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: _BreathingWrapper(
                child: GlassmorphismCard(
                  glowColor: EmergeColors.teal,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
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
                          'Create your first habit to start your identity journey',
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

        const SliverToBoxAdapter(child: NarratorSummaryCard()),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
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

  Future<void> _toggleHabitCompletion(Habit habit) async {
    final now = DateTime.now();
    final isCompleted = habit.isCompletedOn(now);

    if (isCompleted) {
      // Undo completion — completeHabitProvider is a toggle that returns
      // isUndo:true when the habit was already completed today.
      await ref.read(completeHabitProvider(habit.id).future);
      return;
    }

    // One-tap completion - no confirmation dialog
    _completeHabitSilently(habit);
  }

  Future<void> _openTimerDialog(Habit habit) async {
    final minutes = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (_) => HabitTimerDialog(
        habitTitle: habit.title,
        neonColor: attributeColor(habit.attribute),
        durationMinutes: habit.timerDurationMinutes,
        onComplete: () {
          _toggleHabitCompletion(habit);
          Navigator.of(context).pop();
        },
      ),
    );
    if (minutes != null && minutes > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${habit.title}: timer set for ${minutes}m'),
          backgroundColor: EmergeColors.teal,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _completeHabitSilently(Habit habit) async {
    try {
      final result = await ref.read(completeHabitProvider(habit.id).future);

      if (!result.isUndo && mounted) {
        // Show milestone celebration for streak milestones
        if (result.isStreakMilestone) {
          _showCompletionCelebration(
            xpEarned: result.xpEarned,
            newStreak: result.newStreak,
            isMilestone: true,
          );
        } else if (result.wasRecovery) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  StreakRecoveryScreen(habit: habit, xpEarned: result.xpEarned),
            ),
          );
        }
        // Otherwise: silent completion — particles provide visual feedback

        // Show interstitial ad after habit completion (rate-limited to 12h)
        ref.read(adManagerProvider).showInterstitialAd();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save. Check your connection and try again.',
            ),
            backgroundColor: Colors.orange,
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

  void _shareTimelineProgress() {
    final habits = ref.read(dashboardStateProvider).habits;
    final now = DateTime.now();
    final completedToday = habits.where((h) => h.isCompletedOn(now)).toList();

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

class _BreathingWrapper extends StatefulWidget {
  final Widget child;

  const _BreathingWrapper({required this.child});

  @override
  State<_BreathingWrapper> createState() => _BreathingWrapperState();
}

class _BreathingWrapperState extends State<_BreathingWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  late final Animation<double> _scaleAnimation = Tween<double>(
    begin: 0.98,
    end: 1.02,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scaleAnimation, child: widget.child);
  }
}
