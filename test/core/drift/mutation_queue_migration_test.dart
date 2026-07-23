import 'package:drift/native.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift/tables/mutation_queue_table.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mutation queue stores idempotency/status columns', () async {
    final db = AppDatabase.withExecutor(NativeDatabase.memory());
    await db.mutationQueueDao.enqueue(
      collectionPath: 'habits',
      documentId: 'h1',
      operation: 'update',
      idempotencyKey: 'del:habit:h1',
    );
    final rows = await db.select(db.mutationQueueTable).get();
    expect(rows.length, 1);
    expect(rows.first.idempotencyKey, 'del:habit:h1');
    expect(rows.first.status, 'pending');
    await db.close();
  });
}
