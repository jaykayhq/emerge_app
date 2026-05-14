import 'package:drift/drift.dart';
import '../database.dart';
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
  }) {
    return into(mutationQueueTable).insert(
      MutationQueueTableCompanion(
        collectionPath: Value(collectionPath),
        documentId: Value(documentId),
        operation: Value(operation),
        dataJson: Value(dataJson),
        createdAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<void> deleteProcessed(int id) async {
    await (delete(mutationQueueTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> incrementRetry(int id) async {
    await (update(mutationQueueTable)..where((t) => t.id.equals(id))).write(
      MutationQueueTableCompanion(retryCount: const Value(1)),
    );
  }
}
