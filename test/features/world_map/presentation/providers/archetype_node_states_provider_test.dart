import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_node_state.dart';
import 'package:emerge_app/features/world_map/domain/services/archetype_status_service.dart';
import 'package:emerge_app/features/world_map/presentation/providers/archetype_node_states_provider.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';

void main() {
  final now = DateTime.now();

  group('archetypeStatusServiceProvider', () {
    test('creates ArchetypeStatusService instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(archetypeStatusServiceProvider);
      expect(service, isA<ArchetypeStatusService>());
    });
  });

  group('archetypeNodeStatesProvider', () {
    test('returns idle state for all attributes when habits list is empty', () async {
      final container = ProviderContainer(
        overrides: [
          habitsProvider.overrideWith((ref) => Stream.value(<Habit>[])),
          worldEntropyStreamProvider.overrideWith((ref) => Stream.value(0.0)),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(archetypeNodeStatesProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(habitsProvider.future);
      await container.read(worldEntropyStreamProvider.future);

      final nodeStates = container.read(archetypeNodeStatesProvider);
      for (final attr in HabitAttribute.values) {
        expect(nodeStates[attr], isNotNull);
        expect(nodeStates[attr]?.status, NodeHealthStatus.idle);
      }
    });

    test('returns complete state when all habits for an attribute are completed', () async {
      final completedHabit = Habit(
        id: 'h1',
        userId: 'u1',
        title: 'Morning Workout',
        attribute: HabitAttribute.strength,
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

      final sub = container.listen(archetypeNodeStatesProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(habitsProvider.future);
      await container.read(worldEntropyStreamProvider.future);

      final nodeStates = container.read(archetypeNodeStatesProvider);
      final strengthState = nodeStates[HabitAttribute.strength];
      expect(strengthState?.status, NodeHealthStatus.complete);
      expect(strengthState?.completedCount, 1);
      expect(strengthState?.pendingCount, 0);
      expect(strengthState?.isComplete, isTrue);
    });

    test('returns pending state when attribute has pending habits', () async {
      final habit1 = Habit(
        id: 'h1',
        userId: 'u1',
        title: 'Meditation',
        attribute: HabitAttribute.spirit,
        createdAt: DateTime(2026, 1, 1),
        lastCompletedDate: now,
      );
      final habit2 = Habit(
        id: 'h2',
        userId: 'u1',
        title: 'Evening Reflection',
        attribute: HabitAttribute.spirit,
        createdAt: DateTime(2026, 1, 1),
        lastCompletedDate: null,
      );

      final container = ProviderContainer(
        overrides: [
          habitsProvider.overrideWith(
            (ref) => Stream.value([habit1, habit2]),
          ),
          worldEntropyStreamProvider.overrideWith((ref) => Stream.value(0.0)),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(archetypeNodeStatesProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(habitsProvider.future);
      await container.read(worldEntropyStreamProvider.future);

      final nodeStates = container.read(archetypeNodeStatesProvider);
      final spiritState = nodeStates[HabitAttribute.spirit];
      expect(spiritState?.status, NodeHealthStatus.pending);
      expect(spiritState?.completedCount, 1);
      expect(spiritState?.pendingCount, 1);
      expect(spiritState?.hasDecay, isFalse);
    });

    test('returns decaying state when pending habits exist, 0 completed, and entropy > 0.1', () async {
      final decayingHabit = Habit(
        id: 'h1',
        userId: 'u1',
        title: 'Study Architecture',
        attribute: HabitAttribute.intellect,
        createdAt: DateTime(2026, 1, 1),
        lastCompletedDate: null,
      );

      final container = ProviderContainer(
        overrides: [
          habitsProvider.overrideWith(
            (ref) => Stream.value([decayingHabit]),
          ),
          worldEntropyStreamProvider.overrideWith((ref) => Stream.value(0.3)),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(archetypeNodeStatesProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(habitsProvider.future);
      await container.read(worldEntropyStreamProvider.future);

      final nodeStates = container.read(archetypeNodeStatesProvider);
      final intellectState = nodeStates[HabitAttribute.intellect];
      expect(intellectState?.status, NodeHealthStatus.decaying);
      expect(intellectState?.completedCount, 0);
      expect(intellectState?.pendingCount, 1);
      expect(intellectState?.hasDecay, isTrue);
    });
  });
}
