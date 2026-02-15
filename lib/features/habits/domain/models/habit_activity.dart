import 'package:cloud_firestore/cloud_firestore.dart';

class HabitActivity {
  final String id;
  final String habitId;
  final String userId;
  final DateTime date;
  final String type;

  const HabitActivity({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.date,
    required this.type,
  });

  factory HabitActivity.fromMap(Map<String, dynamic> map, String id) {
    return HabitActivity(
      id: id,
      habitId: map['habitId'] ?? '',
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      type: map['type'] ?? 'habit_completion',
    );
  }
}
