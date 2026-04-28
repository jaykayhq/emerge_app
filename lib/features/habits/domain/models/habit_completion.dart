import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class HabitCompletion extends Equatable {
  final String id;
  final String habitId;
  final String userId;
  final DateTime timestamp;
  final String? motiveUsed;
  final int streakAtCompletion;
  final int entropyImpact;

  const HabitCompletion({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.timestamp,
    this.motiveUsed,
    this.streakAtCompletion = 0,
    this.entropyImpact = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'habitId': habitId,
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'motiveUsed': motiveUsed,
      'streakAtCompletion': streakAtCompletion,
      'entropyImpact': entropyImpact,
    };
  }

  factory HabitCompletion.fromMap(Map<String, dynamic> map, String id) {
    return HabitCompletion(
      id: id,
      habitId: map['habitId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      timestamp: map['timestamp'] != null 
          ? (map['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
      motiveUsed: map['motiveUsed'] as String?,
      streakAtCompletion: map['streakAtCompletion'] as int? ?? 0,
      entropyImpact: map['entropyImpact'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        habitId,
        userId,
        timestamp,
        motiveUsed,
        streakAtCompletion,
        entropyImpact,
      ];
}
