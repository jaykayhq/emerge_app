import 'package:emerge_app/features/narrator/data/datasources/narrator_local_datasource.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_note.dart';

/// Repository for the Narrator system.
///
/// Coordinates between the trigger engine (decision logic) and
/// the local datasource (persistence).
class NarratorRepository {
  final NarratorLocalDatasource _datasource;

  NarratorRepository({required NarratorLocalDatasource datasource})
      : _datasource = datasource;

  /// Records a habit completion observation.
  Future<NarratorNote> recordHabitCompleted({
    required String habitId,
    required Map<String, dynamic> data,
  }) {
    return _datasource.recordNote(
      type: NarratorNoteType.habitCompleted,
      data: data,
      habitId: habitId,
    );
  }

  /// Records a reflection observation.
  Future<NarratorNote> recordReflectionLogged({
    required Map<String, dynamic> data,
  }) {
    return _datasource.recordNote(
      type: NarratorNoteType.reflectionLogged,
      data: data,
    );
  }

  /// Returns the most recent narrator notes.
  Future<List<NarratorNote>> getRecentNotes({int limit = 20}) {
    return _datasource.getRecentNotes(limit: limit);
  }

  /// Returns the latest note of a specific type.
  Future<NarratorNote?> getLatestNoteOfType(NarratorNoteType type) {
    return _datasource.getLatestNoteOfType(type);
  }

  /// Returns the latest aiInsight note for the summary card.
  Future<NarratorNote?> getLatestInsight() {
    return _datasource.getLatestNoteOfType(NarratorNoteType.aiInsight);
  }
}
