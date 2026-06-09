import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/health/data/services/screen_time_service.dart';
import 'package:emerge_app/features/health/domain/health_repository.dart';

void main() {
  group('ScreenTimeService', () {
    test('can be instantiated', () {
      final service = ScreenTimeService();
      expect(service, isNotNull);
    });

    test('implements HealthRepository', () {
      final service = ScreenTimeService();
      expect(service, isA<HealthRepository>());
    });
  });
}
