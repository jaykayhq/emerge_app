// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_reflections_dao.dart';

// ignore_for_file: type=lint
mixin _$DailyReflectionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DailyReflectionsTableTable get dailyReflectionsTable =>
      attachedDatabase.dailyReflectionsTable;
  DailyReflectionsDaoManager get managers => DailyReflectionsDaoManager(this);
}

class DailyReflectionsDaoManager {
  final _$DailyReflectionsDaoMixin _db;
  DailyReflectionsDaoManager(this._db);
  $$DailyReflectionsTableTableTableManager get dailyReflectionsTable =>
      $$DailyReflectionsTableTableTableManager(
        _db.attachedDatabase,
        _db.dailyReflectionsTable,
      );
}
