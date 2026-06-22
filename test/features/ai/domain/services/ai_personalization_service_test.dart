import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/ai/data/datasources/groq_ai_service.dart';
import 'package:emerge_app/features/ai/domain/services/ai_personalization_service.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';

class MockGroqAiService extends Mock implements GroqAiService {}

void main() {
  late AiPersonalizationService service;
  late MockGroqAiService mockGroq;

  setUp(() {
    mockGroq = MockGroqAiService();
    service = AiPersonalizationService(groqService: mockGroq);
  });

  group('enhanceUserWhy', () {
    test('returns the AI response when successful', () async {
      when(
        () => mockGroq.getCoachAdvice(any(), any()),
      ).thenAnswer((_) async => 'You are a disciplined creator.');

      final result = await service.enhanceUserWhy('I want to write daily');

      expect(result, 'You are a disciplined creator.');
    });

    test('passes archetype context in the system prompt when provided', () async {
      String? capturedSystemPrompt;
      when(
        () => mockGroq.getCoachAdvice(any(), any()),
      ).thenAnswer((invocation) async {
        capturedSystemPrompt = invocation.positionalArguments[0] as String;
        return 'Your archetype is strong.';
      });

      await service.enhanceUserWhy(
        'I want to write daily',
        archetype: 'Creator',
      );

      expect(capturedSystemPrompt, contains('User Archetype: Creator'));
    });

    test('returns fallback message when AI throws', () async {
      when(
        () => mockGroq.getCoachAdvice(any(), any()),
      ).thenThrow(Exception('AI is down'));

      final result = await service.enhanceUserWhy('I want to write daily');

      expect(
        result,
        "Your motivation is powerful. Let's harness it.",
      );
    });
  });

  group('analyzeHabitPerformance', () {
    final now = DateTime(2025, 6, 1);

    Habit makeHabit({
      String title = 'test habit',
      bool isArchived = false,
      int currentStreak = 0,
      HabitDifficulty difficulty = HabitDifficulty.medium,
    }) {
      return Habit(
        id: title,
        userId: 'user1',
        title: title,
        isArchived: isArchived,
        currentStreak: currentStreak,
        difficulty: difficulty,
        createdAt: now,
      );
    }

    test('returns empty list for empty habits array', () async {
      final result = await service.analyzeHabitPerformance([]);

      expect(result, isEmpty);
    });

    test('returns empty list when all habits are archived', () async {
      final habits = [
        makeHabit(title: 'Archived 1', isArchived: true),
        makeHabit(title: 'Archived 2', isArchived: true),
      ];

      final result = await service.analyzeHabitPerformance(habits);

      expect(result, isEmpty);
    });

    test('parses valid JSON array response into GoldilocksAdjustment list', () async {
      final habits = [makeHabit(title: 'Read daily', currentStreak: 10)];

      when(
        () => mockGroq.getCoachAdvice(any(), any()),
      ).thenAnswer((_) async => '''[
        {"habitTitle": "Read daily", "type": "increase", "suggestion": "Add 10 more pages", "reason": "Strong streak shows readiness"}
      ]''');

      final result = await service.analyzeHabitPerformance(habits);

      expect(result.length, 1);
      expect(result[0].habitTitle, 'Read daily');
      expect(result[0].type, AdjustmentType.increase);
      expect(result[0].suggestion, 'Add 10 more pages');
      expect(result[0].reason, 'Strong streak shows readiness');
    });

    test('handles markdown-wrapped JSON by stripping markers', () async {
      final habits = [makeHabit(title: 'Exercise', currentStreak: 3)];

      when(
        () => mockGroq.getCoachAdvice(any(), any()),
      ).thenAnswer((_) async => '```json\n[{"habitTitle": "Exercise", "type": "maintain", "suggestion": "Keep going", "reason": "Consistent"}]```');

      final result = await service.analyzeHabitPerformance(habits);

      expect(result.length, 1);
      expect(result[0].habitTitle, 'Exercise');
      expect(result[0].type, AdjustmentType.maintain);
    });

    test('returns empty list when JSON parsing fails', () async {
      final habits = [makeHabit(title: 'Read daily')];

      when(
        () => mockGroq.getCoachAdvice(any(), any()),
      ).thenAnswer((_) async => 'not valid json');

      final result = await service.analyzeHabitPerformance(habits);

      expect(result, isEmpty);
    });
  });

  group('generateIdentityInsights', () {
    final now = DateTime(2025, 6, 1);

    Habit makeHabit({
      String title = 'test habit',
      bool isArchived = false,
      int currentStreak = 0,
      HabitAttribute attribute = HabitAttribute.vitality,
    }) {
      return Habit(
        id: title,
        userId: 'user1',
        title: title,
        isArchived: isArchived,
        currentStreak: currentStreak,
        attribute: attribute,
        createdAt: now,
      );
    }

    test('returns empty list for empty habits', () async {
      final result = await service.generateIdentityInsights([]);

      expect(result, isEmpty);
    });

    test('parses JSON into AiInsight list with correct type mapping', () async {
      final habits = [makeHabit(title: 'Meditate', currentStreak: 5)];

      when(
        () => mockGroq.getCoachAdvice(any(), any()),
      ).thenAnswer((_) async => '''[
        {"type": "identity", "title": "Becoming Disciplined", "description": "Your meditation streak shows growing discipline", "action": "Increase to 15 minutes"}
      ]''');

      final result = await service.generateIdentityInsights(habits);

      expect(result.length, 1);
      expect(result[0].type, InsightType.identity);
      expect(result[0].title, 'Becoming Disciplined');
      expect(result[0].description, 'Your meditation streak shows growing discipline');
      expect(result[0].action, 'Increase to 15 minutes');
    });

    test('parses pattern type correctly into InsightType.pattern', () async {
      final habits = [makeHabit(title: 'Read', currentStreak: 3)];

      when(
        () => mockGroq.getCoachAdvice(any(), any()),
      ).thenAnswer((_) async => '''[
        {"type": "pattern", "title": "Morning Reader", "description": "You consistently read in the morning", "action": "Add a second reading session"}
      ]''');

      final result = await service.generateIdentityInsights(habits);

      expect(result.length, 1);
      expect(result[0].type, InsightType.pattern);
    });

    test('returns empty list when AI throws', () async {
      final habits = [makeHabit(title: 'Read', currentStreak: 3)];

      when(
        () => mockGroq.getCoachAdvice(any(), any()),
      ).thenThrow(Exception('AI error'));

      final result = await service.generateIdentityInsights(habits);

      expect(result, isEmpty);
    });
  });
}
