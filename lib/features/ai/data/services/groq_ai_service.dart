import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:emerge_app/core/utils/app_logger.dart';

class GroqAiService {
  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  final String _modelId = 'llama-3.1-8b-instant';

  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  Future<String> getCoachAdvice(String userContext, String userMessage) async {
    if (_apiKey.isEmpty) {
      AppLogger.w('GROQ_API_KEY is missing. Returning fallback advice.');
      return "Keep going! Consistency is key.";
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _modelId,
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert Habit Coach based on Atomic Habits principles. '
                         'Keep your answers short (under 2 sentences) and motivating. '
                         'Context: $userContext'
            },
            {
              'role': 'user',
              'content': userMessage
            }
          ],
          'temperature': 0.7,
          'max_tokens': 150,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        AppLogger.e('Groq API Error: ${response.statusCode} - ${response.body}');
        return "I'm having trouble connecting to your inner coach right now. Keep pushing!";
      }
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
      // This is risky with LLMs, so we need a fallback
      final cleanJson = response.replaceAll('```json', '').replaceAll('```', '').trim();
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
