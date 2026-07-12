// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_reflections_dao.dart';

// ignore_for_file: type=lint
mixin _$HabitReflectionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $HabitReflectionsTableTable get habitReflectionsTable =>
      attachedDatabase.habitReflectionsTable;
  HabitReflectionsDaoManager get managers => HabitReflectionsDaoManager(this);
}

class HabitReflectionsDaoManager {
  final _$HabitReflectionsDaoMixin _db;
  HabitReflectionsDaoManager(this._db);
  $$HabitReflectionsTableTableTableManager get habitReflectionsTable =>
      $$HabitReflectionsTableTableTableManager(
        _db.attachedDatabase,
        _db.habitReflectionsTable,
      );
}
