import 'package:cloud_functions/cloud_functions.dart';
import 'package:emerge_app/features/ai/data/services/groq_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class _MockHttpsCallableResult extends Mock implements HttpsCallableResult {}

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
    when(
      () => mockFunctions.httpsCallable(any()),
    ).thenReturn(mockHttpsCallable);
  });

  group('getCoachAdvice', () {
    test('should return trimmed advice when response has advice', () async {
      // Arrange
      final mockResult = _MockHttpsCallableResult();
      when(() => mockResult.data).thenReturn({'advice': '  You can do it!  '});
      when(
        () => mockHttpsCallable.call(any()),
      ).thenAnswer((_) async => mockResult);

      // Act
      final result = await service.getCoachAdvice("context", "message");

      // Assert
      expect(result, 'You can do it!');
    });

    test('should throw when response data is null', () async {
      // Arrange
      final mockResult = _MockHttpsCallableResult();
      when(() => mockResult.data).thenReturn(null);
      when(
        () => mockHttpsCallable.call(any()),
      ).thenAnswer((_) async => mockResult);

      // Act & Assert
      expect(
        () => service.getCoachAdvice("context", "message"),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Unexpected response format from AI Coach function'),
          ),
        ),
      );
    });

    test('should throw when advice field is missing', () async {
      // Arrange
      final mockResult = _MockHttpsCallableResult();
      when(() => mockResult.data).thenReturn({});
      when(
        () => mockHttpsCallable.call(any()),
      ).thenAnswer((_) async => mockResult);

      // Act & Assert
      expect(
        () => service.getCoachAdvice("context", "message"),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Unexpected response format from AI Coach function'),
          ),
        ),
      );
    });

    test(
      'should throw with the error code on FirebaseFunctionsException',
      () async {
        // Arrange
        when(() => mockHttpsCallable.call(any())).thenThrow(
          FirebaseFunctionsException(code: 'internal', message: 'Server error'),
        );

        // Act & Assert
        expect(
          () => service.getCoachAdvice("context", "message"),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString',
              contains('AI Coach Service Error: internal'),
            ),
          ),
        );
      },
    );

    test('should rethrow generic exceptions', () async {
      // Arrange
      when(
        () => mockHttpsCallable.call(any()),
      ).thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => service.getCoachAdvice("context", "message"),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('Network error'),
          ),
        ),
      );
    });

    test('should pass correct parameters to the callable', () async {
      // Arrange
      final mockResult = _MockHttpsCallableResult();
      when(() => mockResult.data).thenReturn({'advice': 'ok'});
      when(
        () => mockHttpsCallable.call(any()),
      ).thenAnswer((_) async => mockResult);

      // Act
      await service.getCoachAdvice('test_context', 'test_message');

      // Assert
      final captured = verify(
        () => mockHttpsCallable.call(captureAny()),
      ).captured;
      final args = captured.first as Map<String, dynamic>;
      expect(args['userContext'], 'test_context');
      expect(args['userMessage'], 'test_message');
    });
  });

  group('fillNarratorSlots', () {
    test('should return empty map when response data is null', () async {
      // Arrange
      final mockResult = _MockHttpsCallableResult();
      when(() => mockResult.data).thenReturn(null);
      when(
        () => mockHttpsCallable.call(any()),
      ).thenAnswer((_) async => mockResult);

      // Act
      final slots = await service.fillNarratorSlots(
        trigger: 'levelUp',
        context: {'currentStreak': 3},
      );

      // Assert
      expect(slots, isEmpty);
    });

    test('should return empty map when slots key is missing', () async {
      // Arrange
      final mockResult = _MockHttpsCallableResult();
      when(() => mockResult.data).thenReturn({'other': 'data'});
      when(
        () => mockHttpsCallable.call(any()),
      ).thenAnswer((_) async => mockResult);

      // Act
      final slots = await service.fillNarratorSlots(
        trigger: 'levelUp',
        context: {'currentStreak': 3},
      );

      // Assert
      expect(slots, isEmpty);
    });

    test('should return string map when slots exist', () async {
      // Arrange
      final mockResult = _MockHttpsCallableResult();
      when(() => mockResult.data).thenReturn({
        'slots': {'greeting': 'Hello there', 'streak': 7},
      });
      when(
        () => mockHttpsCallable.call(any()),
      ).thenAnswer((_) async => mockResult);

      // Act
      final slots = await service.fillNarratorSlots(
        trigger: 'levelUp',
        context: {'currentStreak': 7},
      );

      // Assert
      expect(slots, {'greeting': 'Hello there', 'streak': '7'});
    });

    test('should pass trigger and context to the callable', () async {
      // Arrange
      final mockResult = _MockHttpsCallableResult();
      when(() => mockResult.data).thenReturn({
        'slots': {'a': 'b'},
      });
      when(
        () => mockHttpsCallable.call(any()),
      ).thenAnswer((_) async => mockResult);

      // Act
      await service.fillNarratorSlots(
        trigger: 'levelUp',
        context: {'currentStreak': 7, 'momentumScore': 0.8},
      );

      // Assert
      final captured = verify(
        () => mockHttpsCallable.call(captureAny()),
      ).captured;
      final args = captured.first as Map<String, dynamic>;
      expect(args['trigger'], 'levelUp');
      expect(args['context'], {'currentStreak': 7, 'momentumScore': 0.8});
    });
  });
}
