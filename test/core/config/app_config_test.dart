import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/config/app_config.dart';

void main() {
  group('AppConfig AdMob Tests', () {
    test('getAdUnitId returns test IDs in development', () {
      // Assuming test environment acts like development
      final bannerId = AppConfig.getAdUnitId('banner', 'android');
      expect(bannerId, equals('ca-app-pub-3940256099942544/6300978111'));

      final iosBannerId = AppConfig.getAdUnitId('banner', 'ios');
      expect(iosBannerId, equals('ca-app-pub-3940256099942544/2934735716'));
    });
  });
}
