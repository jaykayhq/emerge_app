import 'package:emerge_app/core/deletion/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('metrics increment and copy', () {
    final m = SyncMetrics();
    expect(m.queueDepth, 0);
    m.recordEnqueued();
    m.recordSucceeded();
    m.recordDeadLettered();
    expect(m.enqueued, 1);
    expect(m.succeeded, 1);
    expect(m.deadLettered, 1);
    final c = m.copy();
    expect(c.enqueued, 1);
    c.recordFailed();
    expect(m.failed, 0); // copy is independent
  });

  test('SyncStatus enum has expected values', () {
    expect(SyncStatus.values, [
      SyncStatus.idle,
      SyncStatus.processing,
      SyncStatus.degraded,
      SyncStatus.offline,
    ]);
  });
}
