import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/habits/domain/services/free_tier_habit_gate.dart';

void main() {
  group('FreeTierHabitGate.canAddHabits', () {
    test('free user at the limit is blocked from adding more', () {
      expect(
        FreeTierHabitGate.canAddHabits(
          activeHabitCount: 5,
          habitsToAdd: 1,
          freeLimit: 5,
          isPremium: false,
        ),
        false,
      );
    });

    test('free user under the limit may add habits', () {
      expect(
        FreeTierHabitGate.canAddHabits(
          activeHabitCount: 4,
          habitsToAdd: 1,
          freeLimit: 5,
          isPremium: false,
        ),
        true,
      );
    });

    test('blueprint adoption over the cap is blocked as a batch', () {
      // 3 active + a 3-habit blueprint = 6 > 5 → blocked.
      expect(
        FreeTierHabitGate.canAddHabits(
          activeHabitCount: 3,
          habitsToAdd: 3,
          freeLimit: 5,
          isPremium: false,
        ),
        false,
      );
    });

    test('a full free tier exactly is allowed', () {
      expect(
        FreeTierHabitGate.canAddHabits(
          activeHabitCount: 2,
          habitsToAdd: 3,
          freeLimit: 5,
          isPremium: false,
        ),
        true,
      );
    });

    test('premium bypasses the cap entirely', () {
      expect(
        FreeTierHabitGate.canAddHabits(
          activeHabitCount: 50,
          habitsToAdd: 3,
          freeLimit: 5,
          isPremium: true,
        ),
        true,
      );
    });
  });
}
