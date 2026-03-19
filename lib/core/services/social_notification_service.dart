import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:emerge_app/core/domain/entities/app_notification.dart';
import 'package:emerge_app/core/utils/app_logger.dart';

part 'social_notification_service.g.dart';

/// Service for managing in-app notifications for social interactions.
/// Stores notifications in Firestore subcollection: users/{userId}/notifications
@Riverpod(keepAlive: true)
SocialNotificationService socialNotificationService(Ref ref) {
  return SocialNotificationService(FirebaseFirestore.instance);
}

class SocialNotificationService {
  final FirebaseFirestore _firestore;

  SocialNotificationService(this._firestore);

  CollectionReference<Map<String, dynamic>> _notificationsCollection(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

  /// Sends a notification to a specific user.
  /// Automatically creates a new document with a unique ID.
  Future<DocumentReference<Map<String, dynamic>>> sendNotification(
    String userId,
    AppNotification notification,
  ) async {
    final docRef = await _notificationsCollection(
      userId,
    ).add(notification.toFirestore());

    // Increment unread count in user document
    await _firestore.collection('users').doc(userId).set({
      'unreadNotificationCount': FieldValue.increment(1),
      'lastNotificationAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return docRef;
  }

  /// Sends notifications to multiple users (batch operation).
  /// Useful for tribe-wide announcements or challenge broadcasts.
  Future<void> sendNotificationToMultiple(
    List<String> userIds,
    AppNotification notification,
  ) async {
    final batch = _firestore.batch();

    for (final userId in userIds) {
      final docRef = _notificationsCollection(userId).doc();
      batch.set(docRef, notification.toFirestore());

      // Increment unread count
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'unreadNotificationCount': FieldValue.increment(1),
        'lastNotificationAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead(String userId, String notificationId) async {
    await _notificationsCollection(userId).doc(notificationId).update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    });

    // Decrement unread count
    await _firestore.collection('users').doc(userId).update({
      'unreadNotificationCount': FieldValue.increment(-1),
    });
  }

  /// Marks all notifications for a user as read.
  Future<void> markAllAsRead(String userId) async {
    final unreadQuery = await _notificationsCollection(
      userId,
    ).where('read', isEqualTo: false).get();

    if (unreadQuery.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unreadQuery.docs) {
      batch.update(doc.reference, {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    // Reset unread count to 0
    await _firestore.collection('users').doc(userId).update({
      'unreadNotificationCount': 0,
    });
  }

  /// Deletes a specific notification.
  Future<void> deleteNotification(String userId, String notificationId) async {
    final docRef = _notificationsCollection(userId).doc(notificationId);
    final doc = await docRef.get();

    // Only decrement count if notification was unread
    if (doc.exists && doc.data()?['read'] == false) {
      await _firestore.collection('users').doc(userId).update({
        'unreadNotificationCount': FieldValue.increment(-1),
      });
    }

    await docRef.delete();
  }

  /// Deletes all notifications for a user.
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final snapshot = await _notificationsCollection(userId).get();

      if (snapshot.docs.isEmpty) {
        // No notifications to delete
        return;
      }

      // Create a batch for atomic operations
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      // Commit the batch (this awaits all deletes)
      await batch.commit();

      // Reset unread count to 0
      await _firestore.collection('users').doc(userId).update({
        'unreadNotificationCount': 0,
      });

      AppLogger.i(
        'Deleted ${snapshot.docs.length} notifications for user $userId',
      );
    } catch (e, stack) {
      AppLogger.e('Failed to delete all notifications', e, stack);
      // Don't throw - silently handle the error to prevent UI crashes
    }
  }

  /// Deletes expired notifications (cleanup job).
  /// Should be called periodically (e.g., on app start).
  Future<void> deleteExpiredNotifications(String userId) async {
    final now = DateTime.now();
    final expiredQuery = await _notificationsCollection(
      userId,
    ).where('expiresAt', isLessThan: now.toIso8601String()).get();

    final batch = _firestore.batch();
    for (final doc in expiredQuery.docs) {
      batch.delete(doc.reference);
    }

    if (expiredQuery.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  /// Stream of unread notifications for a user.
  Stream<List<AppNotification>> unreadNotificationsStream(String userId) {
    return _notificationsCollection(userId)
        .where('read', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AppNotification.fromFirestore(doc))
              .toList();
        });
  }

  /// Stream of all notifications for a user (paginated).
  Stream<List<AppNotification>> notificationsStream(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) {
    Query<Map<String, dynamic>> query = _notificationsCollection(
      userId,
    ).orderBy('createdAt', descending: true).limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();
    });
  }

  /// Stream of unread count (from user document).
  Stream<int> unreadCountStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      final data = doc.data();
      return data?['unreadNotificationCount'] as int? ?? 0;
    });
  }

  /// Gets the current unread count (one-time fetch).
  Future<int> getUnreadCount(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data();
    return data?['unreadNotificationCount'] as int? ?? 0;
  }

  /// Creates a notification from type and basic data.
  /// Helper method to ensure consistent notification structure.
  AppNotification createNotification({
    required AppNotificationType type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    Duration? expiration,
  }) {
    return AppNotification(
      id: '', // Will be set by Firestore
      type: type,
      title: title,
      body: body,
      data: data,
      createdAt: DateTime.now(),
      expiresAt: expiration != null ? DateTime.now().add(expiration) : null,
    );
  }

  /// Notification helper for friend requests.
  AppNotification createFriendRequestNotification({
    required String senderName,
    required String senderId,
    String senderArchetype = 'creator',
  }) {
    return createNotification(
      type: AppNotificationType.friendRequest,
      title: 'New Friend Request',
      body: '$senderName wants to be your accountability partner',
      data: {
        'senderId': senderId,
        'senderName': senderName,
        'senderArchetype': senderArchetype,
        'route': '/social/friends',
      },
      expiration: const Duration(days: 30),
    );
  }

  /// Notification helper for friend request accepted.
  AppNotification createFriendRequestAcceptedNotification({
    required String friendName,
    required String friendId,
  }) {
    return createNotification(
      type: AppNotificationType.friendRequestAccepted,
      title: 'Friend Request Accepted',
      body: '$friendName is now your accountability partner',
      data: {
        'friendId': friendId,
        'friendName': friendName,
        'route': '/social/friends',
      },
    );
  }

  /// Notification helper for challenge invites.
  AppNotification createChallengeInviteNotification({
    required String challengeTitle,
    required String challengeId,
    required String inviterName,
    int? xpReward,
  }) {
    return createNotification(
      type: AppNotificationType.challengeInvite,
      title: 'Challenge Invite',
      body:
          '$inviterName invited you to: $challengeTitle'
          '${xpReward != null ? ' ($xpReward XP)' : ''}',
      data: {
        'challengeId': challengeId,
        'challengeTitle': challengeTitle,
        'inviterName': inviterName,
        'route': '/challenges/$challengeId',
      },
      expiration: const Duration(days: 7),
    );
  }

  /// Notification helper for achievement unlocks.
  AppNotification createAchievementNotification({
    required String achievementName,
    required String achievementDescription,
  }) {
    return createNotification(
      type: AppNotificationType.achievement,
      title: 'Achievement Unlocked',
      body: '$achievementName: $achievementDescription',
      data: {
        'achievementName': achievementName,
        'achievementDescription': achievementDescription,
        'route': '/profile',
      },
    );
  }

  /// Notification helper for level ups.
  AppNotification createLevelUpNotification({required int newLevel}) {
    return createNotification(
      type: AppNotificationType.levelUp,
      title: 'Level Up!',
      body: 'You reached level $newLevel',
      data: {'newLevel': newLevel, 'route': '/profile'},
    );
  }

  /// Notification helper for tribe activities.
  AppNotification createTribeActivityNotification({
    required String tribeName,
    required String tribeId,
    required String activityDescription,
  }) {
    return createNotification(
      type: AppNotificationType.tribeActivity,
      title: 'Tribe Activity',
      body: '$tribeName: $activityDescription',
      data: {
        'tribeId': tribeId,
        'tribeName': tribeName,
        'route': '/social/tribes/$tribeId',
      },
    );
  }
}
