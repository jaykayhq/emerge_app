import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/companion/domain/entities/companion_message.dart';

void main() {
  group('CompanionMessage', () {
    test('can be constructed with required fields', () {
      final msg = CompanionMessage(
        message: 'Great job on your streak!',
        tone: 'energetic',
      );
      expect(msg.message, 'Great job on your streak!');
      expect(msg.tone, 'energetic');
      expect(msg.suggestions, isNull);
    });

    test('can be constructed with optional suggestions', () {
      final msg = CompanionMessage(
        message: 'Keep going!',
        tone: 'encouraging',
        suggestions: ['Try increasing difficulty', 'Add a new habit'],
      );
      expect(msg.suggestions, hasLength(2));
    });
  });
}
