import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/models/challenge_catalog.dart';

abstract class ChallengeRepository {
  Future<List<Challenge>> getChallenges({bool featuredOnly = false});
  Future<List<Challenge>> getUserChallenges(String userId);
  Future<void> joinChallenge(String userId, String challengeId);
  Future<void> createSoloChallenge(String userId, Challenge challenge);
  Future<void> updateProgress(String userId, String challengeId, int progress);
  Future<void> completeChallenge(String userId, String challengeId);
  Future<List<Challenge>> getChallengesByArchetype(String archetypeId);
  Future<Challenge?> getWeeklySpotlight({String? archetypeId});
  Future<List<Map<String, dynamic>>> getLeaderboard(
    String challengeId, {
    int limit = 3,
  });
}

class FirestoreChallengeRepository implements ChallengeRepository {
  final FirebaseFirestore _firestore;

  FirestoreChallengeRepository(this._firestore);

  @override
  Future<List<Challenge>> getChallenges({bool featuredOnly = false}) async {
    Query query = _firestore.collection('challenges');
    if (featuredOnly) {
      query = query.where('isFeatured', isEqualTo: true);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      return Challenge.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
    }).toList();
  }

  @override
  Future<List<Challenge>> getUserChallenges(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('challenges')
        .get();
    return snapshot.docs.map((doc) {
      return Challenge.fromMap(doc.data(), id: doc.id);
    }).toList();
  }

  @override
  Future<void> joinChallenge(String userId, String challengeId) async {
    final challengeDoc = await _firestore
        .collection('challenges')
        .doc(challengeId)
        .get();

    Map<String, dynamic>? challengeData;

    // Fallback to local ChallengeCatalog if the global doc hasn't been created yet
    if (!challengeDoc.exists) {
      final localChallenge = ChallengeCatalog.getChallengeById(challengeId);
      if (localChallenge == null) {
        throw Exception('Challenge not found globally or locally.');
      }
      challengeData = localChallenge.toMap();
      // Write the global doc instantly so other users can see participants
      await _firestore
          .collection('challenges')
          .doc(challengeId)
          .set(challengeData);
    } else {
      challengeData = challengeDoc.data();
    }

    if (challengeData == null) {
      throw Exception('Challenge data is null');
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('challenges')
        .doc(challengeId)
        .set({
          ...challengeData,
          'joinedAt': FieldValue.serverTimestamp(),
          'status': ChallengeStatus.active.name,
          'currentDay': 0,
        });

    await _firestore.collection('challenges').doc(challengeId).update({
      'participants': FieldValue.increment(1),
    });
  }

  @override
  Future<void> createSoloChallenge(String userId, Challenge challenge) async {
    // 1. We create the raw challenge document
    final challengeData = challenge.toMap();

    // 2. We set it directly into the user's active challenges subcollection
    // Because it's a solo challenge, we don't need a global document for others to discover
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('challenges')
        .doc(challenge.id)
        .set({
          ...challengeData,
          'joinedAt': FieldValue.serverTimestamp(),
          'status': ChallengeStatus.active.name,
          'currentDay': 0,
        });
  }

  @override
  Future<void> updateProgress(
    String userId,
    String challengeId,
    int progress,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('challenges')
        .doc(challengeId)
        .update({'currentDay': progress});
  }

  @override
  Future<void> completeChallenge(String userId, String challengeId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('challenges')
        .doc(challengeId)
        .update({'status': ChallengeStatus.completed.name});
  }

  @override
  Future<List<Challenge>> getChallengesByArchetype(String archetypeId) async {
    // Rely exclusively on the local ChallengeCatalog for robust frontend logic
    return ChallengeCatalog.getAvailableChallenges(archetypeId);
  }

  @override
  Future<Challenge?> getWeeklySpotlight({String? archetypeId}) async {
    // Generate weekly challenge locally instead of pinging Firestore
    if (archetypeId != null) {
      return ChallengeCatalog.getWeeklySpotlight(archetypeId);
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> getLeaderboard(
    String challengeId, {
    int limit = 3,
  }) async {
    final snapshot = await _firestore
        .collection('challenges')
        .doc(challengeId)
        .collection('participants')
        .orderBy('xp', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }
}
