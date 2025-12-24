import 'dart:convert';
import 'package:emerge_app/features/ai/data/datasources/groq_ai_service.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// part 'ai_personalization_service.g.dart';

final aiPersonalizationServiceProvider = Provider<AiPersonalizationService>((
  ref,
) {
  return AiPersonalizationService(groqService: GroqAiService());
});

class AiPersonalizationService {
  final GroqAiService _groqService;

  AiPersonalizationService({required GroqAiService groqService})
    : _groqService = groqService;

  Future<String> enhanceUserWhy(
    String userWhy, {
    String? archetype,
    Map<String, int>? attributes,
  }) async {
    final identityContext = archetype != null
        ? 'User Archetype: $archetype. '
        : '';
    final attributeContext = attributes != null
        ? 'Core Attributes: $attributes. '
        : '';

    final systemPrompt =
        'You are a wise and encouraging mentor. The user has just shared their deep "Why" for building habits. '
        'Context: $identityContext$attributeContext'
        'Acknowledge it, validate it, and rephrase it into a powerful, short affirmation (max 1 sentence) that connects their motivation to their identity. '
        'Do not give advice. Just affirm them.';

    try {
      return await _groqService.getCoachAdvice(systemPrompt, userWhy);
    } catch (e) {
      // Fallback if AI fails
      return "Your motivation is powerful. Let's harness it.";
    }
  }

  Future<List<GoldilocksAdjustment>> analyzeHabitPerformance(
    List<Habit> habits,
  ) async {
    // Filter for active habits
    final activeHabits = habits.where((h) => !h.isArchived).toList();

    if (activeHabits.isEmpty) return [];

    final habitData = activeHabits
        .map(
          (h) => {
            'title': h.title,
            'difficulty': h.difficulty.name,
            'currentStreak': h.currentStreak,
            'frequency': h.frequency.toString(),
            'lastCompleted': h.lastCompletedDate?.toIso8601String(),
          },
        )
        .toList();

    const systemPrompt =
        'You are the Goldilocks Engine. Your job is to analyze habit performance and suggest difficulty adjustments. '
        'Rules:'
        '1. If streak > 5, suggest increasing difficulty (Level Up).'
        '2. If missed > 2 times recently or streak is 0 for a while, suggest decreasing difficulty (Recalibrate).'
        '3. If consistent but not too easy, suggest maintaining (Stay the Course).'
        'Output ONLY valid JSON array of objects: {"habitTitle": "...", "type": "increase"|"decrease"|"maintain", "suggestion": "...", "reason": "..."}';

    try {
      final jsonString = await _groqService.getCoachAdvice(
        systemPrompt,
        jsonEncode(habitData),
      );

      // Clean up potential markdown code blocks if the LLM includes them
      final cleanJson = _cleanJsonOutput(jsonString);

      final List<dynamic> parsed = jsonDecode(cleanJson);

      return parsed
          .map(
            (item) => GoldilocksAdjustment(
              habitTitle: item['habitTitle'],
              type: _parseAdjustmentType(item['type']),
              suggestion: item['suggestion'],
              reason: item['reason'],
            ),
          )
          .toList();
    } catch (e) {
      // Fallback or empty if AI fails
      return [];
    }
  }

  Future<List<AiInsight>> generateIdentityInsights(List<Habit> habits) async {
    final activeHabits = habits.where((h) => !h.isArchived).toList();
    if (activeHabits.isEmpty) return [];

    final habitData = activeHabits
        .map(
          (h) => {
            'title': h.title,
            'attribute': h.attribute.name,
            'currentStreak': h.currentStreak,
          },
        )
        .toList();

    const systemPrompt =
        'You are an Insight Engine. Analyze the user'
        "'"
        's habits and streaks to identify their growing identity. '
        'Output ONLY valid JSON array of objects: {"type": "identity"|"pattern", "title": "...", "description": "...", "action": "..."}';

    try {
      final jsonString = await _groqService.getCoachAdvice(
        systemPrompt,
        jsonEncode(habitData),
      );
      final cleanJson = _cleanJsonOutput(jsonString);
      final List<dynamic> parsed = jsonDecode(cleanJson);

      return parsed
          .map(
            (item) => AiInsight(
              type: item['type'] == 'identity'
                  ? InsightType.identity
                  : InsightType.pattern,
              title: item['title'],
              description: item['description'],
              action: item['action'],
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  String _cleanJsonOutput(String raw) {
    return raw.replaceAll('```json', '').replaceAll('```', '').trim();
  }

  AdjustmentType _parseAdjustmentType(String type) {
    switch (type.toLowerCase()) {
      case 'increase':
        return AdjustmentType.increase;
      case 'decrease':
        return AdjustmentType.decrease;
      default:
        return AdjustmentType.maintain;
    }
  }
}

enum AdjustmentType { increase, decrease, maintain }

enum InsightType { identity, pattern }

class GoldilocksAdjustment {
  final String habitTitle;
  final AdjustmentType type;
  final String suggestion;
  final String reason;

  GoldilocksAdjustment({
    required this.habitTitle,
    required this.type,
    required this.suggestion,
    required this.reason,
  });
}

class AiInsight {
  final InsightType type;
  final String title;
  final String description;
  final String action;

  AiInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.action,
  });
}
