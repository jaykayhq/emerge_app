import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/domain/models/blueprint.dart';
import 'package:emerge_app/features/gamification/presentation/providers/gamification_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/onboarding/domain/entities/onboarding_milestone.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'dashboard_state_provider.g.dart';

/// Unified Dashboard State that combines:
/// - Habits (with optimistic updates)
/// - Onboarding milestones
/// - User profile/archetype
/// - Pending operations status
class DashboardState extends Equatable {
  /// All user habits (includes optimistic additions)
  final List<Habit> habits;

  /// Active onboarding milestones to display
  final List<OnboardingMilestone> activeMilestones;

  /// User's selected archetype (from onboarding)
  final UserArchetype? archetype;

  /// User's "why" motivation statement
  final String? why;

  /// User's attribute distribution
  final Map<String, int> attributes;

  /// Whether a habit creation is in progress
  final bool isCreatingHabit;

  /// Whether a blueprint is being activated
  final bool isActivatingBlueprint;

  /// Error message if any operation failed
  final String? error;

  /// Habits that are pending server confirmation (optimistic)
  final Set<String> pendingHabitIds;

  const DashboardState({
    this.habits = const [],
    this.activeMilestones = const [],
    this.archetype,
    this.why,
    this.attributes = const {},
    this.isCreatingHabit = false,
    this.isActivatingBlueprint = false,
    this.error,
    this.pendingHabitIds = const {},
  });

  /// Check if a specific habit is pending confirmation
  bool isHabitPending(String habitId) => pendingHabitIds.contains(habitId);

  /// Get habits grouped by time of day preference
  Map<TimeOfDayPreference, List<Habit>> get habitsByTimeOfDay {
    final Map<TimeOfDayPreference, List<Habit>> grouped = {};
    for (final habit in habits) {
      final pref = habit.timeOfDayPreference ?? TimeOfDayPreference.anytime;
      grouped.putIfAbsent(pref, () => []).add(habit);
    }
    return grouped;
  }

  /// Get habits that are due today
  List<Habit> get todaysHabits {
    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday

    return habits.where((habit) {
      if (habit.isArchived) return false;

      switch (habit.frequency) {
        case HabitFrequency.daily:
          return true;
        case HabitFrequency.weekly:
          // Show on the day it was created (or Monday if not specified)
          return weekday == (habit.createdAt.weekday);
        case HabitFrequency.specificDays:
          return habit.specificDays.contains(weekday);
      }
    }).toList();
  }

  /// Get completion rate for today
  double get todayCompletionRate {
    final todays = todaysHabits;
    if (todays.isEmpty) return 0.0;

    final now = DateTime.now();
    final completedToday = todays.where((h) {
      final last = h.lastCompletedDate;
      return last != null &&
          last.year == now.year &&
          last.month == now.month &&
          last.day == now.day;
    }).length;

    return completedToday / todays.length;
  }

  DashboardState copyWith({
    List<Habit>? habits,
    List<OnboardingMilestone>? activeMilestones,
    UserArchetype? archetype,
    String? why,
    Map<String, int>? attributes,
    bool? isCreatingHabit,
    bool? isActivatingBlueprint,
    String? error,
    Set<String>? pendingHabitIds,
  }) {
    return DashboardState(
      habits: habits ?? this.habits,
      activeMilestones: activeMilestones ?? this.activeMilestones,
      archetype: archetype ?? this.archetype,
      why: why ?? this.why,
      attributes: attributes ?? this.attributes,
      isCreatingHabit: isCreatingHabit ?? this.isCreatingHabit,
      isActivatingBlueprint:
          isActivatingBlueprint ?? this.isActivatingBlueprint,
      error: error,
      pendingHabitIds: pendingHabitIds ?? this.pendingHabitIds,
    );
  }

  @override
  List<Object?> get props => [
    habits,
    activeMilestones,
    archetype,
    why,
    attributes,
    isCreatingHabit,
    isActivatingBlueprint,
    error,
    pendingHabitIds,
  ];
}

