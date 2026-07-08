import 'package:emerge_app/core/error/failure.dart';
import 'package:fpdart/fpdart.dart';

abstract class HealthRepository {
  Future<Either<Failure, bool>> requestHealthPermissions();
  Future<Either<Failure, bool>> requestScreenTimePermissions();
  Future<int> getTodaySteps();
  Future<int> getTodayScreenTime();
  Future<bool> isHealthConnected();
  Future<bool> isScreenTimeConnected();
}
