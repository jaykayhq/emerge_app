// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tribe_stats_dao.dart';

// ignore_for_file: type=lint
mixin _$TribeStatsDaoMixin on DatabaseAccessor<AppDatabase> {
  $TribeStatsTableTable get tribeStatsTable => attachedDatabase.tribeStatsTable;
  TribeStatsDaoManager get managers => TribeStatsDaoManager(this);
}

class TribeStatsDaoManager {
  final _$TribeStatsDaoMixin _db;
  TribeStatsDaoManager(this._db);
  $$TribeStatsTableTableTableManager get tribeStatsTable =>
      $$TribeStatsTableTableTableManager(
        _db.attachedDatabase,
        _db.tribeStatsTable,
      );
}
