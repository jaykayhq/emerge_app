// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blueprints_dao.dart';

// ignore_for_file: type=lint
mixin _$BlueprintsDaoMixin on DatabaseAccessor<AppDatabase> {
  $BlueprintsTableTable get blueprintsTable => attachedDatabase.blueprintsTable;
  BlueprintsDaoManager get managers => BlueprintsDaoManager(this);
}

class BlueprintsDaoManager {
  final _$BlueprintsDaoMixin _db;
  BlueprintsDaoManager(this._db);
  $$BlueprintsTableTableTableManager get blueprintsTable =>
      $$BlueprintsTableTableTableManager(
        _db.attachedDatabase,
        _db.blueprintsTable,
      );
}
