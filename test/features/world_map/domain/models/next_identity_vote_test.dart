import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/models/next_identity_vote.dart';

void main() {
  final testHabit = Habit(
    id: 'h1',
    userId: 'u1',
    title: 'Deep Work',
    attribute: HabitAttribute.intellect,
    frequency: HabitFrequency.daily,
    currentStreak: 5,
    createdAt: DateTime(2024, 1, 1),
  );

  group('NextVoteType', () {
    test('contains all expected enum values', () {
      expect(NextVoteType.values, containsAll([
        NextVoteType.actionable,
        NextVoteType.harmonized,
        NextVoteType.empty,
      ]));
    });
  });

  group('NextIdentityVote', () {
    test('NextIdentityVote.actionable creates correct model with default isRecovery false', () {
      final vote = NextIdentityVote.actionable(
        habit: testHabit,
        attribute: HabitAttribute.intellect,
        vitalityImpactPercent: 14,
      );

      expect(vote.type, NextVoteType.actionable);
      expect(vote.isActionable, true);
      expect(vote.isHarmonized, false);
      expect(vote.isEmpty, false);
      expect(vote.habit, testHabit);
      expect(vote.attribute, HabitAttribute.intellect);
      expect(vote.vitalityImpactPercent, 14);
      expect(vote.isRecovery, false);
    });

    test('NextIdentityVote.actionable supports isRecovery true', () {
      final vote = NextIdentityVote.actionable(
        habit: testHabit,
        attribute: HabitAttribute.intellect,
        vitalityImpactPercent: 20,
        isRecovery: true,
      );

      expect(vote.isActionable, true);
      expect(vote.isRecovery, true);
      expect(vote.vitalityImpactPercent, 20);
    });

    test('NextIdentityVote.harmonized creates correct model', () {
      final vote = NextIdentityVote.harmonized();

      expect(vote.type, NextVoteType.harmonized);
      expect(vote.isHarmonized, true);
      expect(vote.isActionable, false);
      expect(vote.isEmpty, false);
      expect(vote.habit, isNull);
      expect(vote.attribute, isNull);
      expect(vote.vitalityImpactPercent, 0);
      expect(vote.isRecovery, false);
    });

    test('NextIdentityVote.empty creates correct model', () {
      final vote = NextIdentityVote.empty();

      expect(vote.type, NextVoteType.empty);
      expect(vote.isEmpty, true);
      expect(vote.isHarmonized, false);
      expect(vote.isActionable, false);
      expect(vote.habit, isNull);
      expect(vote.attribute, isNull);
      expect(vote.vitalityImpactPercent, 0);
      expect(vote.isRecovery, false);
    });

    test('supports value equality', () {
      final vote1 = NextIdentityVote.actionable(
        habit: testHabit,
        attribute: HabitAttribute.intellect,
        vitalityImpactPercent: 15,
        isRecovery: false,
      );
      final vote2 = NextIdentityVote.actionable(
        habit: testHabit,
        attribute: HabitAttribute.intellect,
        vitalityImpactPercent: 15,
        isRecovery: false,
      );
      final vote3 = NextIdentityVote.harmonized();
      final vote4 = NextIdentityVote.harmonized();

      expect(vote1, equals(vote2));
      expect(vote1.hashCode, equals(vote2.hashCode));
      expect(vote3, equals(vote4));
      expect(vote3.hashCode, equals(vote4.hashCode));
    });
  });
}
