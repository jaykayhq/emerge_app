import 'package:drift/drift.dart';

class PulseFeedCardsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get cardType => text()();
  TextColumn get title => text()();
  TextColumn get subtitle => text().nullable()();
  TextColumn get body => text().nullable()();
  TextColumn get metadataJson => text().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();
  TextColumn get syncedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
