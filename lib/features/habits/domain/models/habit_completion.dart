import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class HabitCompletion extends Equatable {
  final String id;
  final String habitId;
  final String userId;
  final DateTime completedAt;
  final int momentumAtCompletion;
  final int? completedAtHour;    // 0-23, for AI time-pattern detection
  final bool wasRecovery;        // true if completed after a miss

  const HabitCompletion({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.completedAt,
    required this.momentumAtCompletion,
    this.completedAtHour,
    this.wasRecovery = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'userId': userId,
      'completedAt': Timestamp.fromDate(completedAt),
      'momentumAtCompletion': momentumAtCompletion,
      'completedAtHour': completedAtHour,
      'wasRecovery': wasRecovery,
    };
  }

  factory HabitCompletion.fromMap(Map<String, dynamic> map) {
    return HabitCompletion(
      id: map['id'] as String? ?? '',
      habitId: map['habitId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      completedAt: (map['completedAt'] as Timestamp).toDate(),
      momentumAtCompletion: (map['momentumAtCompletion'] as int?) ?? 0,
      completedAtHour: map['completedAtHour'] as int?,
      wasRecovery: (map['wasRecovery'] as bool?) ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        habitId,
        userId,
        completedAt,
        momentumAtCompletion,
        completedAtHour,
        wasRecovery,
      ];
}
