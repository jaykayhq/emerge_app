import 'package:drift/drift.dart';

class BlueprintsTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get difficulty => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get habitCount => integer().withDefault(const Constant(0))();
  IntColumn get isFallback => integer().withDefault(const Constant(1))();
  TextColumn get dataJson => text().nullable()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}
