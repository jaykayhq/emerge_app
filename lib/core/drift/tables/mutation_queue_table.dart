import 'package:drift/drift.dart';

class MutationQueueTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Owner uid at enqueue time (AGENTS.md shared-device rule). Null on rows
  /// enqueued before the v14 migration; those are treated as this device's
  /// legacy data and flush for whoever signs in.
  TextColumn get userId => text().nullable()();
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
