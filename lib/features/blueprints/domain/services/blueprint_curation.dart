import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';

/// Maps a blueprint's legacy category to the archetype id it was curated for.
/// Kept verbatim from `tribe_blueprints_provider.dart` for backward
/// compatibility with docs that predate `recommendedArchetypes`.
const Map<String, String> categoryToArchetype = {
  'Fitness': 'athlete',
  'Mindfulness': 'stoic',
  'Learning': 'scholar',
  'Productivity': 'zealot',
  'Creativity': 'creator',
  'Faith': 'zealot',
};

/// Archetype ids a blueprint is curated for. Explicit curation wins; legacy
/// docs fall back to the category mapping (unmapped categories, e.g. `Morning`,
/// yield an empty list).
List<String> archetypesFor(Blueprint blueprint) {
  if (blueprint.recommendedArchetypes.isNotEmpty) {
    return blueprint.recommendedArchetypes;
  }
  final mapped = categoryToArchetype[blueprint.category];
  if (mapped == null) return const [];
  return [mapped];
}

/// Whether a blueprint belongs in a tribe's curated set. Matches on curated
/// ids, then on the creator's archetype (case-insensitive, as before).
bool matchesTribe(Blueprint blueprint, String archetypeId) {
  if (archetypeId.isEmpty) return false;
  if (blueprint.creatorArchetype.toLowerCase() == archetypeId) return true;
  return archetypesFor(blueprint).contains(archetypeId);
}