/// Central Dashboard State Notifier
/// Orchestrates all state that affects the dashboard view
@Riverpod(keepAlive: true)
class DashboardStateNotifier extends _$DashboardStateNotifier {
  @override
  DashboardState build() {
    // Listen to habits stream and sync to state
    ref.listen<AsyncValue<List<Habit>>>(habitsProvider, (prev, next) {
      next.whenData((serverHabits) {
        _syncHabitsFromServer(serverHabits);
      });
    });

    // Listen to onboarding milestones
    ref.listen<List<OnboardingMilestone>>(activeMilestonesProvider, (
      prev,
      next,
    ) {
      state = state.copyWith(activeMilestones: next);
    });

    // Listen to user profile for archetype/attributes
    ref.listen<AsyncValue<UserProfile?>>(userProfileProvider, (prev, next) {
      next.whenData((profile) {
        if (profile != null) {
          state = state.copyWith(
            archetype: profile.archetype,
            why: profile.why,
            attributes: _convertAttributes(profile),
          );
        }
      });
    });

    // Initialize with current values
    final habits = ref.read(habitsProvider).valueOrNull ?? [];
    final milestones = ref.read(activeMilestonesProvider);
    final profile = ref.read(userProfileProvider).valueOrNull;

    return DashboardState(
      habits: habits,
      activeMilestones: milestones,
      archetype: profile?.archetype,
      why: profile?.why,
      attributes: profile != null ? _convertAttributes(profile) : const {},
    );
  }

  Map<String, int> _convertAttributes(UserProfile profile) {
    if (profile.identityVotes.isNotEmpty) {
      return profile.identityVotes;
    }
    return {'Vitality': 0, 'Focus': 0, 'Creativity': 0, 'Strength': 0};
  }

  /// Sync habits from server, preserving optimistic additions
  void _syncHabitsFromServer(List<Habit> serverHabits) {
    final serverIds = serverHabits.map((h) => h.id).toSet();

    // Remove pending IDs that are now confirmed
    final stillPending = state.pendingHabitIds.difference(serverIds);

    // Keep optimistic habits that aren't confirmed yet
    final optimisticHabits = state.habits
        .where(
          (h) =>
              state.pendingHabitIds.contains(h.id) && !serverIds.contains(h.id),
        )
        .toList();

    // Merge: server habits + still-pending optimistic habits
    final mergedHabits = [...serverHabits, ...optimisticHabits];

    state = state.copyWith(habits: mergedHabits, pendingHabitIds: stillPending);
  }

  /// Create a habit with optimistic update
  /// The habit appears immediately in the dashboard before server confirmation
  Future<void> createHabitOptimistic(Habit habit) async {
    // 1. Optimistic update - add habit immediately
    state = state.copyWith(
      habits: [...state.habits, habit],
      pendingHabitIds: {...state.pendingHabitIds, habit.id},
      isCreatingHabit: true,
      error: null,
    );

    try {
      // 2. Actually create on server
      await ref.read(createHabitProvider(habit).future);

      // 3. On success, keep in pendingHabitIds until stream confirms
      // _syncHabitsFromServer will remove it when the habit appears in server data
      state = state.copyWith(isCreatingHabit: false);

      AppLogger.i('Habit created successfully: ${habit.id}');
    } catch (e, s) {
      AppLogger.e('Failed to create habit', e, s);

      // 4. On failure, remove optimistic habit and show error
      state = state.copyWith(
        habits: state.habits.where((h) => h.id != habit.id).toList(),
        pendingHabitIds: state.pendingHabitIds.difference({habit.id}),
        isCreatingHabit: false,
        error: 'Failed to create habit: ${e.toString()}',
      );

      rethrow;
    }
  }

