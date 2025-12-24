import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';

abstract class TribeRepository {
  Future<List<Tribe>> getTribes();
  Future<List<Tribe>> getUserTribes(String userId);
  Future<void> createTribe(Tribe tribe);
  Future<void> joinTribe(String userId, String tribeId);
  Future<void> leaveTribe(String userId, String tribeId);
}

class FirestoreTribeRepository implements TribeRepository {
  final FirebaseFirestore _firestore;

  FirestoreTribeRepository(this._firestore);

  @override
  Future<List<Tribe>> getTribes() async {
    final snapshot = await _firestore.collection('tribes').get();
    return snapshot.docs.map((doc) => Tribe.fromMap(doc.data())).toList();
  }

  @override
  Future<List<Tribe>> getUserTribes(String userId) async {
    // Assuming a subcollection 'members' or a field 'members' in tribe
    // For simplicity, querying 'tribes' where 'members' array contains userId
    // Note: This requires 'members' field in Tribe/Firestore which we didn't explicitly add to the model
    // but implies member management.
    // Alternatively, a 'user_tribes' collection.
    // Let's assume a 'members' array of Strings in the firestore doc for now,
    // even if not fully in the model yet, or we fetch all and filter (inefficient but works for now).
    // Better: 'users/{userId}/tribes' subcollection.

    // This would return IDs, then we fetch tribes.
    // Or we store summary in user_tribes.

    // Let's stick to querying tribes collection for now if possible, or just return empty if not implemented yet.
    // Ideally:
    // final snapshot = await _firestore.collection('tribes').where('members', arrayContains: userId).get();

    final query = await _firestore
        .collection('tribes')
        .where('members', arrayContains: userId)
        .get();
    return query.docs.map((doc) => Tribe.fromMap(doc.data())).toList();
  }

  @override
  Future<void> createTribe(Tribe tribe) async {
    await _firestore.collection('tribes').doc(tribe.id).set(tribe.toMap());
    // Also add creator to members
    await joinTribe(tribe.ownerId, tribe.id);
  }

  @override
  Future<void> joinTribe(String userId, String tribeId) async {
    final tribeRef = _firestore.collection('tribes').doc(tribeId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(tribeRef);
      if (!snapshot.exists) {
        throw Exception("Tribe does not exist!");
      }

      // Add user to 'members' array field in tribe document
      transaction.update(tribeRef, {
        'members': FieldValue.arrayUnion([userId]),
        'memberCount': FieldValue.increment(1),
      });

      // Optionally add to user's 'tribes' subcollection
      final userTribeRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tribes')
          .doc(tribeId);
      transaction.set(userTribeRef, {'joinedAt': FieldValue.serverTimestamp()});
    });
  }

  @override
  Future<void> leaveTribe(String userId, String tribeId) async {
    final tribeRef = _firestore.collection('tribes').doc(tribeId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(tribeRef);
      if (!snapshot.exists) {
        throw Exception("Tribe does not exist!");
      }

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
