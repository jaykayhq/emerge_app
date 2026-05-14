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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'period': period,
      'dateRange': dateRange,
      'habitsCompleted': habitsCompleted,
      'perfectDays': perfectDays,
      'xpGained': xpGained,
      'focusTime': focusTime,
      'summary': summary,
      'consistencyChange': consistencyChange,
    };
  }

  factory Recap.fromMap(Map<String, dynamic> map) {
    return Recap(
      id: map['id'] as String? ?? 'empty',
      period: map['period'] as String? ?? 'Weekly',
      dateRange: map['dateRange'] as String? ?? '',
      habitsCompleted: map['habitsCompleted'] as int? ?? 0,
      perfectDays: map['perfectDays'] as int? ?? 0,
      xpGained: map['xpGained'] as int? ?? 0,
      focusTime: map['focusTime'] as String? ?? '0h',
      summary: map['summary'] as String? ?? '',
      consistencyChange: (map['consistencyChange'] as num?)?.toDouble() ?? 0.0,
    );
  }
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
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };

    return map;
  }

  factory Reflection.fromMap(Map<String, dynamic> map, [String? docId]) {
    final id = docId ?? map['id'] as String? ?? '';
    DateTime? createdAt;
    if (map['createdAt'] is Timestamp) {
      createdAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      createdAt = DateTime.tryParse(map['createdAt'] as String);
    }

    return Reflection(
      id: id,
      date: map['date'] as String? ?? '',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      type: map['type'] as String? ?? 'insight',
      moodValue: (map['moodValue'] as num?)?.toDouble(),
      createdAt: createdAt,
    );
  }
}
