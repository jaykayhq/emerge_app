// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_stats_dao.dart';

// ignore_for_file: type=lint
mixin _$UserStatsDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserStatsTableTable get userStatsTable => attachedDatabase.userStatsTable;
  UserStatsDaoManager get managers => UserStatsDaoManager(this);
}

class UserStatsDaoManager {
  final _$UserStatsDaoMixin _db;
  UserStatsDaoManager(this._db);
  $$UserStatsTableTableTableManager get userStatsTable =>
      $$UserStatsTableTableTableManager(
        _db.attachedDatabase,
        _db.userStatsTable,
      );
}
