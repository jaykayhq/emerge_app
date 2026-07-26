import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/timeline/presentation/providers/last_habit_completed_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Habit _habit(String id, {required bool done}) {
  final now = DateTime.now();
  return Habit(
    id: id,
    userId: 'u1',
    title: id,
    attribute: HabitAttribute.vitality,
    lastCompletedDate: done ? now : null,
    createdAt: now,
  );
}

void main() {
  group('isLastHabitJustCompleted', () {
    test('returns true when count goes from total-1 to total', () {
      expect(
        isLastHabitJustCompleted(
          previousCompleted: 4,
          currentCompleted: 5,
          totalHabits: 5,
        ),
        true,
      );
    });

    test('returns false when already all done', () {
      expect(
        isLastHabitJustCompleted(
          previousCompleted: 5,
          currentCompleted: 5,
          totalHabits: 5,
        ),
        false,
      );
    });

    test('returns false when only partial progress', () {
      expect(
        isLastHabitJustCompleted(
          previousCompleted: 2,
          currentCompleted: 3,
          totalHabits: 5,
        ),
        false,
      );
    });

    test('returns false when there are no habits', () {
      expect(
        isLastHabitJustCompleted(
          previousCompleted: 0,
          currentCompleted: 0,
          totalHabits: 0,
        ),
        false,
      );
    });

    test('returns false when a completion is undone', () {
      expect(
        isLastHabitJustCompleted(
          previousCompleted: 5,
          currentCompleted: 4,
          totalHabits: 5,
        ),
        false,
      );
    });
  });

  group('lastHabitCompletedProvider', () {
    test('does not celebrate on first build when all already complete', () {
      final container = ProviderContainer(
        overrides: [
          habitsProvider.overrideWith(
            (ref) => Stream.value([
              _habit('a', done: true),
              _habit('b', done: true),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      // First build with an all-complete list must establish a baseline,
      // never emit true (guards the app-relaunch false positive).
      expect(container.read(lastHabitCompletedProvider), false);
    });
  });
}
