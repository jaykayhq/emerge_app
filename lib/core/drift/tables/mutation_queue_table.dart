import 'package:drift/drift.dart';

class MutationQueueTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get collectionPath => text()();
  TextColumn get documentId => text()();
  TextColumn get operation => text()();
  TextColumn get dataJson => text().nullable()();
  TextColumn get createdAt => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}
