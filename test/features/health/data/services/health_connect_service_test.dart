import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/health/data/services/health_connect_service.dart';
import 'package:emerge_app/features/health/domain/health_repository.dart';

void main() {
  group('HealthConnectService', () {
    test('can be instantiated with default constructor', () {
      final service = HealthConnectService();
      expect(service, isNotNull);
    });

    test('implements HealthRepository', () {
      final service = HealthConnectService();
      expect(service, isA<HealthRepository>());
    });
  });
}
