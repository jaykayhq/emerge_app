import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/ai/data/datasources/groq_ai_service.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

void main() {
  late GroqAiService service;
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockHttpsCallable;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockFunctions = MockFirebaseFunctions();
    mockHttpsCallable = MockHttpsCallable();
    service = GroqAiService(functions: mockFunctions);
  });

  group('GroqAiService', () {
    test('should return advice when response is 200', () async {
      // Arrange
      final mockResult = _MockHttpsCallableResult();
      when(() => mockResult.data).thenReturn({'advice': 'You can do it!'});
      
      when(() => mockFunctions.httpsCallable('getGroqCoachAdvice'))
          .thenReturn(mockHttpsCallable);
      when(() => mockHttpsCallable.call(any())).thenAnswer((_) async => mockResult);

      // Act
      final result = await service.getCoachAdvice("context", "message");

      // Assert
      expect(result, "You can do it!");
    });

    test('should throw Exception on non-200 response', () async {
      // Arrange
      when(() => mockFunctions.httpsCallable('getGroqCoachAdvice'))
          .thenReturn(mockHttpsCallable);
      when(() => mockHttpsCallable.call(any())).thenThrow(
        FirebaseFunctionsException(
          code: 'internal',
          message: 'Server error',
        ),
      );

      // Act & Assert
      expect(
        () => service.getCoachAdvice("context", "message"),
        throwsA(isA<Exception>()),
      );
    });
  });
}

class _MockHttpsCallableResult extends Mock implements HttpsCallableResult {}
