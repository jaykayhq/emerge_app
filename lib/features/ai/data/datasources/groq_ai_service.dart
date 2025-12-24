import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GroqAiService {
  final http.Client _client;
  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  // Hardcoded model ID as per strategy
  final String _modelId = 'llama-3.1-8b-instant';

  GroqAiService({http.Client? client}) : _client = client ?? http.Client();

  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  Future<String> getCoachAdvice(String userContext, String userMessage) async {
    if (_apiKey.isEmpty) {
      throw Exception('Groq API Key not found in .env');
    }

    try {
      final response = await _client.post(
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
              'content':
                  'You are an expert Habit Coach based on Atomic Habits principles. '
                  'Keep your answers short (under 2 sentences) and motivating. '
                  'Context: $userContext',
            },
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.7,
          'max_tokens': 150,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded');
      } else {
        throw Exception(
          'Groq API Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      // Re-throw to be handled by the repository (which will decide on fallback)
      rethrow;
    }
  }
}
