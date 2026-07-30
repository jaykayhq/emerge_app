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
  }) async {
    if (idempotencyKey != null) {
      final existing = await (select(mutationQueueTable)
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
        createdAt: Value(DateTime.now().toIso8601String()),
        status: const Value('pending'),
      ),
    );
  }

  Future<List<MutationQueueTableData>> getDue(String nowIso) {
    return (select(mutationQueueTable)
          ..where((t) =>
              t.status.equals('pending') &
              (t.nextRetryAt.isNull() |
                  t.nextRetryAt.isSmallerOrEqualValue(nowIso)))
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

  Future<void> resetDeadToPending() => (update(mutationQueueTable)
        ..where((t) => t.status.equals('dead')))
      .write(const MutationQueueTableCompanion(
        status: Value('pending'),
        retryCount: Value(0),
        nextRetryAt: Value(null),
        lastError: Value(null),
      ));

  Future<void> deleteProcessed(int id) async {
    await (delete(mutationQueueTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> incrementRetry(int id) async {
    await customStatement(
      'UPDATE mutation_queue_table SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  Future<List<MutationQueueTableData>> getDeadLetters() async {
    return (select(mutationQueueTable)..where((t) => t.status.equals('dead')))
        .get();
  }

  Future<void> updateStatus(int id, String status) async {
    await (update(mutationQueueTable)..where((t) => t.id.equals(id)))
        .write(MutationQueueTableCompanion(status: Value(status)));
  }

  Future<void> updateRetryCount(int id, int count) async {
    await (update(mutationQueueTable)..where((t) => t.id.equals(id)))
        .write(MutationQueueTableCompanion(retryCount: Value(count)));
  }
}
