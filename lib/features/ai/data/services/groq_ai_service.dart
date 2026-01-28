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
}
