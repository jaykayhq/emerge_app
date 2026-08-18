import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/mutation_queue_table.dart';

part 'mutation_queue_dao.g.dart';

@DriftAccessor(tables: [MutationQueueTable])
class MutationQueueDao extends DatabaseAccessor<AppDatabase>
    with _$MutationQueueDaoMixin {
  MutationQueueDao(super.db);

  Future<List<MutationQueueTableData>> getAllPending() async {
    final query = select(mutationQueueTable)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
      ]);
    return await query.get();
  }

  Future<void> enqueue({
    required String collectionPath,
    required String documentId,
    required String operation,
    String? dataJson,
    String? idempotencyKey,
    String? userId,
  }) async {
    if (idempotencyKey != null) {
      final existing =
          await (select(mutationQueueTable)
                ..where((t) => t.idempotencyKey.equals(idempotencyKey)))
              .getSingleOrNull();
      if (existing != null) return; // idempotency: skip duplicate
    }
    await into(mutationQueueTable).insert(
      MutationQueueTableCompanion(
        collectionPath: Value(collectionPath),
        documentId: Value(documentId),
        operation: Value(operation),
        dataJson: Value(dataJson),
        idempotencyKey: Value(idempotencyKey),
        userId: Value(userId),
        createdAt: Value(DateTime.now().toIso8601String()),
        status: const Value('pending'),
      ),
    );
  }

  Future<List<MutationQueueTableData>> getDue(String nowIso, {String? userId}) {
    // userId == null (no auth seam wired) keeps legacy flush-everything
    // behavior; otherwise only the current user's rows (plus pre-migration
    // null rows, which are this device's own data) are due.
    final where = userId == null
        ? (MutationQueueTable t) =>
              t.status.equals('pending') &
              (t.nextRetryAt.isNull() |
                  t.nextRetryAt.isSmallerOrEqualValue(nowIso))
        : (MutationQueueTable t) =>
              t.status.equals('pending') &
              (t.nextRetryAt.isNull() |
                  t.nextRetryAt.isSmallerOrEqualValue(nowIso)) &
              (t.userId.isNull() | t.userId.equals(userId));
    return (select(mutationQueueTable)
          ..where(where)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }

  Future<void> markFailed({
    required int id,
    required int retryCount,
    required String lastError,
    required String nextRetryAt,
    required String status,
  }) {
    return (update(mutationQueueTable)..where((t) => t.id.equals(id))).write(
      MutationQueueTableCompanion(
        retryCount: Value(retryCount),
        lastError: Value(lastError),
        nextRetryAt: Value(nextRetryAt),
        status: Value(status),
      ),
    );
  }

  Future<List<MutationQueueTableData>> getDead() =>
      (select(mutationQueueTable)..where((t) => t.status.equals('dead'))).get();

  Future<void> resetDeadToPending() =>
      (update(mutationQueueTable)..where((t) => t.status.equals('dead'))).write(
        const MutationQueueTableCompanion(
          status: Value('pending'),
          retryCount: Value(0),
          nextRetryAt: Value(null),
          lastError: Value(null),
        ),
      );

  Future<void> deleteProcessed(int id) async {
    await (delete(mutationQueueTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> incrementRetry(int id) async {
    await customStatement(
      'UPDATE mutation_queue_table SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  Future<List<MutationQueueTableData>> getDeadLetters({String? userId}) async {
    final query = userId == null
        ? (select(mutationQueueTable)..where((t) => t.status.equals('dead')))
        : (select(mutationQueueTable)..where(
            (t) =>
                t.status.equals('dead') &
                (t.userId.isNull() | t.userId.equals(userId)),
          ));
    return query.get();
  }

  Future<void> updateStatus(int id, String status) async {
    await (update(mutationQueueTable)..where((t) => t.id.equals(id))).write(
      MutationQueueTableCompanion(status: Value(status)),
    );
  }

  Future<void> updateRetryCount(int id, int count) async {
    await (update(mutationQueueTable)..where((t) => t.id.equals(id))).write(
      MutationQueueTableCompanion(retryCount: Value(count)),
    );
  }

  /// Drops obsolete top-level `tribes` doc mutations.
  ///
  /// The tribe doc (members/memberCount) is server-owned since the
  /// membership trigger; every queued client write to `tribes/{id}` is
  /// stale (permission-denied under the tightened rules) and would
  /// otherwise revive-and-die in a 5-attempt loop on every boot — the
  /// observed 102/103/129/145 dead-letter symptom. Membership/contributor
  /// subcollection rows (paths with slashes) are untouched.
  Future<int> purgeTribeDocMutations() async {
    final rows = await (select(
      mutationQueueTable,
    )..where((t) => t.collectionPath.equals('tribes'))).get();
    var deleted = 0;
    for (final row in rows) {
      await (delete(
        mutationQueueTable,
      )..where((t) => t.id.equals(row.id))).go();
      deleted++;
    }
    return deleted;
  }
}
