import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';

abstract class ChallengeRepository {
  Future<List<Challenge>> getChallenges({bool featuredOnly = false});
  Future<List<Challenge>> getUserChallenges(String userId);
  Future<void> joinChallenge(String userId, String challengeId);
  Future<void> completeChallenge(String userId, String challengeId);
  Future<void> updateProgress(String userId, String challengeId, int day);
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
    return snapshot.docs
        .map((doc) => Challenge.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Challenge>> getUserChallenges(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('challenges')
        .get();
    // These docs probably only contain progress data (currentDay, status, challengeId)
    // We need to merge with the actual challenge details.
    // Ideally we fetch the base challenge for each.

    List<Challenge> userChallenges = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final challengeId = doc.id; // Assuming doc ID is challenge ID

      final challengeDoc = await _firestore
          .collection('challenges')
          .doc(challengeId)
          .get();
      if (challengeDoc.exists) {
        final baseChallenge = Challenge.fromMap(
          challengeDoc.data() as Map<String, dynamic>,
        );

        // Merge progress data
        userChallenges.add(
          baseChallenge.copyWith(
            status: ChallengeStatus.values.firstWhere(
              (e) => e.name == data['status'],
              orElse: () => ChallengeStatus.active,
            ),
            currentDay: data['currentDay'] ?? 0,
          ),
        );
      }
    }
    return userChallenges;
  }

  @override
  Future<void> joinChallenge(String userId, String challengeId) async {
    // Check if valid challenge
    final challengeRef = _firestore.collection('challenges').doc(challengeId);
    final challengeSnap = await challengeRef.get();
    if (!challengeSnap.exists) {
      throw Exception("Challenge does not exist");
    }

    // Add to user challenges
    final userChallengeRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('challenges')
        .doc(challengeId);

    await _firestore.runTransaction((transaction) async {
      // Increment participants on global challenge
      transaction.update(challengeRef, {
        'participants': FieldValue.increment(1),
      });

      // Set initial user status
      transaction.set(userChallengeRef, {
        'status': 'active',
        'currentDay': 1,
        'startDate': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> completeChallenge(String userId, String challengeId) async {
    final userChallengeRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('challenges')
        .doc(challengeId);
    await userChallengeRef.update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateProgress(
    String userId,
    String challengeId,
    int day,
  ) async {
    final userChallengeRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('challenges')
        .doc(challengeId);
    await userChallengeRef.update({
      'currentDay': day,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
}
