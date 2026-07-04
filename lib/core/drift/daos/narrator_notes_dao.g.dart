// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'narrator_notes_dao.dart';

// ignore_for_file: type=lint
mixin _$NarratorNotesDaoMixin on DatabaseAccessor<AppDatabase> {
  $NarratorNotesTableTable get narratorNotesTable =>
      attachedDatabase.narratorNotesTable;
  NarratorNotesDaoManager get managers => NarratorNotesDaoManager(this);
}

class NarratorNotesDaoManager {
  final _$NarratorNotesDaoMixin _db;
  NarratorNotesDaoManager(this._db);
  $$NarratorNotesTableTableTableManager get narratorNotesTable =>
      $$NarratorNotesTableTableTableManager(
        _db.attachedDatabase,
        _db.narratorNotesTable,
      );
}
