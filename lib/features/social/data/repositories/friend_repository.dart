import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/domain/entities/app_notification.dart';
import 'package:emerge_app/core/services/social_notification_service.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:emerge_app/features/social/domain/repositories/friend_repository.dart';

import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:emerge_app/features/social/domain/services/friend_presence.dart';

class FirestoreFriendRepository implements FriendRepository {
  final FirebaseFirestore _firestore;
  final SocialActivityService? _socialActivityService;

  /// Optional in-app notification sender. When provided, partner requests
  /// and acceptances surface on the other end immediately instead of only
  /// being discoverable by opening the friends screen.
  final SocialNotificationService? _notifications;

  FirestoreFriendRepository(
    this._firestore, [
    this._socialActivityService,
    this._notifications,
  ]);

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
    // Guard: prevent a user from adding themselves as a friend.
    // This prevents the self-referential friends subcollection document that
    // causes duplicate leaderboard entries.
    if (userId == friendId) {
      throw Exception('You cannot add yourself as a friend.');
    }

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

    await _notify(
      toId,
      () => _notifications!.createFriendRequestNotification(
        senderName: senderName,
        senderId: fromId,
        senderArchetype: senderArchetype,
      ),
    );
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

    // Log social activity
    if (_socialActivityService != null) {
      _socialActivityService.logPartnerJoined(
        userId: recipientId,
        userName:
            data['recipientName'] ??
            'A member', // Assuming we add this to request
        archetype: data['recipientArchetype'] ?? 'Stoic',
        partnerName: data['senderName'] ?? 'a partner',
      );
    }

    // Tell the original sender who accepted them.
    final recipientDoc = await _firestore
        .collection('users')
        .doc(recipientId)
        .get();
    final recipientData = recipientDoc.data() ?? {};

    await _notify(
      senderId,
      () => _notifications!.createFriendRequestAcceptedNotification(
        friendName:
            recipientData['displayName'] as String? ??
            recipientData['name'] as String? ??
            'Someone',
        friendId: recipientId,
      ),
    );
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
      final presence = <String, PresenceInfo>{};
      for (final friend in friends) {
        final doc = await _presenceDoc(friend.id).get();
        if (!doc.exists) continue;
        presence[friend.id] = _parsePresence(doc.data()!);
      }
      return FriendPresence.markOnline(friends, presence);
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
    // Presence lives in each user's `presence/status` doc, not in the cached
    // friend record, so derive online state by combining both streams.
    late StreamController<List<Friend>> controller;
    StreamSubscription<List<Friend>>? friendsSub;
    final presenceSubs =
        <String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>{};
    final friendsById = <String, Friend>{};
    final presence = <String, PresenceInfo>{};

    /// Friend ids whose presence doc has not delivered its first snapshot.
    /// Emissions wait until this is empty so listeners never see a
    /// partially-resolved online set.
    final pendingPresence = <String>{};

    void emit() {
      if (!controller.hasListener) return;
      if (pendingPresence.isNotEmpty) return;
      final resolved = FriendPresence.markOnline(
        friendsById.values.toList(),
        presence,
      );
      controller.add(resolved);
    }

    void syncPresenceSubs() {
      for (final id in friendsById.keys) {
        if (presenceSubs.containsKey(id)) continue;
        pendingPresence.add(id);
        presenceSubs[id] = _presenceDoc(id).snapshots().listen((snapshot) {
          final data = snapshot.data();
          if (data != null) presence[id] = _parsePresence(data);
          pendingPresence.remove(id);
          emit();
        });
      }
      for (final id in List<String>.of(presenceSubs.keys)) {
        if (friendsById.containsKey(id)) continue;
        presenceSubs.remove(id)?.cancel();
        presence.remove(id);
        pendingPresence.remove(id);
      }
      emit();
    }
    controller = StreamController<List<Friend>>(
      onListen: () {
        friendsSub = watchFriends(userId).listen((friends) {
          friendsById
            ..clear()
            ..addEntries(friends.map((f) => MapEntry(f.id, f)));
          syncPresenceSubs();
          emit();
        });
      },
      onPause: () => friendsSub?.pause(),
      onResume: () => friendsSub?.resume(),
      onCancel: () async {
        await friendsSub?.cancel();
        for (final sub in presenceSubs.values) {
          await sub.cancel();
        }
        presenceSubs.clear();
      },
    );
    return controller.stream;
  }

  DocumentReference<Map<String, dynamic>> _presenceDoc(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('presence')
        .doc('status');
  }

  PresenceInfo _parsePresence(Map<String, dynamic> data) {
    final lastSeenRaw = data['lastSeen'];
    final lastSeen = lastSeenRaw is Timestamp ? lastSeenRaw.toDate() : null;
    return (onlineFlag: data['online'] as bool? ?? false, lastSeen: lastSeen);
  }

  /// Sends an in-app notification without ever failing the surrounding
  /// operation — a missed notification must not break the friend action.
  Future<void> _notify(
    String userId,
    AppNotification Function() build,
  ) async {
    final service = _notifications;
    if (service == null) return;
    try {
      await service.sendNotification(userId, build());
    } catch (_) {
      // Non-blocking: the request/acceptance itself already succeeded.
    }
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
    // Generate a secure 6-character alphanumeric code
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = math.Random.secure();
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
