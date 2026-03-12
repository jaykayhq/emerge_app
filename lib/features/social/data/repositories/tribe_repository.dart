import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';

/// Repository for archetype-based clubs (tribes).
/// Users are auto-assigned to their archetype club — no user creation.
abstract class TribeRepository {
  /// Get the official club for a specific archetype.
  Future<Tribe?> getArchetypeClub(String archetypeId);

  /// Get all official archetype clubs.
  Future<List<Tribe>> getArchetypeClubs();

  /// Watch all official archetype clubs.
  Stream<List<Tribe>> watchArchetypeClubs();

  /// Get top contributors for a club.
  Future<List<Map<String, dynamic>>> getClubContributors(
    String tribeId, {
    int limit = 10,
  });

  /// Get recent activity feed for a club.
  Future<List<Map<String, dynamic>>> getClubActivity(
    String tribeId, {
    int limit = 20,
  });

  /// Join a club (auto-called when user selects archetype).
  Future<void> joinClub(String userId, String tribeId);

  /// Leave a club (when user changes archetype).
  Future<void> leaveClub(String userId, String tribeId);
}

class FirestoreTribeRepository implements TribeRepository {
  final FirebaseFirestore _firestore;

  FirestoreTribeRepository(this._firestore);

  @override
  Future<Tribe?> getArchetypeClub(String archetypeId) async {
    final snapshot = await _firestore
        .collection('tribes')
        .where('archetypeId', isEqualTo: archetypeId)
        .where('type', isEqualTo: TribeType.official.name)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Tribe.fromMap(snapshot.docs.first.data());
  }

  @override
  Future<List<Tribe>> getArchetypeClubs() async {
    final snapshot = await _firestore
        .collection('tribes')
        .where('type', isEqualTo: TribeType.official.name)
        .orderBy('archetypeId')
        .get();

    return snapshot.docs.map((doc) => Tribe.fromMap(doc.data())).toList();
  }

  @override
  Stream<List<Tribe>> watchArchetypeClubs() {
    return _firestore
        .collection('tribes')
        .where('type', isEqualTo: TribeType.official.name)
        .orderBy('archetypeId')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => Tribe.fromMap(doc.data())).toList(),
        );
  }

  @override
  Future<List<Map<String, dynamic>>> getClubContributors(
    String tribeId, {
    int limit = 10,
  }) async {
    final snapshot = await _firestore
        .collection('tribes')
        .doc(tribeId)
        .collection('contributors')
        .orderBy('xp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getClubActivity(
    String tribeId, {
    int limit = 20,
  }) async {
    final snapshot = await _firestore
        .collection('tribes')
        .doc(tribeId)
        .collection('activity')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Future<void> joinClub(String userId, String tribeId) async {
    final tribeRef = _firestore.collection('tribes').doc(tribeId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(tribeRef);
      if (!snapshot.exists) {
        throw Exception('Club does not exist!');
      }

      transaction.update(tribeRef, {
        'members': FieldValue.arrayUnion([userId]),
        'memberCount': FieldValue.increment(1),
      });

      final userTribeRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tribes')
          .doc(tribeId);
      transaction.set(userTribeRef, {'joinedAt': FieldValue.serverTimestamp()});
    });
  }

  @override
  Future<void> leaveClub(String userId, String tribeId) async {
    final tribeRef = _firestore.collection('tribes').doc(tribeId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(tribeRef);
      if (!snapshot.exists) return;

      transaction.update(tribeRef, {
        'members': FieldValue.arrayRemove([userId]),
        'memberCount': FieldValue.increment(-1),
      });

      final userTribeRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tribes')
          .doc(tribeId);
      transaction.delete(userTribeRef);
    });
  }
}
