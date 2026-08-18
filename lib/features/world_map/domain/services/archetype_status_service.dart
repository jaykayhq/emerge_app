import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_node_state.dart';

/// Pure domain service that calculates the per-archetype health state
/// and badge status for World Map archetype nodes.
class ArchetypeStatusService {
  /// Evaluates [habits] and realm [entropy] across all [HabitAttribute] values.
  ///
  /// - If an attribute has no habits: returns [NodeHealthStatus.idle].
  /// - If all habits for an attribute are completed today: returns [NodeHealthStatus.complete].
  /// - If pending habits exist and [entropy] > 0.1 and completed == 0: returns [NodeHealthStatus.decaying] with `hasDecay: true`.
  /// - Otherwise with pending habits: returns [NodeHealthStatus.pending].
  Map<HabitAttribute, ArchetypeNodeState> calculateNodeStates({
    required List<Habit> habits,
    required double entropy,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final result = <HabitAttribute, ArchetypeNodeState>{};

    for (final attr in HabitAttribute.values) {
      final attrHabits = habits.where((h) => h.attribute == attr).toList();
      if (attrHabits.isEmpty) {
        result[attr] = const ArchetypeNodeState(status: NodeHealthStatus.idle);
        continue;
      }

      final completed = attrHabits.where((h) => h.isCompletedOn(today)).length;
      final pending = attrHabits.length - completed;

      if (pending == 0) {
        result[attr] = ArchetypeNodeState(
          status: NodeHealthStatus.complete,
          completedCount: completed,
        );
      } else if (entropy > 0.1 && completed == 0) {
        result[attr] = ArchetypeNodeState(
          status: NodeHealthStatus.decaying,
          pendingCount: pending,
          completedCount: completed,
          hasDecay: true,
        );
      } else {
        result[attr] = ArchetypeNodeState(
          status: NodeHealthStatus.pending,
          pendingCount: pending,
          completedCount: completed,
        );
      }
    }

    return result;
  }
}
