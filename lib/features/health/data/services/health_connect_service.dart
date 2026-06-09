import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/health/domain/health_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:health/health.dart';

class HealthConnectService implements HealthRepository {
  final Health _health;

  HealthConnectService({Health? health}) : _health = health ?? Health();

  @override
  Future<Either<Failure, bool>> requestHealthPermissions() async {
    try {
      final granted = await _health.requestAuthorization([
        HealthDataType.STEPS,
      ]);
      return Right(granted);
    } catch (e) {
      return Left(HealthFailure('Failed to request health permissions: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> requestScreenTimePermissions() async {
    return const Right(true);
  }

  @override
  Future<int> getTodaySteps() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: startOfDay,
        endTime: now,
        types: [HealthDataType.STEPS],
      );
      if (data.isEmpty) return 0;
      final lastPoint = data.last;
      if (lastPoint.value is NumericHealthValue) {
        return (lastPoint.value as NumericHealthValue).numericValue.toInt();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<int> getTodayScreenTime() async {
    return 0;
  }

  @override
  Future<bool> isHealthConnected() async {
    try {
      final hasPerm = await _health.hasPermissions([HealthDataType.STEPS]);
      return hasPerm ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isScreenTimeConnected() async {
    return false;
  }
}
