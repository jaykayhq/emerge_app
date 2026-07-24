import 'package:emerge_app/core/deletion/deletion_audit.dart';
import 'package:emerge_app/core/deletion/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emits structured event with required keys', () {
    final events = <Map<String, dynamic>>[];
    final audit = DeletionAudit(
      metrics: SyncMetrics(),
      onEvent: events.add,
    );
    audit.log(
      op: 'deleteHabit',
      target: 'habit',
      habitId: 'h1',
      outcome: 'success',
      durationMs: 12,
      attempt: 1,
    );
    expect(events.length, 1);
    final e = events.first;
    expect(e['op'], 'deleteHabit');
    expect(e['target'], 'habit');
    expect(e['outcome'], 'success');
    expect(e['durationMs'], 12);
    expect(e['attempt'], 1);
    expect(e['habitId'], 'h1');
    expect(e['timestamp'], isNotNull);
  });
}
