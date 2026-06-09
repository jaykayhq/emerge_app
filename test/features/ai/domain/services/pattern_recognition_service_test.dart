import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/features/ai/domain/services/pattern_recognition_service.dart';

void main() {
  group('PatternRecognitionService', () {
    final now = DateTime(2025, 1, 15); // Use a fixed reference date

    HabitCompletionsTableData makeCompletion(
      String id,
      String habitId,
      DateTime date,
    ) {
      return HabitCompletionsTableData(
        id: id,
        habitId: habitId,
        userId: 'test_user',
        completedAt: date.toIso8601String(),
        xpGained: 10,
        streakDay: 1,
        wasRecovery: 0,
      );
    }

    test('analyzePatterns returns "No recent history" for empty list', () {
      final result = PatternRecognitionService.analyzePatterns(
        [],
        referenceDate: now,
      );
      expect(result['status'], 'No recent history');
    });

    test('analyzePatterns detects dropping off velocity', () {
      final completions = [
        makeCompletion(
          '1',
          'habit_a',
          DateTime(2025, 1, 5),
        ), // 10 days ago (previous 7)
        makeCompletion(
          '2',
          'habit_a',
          DateTime(2025, 1, 6),
        ), // 9 days ago (previous 7)
        makeCompletion(
          '3',
          'habit_a',
          DateTime(2025, 1, 14),
        ), // 1 day ago (last 7)
      ];

      final result = PatternRecognitionService.analyzePatterns(
        completions,
        referenceDate: now,
      );
      final details = result['details'] as Map<String, dynamic>;

      expect(details['habit_a']['recentVelocity'], 'dropping off');
      expect(details['habit_a']['last7Days'], 1);
      expect(details['habit_a']['previous7Days'], 2);
    });

    test('analyzePatterns detects accelerating velocity', () {
      final completions = [
        makeCompletion(
          '1',
          'habit_b',
          DateTime(2025, 1, 5),
        ), // 10 days ago (previous 7)
        makeCompletion(
          '2',
          'habit_b',
          DateTime(2025, 1, 13),
        ), // 2 days ago (last 7)
        makeCompletion(
          '3',
          'habit_b',
          DateTime(2025, 1, 14),
        ), // 1 day ago (last 7)
      ];

      final result = PatternRecognitionService.analyzePatterns(
        completions,
        referenceDate: now,
      );
      final details = result['details'] as Map<String, dynamic>;

      expect(details['habit_b']['recentVelocity'], 'accelerating');
      expect(details['habit_b']['last7Days'], 2);
      expect(details['habit_b']['previous7Days'], 1);
    });

    test('analyzePatterns detects steady velocity', () {
      final completions = [
        makeCompletion(
          '1',
          'habit_c',
          DateTime(2025, 1, 5),
        ), // 10 days ago (previous 7)
        makeCompletion(
          '2',
          'habit_c',
          DateTime(2025, 1, 14),
        ), // 1 day ago (last 7)
      ];

      final result = PatternRecognitionService.analyzePatterns(
        completions,
        referenceDate: now,
      );
      final details = result['details'] as Map<String, dynamic>;

      expect(details['habit_c']['recentVelocity'], 'steady');
      expect(details['habit_c']['last7Days'], 1);
      expect(details['habit_c']['previous7Days'], 1);
    });
  });
}
