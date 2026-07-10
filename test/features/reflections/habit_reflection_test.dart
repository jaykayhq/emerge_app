import 'package:emerge_app/features/reflections/domain/entities/habit_reflection.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HabitReflection', () {
    test('equality is value-based', () {
      final a = HabitReflection(
        id: 'hr1',
        userId: 'u1',
        habitId: 'h1',
        localDate: DateTime(2026, 7, 10),
        mood: Mood.ok,
        note: 'good day',
        createdAt: DateTime(2026, 7, 10, 9),
        updatedAt: DateTime(2026, 7, 10, 9),
      );
      final b = a.copyWith();
      expect(a, equals(b));
    });

    test('copyWith updates mood + note + updatedAt', () {
      final a = HabitReflection(
        id: 'hr1',
        userId: 'u1',
        habitId: 'h1',
        localDate: DateTime(2026, 7, 10),
        mood: Mood.ok,
        note: 'first',
        createdAt: DateTime(2026, 7, 10, 9),
        updatedAt: DateTime(2026, 7, 10, 9),
      );
      final b = a.copyWith(mood: Mood.great, note: 'amazing', updatedAt: DateTime(2026, 7, 10, 10));
      expect(b.mood, Mood.great);
      expect(b.note, 'amazing');
      expect(b.updatedAt, DateTime(2026, 7, 10, 10));
      // Unchanged fields
      expect(b.id, a.id);
      expect(b.userId, a.userId);
      expect(b.habitId, a.habitId);
      expect(b.localDate, a.localDate);
      expect(b.createdAt, a.createdAt);
    });
  });
}
