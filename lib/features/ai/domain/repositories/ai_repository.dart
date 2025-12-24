abstract class AiRepository {
  Future<String> getCoachAdvice({
    required String userContext,
    required String userMessage,
  });
}
