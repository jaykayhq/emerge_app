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
  final DateTime createdAt;

  const Reflection({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.type,
    this.moodValue,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'title': title,
      'content': content,
      'type': type,
      'moodValue': moodValue,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Reflection.fromMap(Map<String, dynamic> map, String docId) {
    return Reflection(
      id: docId,
      date: map['date'] as String? ?? '',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      type: map['type'] as String? ?? 'insight',
      moodValue: (map['moodValue'] as num?)?.toDouble(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
