import 'package:emerge_app/features/companion/domain/entities/companion_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompanionMessage', () {
    test('constructor sets message and tone', () {
      const message = CompanionMessage(
        message: 'Hello!',
        tone: 'encouraging',
      );

      expect(message.message, 'Hello!');
      expect(message.tone, 'encouraging');
      expect(message.suggestions, isNull);
    });

    test('constructor with non-null suggestions', () {
      const message = CompanionMessage(
        message: 'Try these:',
        tone: 'suggestive',
        suggestions: ['Drink water', 'Take a walk'],
      );

      expect(message.message, 'Try these:');
      expect(message.tone, 'suggestive');
      expect(message.suggestions, ['Drink water', 'Take a walk']);
    });

    test('constructor with null suggestions defaults to null', () {
      const message = CompanionMessage(
        message: 'Hello!',
        tone: 'friendly',
        suggestions: null,
      );

      expect(message.suggestions, isNull);
    });
  });
}
