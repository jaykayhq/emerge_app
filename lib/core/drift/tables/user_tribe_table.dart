import 'package:drift/drift.dart';

class UserTribeTable extends Table {
  TextColumn get userId => text()();
  TextColumn get tribeId => text()();
  TextColumn get membershipType => text()();
  TextColumn get joinedAt => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  TextColumn get syncedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {userId, tribeId};
}
