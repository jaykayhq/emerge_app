import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/gamification/presentation/providers/world_entropy_provider.dart';

void main() {
  group('calculateWorldEntropyEffects', () {
    test('returns empty list for thriving state (entropy < 0.1)', () {
      final effects = calculateWorldEntropyEffects(0.05);
      expect(effects, isEmpty);
    });

    test(
      'returns mild effects for neutral state (entropy between 0.1 and 0.3)',
      () {
        final effects = calculateWorldEntropyEffects(0.2);
        expect(effects, contains('fog'));
      },
    );

    test('returns severe effects for decaying state (entropy > 0.3)', () {
      final effects = calculateWorldEntropyEffects(0.4);
      expect(effects, containsAll(['fog', 'weeds', 'dark_sky']));
    });
  });
}
