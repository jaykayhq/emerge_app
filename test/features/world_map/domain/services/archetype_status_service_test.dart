import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_node_state.dart';
import 'package:emerge_app/features/world_map/domain/services/archetype_status_service.dart';

void main() {
  late ArchetypeStatusService service;
  final now = DateTime(2026, 8, 19, 10, 0);

  setUp(() {
    service = ArchetypeStatusService();
  });

  group('ArchetypeStatusService', () {
    test('attribute with no habits returns NodeHealthStatus.idle', () {
      final nodeStates = service.calculateNodeStates(
        habits: [],
        entropy: 0.0,
        now: now,
      );

      for (final attr in HabitAttribute.values) {
        expect(nodeStates[attr], isNotNull);
        expect(nodeStates[attr]?.status, NodeHealthStatus.idle);
        expect(nodeStates[attr]?.pendingCount, 0);
        expect(nodeStates[attr]?.completedCount, 0);
        expect(nodeStates[attr]?.hasDecay, isFalse);
      }
    });

    test('attribute with all habits done returns NodeHealthStatus.complete', () {
      final habits = [
        Habit(
          id: 'h1',
          userId: 'u1',
          title: 'Weight Training',
          attribute: HabitAttribute.strength,
          createdAt: DateTime(2026, 1, 1),
          lastCompletedDate: now,
        ),
        Habit(
          id: 'h2',
          userId: 'u1',
          title: 'Sprint Intervals',
          attribute: HabitAttribute.strength,
          createdAt: DateTime(2026, 1, 1),
          lastCompletedDate: now,
        ),
      ];

      final nodeStates = service.calculateNodeStates(
        habits: habits,
        entropy: 0.0,
        now: now,
      );

      final strengthState = nodeStates[HabitAttribute.strength];
      expect(strengthState?.status, NodeHealthStatus.complete);
      expect(strengthState?.completedCount, 2);
      expect(strengthState?.pendingCount, 0);
      expect(strengthState?.isComplete, isTrue);
      expect(strengthState?.hasDecay, isFalse);
    });

    test('attribute with pending habits returns NodeHealthStatus.pending', () {
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
          title: 'Evening Gratitude',
          attribute: HabitAttribute.spirit,
          createdAt: DateTime(2026, 1, 1),
          lastCompletedDate: null,
        ),
      ];

      final nodeStates = service.calculateNodeStates(
        habits: habits,
        entropy: 0.0,
        now: now,
      );

      final spiritState = nodeStates[HabitAttribute.spirit];
      expect(spiritState?.status, NodeHealthStatus.pending);
      expect(spiritState?.completedCount, 1);
      expect(spiritState?.pendingCount, 1);
      expect(spiritState?.isComplete, isFalse);
      expect(spiritState?.hasDecay, isFalse);
    });

    test('attribute with pending habits and entropy > 0.1 returns NodeHealthStatus.decaying with hasDecay true when completed is 0', () {
      final habits = [
        Habit(
          id: 'h1',
          userId: 'u1',
          title: 'Study Architecture',
          attribute: HabitAttribute.intellect,
          createdAt: DateTime(2026, 1, 1),
          lastCompletedDate: null,
        ),
      ];

      final nodeStates = service.calculateNodeStates(
        habits: habits,
        entropy: 0.3,
        now: now,
      );

      final intellectState = nodeStates[HabitAttribute.intellect];
      expect(intellectState?.status, NodeHealthStatus.decaying);
      expect(intellectState?.completedCount, 0);
      expect(intellectState?.pendingCount, 1);
      expect(intellectState?.hasDecay, isTrue);
    });

    test('attribute with completed habits is pending (not decaying) even if entropy > 0.1 as long as 1 habit is done', () {
      final habits = [
        Habit(
          id: 'h1',
          userId: 'u1',
          title: 'Study Architecture',
          attribute: HabitAttribute.intellect,
          createdAt: DateTime(2026, 1, 1),
          lastCompletedDate: now,
        ),
        Habit(
          id: 'h2',
          userId: 'u1',
          title: 'Read Research Paper',
          attribute: HabitAttribute.intellect,
          createdAt: DateTime(2026, 1, 1),
          lastCompletedDate: null,
        ),
      ];

      final nodeStates = service.calculateNodeStates(
        habits: habits,
        entropy: 0.3,
        now: now,
      );

      final intellectState = nodeStates[HabitAttribute.intellect];
      expect(intellectState?.status, NodeHealthStatus.pending);
      expect(intellectState?.completedCount, 1);
      expect(intellectState?.pendingCount, 1);
      expect(intellectState?.hasDecay, isFalse);
    });
  });
}
