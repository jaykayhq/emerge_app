import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/health/data/services/screen_time_service.dart';
import 'package:emerge_app/features/health/domain/health_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScreenTimeService', () {
    test('can be instantiated', () {
      final service = ScreenTimeService();
      expect(service, isNotNull);
    });

    test('implements HealthRepository', () {
      final service = ScreenTimeService();
      expect(service, isA<HealthRepository>());
    });

    test('requestScreenTimePermissions returns true when channel returns true',
        () async {
      final channel = MethodChannel('com.emerge.emerge_app/screen_time');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'requestUsageStatsPermission') return true;
        return null;
      });

      final service = ScreenTimeService();
      final result = await service.requestScreenTimePermissions();
      expect(result.isRight(), true);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('getTodayScreenTime handles MissingPluginException gracefully',
        () async {
      final channel = MethodChannel('com.emerge.emerge_app/screen_time');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        throw MissingPluginException('not implemented');
      });

      final service = ScreenTimeService();
      final result = await service.getTodayScreenTime();
      expect(result, 0);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
  });
}
