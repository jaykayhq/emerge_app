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
    when(
      () => sync.enqueueUpdate(
        collectionPath: any(named: 'collectionPath'),
        documentId: any(named: 'documentId'),
        data: any(named: 'data'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => sync.enqueueMutation(
        collectionPath: any(named: 'collectionPath'),
        documentId: any(named: 'documentId'),
        operation: any(named: 'operation'),
        data: any(named: 'data'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((_) async {});
    service = DeletionService(
      db: db,
      syncEngine: sync,
      audit: DeletionAudit(metrics: SyncMetrics()),
    );
  });
  tearDown(() => db.close());

  test(
    'deleteHabit archives + cascades + enqueues with idempotency key',
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
      await db.habitCompletionsDao.insertFromData(
        id: 'c2',
        habitId: 'h1',
        userId: 'u1',
        completedAt: DateTime(2026, 3).toIso8601String(),
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

      final captured = verify(
        () => sync.enqueueMutation(
          collectionPath: 'habits',
          documentId: 'h1',
          operation: 'delete',
          idempotencyKey: captureAny(named: 'idempotencyKey'),
        ),
      ).captured;
      expect(captured.single, 'del:habit:h1');

      // Remote history is deleted too: each local completion gets its own
      // idempotent delete on users/{uid}/habit_completions so a clean reinstall
      // does not resurrect the habit's history.
      final capturedCompletions = verify(
        () => sync.enqueueMutation(
          collectionPath: 'users/u1/habit_completions',
          documentId: captureAny(named: 'documentId'),
          operation: 'delete',
          idempotencyKey: captureAny(named: 'idempotencyKey'),
        ),
      ).captured;
      expect(
        capturedCompletions,
        containsAllInOrder([
          'c1',
          'del:completion:c1',
          'c2',
          'del:completion:c2',
        ]),
      );
    },
  );

  test(
    'completion remote-enqueue failures do not fail the habit delete',
    () async {
      var failCompletions = true;
      when(
        () => sync.enqueueMutation(
          collectionPath: any(named: 'collectionPath'),
          documentId: any(named: 'documentId'),
          operation: any(named: 'operation'),
          data: any(named: 'data'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((invocation) async {
        if (failCompletions &&
            invocation.namedArguments[#collectionPath]?.toString().contains(
                  'habit_completions',
                ) ==
                true) {
          throw Exception('network down');
        }
      });
      await db.habitsDao.insertFromData(
        id: 'h5',
        userId: 'u1',
        title: 'X',
        createdAt: DateTime(2026).toIso8601String(),
        updatedAt: DateTime(2026).toIso8601String(),
      );
      await db.habitCompletionsDao.insertFromData(
        id: 'c9',
        habitId: 'h5',
        userId: 'u1',
        completedAt: DateTime(2026, 2).toIso8601String(),
      );

      final res = await service.deleteHabit(userId: 'u1', habitId: 'h5');

      expect(res, const Right<Failure, Unit>(unit));
      final row = await db.habitsDao.getHabit('h5');
      expect(row!.isArchived, 1);

      // The completion enqueue WAS attempted and threw — and was absorbed — while
      // the primary habit-doc delete still went through. This is what makes the
      // test meaningful: it fails if the production catch around the mirror loop
      // is removed (the throw would then leak out as Left).
      verify(
        () => sync.enqueueMutation(
          collectionPath: 'users/u1/habit_completions',
          documentId: 'c9',
          operation: 'delete',
          idempotencyKey: 'del:completion:c9',
        ),
      ).called(1);
      verify(
        () => sync.enqueueMutation(
          collectionPath: 'habits',
          documentId: 'h5',
          operation: 'delete',
          idempotencyKey: 'del:habit:h5',
        ),
      ).called(1);
    },
  );

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
    verifyNever(
      () => sync.enqueueUpdate(
        collectionPath: any(named: 'collectionPath'),
        documentId: any(named: 'documentId'),
        data: any(named: 'data'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    );
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
    expect(results.every((r) => r == const Right<Failure, Unit>(unit)), isTrue);
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
  test(
    'remote enqueue failure surfaces Left but local archive committed',
    () async {
      when(
        () => sync.enqueueMutation(
          collectionPath: any(named: 'collectionPath'),
          documentId: any(named: 'documentId'),
          operation: any(named: 'operation'),
          data: any(named: 'data'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenThrow(Exception('network down'));
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
    },
  );

  test(
    'habit-doc enqueue failure still leaves the completion mirrors enqueued',
    () async {
      when(
        () => sync.enqueueMutation(
          collectionPath: any(named: 'collectionPath'),
          documentId: any(named: 'documentId'),
          operation: any(named: 'operation'),
          data: any(named: 'data'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((invocation) async {
        if (invocation.namedArguments[#collectionPath] == 'habits') {
          throw Exception('network down');
        }
      });
      await db.habitsDao.insertFromData(
        id: 'h6',
        userId: 'u1',
        title: 'X',
        createdAt: DateTime(2026).toIso8601String(),
        updatedAt: DateTime(2026).toIso8601String(),
      );
      await db.habitCompletionsDao.insertFromData(
        id: 'c6',
        habitId: 'h6',
        userId: 'u1',
        completedAt: DateTime(2026, 2).toIso8601String(),
      );

      final res = await service.deleteHabit(userId: 'u1', habitId: 'h6');

      expect(res.isLeft(), isTrue);
      final row = await db.habitsDao.getHabit('h6');
      expect(row!.isArchived, 1);

      // The remote history mirrors are enqueued BEFORE the habit-doc delete, so
      // this failure cannot strand the completed history remotely.
      verify(
        () => sync.enqueueMutation(
          collectionPath: 'users/u1/habit_completions',
          documentId: 'c6',
          operation: 'delete',
          idempotencyKey: 'del:completion:c6',
        ),
      ).called(1);
    },
  );

  test(
    'retry after habit-enqueue failure re-enqueues the habit-doc delete',
    () async {
      var failHabitEnqueue = true;
      when(
        () => sync.enqueueMutation(
          collectionPath: any(named: 'collectionPath'),
          documentId: any(named: 'documentId'),
          operation: any(named: 'operation'),
          data: any(named: 'data'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((invocation) async {
        if (invocation.namedArguments[#collectionPath] == 'habits' &&
            failHabitEnqueue) {
          throw Exception('network down');
        }
      });
      await db.habitsDao.insertFromData(
        id: 'h7',
        userId: 'u1',
        title: 'X',
        createdAt: DateTime(2026).toIso8601String(),
        updatedAt: DateTime(2026).toIso8601String(),
      );
      await db.habitCompletionsDao.insertFromData(
        id: 'c7',
        habitId: 'h7',
        userId: 'u1',
        completedAt: DateTime(2026, 2).toIso8601String(),
      );

      final first = await service.deleteHabit(userId: 'u1', habitId: 'h7');
      expect(first.isLeft(), isTrue);
      expect((await db.habitsDao.getHabit('h7'))!.isArchived, 1);

      failHabitEnqueue = false; // connectivity restored
      final second = await service.deleteHabit(userId: 'u1', habitId: 'h7');
      expect(second, const Right<Failure, Unit>(unit));

      // First attempt + self-healing re-enqueue on the already-archived retry.
      verify(
        () => sync.enqueueMutation(
          collectionPath: 'habits',
          documentId: 'h7',
          operation: 'delete',
          idempotencyKey: 'del:habit:h7',
        ),
      ).called(2);
    },
  );
}
