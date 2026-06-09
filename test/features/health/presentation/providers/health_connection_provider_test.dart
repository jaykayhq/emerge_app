import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/health/presentation/providers/health_connection_provider.dart';

void main() {
  test('healthConnectionProvider can be read', () {
    final container = ProviderContainer();
    final state = container.read(healthConnectionProvider);
    expect(state.healthConnected, isFalse);
    expect(state.screenTimeConnected, isFalse);
  });

  test('healthConnectionState can be created', () {
    const state = HealthConnectionState(
      healthConnected: false,
      screenTimeConnected: false,
    );
    expect(state.healthConnected, isFalse);
    expect(state.screenTimeConnected, isFalse);
  });

  test('HealthConnectionState copyWith works', () {
    const state = HealthConnectionState(
      healthConnected: false,
      screenTimeConnected: false,
    );
    final updated = state.copyWith(healthConnected: true);
    expect(updated.healthConnected, isTrue);
    expect(updated.screenTimeConnected, isFalse);
  });
}
