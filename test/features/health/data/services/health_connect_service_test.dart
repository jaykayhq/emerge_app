import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/health/data/services/health_connect_service.dart';
import 'package:emerge_app/features/health/domain/health_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:health/health.dart';
import 'package:mocktail/mocktail.dart';

class MockHealth extends Mock implements Health {}

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

    test('getTodaySteps returns 0 when health data is empty', () async {
      final mockHealth = MockHealth();
      final service = HealthConnectService(health: mockHealth);

      when(
        () => mockHealth.getHealthDataFromTypes(
          types: any(named: 'types'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
        ),
      ).thenAnswer((_) async => []);

      final result = await service.getTodaySteps();
      expect(result, 0);
    });

    test('getTodaySteps returns step count from NumericHealthValue', () async {
      final mockHealth = MockHealth();
      final service = HealthConnectService(health: mockHealth);

      final dataPoint = HealthDataPoint(
        uuid: 'test-uuid',
        value: NumericHealthValue(numericValue: 5000),
        type: HealthDataType.STEPS,
        unit: HealthDataUnit.UNKNOWN_UNIT,
        dateFrom: DateTime(2024, 1, 1),
        dateTo: DateTime(2024, 1, 1),
        sourcePlatform: HealthPlatformType.appleHealth,
        sourceDeviceId: 'test-device',
        sourceId: 'test-source',
        sourceName: 'Test Source',
      );

      when(
        () => mockHealth.getHealthDataFromTypes(
          types: any(named: 'types'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
        ),
      ).thenAnswer((_) async => [dataPoint]);

      final result = await service.getTodaySteps();
      expect(result, 5000);
    });

    test('requestHealthPermissions returns Left on exception', () async {
      final mockHealth = MockHealth();
      final service = HealthConnectService(health: mockHealth);

      when(
        () => mockHealth.requestAuthorization(any()),
      ).thenThrow(Exception('Permission denied'));

      final result = await service.requestHealthPermissions();
      expect(result, isA<Left<Failure, bool>>());
      result.fold(
        (failure) => expect(failure, isA<HealthFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('isHealthConnected returns false on exception', () async {
      final mockHealth = MockHealth();
      final service = HealthConnectService(health: mockHealth);

      when(
        () => mockHealth.hasPermissions(any()),
      ).thenThrow(Exception('Not available'));

      final result = await service.isHealthConnected();
      expect(result, false);
    });
  });
}
