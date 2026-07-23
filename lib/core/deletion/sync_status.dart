enum SyncStatus { idle, processing, degraded, offline }

/// In-memory counters for deletion/sync observability.
class SyncMetrics {
  int enqueued = 0;
  int succeeded = 0;
  int failed = 0;
  int deadLettered = 0;
  int queueDepth = 0;
  int lastProcessingMs = 0;
  int consecutiveFailures = 0;
  int totalProcessed = 0;

  /// Alias kept for observability dashboards.
  int get deadLetters => deadLettered;

  void recordEnqueued() => enqueued++;
  void recordSucceeded() {
    succeeded++;
    totalProcessed++;
  }

  void recordFailed() => failed++;
  void recordDeadLettered() => deadLettered++;

  SyncMetrics copy() => SyncMetrics()
    ..enqueued = enqueued
    ..succeeded = succeeded
    ..failed = failed
    ..deadLettered = deadLettered
    ..queueDepth = queueDepth
    ..lastProcessingMs = lastProcessingMs
    ..consecutiveFailures = consecutiveFailures
    ..totalProcessed = totalProcessed;
}
