import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/services/smart_defaults_service.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'smart_defaults_provider.g.dart';

/// Computes smart defaults for habit creation based on existing habits
/// and the user's archetype. Auto-disposes when no longer watched.
@riverpod
SmartDefaults smartDefaults(Ref ref) {
  final habitsAsync = ref.watch(habitsProvider);
  final archetype = ref.watch(currentArchetypeProvider);

  final habits = habitsAsync.value ?? <Habit>[];
  final activeHabits = habits.where((h) => !h.isArchived).toList();

  return computeSmartDefaults(
    existingHabits: activeHabits,
    archetype: archetype,
    activeHabitCount: activeHabits.length,
  );
}
