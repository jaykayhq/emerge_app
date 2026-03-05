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

/// Top contributors for a given club.
final clubContributorsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, tribeId) {
      final repository = ref.watch(tribeRepositoryProvider);
      return repository.getClubContributors(tribeId);
    });

/// Activity feed for a given club.
final clubActivityProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, tribeId) {
      final repository = ref.watch(tribeRepositoryProvider);
      return repository.getClubActivity(tribeId);
    });
