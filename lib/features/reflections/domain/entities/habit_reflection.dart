import 'package:equatable/equatable.dart';

import 'mood.dart';

/// One-per-(userId, habitId, localDate) mood + note entry for a single habit.
class HabitReflection extends Equatable {
  final String id;
  final String userId;
  final String habitId;
  final DateTime localDate;
  final Mood mood;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HabitReflection({
    required this.id,
    required this.userId,
    required this.habitId,
    required this.localDate,
    required this.mood,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  HabitReflection copyWith({
    Mood? mood,
    String? note,
    DateTime? updatedAt,
  }) {
    return HabitReflection(
      id: id,
      userId: userId,
      habitId: habitId,
      localDate: localDate,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    habitId,
    localDate,
    mood,
    note,
    createdAt,
    updatedAt,
  ];
}
