import 'dart:convert';

import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/drift/daos/narrator_notes_dao.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_note.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:uuid/uuid.dart';

/// Local datasource for Narrator notes backed by Drift.
class NarratorLocalDatasource {
  final NarratorNotesDao _dao;
  final Uuid _uuid;

  NarratorLocalDatasource({
    required NarratorNotesDao dao,
    Uuid? uuid,
  })  : _dao = dao,
        _uuid = uuid ?? const Uuid();

  /// Records a new narrator observation note.
  Future<NarratorNote> recordNote({
    required NarratorNoteType type,
    required Map<String, dynamic> data,
    String? habitId,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _dao.insertNote(
      id: id,
      type: type.name,
      data: data,
      recordedAt: now,
      habitId: habitId,
    );

    return NarratorNote(
      id: id,
      type: type,
      data: data,
      recordedAt: now,
      habitId: habitId,
    );
  }

  /// Returns the most recent notes, optionally filtered by type.
  Future<List<NarratorNote>> getRecentNotes({
    int limit = 20,
    NarratorNoteType? typeFilter,
  }) async {
    final rows = await _dao.getRecentNotes(
      limit: limit,
      typeFilter: typeFilter?.name,
    );
    return rows.map(_mapRowToNote).toList();
  }

  /// Returns the latest note of a given type, or null.
  Future<NarratorNote?> getLatestNoteOfType(NarratorNoteType type) async {
    final row = await _dao.getLatestNoteOfType(type.name);
    if (row == null) return null;
    return _mapRowToNote(row);
  }

  /// Returns whether the most recent trigger of the given type was within
  /// [duration] of [now] (i.e. is on cooldown).
  Future<bool> isTriggerOnCooldown({
    required NarratorTrigger trigger,
    required Duration cooldown,
    required DateTime now,
  }) async {
    final lastNote = await getLatestNoteOfType(
      _triggerToNoteType(trigger),
    );
    if (lastNote == null) return false;
    return now.difference(lastNote.recordedAt) < cooldown;
  }

  /// Cleans up notes older than the given date.
  Future<int> deleteOldNotes({required DateTime before}) {
    return _dao.deleteOldNotes(before: before);
  }

  /// Maps a Drift row to a NarratorNote domain model.
  NarratorNote _mapRowToNote(NarratorNotesTableData row) {
    return NarratorNote(
      id: row.id,
      type: NarratorNoteType.values.firstWhere(
        (t) => t.name == row.type,
        orElse: () => NarratorNoteType.aiInsight,
      ),
      data: (jsonDecode(row.dataJson) as Map<String, dynamic>?) ?? {},
      recordedAt: DateTime.parse(row.recordedAt),
      habitId: row.habitId,
    );
  }

  NarratorNoteType _triggerToNoteType(NarratorTrigger trigger) =>
      trigger.toNoteType();
}
