import 'package:emerge_app/features/habits/data/repositories/fake_habit_repository.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

void main() {
  late FakeHabitRepository habitRepository;

  setUp(() {
    habitRepository = FakeHabitRepository();
  });

  group('FakeHabitRepository', () {
    final testHabit = Habit(
      id: const Uuid().v4(),
      userId: '123',
      title: 'Test Habit',
      cue: 'Cue',
      routine: 'Routine',
      reward: 'Reward',
      createdAt: DateTime.now(),
      difficulty: HabitDifficulty.medium,
    );

    test('createHabit adds habit', () async {
      final result = await habitRepository.createHabit(testHabit);
      expect(result.isRight(), true);

      final habitsStream = habitRepository.watchHabits('123');
      expect(
        habitsStream,
        emits(
          predicate<List<Habit>>(
            (list) => list.any((h) => h.id == testHabit.id),
          ),
        ),
      );
    });

    test('updateHabit updates existing habit', () async {
      await habitRepository.createHabit(testHabit);

      final updatedHabit = testHabit.copyWith(title: 'Updated Title');
      final result = await habitRepository.updateHabit(updatedHabit);

      expect(result.isRight(), true);

      final retrievedHabit = await habitRepository.getHabit(testHabit.id);
      expect(retrievedHabit?.title, 'Updated Title');
    });

    test('deleteHabit removes habit', () async {
      await habitRepository.createHabit(testHabit);

      final result = await habitRepository.deleteHabit(testHabit.id);
      expect(result.isRight(), true);

      final retrievedHabit = await habitRepository.getHabit(testHabit.id);
      expect(retrievedHabit, null);
    });

    test('completeHabit toggles completion and updates streak', () async {
      await habitRepository.createHabit(testHabit);
      final date = DateTime.now();

      // Complete
      final result1 = await habitRepository.completeHabit(testHabit.id, date);
      expect(result1, const Right(true));

      var retrievedHabit = await habitRepository.getHabit(testHabit.id);
      expect(retrievedHabit?.currentStreak, 1);
      expect(retrievedHabit?.lastCompletedDate?.day, date.day);

      // Undo Complete
      final result2 = await habitRepository.completeHabit(testHabit.id, date);
      expect(result2, const Right(false));

      retrievedHabit = await habitRepository.getHabit(testHabit.id);
      expect(retrievedHabit?.currentStreak, 0);
      expect(retrievedHabit?.lastCompletedDate, null);
    });
  });
}
