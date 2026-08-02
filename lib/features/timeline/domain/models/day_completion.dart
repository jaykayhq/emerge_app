/// Completion status for a single calendar day.
enum DayCompletionStatus { none, partial, complete }

/// Per-day completion summary shown on the calendar strip's dot + percentage.
class DayCompletion {
  final DayCompletionStatus status;
  final int percent;

  const DayCompletion({required this.status, required this.percent});

  /// A day with no scheduled (active) habits or no completions at all.
  static const none = DayCompletion(
    status: DayCompletionStatus.none,
    percent: 0,
  );
}
