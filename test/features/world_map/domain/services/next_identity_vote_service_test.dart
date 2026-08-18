import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/models/next_identity_vote.dart';
import 'package:emerge_app/features/world_map/domain/services/next_identity_vote_service.dart';

void main() {
  late NextIdentityVoteService service;
  final now = DateTime(2026, 8, 19, 10, 0);

  setUp(() {
    service = NextIdentityVoteService();
  });

  group('NextIdentityVoteService', () {
    test('returns NextIdentityVote.empty() when habit list is empty', () {
      final vote = service.calculateNextVote(
        habits: [],
        entropy: 0.0,
        now: now,
      );

      expect(vote.isEmpty, isTrue);
      expect(vote.isActionable, isFalse);
      expect(vote.isHarmonized, isFalse);
    });

    test('returns NextIdentityVote.harmonized() when all habits completed today', () {
      final habits = [
        Habit(
          id: 'h1',
          userId: 'u1',
          title: 'Morning Meditation',
          attribute: HabitAttribute.spirit,
          createdAt: DateTime(2026, 1, 1),
          lastCompletedDate: now,
        ),
        Habit(
          id: 'h2',
          userId: 'u1',
          title: 'Weight Training',
          attribute: HabitAttribute.strength,
          createdAt: DateTime(2026, 1, 1),
          lastCompletedDate: now,
        ),
      ];

      final vote = service.calculateNextVote(
        habits: habits,
        entropy: 0.0,
        now: now,
      );

      expect(vote.isHarmonized, isTrue);
      expect(vote.isActionable, isFalse);
      expect(vote.isEmpty, isFalse);
    });

    test('prioritizes recovery action with isRecovery: true and lowest streak when entropy > 0.05', () {
      final habits = [
        Habit(
          id: 'h1',
          userId: 'u1',
          title: 'Daily Journaling',
          attribute: HabitAttribute.intellect,
          createdAt: DateTime(2026, 1, 1),
          currentStreak: 12,
          lastCompletedDate: null,
        ),
        Habit(
          id: 'h2',
          userId: 'u1',
          title: 'Breathwork Reset',
          attribute: HabitAttribute.spirit,
          createdAt: DateTime(2026, 1, 1),
          currentStreak: 1,
          lastCompletedDate: null,
        ),
      ];

      final vote = service.calculateNextVote(
        habits: habits,
        entropy: 0.25,
        now: now,
      );

      expect(vote.isActionable, isTrue);
      expect(vote.isRecovery, isTrue);
      expect(vote.habit?.id, 'h2');
      expect(vote.attribute, HabitAttribute.spirit);
    });

    test('selects priority habit with highest streak and calculates vitalityImpactPercent when entropy <= 0.05', () {
      final habits = [
        Habit(
          id: 'h1',
          userId: 'u1',
          title: 'Daily Journaling',
          attribute: HabitAttribute.intellect,
          createdAt: DateTime(2026, 1, 1),
          currentStreak: 12,
          lastCompletedDate: null,
        ),
        Habit(
          id: 'h2',
          userId: 'u1',
          title: 'Deep Work Session',
          attribute: HabitAttribute.focus,
          createdAt: DateTime(2026, 1, 1),
          currentStreak: 3,
          lastCompletedDate: null,
        ),
        Habit(
          id: 'h3',
          userId: 'u1',
          title: 'Already Done Habit',
          attribute: HabitAttribute.vitality,
          createdAt: DateTime(2026, 1, 1),
          lastCompletedDate: now,
        ),
      ];

      final vote = service.calculateNextVote(
        habits: habits,
        entropy: 0.0,
        now: now,
      );

      expect(vote.isActionable, isTrue);
      expect(vote.isRecovery, isFalse);
      expect(vote.habit?.id, 'h1');
      expect(vote.attribute, HabitAttribute.intellect);
      // 3 total habits -> (1/3)*100 = 33% clamped to [10, 35] -> 33
      expect(vote.vitalityImpactPercent, 33);
    });

    test('vitalityImpactPercent clamps to minimum 10 and maximum 35', () {
      // 20 habits -> (1/20)*100 = 5% -> clamped to 10
      final manyHabits = List.generate(
        20,
        (i) => Habit(
          id: 'h$i',
          userId: 'u1',
          title: 'Habit $i',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      final voteMin = service.calculateNextVote(
        habits: manyHabits,
        entropy: 0.0,
        now: now,
      );
      expect(voteMin.vitalityImpactPercent, 10);

      // 1 habit -> (1/1)*100 = 100% -> clamped to 35
      final singleHabit = [
        Habit(
          id: 'h1',
          userId: 'u1',
          title: 'Single Habit',
          createdAt: DateTime(2026, 1, 1),
        ),
      ];

      final voteMax = service.calculateNextVote(
        habits: singleHabit,
        entropy: 0.0,
        now: now,
      );
      expect(voteMax.vitalityImpactPercent, 35);
    });
  });
}
