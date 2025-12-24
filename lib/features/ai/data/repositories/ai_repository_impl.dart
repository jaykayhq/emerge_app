import 'package:emerge_app/features/ai/data/datasources/groq_ai_service.dart';
import 'package:emerge_app/features/ai/domain/repositories/ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  final GroqAiService _remoteDataSource;

  AiRepositoryImpl({required GroqAiService remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  @override
  Future<String> getCoachAdvice({
    required String userContext,
    required String userMessage,
  }) async {
    try {
      return await _remoteDataSource.getCoachAdvice(userContext, userMessage);
    } catch (e) {
      // Fallback logic for errors (Offline, Rate Limit, etc.)
      // In a real app, we might check the error type to give more specific fallbacks.
      // For now, we return a safe, motivating default message.
      return _getFallbackQuote();
    }
  }

  String _getFallbackQuote() {
    final quotes = [
      "Small habits make a big difference. Keep going!",
      "You don't have to be perfect, just consistent.",
      "Every action is a vote for the person you want to become.",
      "Success is the product of daily habits, not once-in-a-lifetime transformations.",
      "Focus on the system, and the goals will take care of themselves.",
    ];
    return (quotes..shuffle()).first;
  }
}
