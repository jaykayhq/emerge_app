import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/core/error/failure.dart';
import '../../domain/health_repository.dart';

class ScreenTimeService implements HealthRepository {
  static const _channel = MethodChannel('com.emerge.emerge_app/screen_time');

  @override
  Future<Either<Failure, bool>> requestHealthPermissions() async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> requestScreenTimePermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'requestUsageStatsPermission',
      );
      return Right(result ?? false);
    } catch (e) {
      return Left(
        HealthFailure('Failed to request screen time permission: $e'),
      );
    }
  }

  @override
  Future<int> getTodaySteps() async => 0;

  @override
  Future<int> getTodayScreenTime() async {
    try {
      final result = await _channel.invokeMethod<int>('getTodayScreenTime');
      return result ?? 0;
    } on MissingPluginException {
      return 0;
    }
  }

  @override
  Future<bool> isHealthConnected() async => false;

  @override
  Future<bool> isScreenTimeConnected() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isUsageStatsPermissionGranted',
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }
}
