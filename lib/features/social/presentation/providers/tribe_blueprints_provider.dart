import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _categoryToArchetype = {
  'Fitness': 'athlete',
  'Mindfulness': 'stoic',
  'Learning': 'scholar',
  'Productivity': 'zealot',
  'Creativity': 'creator',
  'Faith': 'zealot',
};

final tribeBlueprintsProvider =
    StreamProvider.autoDispose.family<List<Blueprint>, String>((
  ref,
  tribeArchetypeId,
) {
  final repository = ref.watch(blueprintRepositoryProvider);
  return repository.getBlueprints().map((blueprints) {
    final id = tribeArchetypeId.toLowerCase();
    return blueprints.where((bp) {
      if (bp.creatorArchetype.toLowerCase() == id) return true;
      final mapped = _categoryToArchetype[bp.category];
      if (mapped != null && mapped == id) return true;
      return false;
    }).toList();
  });
});

/// Blueprints curated for the user's active tribe, based on the tribe's
/// archetype. Delegates to [tribeBlueprintsProvider] with the resolved
/// archetype ID. Emits an empty list when no active membership exists.
final tribeBlueprintsForActiveTribeProvider =
    StreamProvider.autoDispose<List<Blueprint>>((ref) {
  final membership = ref.watch(activeMembershipProvider).value;
  final clubs = ref.watch(allArchetypeClubsProvider).value ?? [];
  final repo = ref.watch(blueprintRepositoryProvider);
  if (membership == null) return Stream.value([]);
  final tribe = clubs.where((t) => t.id == membership.tribeId).firstOrNull;
  final archetypeId = tribe?.archetypeId ?? '';
  final id = archetypeId.toLowerCase();
  return repo.getBlueprints().map((blueprints) {
    return blueprints.where((bp) {
      if (bp.creatorArchetype.toLowerCase() == id) return true;
      final mapped = _categoryToArchetype[bp.category];
      return mapped != null && mapped == id;
    }).toList();
  });
});
