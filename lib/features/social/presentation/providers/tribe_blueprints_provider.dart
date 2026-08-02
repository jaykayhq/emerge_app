import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/blueprints/domain/services/blueprint_curation.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tribeBlueprintsProvider =
    StreamProvider.autoDispose.family<List<Blueprint>, String>((
  ref,
  tribeArchetypeId,
) {
  final repository = ref.watch(blueprintRepositoryProvider);
  return repository.getBlueprints().map((blueprints) {
    final id = tribeArchetypeId.toLowerCase();
    return blueprints.where((bp) => matchesTribe(bp, id)).toList();
  });
});

/// Blueprints for the user's active tribe. Archetype clubs get their curated
/// set via [matchesTribe]; creator tribes carry no archetype id, so they
/// surface the tribe's own published blueprints instead. Emits an empty list
/// when no active membership exists.
final tribeBlueprintsForActiveTribeProvider =
    StreamProvider.autoDispose<List<Blueprint>>((ref) {
  final membership = ref.watch(activeMembershipProvider).value;
  final clubs = ref.watch(allArchetypeClubsProvider).value ?? [];
  final repo = ref.watch(blueprintRepositoryProvider);
  if (membership == null) return Stream.value([]);
  final tribe = clubs.where((t) => t.id == membership.tribeId).firstOrNull;
  final archetypeId = tribe?.archetypeId;
  if (archetypeId == null) {
    return repo.getBlueprints().map((blueprints) {
      return blueprints
          .where((bp) => bp.creatorTribeId == membership.tribeId)
          .toList();
    });
  }
  final id = archetypeId.toLowerCase();
  return repo.getBlueprints().map((blueprints) {
    return blueprints.where((bp) => matchesTribe(bp, id)).toList();
  });
});

/// Blueprints published by a creator tribe, keyed by tribe id.
final tribeCreatorBlueprintsProvider =
    StreamProvider.autoDispose.family<List<Blueprint>, String>((ref, tribeId) {
  final repository = ref.watch(blueprintRepositoryProvider);
  return repository.getBlueprints().map((blueprints) {
    return blueprints.where((bp) => bp.creatorTribeId == tribeId).toList();
  });
});
