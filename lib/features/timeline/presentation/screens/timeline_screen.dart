import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/presentation/widgets/glassmorphism_card.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/dashboard_state_provider.dart';
import 'package:emerge_app/features/timeline/presentation/providers/goal_gradient_helpers.dart';
import 'package:emerge_app/features/timeline/presentation/providers/goal_gradient_providers.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/habits/presentation/screens/streak_recovery_screen.dart';
import 'package:emerge_app/features/habits/presentation/widgets/miss_recovery_sheet.dart';
import 'package:emerge_app/features/monetization/domain/services/ad_manager_service.dart';
import 'package:emerge_app/features/monetization/presentation/widgets/ad_banner_widget.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/month_calendar_strip.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/recap_summary_card.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/habit_timeline_section.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/completion_celebration.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/all_done_celebration.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/tribal_presence_strip.dart';
import 'package:emerge_app/features/timeline/presentation/providers/last_habit_completed_provider.dart';
import 'package:emerge_app/features/timeline/presentation/providers/month_completion_provider.dart';
import 'package:emerge_app/features/timeline/domain/models/day_completion.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/timeline_share_preview.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/core/presentation/widgets/world_background.dart';
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/habits/presentation/widgets/habit_timer_dialog.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/reflections/presentation/widgets/habit_options_sheet.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_note.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_card.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_guide_host.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_milestone_card.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_avatar.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/domain/services/narrator_open_evaluator.dart';
import 'package:emerge_app/features/narrator/domain/services/narrator_trigger_engine.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
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
  bool _hasEvaluatedOpen = false;
  bool _showOverlay = false;
  PendingMilestoneLine? _pendingOverlayLine;
  final GlobalKey<AllDoneCelebrationState> _celebrationKey =
      GlobalKey<AllDoneCelebrationState>();
  final GlobalKey _fabGuideKey = GlobalKey();
  final GlobalKey _ringGuideKey = GlobalKey();
  final GlobalKey _cardGuideKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkEveningReflection();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _evaluateNarratorOnOpen(),
    );
  }

  /// Ambient narrator evaluation on timeline open: computes the trigger via
  /// the pure [NarratorOpenEvaluator] (long absence, morning brief, streak
  /// break — with cooldowns) and surfaces the resolved line as a pending
  /// milestone. Runs once per screen mount; also persists app-open metadata
  /// (installed-at, last-open, recent triggers) for the cooldown logic.
  Future<void> _evaluateNarratorOnOpen() async {
    if (_hasEvaluatedOpen || !mounted) return;
    _hasEvaluatedOpen = true;

    final repo = ref.read(localSettingsRepositoryProvider);
    final now = DateTime.now();
    var installedAt = repo.getAppInstalledAt();
    if (installedAt == null) {
      await repo.setAppInstalledAt(now);
      installedAt = now;
    }
    final lastOpen = repo.getLastAppOpen();
    final recent = await repo.getRecentNarratorTriggers();

    final profile = ref.read(userStatsStreamProvider).value;
    final todayHabits = ref
        .read(dashboardStateProvider)
        .habits
        .where((h) => h.isActiveOnDay(now))
        .toList();
    final bestStreak = todayHabits.fold<int>(
      0,
      (max, h) => h.currentStreak > max ? h.currentStreak : max,
    );
    final misses = todayHabits.fold<int>(
      0,
      (max, h) => h.consecutiveMisses > max ? h.consecutiveMisses : max,
    );

    final input = NarratorOpenInput(
      now: now,
      installedAt: installedAt,
      lastOpenAt: lastOpen,
      momentumScore: ((profile?.avatarStats.momentumScore ?? 0) / 100).clamp(
        0.0,
        1.0,
      ),
      consecutiveActiveDays: 0, // not exposed on the profile
      currentStreak: bestStreak,
      longestStreak: bestStreak,
      consecutiveMisses: misses,
      hasCompletedOnboarding: true,
      archetypeSelected: profile?.archetype != UserArchetype.none,
      recentTriggers: recent,
    );
    await repo.setLastAppOpen(now);

    final trigger = NarratorOpenEvaluator.evaluate(input);
    if (trigger == null || !mounted) return;

    final resolver = ref.read(lineResolverProvider);
    final line = await resolver.resolve(
      trigger: trigger,
      stats: NarratorUserStats(
        momentumScore: input.momentumScore,
        consecutiveActiveDays: 0,
        totalHabitsToday: todayHabits.length,
        completedHabitsToday: todayHabits
            .where((h) => h.isCompletedOn(now))
            .length,
        currentLevel: profile?.avatarStats.level ?? 1,
        previousLevel: profile?.avatarStats.level ?? 1,
        hasStreakBreak: misses > 0,
        currentStreak: bestStreak,
        longestStreak: bestStreak,
        consecutiveMisses: misses,
        hasCompletedEveningReflectionToday: true,
        hasCompletedOnboarding: true,
        archetypeSelected: profile?.archetype != UserArchetype.none,
      ),
    );
    if (!mounted) return;
    ref
        .read(pendingMilestoneProvider.notifier)
        .set(PendingMilestoneLine(line: line, trigger: trigger));
    await repo.recordNarratorTrigger(trigger, now);
  }

  int _bestStreak(List<Habit> habits) {
    int max = 0;
    for (final h in habits) {
      if (h.currentStreak > max) max = h.currentStreak;
    }
    return max;
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  void _onPendingMilestoneChange(
    PendingMilestoneLine? prev,
    PendingMilestoneLine? next,
  ) {
    if (prev == null && next != null) {
      setState(() {
        _pendingOverlayLine = next;
        _showOverlay = true;
      });
    }
  }

  void _dismissMilestone() {
    setState(() {
      _showOverlay = false;
      _pendingOverlayLine = null;
    });
    ref.read(pendingMilestoneProvider.notifier).clear();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Goal Gradient Effect: completion-ring color.
  /// green ≥80%, amber 50–79%, coral below 50%.
  Color _ringColor(double fraction) => Color(ringColorValue(fraction));

  void _checkEveningReflection() {
    final now = DateTime.now();
    if (now.hour < 18) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final habits = ref
          .read(dashboardStateProvider)
          .habits
          .where((h) => h.isActiveOnDay(now))
          .toList();
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

      ref
          .read(pendingMilestoneProvider.notifier)
          .set(
            PendingMilestoneLine(
              line: const GenericLine(
                'Evening check-in. How did your habits serve you today? Take a moment to reflect on what worked and what you\'ll adjust tomorrow.',
              ),
              trigger: NarratorTrigger.eveningReflection,
            ),
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
    // Use habitsAsync (Drift-backed stream) as the primary source so the
    // timeline renders immediately on first build.  dashboardState.habits
    // is populated via a listener/microtask and may still be [] on the
    // initial frame even though habitsAsync already has data.
    final allHabits = habitsAsync.value ?? dashboardState.habits;
    final habits = allHabits
        .where((h) => h.isActiveOnDay(_selectedDate))
        .toList();
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

    ref.listen<PendingMilestoneLine?>(
      pendingMilestoneProvider,
      _onPendingMilestoneChange,
    );

    // Peak-End: fire the all-done celebration when the last habit completes.
    ref.listen<bool>(lastHabitCompletedProvider, (_, next) {
      if (next) {
        _celebrationKey.currentState?.show();
      }
    });

    return NarratorGuideHost(
      nodeId: 'timeline',
      targets: {
        'fab': _fabGuideKey,
        'ring': _ringGuideKey,
        'card': _cardGuideKey,
      },
      child: WorldBackground(
        useSafeArea: false,
        themeOverride: AppWorldTheme.nebula,
        child: Stack(
          children: [
            SafeArea(
              child: habits.isNotEmpty
                  ? _buildTimelineList(context, habits, statsAsync)
                  : habitsAsync.when(
                      data: (_) => _buildEmptyTimeline(
                        context: context,
                        onCreateHabit: () =>
                            context.push('/timeline/create-habit'),
                      ),
                      loading: () => const EmergeLoadingSkeleton(
                        itemCount: 3,
                        itemHeight: 100,
                      ),
                      error: (e, s) => _buildErrorView(context),
                    ),
            ),
            // Floating Action Button to create new habits.
            // Goal Gradient Effect: a progress ring wraps the FAB showing
            // today's completion fraction (green ≥80%, amber 50–79%, coral
            // below 50%). The FAB stays circular so the ring reads cleanly.
            Positioned(
              right: 16,
              bottom: 16 + MediaQuery.paddingOf(context).bottom,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  KeyedSubtree(
                    key: _ringGuideKey,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final fraction = ref.watch(completionFractionProvider);
                        return SizedBox(
                          width: 64,
                          height: 64,
                          child: CircularProgressIndicator(
                            value: fraction,
                            strokeWidth: 3,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _ringColor(fraction),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  KeyedSubtree(
                    key: _fabGuideKey,
                    child: FloatingActionButton(
                      heroTag: 'timeline_create_habit',
                      backgroundColor: EmergeColors.teal,
                      tooltip: 'Log Habit',
                      onPressed: () => context.push('/timeline/create-habit'),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            // Milestone slide-up overlay
            if (_showOverlay && _pendingOverlayLine != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 100 + MediaQuery.paddingOf(context).bottom,
                child: NarratorMilestoneCard(
                  line: _pendingOverlayLine!.line,
                  trigger: _pendingOverlayLine!.trigger,
                  actions:
                      _pendingOverlayLine!.trigger ==
                          NarratorTrigger.eveningReflection
                      ? [
                          NarratorMilestoneAction(
                            label: 'Log Reflection',
                            onTap: () {
                              final completed = ref
                                  .read(dashboardStateProvider)
                                  .habits
                                  .where(
                                    (h) =>
                                        h.isActiveOnDay(DateTime.now()) &&
                                        h.isCompletedOn(DateTime.now()),
                                  )
                                  .length;
                              final total = ref
                                  .read(dashboardStateProvider)
                                  .habits
                                  .where((h) => h.isActiveOnDay(DateTime.now()))
                                  .length;
                              ref
                                  .read(narratorLocalDatasourceProvider)
                                  .recordNote(
                                    type: NarratorNoteType.reflectionLogged,
                                    data: {
                                      'completedCount': completed,
                                      'totalHabits': total,
                                      'response': 'Log Reflection',
                                    },
                                  );
                              _dismissMilestone();
                            },
                          ),
                          NarratorMilestoneAction(
                            label: 'Skip',
                            onTap: _dismissMilestone,
                          ),
                        ]
                      : null,
                  onDismissed: _dismissMilestone,
                ),
              ),
            // Peak-End all-done celebration: full-screen glow + narrator line.
            Positioned.fill(child: AllDoneCelebration(key: _celebrationKey)),
          ],
        ),
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

    final userProfile = statsAsync.value;
    final displayName = userProfile?.displayName ?? '';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: EmergeHeader(
            displayName: displayName,
            showToday: _isToday(_selectedDate),
            onAvatarTap: () => context.push('/profile'),
            onUpgradeTap: () => context.push('/paywall'),
            trailing: NarratorAvatar(
              onTap: () =>
                  ref.read(narratorAskFocusProvider.notifier).request(),
            ),
          ),
        ),

        // Social proof: tribal presence strip (only for users in a tribe).
        SliverToBoxAdapter(
          child: Consumer(
            builder: (context, ref, _) {
              final archetype = ref.watch(currentArchetypeProvider);
              if (archetype == UserArchetype.none) {
                return const SizedBox.shrink();
              }
              final clubAsync = ref.watch(userClubProvider(archetype.name));
              return clubAsync.when(
                data: (club) {
                  if (club == null || club.memberCount <= 0) {
                    return const SizedBox.shrink();
                  }
                  return TribalPresenceStrip(memberCount: club.memberCount);
                },
                // Passive social-proof pill: while loading, show nothing
                // rather than a skeleton (it must never block the timeline).
                loading: () => const SizedBox.shrink(),
                // §5: don't silently swallow — log, then degrade gracefully.
                error: (e, s) {
                  AppLogger.e('Tribal presence strip failed to load', e, s);
                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ),

        SliverToBoxAdapter(
          child: MonthCalendarStrip(
            key: _calendarKey,
            selectedDate: _selectedDate,
            onDateSelected: (date) {
              setState(() => _selectedDate = date);
            },
            completionStatus:
                ref.watch(monthCompletionProvider).value ??
                const <String, DayCompletion>{},
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        SliverToBoxAdapter(
          child: RecapSummaryCard(
            completionFraction: habits.isEmpty
                ? 0.0
                : habits.where((h) => h.isCompletedOn(_selectedDate)).length /
                      habits.length,
            currentStreak: _bestStreak(habits),
            // tribePercentile: null until tribe stats provider is wired
            onTap: () => context.push('/world-map/recap'),
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
              context.push('/timeline/habit/${habit.id}');
            },
            onHabitToggle: (habit) {
              _toggleHabitCompletion(habit);
            },
            onTimerTap: (habit) => _openTimerDialog(habit),
            onMenuTap: (habit) {
              HabitOptionsSheet.show(context, habit, _selectedDate);
            },
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        SliverToBoxAdapter(child: NarratorCard(key: _cardGuideKey)),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Identity-first banner ad (premium users auto-hide)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [const AdBannerWidget(), const SizedBox(height: 16)],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildEmptyTimeline({
    required BuildContext context,
    required VoidCallback onCreateHabit,
  }) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _BreathingWrapper(
            child: GlassmorphismCard(
              glowColor: EmergeColors.teal,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                      onPressed: onCreateHabit,
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
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return AppErrorWidget(
      message: "Couldn't load habits. Check your connection and try again.",
      onRetry: () => ref.invalidate(habitsProvider),
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

  /// Opens the timer dialog and returns the chosen duration in
  /// minutes (null if cancelled). The habit card uses this to
  /// transition into its running-timer state (play button).
  Future<int?> _openTimerDialog(Habit habit) async {
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
    // Return the chosen duration so the caller (the card) can start
    // the countdown. (0/null = cancelled.)
    return minutes;
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

        // Narrator milestone card for on-fire completions. Skipped when the
        // streak-recovery screen (opaque route) or the legacy celebration
        // dialog (isStreakMilestone: 7/14/30-day) is the presenting surface,
        // so the card is never produced behind another surface.
        if (result.narratorTrigger != null &&
            !result.wasRecovery &&
            !result.isStreakMilestone) {
          final resolver = ref.read(lineResolverProvider);
          final profile = ref.read(userStatsStreamProvider).value;
          final now = DateTime.now();
          final todayHabits = ref
              .read(dashboardStateProvider)
              .habits
              .where((h) => h.isActiveOnDay(now))
              .toList();
          final line = await resolver.resolve(
            trigger: result.narratorTrigger!,
            stats: NarratorUserStats(
              momentumScore: (result.newMomentumScore / 100).clamp(0.0, 1.0),
              // Real fields: momentum/streak come from the completion result,
              // level + habit counts come from the profile/dashboard.
              // consecutiveActiveDays is not exposed on the profile — 0.
              consecutiveActiveDays: 0,
              totalHabitsToday: todayHabits.length,
              completedHabitsToday: todayHabits
                  .where((h) => h.isCompletedOn(now))
                  .length,
              currentLevel: profile?.avatarStats.level ?? 1,
              previousLevel: profile?.avatarStats.level ?? 1,
              hasStreakBreak: result.wasRecovery,
              currentStreak: result.newStreak,
              longestStreak: result.newStreak,
              consecutiveMisses: 0,
              hasCompletedEveningReflectionToday: true,
              hasCompletedOnboarding: true,
              archetypeSelected: true,
            ),
          );
          if (mounted) {
            ref
                .read(pendingMilestoneProvider.notifier)
                .set(
                  PendingMilestoneLine(
                    line: line,
                    trigger: result.narratorTrigger!,
                  ),
                );
          }
        }

        // Show interstitial ad after a delay to let celebration play first
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            ref.read(adManagerProvider).showInterstitialAd();
          }
        });
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
    final now = DateTime.now();
    final habits = ref
        .read(dashboardStateProvider)
        .habits
        .where((h) => h.isActiveOnDay(now))
        .toList();
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
