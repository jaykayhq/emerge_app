import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/world_map/domain/models/next_identity_vote.dart';
import 'package:emerge_app/features/world_map/domain/services/next_identity_vote_service.dart';
import 'package:emerge_app/features/world_map/presentation/providers/next_identity_vote_provider.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';

void main() {
  final now = DateTime.now();

  group('nextIdentityVoteServiceProvider', () {
    test('creates NextIdentityVoteService instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(nextIdentityVoteServiceProvider);
      expect(service, isA<NextIdentityVoteService>());
    });
  });

  group('nextIdentityVoteProvider', () {
    test('returns NextIdentityVote.empty() when habits list is empty', () async {
      final container = ProviderContainer(
        overrides: [
          habitsProvider.overrideWith((ref) => Stream.value(<Habit>[])),
          worldEntropyStreamProvider.overrideWith((ref) => Stream.value(0.0)),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(nextIdentityVoteProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(habitsProvider.future);
      await container.read(worldEntropyStreamProvider.future);

      final vote = container.read(nextIdentityVoteProvider);
      expect(vote.isEmpty, isTrue);
      expect(vote.isActionable, isFalse);
      expect(vote.isHarmonized, isFalse);
    });

    test('returns NextIdentityVote.harmonized() when all habits completed today', () async {
      final completedHabit = Habit(
        id: 'h1',
        userId: 'u1',
        title: 'Morning Run',
        attribute: HabitAttribute.vitality,
        createdAt: DateTime(2026, 1, 1),
        lastCompletedDate: now,
      );

      final container = ProviderContainer(
        overrides: [
          habitsProvider.overrideWith(
            (ref) => Stream.value([completedHabit]),
          ),
          worldEntropyStreamProvider.overrideWith((ref) => Stream.value(0.0)),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(nextIdentityVoteProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(habitsProvider.future);
      await container.read(worldEntropyStreamProvider.future);

      final vote = container.read(nextIdentityVoteProvider);
      expect(vote.isHarmonized, isTrue);
      expect(vote.isActionable, isFalse);
    });

    test('returns actionable NextIdentityVote prioritizing uncompleted habit', () async {
      final uncompletedHabit = Habit(
        id: 'h1',
        userId: 'u1',
        title: 'Deep Coding',
        attribute: HabitAttribute.intellect,
        createdAt: DateTime(2026, 1, 1),
        currentStreak: 5,
        lastCompletedDate: null,
      );

      final container = ProviderContainer(
        overrides: [
          habitsProvider.overrideWith(
            (ref) => Stream.value([uncompletedHabit]),
          ),
          worldEntropyStreamProvider.overrideWith((ref) => Stream.value(0.0)),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(nextIdentityVoteProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(habitsProvider.future);
      await container.read(worldEntropyStreamProvider.future);

      final vote = container.read(nextIdentityVoteProvider);
      expect(vote.isActionable, isTrue);
      expect(vote.habit?.id, 'h1');
      expect(vote.attribute, HabitAttribute.intellect);
      expect(vote.isRecovery, isFalse);
    });

    test('prioritizes recovery habit when entropy > 0.05', () async {
      final highStreakHabit = Habit(
        id: 'h1',
        userId: 'u1',
        title: 'Deep Coding',
        attribute: HabitAttribute.intellect,
        createdAt: DateTime(2026, 1, 1),
        currentStreak: 10,
        lastCompletedDate: null,
      );
      final lowStreakHabit = Habit(
        id: 'h2',
        userId: 'u1',
        title: 'Meditation',
        attribute: HabitAttribute.spirit,
        createdAt: DateTime(2026, 1, 1),
        currentStreak: 1,
        lastCompletedDate: null,
      );

      final container = ProviderContainer(
        overrides: [
          habitsProvider.overrideWith(
            (ref) => Stream.value([highStreakHabit, lowStreakHabit]),
          ),
          worldEntropyStreamProvider.overrideWith((ref) => Stream.value(0.2)),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(nextIdentityVoteProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(habitsProvider.future);
      await container.read(worldEntropyStreamProvider.future);

      final vote = container.read(nextIdentityVoteProvider);
      expect(vote.isActionable, isTrue);
      expect(vote.habit?.id, 'h2');
      expect(vote.attribute, HabitAttribute.spirit);
      expect(vote.isRecovery, isTrue);
    });
  });
}
