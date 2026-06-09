import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:emerge_app/core/utils/app_logger.dart';

class GroqAiService {
  final FirebaseFunctions _functions;

  GroqAiService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  Future<String> getCoachAdvice(String userContext, String userMessage) async {
    try {
      final result = await _functions.httpsCallable('getGroqCoachAdvice').call({
        'userContext': userContext,
        'userMessage': userMessage,
      });

      if (result.data != null && result.data['advice'] != null) {
        return result.data['advice'].toString().trim();
      }

      return "Keep going! Consistency is key.";
    } on FirebaseFunctionsException catch (e) {
      AppLogger.e('AI Coach Service Error: ${e.code} - ${e.message}');
      return "I'm having trouble connecting to your inner coach right now. Keep pushing!";
    } catch (e, s) {
      AppLogger.e('Groq Exception', e, s);
      return "You're doing great. Stay focused!";
    }
  }

  // Expanded methods to match AiService requirements

  Future<String> getIdentityAffirmation(String context) async {
    return getCoachAdvice(
      context,
      "Give me a short, powerful identity-based affirmation based on my habits.",
    );
  }

  Future<String> getPatternRecognition(List<dynamic> history) async {
    // Flatten history for context
    final context = history.toString();
    return getCoachAdvice(
      "User Habit History: $context",
      "Analyze my recent habit history and give me one specific insight about my patterns.",
    );
  }

  Future<String> getGoldilocksAdjustment(int streak, double difficulty) async {
    return getCoachAdvice(
      "Current Streak: $streak days. Difficulty rating: $difficulty/10.",
      "Based on my streak and difficulty, should I adjust my habit difficulty? Answer in 1 sentence.",
    );
  }

  Future<List<String>> getPersonalizedChallenges() async {
    final response = await getCoachAdvice(
      "User wants new challenges.",
      "Give me 3 short, specific habit challenges as a JSON list of strings. Example: [\"Run 1km\", \"Read 5 pages\"]",
    );

    try {
      // Attempt to parse the JSON response
      final cleanJson = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final List<dynamic> parsed = jsonDecode(cleanJson);
      return parsed.map((e) => e.toString()).toList();
    } catch (e) {
      return [
        "Complete your main habit 3 days in a row",
        "Reflect on your 'Why' for 2 minutes",
        "Stack a new habit after your morning coffee",
      ];
    }
  }

  Future<Map<String, dynamic>> getCompanionMessage({
    required String archetype,
    required String eventType,
    required Map<String, dynamic> userContext,
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      final result = await _functions.httpsCallable('getGroqCoachAdvice').call({
        'eventType': eventType,
        'archetype': archetype,
        'userContext': userContext,
        'conversationHistory': conversationHistory ?? [],
      });

      if (result.data != null && result.data['message'] != null) {
        return {
          'message': result.data['message'].toString().trim(),
          'tone': result.data['tone']?.toString() ?? 'neutral',
          'suggestions': result.data['suggestions'] != null
              ? List<String>.from(result.data['suggestions'])
              : null,
        };
      }

      return {
        'message': getFallbackMessage(archetype, eventType),
        'tone': 'neutral',
        'suggestions': null,
      };
    } catch (e) {
      AppLogger.e('Companion Groq Error', e);
      return {
        'message': getFallbackMessage(archetype, eventType),
        'tone': 'neutral',
        'suggestions': null,
      };
    }
  }

  String getFallbackMessage(String archetype, String eventType) {
    final fallbacks = <String, Map<String, String>>{
      'athlete': {
        'milestoneReached':
            'Solid work. That streak is proof of your discipline. Keep stacking.',
        'firstFeatureVisit':
            'This is where the work happens. Every action here shapes your future self.',
        'struggleDetected':
            'A stumble isn\'t a fall. Reset and lock in. Your future self is counting on you.',
        'dailyCheckIn': 'Another day to earn your identity. Let\'s move.',
      },
      'scholar': {
        'milestoneReached':
            'Fascinating. The data shows a clear pattern of growth. What do you observe about yourself?',
        'firstFeatureVisit':
            'A new area to explore. Knowledge awaits — let\'s see what patterns emerge.',
        'struggleDetected':
            'Inconsistency is data, not failure. What variable changed? Let\'s investigate.',
        'dailyCheckIn':
            'Good morning. I\'ve been tracking the correlations. Today is another data point.',
      },
      'creator': {
        'milestoneReached':
            'Beautiful. Each completed habit is a brushstroke on the canvas of your identity.',
        'firstFeatureVisit':
            'A fresh canvas! This space is yours to shape. What will you create here?',
        'struggleDetected':
            'Every creator faces blocks. The muse returns when you simply begin again.',
        'dailyCheckIn':
            'The world awaits your unique contribution. What will you bring to life today?',
      },
      'stoic': {
        'milestoneReached':
            'Well done. Not because of the achievement, but because you showed up when it mattered.',
        'firstFeatureVisit':
            'A new practice ground. Approach it with focus and equanimity.',
        'struggleDetected':
            'This is the training ground of virtue. What does this obstacle reveal about your character?',
        'dailyCheckIn':
            'You woke up. That\'s enough. Everything else is practice.',
      },
      'zealot': {
        'milestoneReached':
            'Your vision is crystallizing. Every completed habit is a declaration of your destiny.',
        'firstFeatureVisit':
            'A new arena for your mission. Explore it with the intensity it deserves.',
        'struggleDetected':
            'The path demands everything. This is where most turn back. Will you?',
        'dailyCheckIn':
            'Your purpose doesn\'t rest. Neither should you. The mission continues today.',
      },
    };

    final archetypeFallbacks = fallbacks[archetype] ?? fallbacks['scholar']!;
    return archetypeFallbacks[eventType] ??
        'Stay focused on what matters. Every action is a vote for who you want to become.';
  }
}
