import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:emerge_app/features/social/domain/repositories/friend_repository.dart';

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
  Stream<List<Friend>> watchFriends(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Friend.fromMap(data);
          }).toList();
        });
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

  @override
  Stream<List<PartnerRequest>> watchPendingRequests(String userId) {
    return _firestore
        .collection('partner_requests')
        .where('recipientId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PartnerRequest.fromMap(doc.data(), id: doc.id))
              .toList();
        });
  }

  @override
  Stream<List<Friend>> watchOnlinePartners(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Friend.fromMap(data);
          }).toList();
        });
  }

  @override
  Stream<bool> watchOnlineStatus(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('presence')
        .doc('status')
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return false;
          final data = snapshot.data();
          if (data == null) return false;

          final isOnline = data['online'] as bool? ?? false;
          final lastSeen = data['lastSeen'] as Timestamp?;

          if (!isOnline || lastSeen == null) return false;

          // Double check: if last heartbeat was > 5 minutes ago, consider offline
          final fiveMinutesAgo = DateTime.now().subtract(
            const Duration(minutes: 5),
          );
          return lastSeen.toDate().isAfter(fiveMinutesAgo);
        });
  }

  // ============ INVITATIONS ============

  @override
  Future<String> generateInviteCode(String userId) async {
    // Generate a simple 6-character alphanumeric code
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = math.Random();
    final code = String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );

    // Store in invite_codes collection
    await _firestore.collection('invite_codes').doc(code).set({
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return code;
  }

  @override
  Future<void> redeemInviteCode(String userId, String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      throw Exception('Invite code cannot be empty.');
    }

    final doc = await _firestore
        .collection('invite_codes')
        .doc(cleanCode)
        .get();

    if (!doc.exists) {
      throw Exception('Invalid or expired invite code.');
    }

    final data = doc.data()!;
    final partnerId = data['userId'] as String;

    if (partnerId == userId) {
      throw Exception('You cannot use your own invite code.');
    }

    // Check if already friends
    final friendDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc(partnerId)
        .get();

    if (friendDoc.exists) {
      throw Exception('You are already partners with this user.');
    }

    // Add friend connections in both directions
    await addFriend(userId, partnerId);

    // Delete code (single-use) to prevent abuse
    await doc.reference.delete();
  }
}
