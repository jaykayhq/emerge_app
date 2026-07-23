import 'package:drift/native.dart';
import 'package:emerge_app/core/deletion/deletion_audit.dart';
import 'package:emerge_app/core/deletion/deletion_service.dart';
import 'package:emerge_app/core/deletion/sync_status.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncEngine extends Mock implements EnhancedSyncEngine {}

void main() {
  late AppDatabase db;
  late MockSyncEngine sync;
  late DeletionService service;

  setUp(() async {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    sync = MockSyncEngine();
    when(() => sync.enqueueUpdate(
          collectionPath: any(named: 'collectionPath'),
          documentId: any(named: 'documentId'),
          data: any(named: 'data'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenAnswer((_) async {});
    service = DeletionService(
      db: db,
      syncEngine: sync,
      audit: DeletionAudit(metrics: SyncMetrics()),
    );
  });
  tearDown(() => db.close());

  test('deleteHabit archives + cascades + enqueues with idempotency key',
      () async {
    await db.habitsDao.insertFromData(
      id: 'h1',
      userId: 'u1',
      title: 'Read',
      cue: 'x',
      currentStreak: 5,
      createdAt: DateTime(2026).toIso8601String(),
      updatedAt: DateTime(2026).toIso8601String(),
    );
    await db.habitCompletionsDao.insertFromData(
      id: 'c1',
      habitId: 'h1',
      userId: 'u1',
      completedAt: DateTime(2026, 2).toIso8601String(),
    );

    final res = await service.deleteHabit(userId: 'u1', habitId: 'h1');
    expect(res, const Right<Failure, Unit>(unit));

    final row = await db.habitsDao.getHabit('h1');
    expect(row!.isArchived, 1);
    expect(row.currentStreak, 5); // preserved
    expect(row.cue, 'x');
    final comps = await db.habitCompletionsDao.getBetweenDates(
      'u1',
      DateTime(2020).toIso8601String(),
      DateTime(2030).toIso8601String(),
    );
    expect(comps.length, 0);

    final captured = verify(() => sync.enqueueUpdate(
          collectionPath: 'users/u1/habits',
          documentId: 'h1',
          data: any(named: 'data'),
          idempotencyKey: captureAny(named: 'idempotencyKey'),
        )).captured;
    expect(captured.single, 'del:habit:h1');
  });

  test('deleting an already-archived habit is a no-op success', () async {
    await db.habitsDao.insertFromData(
      id: 'h1',
      userId: 'u1',
      title: 'Read',
      currentStreak: 5,
      isArchived: 1,
      createdAt: DateTime(2026).toIso8601String(),
      updatedAt: DateTime(2026).toIso8601String(),
    );
    final res = await service.deleteHabit(userId: 'u1', habitId: 'h1');
    expect(res, const Right<Failure, Unit>(unit));
    verifyNever(() => sync.enqueueUpdate(
          collectionPath: any(named: 'collectionPath'),
          documentId: any(named: 'documentId'),
          data: any(named: 'data'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ));
  });

  test('missing habit returns Left', () async {
    final res = await service.deleteHabit(userId: 'u1', habitId: 'nope');
    expect(res.isLeft(), isTrue);
  });

  test('concurrent deletes all succeed and archive local row once', () async {
    await db.habitsDao.insertFromData(
      id: 'h3',
      userId: 'u1',
      title: 'X',
      createdAt: DateTime(2026).toIso8601String(),
      updatedAt: DateTime(2026).toIso8601String(),
    );
    // Real engine so the queue is exercised.
    final realEngine = EnhancedSyncEngine(
      db.mutationQueueDao,
      FakeFirebaseFirestore(),
      metrics: SyncMetrics(),
    );
    final svc = DeletionService(
      db: db,
      syncEngine: realEngine,
      audit: DeletionAudit(metrics: SyncMetrics()),
    );
    final results = await Future.wait([
      svc.deleteHabit(userId: 'u1', habitId: 'h3'),
      svc.deleteHabit(userId: 'u1', habitId: 'h3'),
      svc.deleteHabit(userId: 'u1', habitId: 'h3'),
    ]);
    // Every concurrent call reports success and the local row is archived
    // exactly once (and idempotencyKey is present on the queued mutations).
    expect(
      results.every((r) => r == const Right<Failure, Unit>(unit)),
      isTrue,
    );
    final row = await db.habitsDao.getHabit('h3');
    expect(row!.isArchived, 1);
    final queued = await db.mutationQueueDao.getAllPending();
    expect(queued.every((q) => q.idempotencyKey == 'del:habit:h3'), isTrue);
  });

  test('sequential deletes dedupe to a single queued mutation', () async {
    await db.habitsDao.insertFromData(
      id: 'h4',
      userId: 'u1',
      title: 'Y',
      createdAt: DateTime(2026).toIso8601String(),
      updatedAt: DateTime(2026).toIso8601String(),
    );
    final realEngine = EnhancedSyncEngine(
      db.mutationQueueDao,
      FakeFirebaseFirestore(),
      metrics: SyncMetrics(),
    );
    final svc = DeletionService(
      db: db,
      syncEngine: realEngine,
      audit: DeletionAudit(metrics: SyncMetrics()),
    );
    await svc.deleteHabit(userId: 'u1', habitId: 'h4');
    await svc.deleteHabit(userId: 'u1', habitId: 'h4');
    final queued = await db.mutationQueueDao.getAllPending();
    expect(queued.length, 1); // deduped on idempotencyKey
    expect(queued.first.idempotencyKey, 'del:habit:h4');
  });
  test('remote enqueue failure surfaces Left but local archive committed',
      () async {
    when(() => sync.enqueueUpdate(
          collectionPath: any(named: 'collectionPath'),
          documentId: any(named: 'documentId'),
          data: any(named: 'data'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenThrow(Exception('network down'));
    await db.habitsDao.insertFromData(
      id: 'h2',
      userId: 'u1',
      title: 'X',
      currentStreak: 9,
      createdAt: DateTime(2026).toIso8601String(),
      updatedAt: DateTime(2026).toIso8601String(),
    );
    final res = await service.deleteHabit(userId: 'u1', habitId: 'h2');
    expect(res.isLeft(), isTrue);
    final row = await db.habitsDao.getHabit('h2');
    expect(row!.isArchived, 1); // local archive committed before enqueue
  });
}