  /// Activate a blueprint - creates all habits from the blueprint
  Future<void> activateBlueprint(Blueprint blueprint, String userId) async {
    state = state.copyWith(isActivatingBlueprint: true, error: null);

    final List<Habit> createdHabits = [];
    final Set<String> pendingIds = {};

    try {
      // Create habits from blueprint
      for (final blueprintHabit in blueprint.habits) {
        final habitId = const Uuid().v4();
        final habit = Habit(
          id: habitId,
          userId: userId,
          title: blueprintHabit.title,
          cue: 'From blueprint: ${blueprint.title}',
          createdAt: DateTime.now(),
          difficulty: _mapDifficulty(blueprint.difficulty),
          timeOfDayPreference: _mapTimeOfDay(blueprintHabit.timeOfDay),
          frequency: _mapFrequency(blueprintHabit.frequency),
          identityTags: [blueprint.category.toLowerCase(), 'blueprint'],
        );

        createdHabits.add(habit);
        pendingIds.add(habitId);
      }

      // Optimistic update - add all habits at once
      state = state.copyWith(
        habits: [...state.habits, ...createdHabits],
        pendingHabitIds: {...state.pendingHabitIds, ...pendingIds},
      );

      // Create each habit on server
      for (final habit in createdHabits) {
        await ref.read(createHabitProvider(habit).future);
      }

      state = state.copyWith(
        isActivatingBlueprint: false,
        pendingHabitIds: state.pendingHabitIds.difference(pendingIds),
      );

      AppLogger.i(
        'Blueprint activated: ${blueprint.title} with ${createdHabits.length} habits',
      );
    } catch (e, s) {
      AppLogger.e('Failed to activate blueprint', e, s);

      // Remove all optimistic habits from this blueprint
      final failedIds = createdHabits.map((h) => h.id).toSet();
      state = state.copyWith(
        habits: state.habits.where((h) => !failedIds.contains(h.id)).toList(),
        pendingHabitIds: state.pendingHabitIds.difference(failedIds),
        isActivatingBlueprint: false,
        error: 'Failed to activate blueprint: ${e.toString()}',
      );

      rethrow;
    }
  }

  HabitDifficulty _mapDifficulty(BlueprintDifficulty difficulty) {
    switch (difficulty) {
      case BlueprintDifficulty.beginner:
        return HabitDifficulty.easy;
      case BlueprintDifficulty.intermediate:
        return HabitDifficulty.medium;
      case BlueprintDifficulty.advanced:
        return HabitDifficulty.hard;
    }
  }

  TimeOfDayPreference _mapTimeOfDay(String timeOfDay) {
    switch (timeOfDay.toLowerCase()) {
      case 'morning':
        return TimeOfDayPreference.morning;
      case 'afternoon':
        return TimeOfDayPreference.afternoon;
      case 'evening':
        return TimeOfDayPreference.evening;
      default:
        return TimeOfDayPreference.anytime;
    }
  }

  HabitFrequency _mapFrequency(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return HabitFrequency.daily;
      case 'weekly':
      case 'weekdays':
        return HabitFrequency.weekly;
      default:
        return HabitFrequency.daily;
    }
  }

  /// Update onboarding data and sync to dashboard
  void syncOnboardingState(OnboardingState onboardingState) {
    state = state.copyWith(
      archetype: onboardingState.selectedArchetype,
      why: onboardingState.why,
      attributes: onboardingState.attributes,
    );
  }

  /// Clear any error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for today's habits only (derived from dashboard state)
@riverpod
List<Habit> todaysHabits(Ref ref) {
  final dashboardState = ref.watch(dashboardStateNotifierProvider);
  return dashboardState.todaysHabits;
}

/// Provider for today's completion rate
@riverpod
double todayCompletionRate(Ref ref) {
  final dashboardState = ref.watch(dashboardStateNotifierProvider);
  return dashboardState.todayCompletionRate;
}

/// Provider to check if dashboard is loading
@riverpod
bool isDashboardLoading(Ref ref) {
  final dashboardState = ref.watch(dashboardStateNotifierProvider);
  return dashboardState.isCreatingHabit || dashboardState.isActivatingBlueprint;
}

/// Provider for dashboard error
@riverpod
String? dashboardError(Ref ref) {
  final dashboardState = ref.watch(dashboardStateNotifierProvider);
  return dashboardState.error;
}
