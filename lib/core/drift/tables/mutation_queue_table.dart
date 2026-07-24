import 'package:drift/drift.dart';

class MutationQueueTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get collectionPath => text()();
  TextColumn get documentId => text()();
  TextColumn get operation => text()();
  TextColumn get dataJson => text().nullable()();
  TextColumn get createdAt => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get idempotencyKey => text().nullable()();
  TextColumn get lastError => text().nullable()();
  TextColumn get nextRetryAt => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
}
