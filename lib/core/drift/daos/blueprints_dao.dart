import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/blueprints_table.dart';

part 'blueprints_dao.g.dart';

@DriftAccessor(tables: [BlueprintsTable])
class BlueprintsDao extends DatabaseAccessor<AppDatabase>
    with _$BlueprintsDaoMixin {
  BlueprintsDao(super.db);

  Future<List<BlueprintsTableData>> getAll() {
    return select(blueprintsTable).get();
  }

  Future<void> upsertBlueprint(Insertable<BlueprintsTableData> entry) {
    return into(blueprintsTable).insertOnConflictUpdate(entry);
  }
}
