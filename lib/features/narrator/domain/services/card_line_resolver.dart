import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';

/// Snapshot of the user's day used to compose the narrator card's line.
class DayStatus {
  final int completed;
  final int total;
  final int streak;
  final String? firstIncompleteName;

  const DayStatus({
    required this.completed,
    required this.total,
    required this.streak,
    this.firstIncompleteName,
  });
}

/// The narrator's no-LLM day-status line. Pure — unit-tested directly.
String dayStatusLine(DayStatus day) {
  if (day.total == 0) {
    return 'This is where your day takes shape. Add a habit and I\'ll keep watch.';
  }
  if (day.completed >= day.total) {
    if (day.streak > 0) {
      return 'All done for today. ${day.streak}-day streak is starting to hold you.';
    }
    return 'All done for today. That\'s how momentum starts.';
  }
  final remaining = day.total - day.completed;
  final name = day.firstIncompleteName;
  if (name != null && name.isNotEmpty) {
    return '$remaining left today — start with $name.';
  }
  return '$remaining left today.';
}

/// Day Card line priority: pending milestone line → latest insight → day
/// status. Pure — the widget only wires providers into this.
NarratorLine? resolveCardLine({
  required NarratorLine? pendingLine,
  required String? insightText,
  required DayStatus day,
}) {
  if (pendingLine != null) return pendingLine;
  if (insightText != null && insightText.isNotEmpty) {
    return GenericLine(insightText);
  }
  return GenericLine(dayStatusLine(day));
}
