import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';

abstract class FriendRepository {
  Future<List<Friend>> getFriends(String userId);
  Future<void> addFriend(String userId, String friendId);
  Future<void> removeFriend(String userId, String friendId);
  Future<void> sendPartnerRequest(
    String fromId,
    String toId,
    String senderName,
    String senderArchetype,
    int senderLevel,
  );
  Future<void> acceptPartnerRequest(String requestId);
  Future<void> rejectPartnerRequest(String requestId);
  Future<List<PartnerRequest>> getPendingRequests(String userId);
  Future<List<Friend>> getOnlinePartners(String userId);
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
        data['id'] = doc.id;
        return Friend.fromMap(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addFriend(String userId, String friendId) async {
    // Get the friend's user data
    final friendDoc = await _firestore.collection('users').doc(friendId).get();
    if (!friendDoc.exists) {
      throw Exception('User not found');
    }
    final friendData = friendDoc.data() ?? {};

    // Get current user's data
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};

    // Create mutual friend records using a batch
    final batch = _firestore.batch();

    // Add friend to current user's friends subcollection
    batch.set(
      _firestore
          .collection('users')
          .doc(userId)
          .collection('friends')
          .doc(friendId),
      {
        'id': friendId,
        'name': friendData['displayName'] ?? friendData['name'] ?? 'Unknown',
        'archetype': friendData['archetype'] ?? 'creator',
        'level': friendData['avatarStats']?['level'] ?? 1,
        'streak': friendData['settings']?['currentStreak'] ?? 0,
        'isOnline': false,
        'lastSeen': 'Just now',
        'xp': friendData['avatarStats']?['currentXp'] ?? 0,
        'addedAt': FieldValue.serverTimestamp(),
      },
    );

    // Add current user to friend's friends subcollection
    batch.set(
      _firestore
          .collection('users')
          .doc(friendId)
          .collection('friends')
          .doc(userId),
      {
        'id': userId,
        'name': userData['displayName'] ?? userData['name'] ?? 'Unknown',
        'archetype': userData['archetype'] ?? 'creator',
        'level': userData['avatarStats']?['level'] ?? 1,
        'streak': userData['settings']?['currentStreak'] ?? 0,
        'isOnline': false,
        'lastSeen': 'Just now',
        'xp': userData['avatarStats']?['currentXp'] ?? 0,
        'addedAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  @override
  Future<void> removeFriend(String userId, String friendId) async {
    final batch = _firestore.batch();

    // Remove from both sides
    batch.delete(
      _firestore
          .collection('users')
          .doc(userId)
          .collection('friends')
          .doc(friendId),
    );
    batch.delete(
      _firestore
          .collection('users')
          .doc(friendId)
          .collection('friends')
          .doc(userId),
    );

    await batch.commit();
  }

  @override
  Future<void> sendPartnerRequest(
    String fromId,
    String toId,
    String senderName,
    String senderArchetype,
    int senderLevel,
  ) async {
    await _firestore.collection('partner_requests').add({
      'senderId': fromId,
      'senderName': senderName,
      'senderArchetype': senderArchetype,
      'senderLevel': senderLevel,
      'recipientId': toId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> acceptPartnerRequest(String requestId) async {
    final requestDoc = await _firestore
        .collection('partner_requests')
        .doc(requestId)
        .get();
    if (!requestDoc.exists) return;

    final data = requestDoc.data()!;
    final senderId = data['senderId'] as String;
    final recipientId = data['recipientId'] as String;

    // Create mutual friend records
    await addFriend(recipientId, senderId);

    // Update request status
    await requestDoc.reference.update({'status': 'accepted'});
  }

  @override
  Future<void> rejectPartnerRequest(String requestId) async {
    await _firestore.collection('partner_requests').doc(requestId).update({
      'status': 'rejected',
    });
  }

  @override
  Future<List<PartnerRequest>> getPendingRequests(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('partner_requests')
          .where('recipientId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs.map((doc) {
        return PartnerRequest.fromMap(doc.data(), id: doc.id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Friend>> getOnlinePartners(String userId) async {
    try {
      final friends = await getFriends(userId);
      // Return friends sorted by most recently active first
      friends.sort((a, b) {
        if (a.isOnline && !b.isOnline) return -1;
        if (!a.isOnline && b.isOnline) return 1;
        return 0;
      });
      return friends.take(5).toList();
    } catch (e) {
      return [];
    }
  }
}
