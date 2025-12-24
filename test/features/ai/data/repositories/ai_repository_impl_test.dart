import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/ai/data/datasources/groq_ai_service.dart';
import 'package:emerge_app/features/ai/data/repositories/ai_repository_impl.dart';

class MockGroqAiService extends Mock implements GroqAiService {}

void main() {
  late AiRepositoryImpl repository;
  late MockGroqAiService mockService;

  setUp(() {
    mockService = MockGroqAiService();
    repository = AiRepositoryImpl(remoteDataSource: mockService);
  });

  group('AiRepositoryImpl', () {
    test('should return data when service call is successful', () async {
      // Arrange
      when(
        () => mockService.getCoachAdvice(any(), any()),
      ).thenAnswer((_) async => "Test Advice");

      // Act
      final result = await repository.getCoachAdvice(
        userContext: "ctx",
        userMessage: "msg",
      );

      // Assert
      expect(result, "Test Advice");
      verify(() => mockService.getCoachAdvice("ctx", "msg")).called(1);
    });

    test(
      'should return fallback quote when service throws exception',
      () async {
        // Arrange
        when(
          () => mockService.getCoachAdvice(any(), any()),
        ).thenThrow(Exception("API Error"));

        // Act
        final result = await repository.getCoachAdvice(
          userContext: "ctx",
          userMessage: "msg",
        );

        // Assert
        expect(result, isNotEmpty); // Should return a quote
        expect(result, isNot("Test Advice"));
      },
    );
  });
}
