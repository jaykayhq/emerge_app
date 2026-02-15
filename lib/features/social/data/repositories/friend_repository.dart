import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';

abstract class FriendRepository {
  Future<List<Friend>> getFriends(String userId);
  Future<void> addFriend(String userId, String friendId);
  Future<void> removeFriend(String userId, String friendId);
}

class FirestoreFriendRepository implements FriendRepository {
  final FirebaseFirestore _firestore;

  FirestoreFriendRepository(this._firestore);

  @override
  Future<List<Friend>> getFriends(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('friends')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Ensure ID is set from doc ID if not in data
        data['id'] = doc.id;
        return Friend.fromMap(data);
      }).toList();
    } catch (e) {
      // Return empty list on error for now, or rethrow
      return [];
    }
  }

  @override
  Future<void> addFriend(String userId, String friendId) async {
    // In a real app, this would likely trigger a cloud function to:
    // 1. Verify friend exists
    // 2. Create mutual friend records
    // 3. Populate initial data (name, basics)
    // For now, we'll assume the UI or specific flow handles creating the document
    // with the necessary 'Friend' data fields.
    throw UnimplementedError('Friend addition handled via invites/functions');
  }

  @override
  Future<void> removeFriend(String userId, String friendId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc(friendId)
        .delete();
  }
}
