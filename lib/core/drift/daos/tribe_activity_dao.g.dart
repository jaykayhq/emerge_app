// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tribe_activity_dao.dart';

// ignore_for_file: type=lint
mixin _$TribeActivityDaoMixin on DatabaseAccessor<AppDatabase> {
  $TribeActivityTableTable get tribeActivityTable =>
      attachedDatabase.tribeActivityTable;
  TribeActivityDaoManager get managers => TribeActivityDaoManager(this);
}

class TribeActivityDaoManager {
  final _$TribeActivityDaoMixin _db;
  TribeActivityDaoManager(this._db);
  $$TribeActivityTableTableTableManager get tribeActivityTable =>
      $$TribeActivityTableTableTableManager(
        _db.attachedDatabase,
        _db.tribeActivityTable,
      );
}
