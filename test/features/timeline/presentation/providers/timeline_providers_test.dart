import 'package:emerge_app/features/timeline/presentation/providers/reflection_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('todayReflectionStateProvider', () {
    test('initial value is false', () {
      final container = ProviderContainer();
      expect(container.read(todayReflectionStateProvider), false);
      container.dispose();
    });

    test('setLogged updates to true', () {
      final container = ProviderContainer();
      container.read(todayReflectionStateProvider.notifier).setLogged(true);
      expect(container.read(todayReflectionStateProvider), true);
      container.dispose();
    });

    test('resetForNewDay sets back to false', () {
      final container = ProviderContainer();
      final notifier = container.read(todayReflectionStateProvider.notifier);
      notifier.setLogged(true);
      notifier.resetForNewDay();
      expect(container.read(todayReflectionStateProvider), false);
      container.dispose();
    });
  });
}
