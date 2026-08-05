import 'package:emerge_app/core/services/daily_insight_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generateDailyInsight', () {
    // Mirrors the server ladder formerly in
    // functions/src/habit_notifications.ts (generateAIInsight):
    // streak 30+ → 14+ → 7+ → 3+ → level > 5 → totalXp > 500 → fallback.

    test('streak >= 30 celebrates exceptional consistency', () {
      final msg = generateDailyInsight(level: 10, streak: 30, totalXp: 2000);
      expect(msg, contains('Extraordinary!'));
      expect(msg, contains('30-day streak'));
    });

    test('streak 14-29 praises a strong foundation', () {
      final msg = generateDailyInsight(level: 10, streak: 14, totalXp: 2000);
      expect(msg, contains('Impressive dedication!'));
      expect(msg, contains('14 days of progress'));
    });

    test('streak 7-13 references habit automaticity research', () {
      final msg = generateDailyInsight(level: 10, streak: 7, totalXp: 2000);
      expect(msg, contains('7 days strong'));
    });

    test('streak 3-6 acknowledges momentum', () {
      final msg = generateDailyInsight(level: 10, streak: 3, totalXp: 2000);
      expect(msg, contains('3 days of momentum'));
    });

    test('level > 5 (short streak) praises the level', () {
      final msg = generateDailyInsight(level: 6, streak: 2, totalXp: 200);
      expect(msg, contains('Level 6 achieved'));
    });

    test('totalXp > 500 (low streak, low level) celebrates XP', () {
      final msg = generateDailyInsight(level: 3, streak: 2, totalXp: 501);
      expect(msg, contains('501 XP'));
    });

    test('falls back to the progress-over-perfection message', () {
      final msg = generateDailyInsight(level: 3, streak: 2, totalXp: 100);
      expect(msg, contains('Progress over perfection'));
    });

    test('higher tiers win over lower ones', () {
      final msg = generateDailyInsight(level: 1, streak: 40, totalXp: 0);
      expect(msg, contains('Extraordinary!'));
      expect(msg, contains('40-day streak'));
    });
  });
}
