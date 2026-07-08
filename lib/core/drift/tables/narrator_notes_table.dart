import 'package:drift/drift.dart';

/// Drift table for Narrator observation notes.
///
/// Stores observations the Narrator system logs about user activity,
/// such as completed habits, level-ups, streak milestones, etc.
class NarratorNotesTable extends Table {
  /// Unique identifier for this note.
  TextColumn get id => text()();

  /// The type of note, stored as a string (NarratorNoteType enum name).
  TextColumn get type => text()();

  /// Arbitrary JSON data associated with this note.
  TextColumn get dataJson => text()();

  /// ISO8601 timestamp of when this note was recorded.
  TextColumn get recordedAt => text()();

  /// Optional habit ID this note is associated with.
  TextColumn get habitId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String? get tableName => 'narrator_notes';
}
