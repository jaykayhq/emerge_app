// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tribe_membership_dao.dart';

// ignore_for_file: type=lint
mixin _$TribeMembershipDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserTribeTableTable get userTribeTable => attachedDatabase.userTribeTable;
  TribeMembershipDaoManager get managers => TribeMembershipDaoManager(this);
}

class TribeMembershipDaoManager {
  final _$TribeMembershipDaoMixin _db;
  TribeMembershipDaoManager(this._db);
  $$UserTribeTableTableTableManager get userTribeTable =>
      $$UserTribeTableTableTableManager(
        _db.attachedDatabase,
        _db.userTribeTable,
      );
}
