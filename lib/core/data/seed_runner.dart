import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';

// NOTE: seedChallenges was removed — the client write to the `challenges`
// collection is admin-only under the current Firestore rules and always
// failed into a debugPrint catch. Catalog challenges are seeded server-side
// and creator-authored challenges are written by verified creators through
// createCatalogChallenge.

Future<void> seedBlueprints({FirebaseFirestore? firestore}) async {
  try {
    final repo = BlueprintRepository(firestore ?? FirebaseFirestore.instance);
    await repo.seedBlueprintsIfEmpty();
  } catch (e) {
    debugPrint('❌ Error seeding blueprints: $e');
  }
}
