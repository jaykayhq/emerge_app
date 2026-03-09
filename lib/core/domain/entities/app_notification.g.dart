// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    _AppNotification(
      id: json['id'] as String,
      type: $enumDecode(_$AppNotificationTypeEnumMap, json['type']),
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>? ?? const {},
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$AppNotificationToJson(_AppNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$AppNotificationTypeEnumMap[instance.type]!,
      'title': instance.title,
      'body': instance.body,
      'data': instance.data,
      'read': instance.read,
      'createdAt': instance.createdAt.toIso8601String(),
      'readAt': instance.readAt?.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
    };

const _$AppNotificationTypeEnumMap = {
  AppNotificationType.friendRequest: 'friendRequest',
  AppNotificationType.friendRequestAccepted: 'friendRequestAccepted',
  AppNotificationType.challengeInvite: 'challengeInvite',
  AppNotificationType.challengeCompleted: 'challengeCompleted',
  AppNotificationType.achievement: 'achievement',
  AppNotificationType.tribeJoined: 'tribeJoined',
  AppNotificationType.tribeActivity: 'tribeActivity',
  AppNotificationType.levelUp: 'levelUp',
  AppNotificationType.milestone: 'milestone',
  AppNotificationType.system: 'system',
};
