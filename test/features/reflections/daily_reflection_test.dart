import 'package:emerge_app/features/reflections/domain/entities/daily_reflection.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mood', () {
    test('int values are 1..5 in order', () {
      expect(Mood.terrible.value, 1);
      expect(Mood.meh.value, 2);
      expect(Mood.ok.value, 3);
      expect(Mood.good.value, 4);
      expect(Mood.great.value, 5);
    });

    test('fromInt round-trips', () {
      for (final m in Mood.values) {
        expect(Mood.fromInt(m.value), m);
      }
    });
  });

  group('DailyReflection', () {
    test('equality is value-based', () {
      final a = DailyReflection(
        id: 'r1',
        userId: 'u1',
        localDate: DateTime(2026, 7, 5),
        mood: Mood.ok,
        note: 'good day',
        createdAt: DateTime(2026, 7, 5, 9),
        updatedAt: DateTime(2026, 7, 5, 9),
      );
      final b = a.copyWith();
      expect(a, equals(b));
    });

    test('moodEmoji returns expected emoji', () {
      expect(Mood.great.emoji, '🔥');
      expect(Mood.terrible.emoji, '😞');
    });
  });
}
