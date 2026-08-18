import 'package:drift/native.dart';
import 'package:emerge_app/core/deletion/sync_status.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late EnhancedSyncEngine engine;

  setUp(() async {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  test('dedupes by idempotencyKey', () async {
    engine = EnhancedSyncEngine(
      db.mutationQueueDao,
      FakeFirebaseFirestore(),
      metrics: SyncMetrics(),
    );
    await engine.enqueueMutation(
      collectionPath: 'habits',
      documentId: 'h1',
      operation: 'update',
      idempotencyKey: 'k1',
    );
    await engine.enqueueMutation(
      collectionPath: 'habits',
      documentId: 'h1',
      operation: 'update',
      idempotencyKey: 'k1',
    );
    final rows = await db.mutationQueueDao.getAllPending();
    expect(rows.length, 1);
  });

  test('dead-letters after maxRetries instead of dropping', () async {
    int attempts = 0;
    engine = EnhancedSyncEngine(
      db.mutationQueueDao,
      FakeFirebaseFirestore(),
      metrics: SyncMetrics(),
      baseBackoff: Duration.zero,
      applier: (_) async {
        attempts++;
        return false;
      },
    );
    await engine.enqueueMutation(
      collectionPath: 'habits',
      documentId: 'h1',
      operation: 'update',
    );
    for (int i = 0; i < 6; i++) {
      await engine.processMutationQueue();
    }
    final dead = await db.mutationQueueDao.getDead();
    expect(dead.length, 1, reason: 'row must be retained as dead, not dropped');
    expect(dead.first.status, 'dead');
    expect(attempts, greaterThanOrEqualTo(5));
  });

  test(
    'circuit breaker flips to degraded after consecutive failures',
    () async {
      engine = EnhancedSyncEngine(
        db.mutationQueueDao,
        FakeFirebaseFirestore(),
        metrics: SyncMetrics(),
        breakerThreshold: 2,
        baseBackoff: Duration.zero,
        applier: (_) async => false,
      );
      await engine.enqueueMutation(
        collectionPath: 'habits',
        documentId: 'h1',
        operation: 'update',
      );
      await engine.processMutationQueue();
      await engine.processMutationQueue();
      final states = <SyncStatus>[];
      final sub = engine.status.listen(states.add);
      await engine.processMutationQueue();
      await Future.delayed(Duration.zero);
      expect(states, contains(SyncStatus.degraded));
      await sub.cancel();
    },
  );

  test('backoff schedules nextRetryAt in the future', () async {
    engine = EnhancedSyncEngine(
      db.mutationQueueDao,
      FakeFirebaseFirestore(),
      metrics: SyncMetrics(),
      applier: (_) async => false,
    );
    await engine.enqueueMutation(
      collectionPath: 'habits',
      documentId: 'h1',
      operation: 'update',
    );
    await engine.processMutationQueue();
    final rows = await db.mutationQueueDao.getAllPending();
    final next = DateTime.parse(rows.first.nextRetryAt!);
    expect(next.isAfter(DateTime.now()), isTrue);
  });

  test('resetDeadLetters revives dead rows and clears breaker', () async {
    engine = EnhancedSyncEngine(
      db.mutationQueueDao,
      FakeFirebaseFirestore(),
      metrics: SyncMetrics(),
      maxRetries: 1,
      baseBackoff: Duration.zero,
      applier: (_) async => false,
    );
    await engine.enqueueMutation(
      collectionPath: 'habits',
      documentId: 'h1',
      operation: 'update',
    );
    await engine.processMutationQueue();
    expect((await db.mutationQueueDao.getDead()).length, 1);
    await engine.resetDeadLetters();
    expect((await db.mutationQueueDao.getDead()).length, 0);
  });
}
