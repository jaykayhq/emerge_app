// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_completions_dao.dart';

// ignore_for_file: type=lint
mixin _$HabitCompletionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $HabitCompletionsTableTable get habitCompletionsTable =>
      attachedDatabase.habitCompletionsTable;
  HabitCompletionsDaoManager get managers => HabitCompletionsDaoManager(this);
}

class HabitCompletionsDaoManager {
  final _$HabitCompletionsDaoMixin _db;
  HabitCompletionsDaoManager(this._db);
  $$HabitCompletionsTableTableTableManager get habitCompletionsTable =>
      $$HabitCompletionsTableTableTableManager(
        _db.attachedDatabase,
        _db.habitCompletionsTable,
      );
}
