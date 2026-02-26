import 'package:cloud_firestore/cloud_firestore.dart';

class Recap {
  final String id;
  final String period; // e.g., "Weekly", "Monthly"
  final String dateRange;
  final int habitsCompleted;
  final int perfectDays;
  final int xpGained;
  final String focusTime;
  final String summary;
  final double consistencyChange; // e.g., 0.2 for +20%

  const Recap({
    required this.id,
    required this.period,
    required this.dateRange,
    required this.habitsCompleted,
    required this.perfectDays,
    required this.xpGained,
    required this.focusTime,
    required this.summary,
    required this.consistencyChange,
  });
}

class Reflection {
  final String id;
  final String date;
  final String title;
  final String content;
  final String type; // e.g., "insight", "pattern", "suggestion", "daily"
  final double? moodValue; // 0.0-1.0 for daily reflections
  final DateTime? createdAt;

  const Reflection({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.type,
    this.moodValue,
    this.createdAt,
  });

  /// Creates a map for Firestore serialization.
  /// Note: createdAt should be set to FieldValue.serverTimestamp() when saving.
  Map<String, dynamic> toMap({bool useServerTimestamp = true}) {
    final map = <String, dynamic>{
      'id': id,
      'date': date,
      'title': title,
      'content': content,
      'type': type,
      if (moodValue != null) 'moodValue': moodValue,
    };

    // Only include createdAt if we're not using server timestamp
    // When useServerTimestamp is true, the repository should handle it
    if (!useServerTimestamp && createdAt != null) {
      map['createdAt'] = Timestamp.fromDate(createdAt!);
    }

    return map;
  }

  factory Reflection.fromMap(Map<String, dynamic> map, String docId) {
    return Reflection(
      id: docId,
      date: map['date'] as String? ?? '',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      type: map['type'] as String? ?? 'insight',
      moodValue: (map['moodValue'] as num?)?.toDouble(),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}
