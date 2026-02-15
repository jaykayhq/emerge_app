import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emerge_app/features/social/data/repositories/challenge_repository.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return FirestoreChallengeRepository(FirebaseFirestore.instance);
});

final featuredChallengesProvider = FutureProvider<List<Challenge>>((ref) async {
  final repository = ref.read(challengeRepositoryProvider);
  return repository.getChallenges(featuredOnly: true);
});

final allChallengesProvider = FutureProvider<List<Challenge>>((ref) async {
  final repository = ref.read(challengeRepositoryProvider);
  return repository.getChallenges(featuredOnly: false);
});

final userChallengesProvider = FutureProvider<List<Challenge>>((ref) async {
  final repository = ref.read(challengeRepositoryProvider);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];
  return repository.getUserChallenges(user.uid);
});

final filteredChallengesProvider =
    FutureProvider.family<List<Challenge>, ChallengeStatus>((
      ref,
      status,
    ) async {
      if (status == ChallengeStatus.featured) {
        return ref.watch(featuredChallengesProvider.future);
      } else {
        final userChallenges = await ref.watch(userChallengesProvider.future);
        return userChallenges.where((c) => c.status == status).toList();
      }
    });
