import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/health/presentation/providers/health_sync_provider.dart';

void main() {
  test('healthSyncProvider exists', () {
    final container = ProviderContainer();
    final notifier = container.read(healthSyncProvider.notifier);
    expect(notifier, isA<HealthSyncNotifier>());
  });
}
