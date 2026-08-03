import 'package:drift/native.dart';
import 'package:emerge_app/core/deletion/sync_status.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression for the signed-out replay bug: dead-lettered mutations were
/// revived and flushed at boot regardless of auth state, so every signed-out
/// session hammered Firestore with guaranteed `permission-denied` retries
/// (mutations 21/86 in the wild). The engine must skip flushing while signed
/// out and only ever apply the CURRENT user's rows.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.withExecutor(NativeDatabase.memory()));
  tearDown(() => db.close());

  EnhancedSyncEngine engine({String? Function()? currentUserId, MutationApplier? applier}) {
    return EnhancedSyncEngine(
      db.mutationQueueDao,
      FakeFirebaseFirestore(),
      metrics: SyncMetrics(),
      baseBackoff: Duration.zero,
      currentUserId: currentUserId,
      applier: applier ?? (_) async => true,
    );
  }

  test('signed-out engine never flushes the queue', () async {
    final applied = <int>[];
    final e = engine(
      currentUserId: () => null,
      applier: (m) async {
        applied.add(m.id);
        return true;
      },
    );
    await e.enqueueMutation(
      collectionPath: 'habits',
      documentId: 'h1',
      operation: 'update',
    );
    await e.processMutationQueue();
    expect(applied, isEmpty, reason: 'signed out: no writes may be attempted');
    final rows = await db.mutationQueueDao.getAllPending();
    expect(rows, hasLength(1), reason: 'row stays queued for the next sign-in');
  });

  test('only the current user\'s mutations are flushed', () async {
    final applied = <String>[];
    final e = engine(
      currentUserId: () => 'user-1',
      applier: (m) async {
        applied.add(m.documentId);
        return true;
      },
    );
    await db.mutationQueueDao.enqueue(
      collectionPath: 'habits',
      documentId: 'mine',
      operation: 'update',
      userId: 'user-1',
    );
    await db.mutationQueueDao.enqueue(
      collectionPath: 'habits',
      documentId: 'theirs',
      operation: 'update',
      userId: 'user-2',
    );
    await e.processMutationQueue();
    expect(applied, ['mine'], reason: 'another user\'s row must never apply');
    final remaining = await db.mutationQueueDao.getAllPending();
    expect(remaining.map((r) => r.documentId), ['theirs']);
  });

  test('enqueue stamps the current user id', () async {
    final e = engine(currentUserId: () => 'user-1');
    await e.enqueueMutation(
      collectionPath: 'habits',
      documentId: 'h1',
      operation: 'update',
    );
    final rows = await db.mutationQueueDao.getAllPending();
    expect(rows.single.userId, 'user-1');
  });

  test('legacy null-user rows flush for the signed-in user', () async {
    final applied = <String>[];
    final e = engine(
      currentUserId: () => 'user-1',
      applier: (m) async {
        applied.add(m.documentId);
        return true;
      },
    );
    await db.mutationQueueDao.enqueue(
      collectionPath: 'habits',
      documentId: 'legacy',
      operation: 'update',
    );
    await e.processMutationQueue();
    expect(applied, ['legacy'], reason: 'pre-migration rows are this device\'s data');
  });

  test('reviveDeadLetters is a no-op while signed out', () async {
    final e = engine(currentUserId: () => null);
    await db.mutationQueueDao.enqueue(
      collectionPath: 'habits',
      documentId: 'h1',
      operation: 'update',
    );
    await db.mutationQueueDao.markFailed(
      id: (await db.mutationQueueDao.getAllPending()).single.id,
      retryCount: 5,
      lastError: 'apply failed',
      nextRetryAt: DateTime.now().toIso8601String(),
      status: 'dead',
    );
    await e.reviveDeadLetters();
    final dead = await db.mutationQueueDao.getDeadLetters();
    expect(dead, hasLength(1), reason: 'dead rows stay dead until a sign-in');
  });

  test('reviveDeadLetters revives only the current user\'s dead rows', () async {
    final e = engine(currentUserId: () => 'user-1');
    await db.mutationQueueDao.enqueue(
      collectionPath: 'habits',
      documentId: 'mine',
      operation: 'update',
      userId: 'user-1',
    );
    await db.mutationQueueDao.enqueue(
      collectionPath: 'habits',
      documentId: 'theirs',
      operation: 'update',
      userId: 'user-2',
    );
    for (final row in await db.mutationQueueDao.getAllPending()) {
      await db.mutationQueueDao.markFailed(
        id: row.id,
        retryCount: 5,
        lastError: 'apply failed',
        nextRetryAt: DateTime.now().toIso8601String(),
        status: 'dead',
      );
    }
    await e.reviveDeadLetters();
    // getAllPending returns rows of EVERY status; only the revived row may
    // be pending again.
    final pending = (await db.mutationQueueDao.getAllPending())
        .where((r) => r.status == 'pending')
        .map((r) => r.documentId)
        .toList();
    expect(pending, ['mine']);
  });
}
