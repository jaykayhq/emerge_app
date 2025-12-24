import 'package:emerge_app/features/ai/domain/repositories/ai_repository.dart';

class GetCoachAdvice {
  final AiRepository repository;

  GetCoachAdvice(this.repository);

  Future<String> call({
    required String userContext,
    required String userMessage,
  }) {
    return repository.getCoachAdvice(
      userContext: userContext,
      userMessage: userMessage,
    );
  }
}
