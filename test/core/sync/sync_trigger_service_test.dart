import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/core/sync/sync_trigger_service.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';

class MockSyncEngine extends Mock implements EnhancedSyncEngine {}

void main() {
  late MockSyncEngine mockSyncEngine;
  late List<ConnectivityListener> capturedListeners;
  late SyncTriggerService service;

  setUp(() {
    mockSyncEngine = MockSyncEngine();
    capturedListeners = [];
    service = SyncTriggerService(mockSyncEngine, (callback) {
      capturedListeners.add(callback);
    });
  });

  group('SyncTriggerService', () {
    test('onConnectivityChanged triggers sync when online', () async {
      when(() => mockSyncEngine.processMutationQueue())
          .thenAnswer((_) async {});

      await service.onConnectivityChanged([ConnectivityResult.wifi]);

      verify(() => mockSyncEngine.processMutationQueue()).called(1);
    });

    test('onConnectivityChanged does not trigger sync when offline', () async {
      when(() => mockSyncEngine.processMutationQueue())
          .thenAnswer((_) async {});

      await service.onConnectivityChanged([ConnectivityResult.none]);

      verifyNever(() => mockSyncEngine.processMutationQueue());
    });

    test('triggerSync does nothing when already in progress', () async {
      when(() => mockSyncEngine.processMutationQueue())
          .thenAnswer((_) async {});

      await Future.wait([
        service.triggerSync(),
        service.triggerSync(),
      ]);

      verify(() => mockSyncEngine.processMutationQueue()).called(1);
    });

    test('start registers the connectivity listener', () async {
      when(() => mockSyncEngine.processMutationQueue())
          .thenAnswer((_) async {});

      service.start();

      expect(capturedListeners.length, 1);

      await capturedListeners[0]([ConnectivityResult.wifi]);

      verify(() => mockSyncEngine.processMutationQueue()).called(1);
    });
  });
}
