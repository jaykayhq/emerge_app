import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/health/data/services/health_connect_service.dart';
import 'package:emerge_app/features/health/data/services/screen_time_service.dart';
import 'package:emerge_app/features/health/data/repositories/health_repository_impl.dart';

class MockHealthConnectService extends Mock implements HealthConnectService {}

class MockScreenTimeService extends Mock implements ScreenTimeService {}

void main() {
  late MockHealthConnectService mockHealthService;
  late MockScreenTimeService mockScreenTimeService;
  late HealthRepositoryImpl repository;

  setUp(() {
    mockHealthService = MockHealthConnectService();
    mockScreenTimeService = MockScreenTimeService();
    repository = HealthRepositoryImpl(
      healthService: mockHealthService,
      screenTimeService: mockScreenTimeService,
    );
  });

  group('HealthRepositoryImpl', () {
    group('getTodaySteps', () {
      test('delegates to healthService', () async {
        when(
          () => mockHealthService.getTodaySteps(),
        ).thenAnswer((_) async => 7500);

        final result = await repository.getTodaySteps();

        expect(result, 7500);
        verify(() => mockHealthService.getTodaySteps()).called(1);
      });

      test('returns 0 when no steps recorded', () async {
        when(
          () => mockHealthService.getTodaySteps(),
        ).thenAnswer((_) async => 0);

        final result = await repository.getTodaySteps();

        expect(result, 0);
      });
    });

    group('getTodayScreenTime', () {
      test('delegates to screenTimeService', () async {
        when(
          () => mockScreenTimeService.getTodayScreenTime(),
        ).thenAnswer((_) async => 120);

        final result = await repository.getTodayScreenTime();

        expect(result, 120);
        verify(() => mockScreenTimeService.getTodayScreenTime()).called(1);
      });

      test('returns 0 when no screen time recorded', () async {
        when(
          () => mockScreenTimeService.getTodayScreenTime(),
        ).thenAnswer((_) async => 0);

        final result = await repository.getTodayScreenTime();

        expect(result, 0);
      });
    });

    group('requestHealthPermissions', () {
      test('delegates to healthService and returns Right(true)', () async {
        when(
          () => mockHealthService.requestHealthPermissions(),
        ).thenAnswer((_) async => const Right(true));

        final result = await repository.requestHealthPermissions();

        expect(result.isRight(), isTrue);
        result.fold((_) => null, (value) => expect(value, isTrue));
        verify(() => mockHealthService.requestHealthPermissions()).called(1);
      });

      test('delegates to healthService and returns Left on failure', () async {
        when(
          () => mockHealthService.requestHealthPermissions(),
        ).thenAnswer((_) async => Left(HealthFailure('Permission denied')));

        final result = await repository.requestHealthPermissions();

        expect(result.isLeft(), isTrue);
        verify(() => mockHealthService.requestHealthPermissions()).called(1);
      });
    });

    group('requestScreenTimePermissions', () {
      test('delegates to screenTimeService and returns Right(true)', () async {
        when(
          () => mockScreenTimeService.requestScreenTimePermissions(),
        ).thenAnswer((_) async => const Right(true));

        final result = await repository.requestScreenTimePermissions();

        expect(result.isRight(), isTrue);
        verify(
          () => mockScreenTimeService.requestScreenTimePermissions(),
        ).called(1);
      });

      test(
        'delegates to screenTimeService and returns Left on failure',
        () async {
          when(
            () => mockScreenTimeService.requestScreenTimePermissions(),
          ).thenAnswer((_) async => Left(HealthFailure('Permission denied')));

          final result = await repository.requestScreenTimePermissions();

          expect(result.isLeft(), isTrue);
          verify(
            () => mockScreenTimeService.requestScreenTimePermissions(),
          ).called(1);
        },
      );
    });

    group('isHealthConnected', () {
      test('delegates to healthService', () async {
        when(
          () => mockHealthService.isHealthConnected(),
        ).thenAnswer((_) async => true);

        final result = await repository.isHealthConnected();

        expect(result, isTrue);
        verify(() => mockHealthService.isHealthConnected()).called(1);
      });
    });

    group('isScreenTimeConnected', () {
      test('delegates to screenTimeService', () async {
        when(
          () => mockScreenTimeService.isScreenTimeConnected(),
        ).thenAnswer((_) async => false);

        final result = await repository.isScreenTimeConnected();

        expect(result, isFalse);
        verify(() => mockScreenTimeService.isScreenTimeConnected()).called(1);
      });
    });
  });
}
