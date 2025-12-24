import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:emerge_app/features/ai/data/datasources/groq_ai_service.dart';
import 'package:emerge_app/features/ai/data/repositories/ai_repository_impl.dart';
import 'package:emerge_app/features/ai/domain/repositories/ai_repository.dart';
import 'package:emerge_app/features/ai/domain/usecases/get_coach_advice.dart';

// Data Source Provider
final groqAiServiceProvider = Provider<GroqAiService>((ref) {
  return GroqAiService(client: http.Client());
});

// Repository Provider
final aiRepositoryProvider = Provider<AiRepository>((ref) {
  final remoteDataSource = ref.watch(groqAiServiceProvider);
  return AiRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Use Case Provider
final getCoachAdviceProvider = Provider<GetCoachAdvice>((ref) {
  final repository = ref.watch(aiRepositoryProvider);
  return GetCoachAdvice(repository);
});
