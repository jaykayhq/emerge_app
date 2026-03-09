import 'package:cloud_firestore/cloud_firestore.dart';

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

class AppNotification {
  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? expiresAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    Map<String, dynamic>? data,
    this.read = false,
    required this.createdAt,
    this.readAt,
    this.expiresAt,
  }) : data = data ?? {};

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      type: AppNotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AppNotificationType.system,
      ),
      title: map['title'] as String,
      body: map['body'] as String,
      data: Map<String, dynamic>.from(map['data'] as Map? ?? {}),
      read: map['read'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      readAt: map['readAt'] != null
          ? (map['readAt'] as Timestamp).toDate()
          : null,
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'body': body,
      'data': data,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
      if (readAt != null) 'readAt': Timestamp.fromDate(readAt!),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
    };
  }

  /// Create entity from Firestore document
  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AppNotification.fromMap(data, doc.id);
  }

  /// Convert to Firestore map (excludes 'id' as it's the document ID)
  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  AppNotification copyWith({
    String? id,
    AppNotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? read,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? expiresAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
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
