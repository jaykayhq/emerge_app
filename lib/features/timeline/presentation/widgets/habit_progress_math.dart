/// Returns the fraction (0..1) of the timeline habit card that should be
/// filled given the timer's remaining seconds and total duration.
///
/// Pure; no widgets, no Riverpod. Extracted so the math is unit-testable
/// independent of any UI.
///
/// - When [totalSeconds] <= 0, returns 0.
/// - When [remainingSeconds] is out of range, clamps to [0, 1].
double habitCardFillFraction({
  required int remainingSeconds,
  required int totalSeconds,
}) {
  if (totalSeconds <= 0) return 0.0;
  final f = 1 - (remainingSeconds / totalSeconds);
  return f.clamp(0.0, 1.0);
}
