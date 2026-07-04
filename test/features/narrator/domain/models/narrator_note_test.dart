import 'package:emerge_app/features/narrator/domain/models/narrator_note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NarratorNoteType', () {
    test('has exactly 10 values', () {
      expect(NarratorNoteType.values.length, 10);
    });

    test('contains aiInsight', () {
      expect(NarratorNoteType.values, contains(NarratorNoteType.aiInsight));
    });

    test('contains reflectionLogged', () {
      expect(
        NarratorNoteType.values,
        contains(NarratorNoteType.reflectionLogged),
      );
    });

    test('contains habitCompleted', () {
      expect(
        NarratorNoteType.values,
        contains(NarratorNoteType.habitCompleted),
      );
    });

    test('contains levelUp', () {
      expect(NarratorNoteType.values, contains(NarratorNoteType.levelUp));
    });

    test('contains streakMilestone', () {
      expect(
        NarratorNoteType.values,
        contains(NarratorNoteType.streakMilestone),
      );
    });

    test('contains onboardingStep', () {
      expect(
        NarratorNoteType.values,
        contains(NarratorNoteType.onboardingStep),
      );
    });

    test('contains absenceDetected', () {
      expect(
        NarratorNoteType.values,
        contains(NarratorNoteType.absenceDetected),
      );
    });

    test('contains morningBrief', () {
      expect(NarratorNoteType.values, contains(NarratorNoteType.morningBrief));
    });

    test('contains weeklyRecap', () {
      expect(NarratorNoteType.values, contains(NarratorNoteType.weeklyRecap));
    });

    test('contains screenVisit', () {
      expect(NarratorNoteType.values, contains(NarratorNoteType.screenVisit));
    });
  });

  group('NarratorNote', () {
    test('can be created with all required fields', () {
      final note = NarratorNote(
        id: 'note_1',
        type: NarratorNoteType.aiInsight,
        data: {'key': 'value'},
        recordedAt: DateTime(2026, 7, 2),
      );

      expect(note.id, 'note_1');
      expect(note.type, NarratorNoteType.aiInsight);
      expect(note.data, {'key': 'value'});
      expect(note.recordedAt, DateTime(2026, 7, 2));
      expect(note.habitId, isNull);
    });

    test('can be created with optional habitId', () {
      final note = NarratorNote(
        id: 'note_2',
        type: NarratorNoteType.habitCompleted,
        data: {},
        recordedAt: DateTime(2026, 7, 2),
        habitId: 'habit_123',
      );

      expect(note.habitId, 'habit_123');
    });

    test('supports value equality', () {
      final note1 = NarratorNote(
        id: 'note_1',
        type: NarratorNoteType.aiInsight,
        data: {'key': 'value'},
        recordedAt: DateTime(2026, 7, 2),
      );
      final note2 = NarratorNote(
        id: 'note_1',
        type: NarratorNoteType.aiInsight,
        data: {'key': 'value'},
        recordedAt: DateTime(2026, 7, 2),
      );

      expect(note1, equals(note2));
    });

    test('supports copyWith', () {
      final note = NarratorNote(
        id: 'note_1',
        type: NarratorNoteType.aiInsight,
        data: {'key': 'value'},
        recordedAt: DateTime(2026, 7, 2),
      );

      final updated = note.copyWith(
        type: NarratorNoteType.reflectionLogged,
        habitId: 'habit_456',
      );

      expect(updated.id, 'note_1');
      expect(updated.type, NarratorNoteType.reflectionLogged);
      expect(updated.data, {'key': 'value'});
      expect(updated.recordedAt, DateTime(2026, 7, 2));
      expect(updated.habitId, 'habit_456');
    });
  });
}
