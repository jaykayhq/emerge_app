import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/data/repositories/tribe_repository.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tribeRepositoryProvider = Provider<TribeRepository>((ref) {
  return FirestoreTribeRepository(FirebaseFirestore.instance);
});

/// The user's archetype club — auto-joined based on their archetype.
final userClubProvider = FutureProvider.family<Tribe?, String>((
  ref,
  archetypeId,
) {
  final repository = ref.watch(tribeRepositoryProvider);
  return repository.getArchetypeClub(archetypeId);
});

/// All official archetype clubs.
final allArchetypeClubsProvider = FutureProvider<List<Tribe>>((ref) {
  final repository = ref.watch(tribeRepositoryProvider);
  return repository.getArchetypeClubs();
});

/// Real-time stream of top contributors for a given club.
///
/// Takes a [tribeId] as parameter and streams the contributors collection,
/// ordered by contributionCount descending, limited to 10 items.
final clubContributorsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, tribeId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('tribes')
      .doc(tribeId)
      .collection('contributors')
      .orderBy('contributionCount', descending: true)
      .limit(10)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});

/// Real-time stream of activity feed for a given club.
///
/// Takes a [tribeId] as parameter and streams the activity collection,
/// ordered by timestamp descending, limited to 20 items.
final clubActivityProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, tribeId) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('tribes')
      .doc(tribeId)
      .collection('activity')
      .orderBy('timestamp', descending: true)
      .limit(20)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});
