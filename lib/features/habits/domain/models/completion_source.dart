/// How a habit completion was triggered.
///
/// Provides an audit trail for the Narrator's AI learning engine
/// so it can correlate completion methods with user behavior patterns.
enum CompletionSource {
  /// Tapped directly on the habit card in Timeline.
  tap,

  /// Tapped via the Android/iOS home screen widget.
  widget,

  /// Completed via notification action button.
  notification,

  /// Completed via voice command (future).
  voice,

  /// Auto-completed via health data sync (future — Apple Health / Google Fit).
  healthSync,
}
