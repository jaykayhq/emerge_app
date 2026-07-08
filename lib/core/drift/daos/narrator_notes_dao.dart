import 'dart:convert';

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/narrator_notes_table.dart';

part 'narrator_notes_dao.g.dart';

/// DAO for reading and writing Narrator notes.
@DriftAccessor(tables: [NarratorNotesTable])
class NarratorNotesDao extends DatabaseAccessor<AppDatabase>
    with _$NarratorNotesDaoMixin {
  NarratorNotesDao(super.db);

  /// Inserts a new narrator note.
  Future<void> insertNote({
    required String id,
    required String type,
    required Map<String, dynamic> data,
    required DateTime recordedAt,
    String? habitId,
  }) {
    return into(narratorNotesTable).insert(
      NarratorNotesTableCompanion(
        id: Value(id),
        type: Value(type),
        dataJson: Value(jsonEncode(data)),
        recordedAt: Value(recordedAt.toIso8601String()),
        habitId: Value(habitId),
      ),
    );
  }

  /// Returns the most recent notes, ordered by recordedAt descending.
  Future<List<NarratorNotesTableData>> getRecentNotes({
    int limit = 20,
    String? typeFilter,
  }) {
    final query = select(narratorNotesTable)
      ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
      ..limit(limit);

    if (typeFilter != null) {
      query.where((t) => t.type.equals(typeFilter));
    }

    return query.get();
  }

  /// Returns the latest note of a given type, or null.
  Future<NarratorNotesTableData?> getLatestNoteOfType(String type) {
    return (select(narratorNotesTable)
          ..where((t) => t.type.equals(type))
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Deletes notes older than the given date.
  Future<int> deleteOldNotes({required DateTime before}) {
    final beforeStr = before.toIso8601String();
    return (delete(narratorNotesTable)
          ..where((t) => t.recordedAt.isSmallerThanValue(beforeStr)))
        .go();
  }

  /// Returns the count of notes in the table.
  Future<int> countNotes() {
    return select(narratorNotesTable).map((row) => row.id).get().then(
      (rows) => rows.length,
    );
  }
}
