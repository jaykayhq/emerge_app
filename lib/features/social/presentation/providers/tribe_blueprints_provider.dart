import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
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
