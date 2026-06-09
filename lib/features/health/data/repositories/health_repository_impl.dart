import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/health/domain/health_repository.dart';
import 'package:emerge_app/features/health/data/services/health_connect_service.dart';
import 'package:emerge_app/features/health/data/services/screen_time_service.dart';

class HealthRepositoryImpl extends HealthRepository {
  final HealthConnectService healthService;
  final ScreenTimeService screenTimeService;

  HealthRepositoryImpl({
    required this.healthService,
    required this.screenTimeService,
  });

  @override
  Future<Either<Failure, bool>> requestHealthPermissions() =>
      healthService.requestHealthPermissions();

  @override
  Future<Either<Failure, bool>> requestScreenTimePermissions() =>
      screenTimeService.requestScreenTimePermissions();

  @override
  Future<int> getTodaySteps() => healthService.getTodaySteps();

  @override
  Future<int> getTodayScreenTime() => screenTimeService.getTodayScreenTime();

  @override
  Future<bool> isHealthConnected() => healthService.isHealthConnected();

  @override
  Future<bool> isScreenTimeConnected() => screenTimeService.isScreenTimeConnected();
}
