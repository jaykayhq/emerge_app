import 'package:emerge_app/features/social/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final blueprintsStreamProvider = StreamProvider<List<CreatorBlueprint>>((ref) {
  final repository = ref.watch(blueprintRepositoryProvider);
  
  // Trigger seeding if empty - non-blocking but ensures data presence
  repository.seedBlueprintsIfEmpty();
  
  return repository.getBlueprints();
});
