import 'package:emerge_app/features/health/domain/health_repository.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

class HealthAutoCompleteService {
  final HealthRepository healthRepository;

  HealthAutoCompleteService({required this.healthRepository});

  Future<List<String>> getHabitIdsToAutoComplete(List<Habit> habits) async {
    if (habits.isEmpty) return [];

    final todaySteps = await healthRepository.getTodaySteps();
    final todayScreenTime = await healthRepository.getTodayScreenTime();
    final now = DateTime.now();

    final toComplete = <String>[];

    for (final habit in habits) {
      if (habit.integrationType == HabitIntegrationType.none) continue;
      if (habit.isArchived) continue;

      final lastCompleted = habit.lastCompletedDate;
      if (lastCompleted != null &&
          lastCompleted.year == now.year &&
          lastCompleted.month == now.month &&
          lastCompleted.day == now.day) {
        continue;
      }

      switch (habit.integrationType) {
        case HabitIntegrationType.healthSteps:
          if (habit.integrationTarget != null &&
              todaySteps >= habit.integrationTarget!) {
            toComplete.add(habit.id);
          }
        case HabitIntegrationType.screenTimeLimit:
          if (habit.integrationTarget != null &&
              todayScreenTime >= habit.integrationTarget!) {
            toComplete.add(habit.id);
          }
        case HabitIntegrationType.none:
          break;
      }
    }

    return toComplete;
  }
}
