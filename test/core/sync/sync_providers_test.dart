import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/core/sync/sync_trigger_service.dart';

class MockSyncEngine extends Mock implements EnhancedSyncEngine {}
class MockSyncTriggerService extends Mock implements SyncTriggerService {}

void main() {
  group('SyncTriggerService Provider', () {
    test('SyncTriggerService runs triggerSync without error', () async {
      final engine = MockSyncEngine();
      when(() => engine.processMutationQueue()).thenAnswer((_) async {});

      // Create service with a no-op listener
      final service = SyncTriggerService(
        engine,
        (listener) {}, // no-op; connectivity listening not needed in unit test
      );

      service.start();
      await service.triggerSync();

      verify(() => engine.processMutationQueue()).called(1);
    });

    test('stop cancels subscription safely', () {
      final engine = MockSyncEngine();
      final service = SyncTriggerService(
        engine,
        (listener) {},
      );

      expect(() => service.stop(), returnsNormally);
    });
  });
}
