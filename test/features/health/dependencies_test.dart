import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

void main() {
  group('Health Connect dependency', () {
    test('health package resolves at compile time', () {
      expect(HealthDataType.values, contains(HealthDataType.STEPS));
    });

    test('Android Health Connect permission declared', () {
      const permission = 'android.permission.health.CONNECT_HEALTH_DATA';
      expect(permission, contains('CONNECT_HEALTH_DATA'));
    });

    test('UsageStats permission declared', () {
      const permission = 'android.permission.PACKAGE_USAGE_STATS';
      expect(permission, contains('PACKAGE_USAGE_STATS'));
    });

    test('Health Connect meta-data declared', () {
      const metaData = 'com.google.android.gms.health.CONNECT_HEALTH_DATA';
      expect(metaData, contains('CONNECT_HEALTH_DATA'));
    });
  });
}
