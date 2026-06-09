import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/health/domain/health_repository.dart';

class MockHealthRepository extends Mock implements HealthRepository {}

void main() {
  late MockHealthRepository repository;

  setUp(() {
    repository = MockHealthRepository();
  });

  group('HealthRepository', () {
    test('requestHealthPermissions returns Either', () async {
      when(
        () => repository.requestHealthPermissions(),
      ).thenAnswer((_) async => const Right(true));

      final result = await repository.requestHealthPermissions();
      expect(result.isRight(), isTrue);
      result.fold((_) => null, (value) => expect(value, isTrue));
    });

    test('requestScreenTimePermissions returns Either', () async {
      when(
        () => repository.requestScreenTimePermissions(),
      ).thenAnswer((_) async => const Right(true));

      final result = await repository.requestScreenTimePermissions();
      expect(result.isRight(), isTrue);
    });

    test('requestHealthPermissions can return failure', () async {
      when(
        () => repository.requestHealthPermissions(),
      ).thenAnswer((_) async => Left(HealthFailure('Permission denied')));

      final result = await repository.requestHealthPermissions();
      expect(result.isLeft(), isTrue);
    });

    test('getTodaySteps returns 5000', () async {
      when(() => repository.getTodaySteps()).thenAnswer((_) async => 5000);

      final result = await repository.getTodaySteps();

      expect(result, 5000);
    });

    test('getTodayScreenTime returns 120', () async {
      when(() => repository.getTodayScreenTime()).thenAnswer((_) async => 120);

      final result = await repository.getTodayScreenTime();

      expect(result, 120);
    });

    test('isHealthConnected returns true', () async {
      when(() => repository.isHealthConnected()).thenAnswer((_) async => true);

      final result = await repository.isHealthConnected();

      expect(result, true);
    });

    test('isScreenTimeConnected returns false', () async {
      when(
        () => repository.isScreenTimeConnected(),
      ).thenAnswer((_) async => false);

      final result = await repository.isScreenTimeConnected();

      expect(result, false);
    });
  });
}
