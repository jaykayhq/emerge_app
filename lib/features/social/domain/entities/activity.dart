import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  habitComplete,
  levelUp,
  challengeComplete,
  challengeJoin,
  streakMilestone,
  nodeClaim,
}

class Activity {
  final String id;
  final ActivityType type;
  final String userId;
  final String userName;
  final String archetypeId;
  final String? clubId;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  Activity({
    required this.id,
    required this.type,
    required this.userId,
    required this.userName,
    required this.archetypeId,
    this.clubId,
    required this.data,
    required this.timestamp,
  });

  factory Activity.fromMap(Map<String, dynamic> map, String id) {
    return Activity(
      id: id,
      type: ActivityType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ActivityType.habitComplete,
      ),
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      archetypeId: map['archetypeId'] as String,
      clubId: map['clubId'] as String?,
      data: Map<String, dynamic>.from(map['data'] as Map),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'userId': userId,
      'userName': userName,
      'archetypeId': archetypeId,
      'clubId': clubId,
      'data': data,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  Activity copyWith({
    String? id,
    ActivityType? type,
    String? userId,
    String? userName,
    String? archetypeId,
    String? clubId,
    Map<String, dynamic>? data,
    DateTime? timestamp,
  }) {
    return Activity(
      id: id ?? this.id,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      archetypeId: archetypeId ?? this.archetypeId,
      clubId: clubId ?? this.clubId,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
