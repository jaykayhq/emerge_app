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
  final String type; // e.g., "insight", "pattern", "suggestion"

  const Reflection({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.type,
  });
}
