import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_node_state.dart';
import 'package:emerge_app/features/world_map/domain/services/archetype_status_service.dart';
import 'package:emerge_app/features/world_map/presentation/providers/world_health_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'archetype_node_states_provider.g.dart';

/// Provider for [ArchetypeStatusService]
@riverpod
ArchetypeStatusService archetypeStatusService(Ref ref) {
  return ArchetypeStatusService();
}

/// Computes the per-archetype [ArchetypeNodeState] map by watching
/// [habitsProvider] and [worldEntropyStreamProvider].
@riverpod
Map<HabitAttribute, ArchetypeNodeState> archetypeNodeStates(Ref ref) {
  final habitsAsync = ref.watch(habitsProvider);
  final entropyAsync = ref.watch(worldEntropyStreamProvider);
  final service = ref.watch(archetypeStatusServiceProvider);

  final habits = habitsAsync.value ?? [];
  final entropy = entropyAsync.value ?? 0.0;

  return service.calculateNodeStates(
    habits: habits,
    entropy: entropy,
  );
}
