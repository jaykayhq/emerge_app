import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

/// Notification types for social interactions
enum AppNotificationType {
  friendRequest,
  friendRequestAccepted,
  challengeInvite,
  challengeCompleted,
  achievement,
  tribeJoined,
  tribeActivity,
  levelUp,
  milestone,
  system,
}

/// Entity representing an in-app notification for social interactions.
/// Stored in Firestore subcollection: users/{userId}/notifications
@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    /// Unique notification ID (Firestore document ID)
    required String id,

    /// Type of notification
    required AppNotificationType type,

    /// Notification title (short, bold text)
    required String title,

    /// Notification body (longer descriptive text)
    required String body,

    /// Additional data payload for navigation/action handling
    /// e.g., {'userId': 'abc123', 'challengeId': 'xyz789'}
    @Default({}) Map<String, dynamic> data,

    /// Whether the notification has been read
    @Default(false) bool read,

    /// When the notification was created
    required DateTime createdAt,

    /// Optional timestamp for when notification was read
    DateTime? readAt,

    /// Optional expiration time (auto-delete after this)
    DateTime? expiresAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

  /// Create entity from Firestore document
  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AppNotification.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  /// Convert to Firestore map (excludes 'id' as it's the document ID)
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    return json;
  }
}

extension AppNotificationExt on AppNotification {
  /// Check if notification has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Get route path from data payload for navigation
  String? get routePath {
    if (data.containsKey('route')) return data['route'] as String?;

    // Derive route from notification type
    switch (type) {
      case AppNotificationType.friendRequest:
      case AppNotificationType.friendRequestAccepted:
        return '/social/friends';
      case AppNotificationType.challengeInvite:
      case AppNotificationType.challengeCompleted:
        return data['challengeId'] != null
            ? '/challenges/${data['challengeId']}'
            : '/challenges';
      case AppNotificationType.achievement:
      case AppNotificationType.levelUp:
        return '/profile';
      case AppNotificationType.tribeJoined:
      case AppNotificationType.tribeActivity:
        return data['tribeId'] != null
            ? '/social/tribes/${data['tribeId']}'
            : '/social/tribes';
      default:
        return null;
    }
  }
}
