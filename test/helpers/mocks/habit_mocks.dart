import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';

class MockHabitRepository extends Mock implements HabitRepository {}

final List<Habit> testHabits = [
  Habit(
    id: 'h1',
    userId: 'test-uid',
    title: 'Morning Run',
    frequency: HabitFrequency.daily,
    attribute: HabitAttribute.vitality,
    createdAt: DateTime(2024, 1, 1),
  ),
  Habit(
    id: 'h2',
    userId: 'test-uid',
    title: 'Read 30m',
    frequency: HabitFrequency.daily,
    attribute: HabitAttribute.intellect,
    createdAt: DateTime(2024, 1, 1),
  ),
];
