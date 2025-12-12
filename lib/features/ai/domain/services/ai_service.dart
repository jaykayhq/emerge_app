import 'package:emerge_app/features/ai/data/services/groq_ai_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Interface definition (abstract class)
abstract class AiService {
  Future<String> getIdentityAffirmation(String context);
  Future<String> getPatternRecognition(List<dynamic> history);
  Future<String> getGoldilocksAdjustment(int streak, double difficulty);
  Future<List<String>> getPersonalizedChallenges();
}

// Implementation wrapper
class GroqAiServiceImpl implements AiService {
  final GroqAiService _groqService;

  GroqAiServiceImpl(this._groqService);

  @override
  Future<String> getIdentityAffirmation(String context) {
    return _groqService.getIdentityAffirmation(context);
  }

  @override
  Future<String> getPatternRecognition(List<dynamic> history) {
    return _groqService.getPatternRecognition(history);
  }

  @override
  Future<String> getGoldilocksAdjustment(int streak, double difficulty) {
    return _groqService.getGoldilocksAdjustment(streak, difficulty);
  }

  @override
  Future<List<String>> getPersonalizedChallenges() {
    return _groqService.getPersonalizedChallenges();
  }
}

final aiServiceProvider = Provider<AiService>((ref) {
  // Directly use the Groq implementation
  return GroqAiServiceImpl(GroqAiService());
});
