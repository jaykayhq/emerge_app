import 'package:equatable/equatable.dart';

import 'mood.dart';

class DailyReflection extends Equatable {
  final String id;
  final String userId;
  final DateTime localDate;
  final Mood mood;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyReflection({
    required this.id,
    required this.userId,
    required this.localDate,
    required this.mood,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  DailyReflection copyWith({
    Mood? mood,
    String? note,
    DateTime? updatedAt,
  }) {
    return DailyReflection(
      id: id,
      userId: userId,
      localDate: localDate,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, localDate, mood, note, createdAt, updatedAt];
}
