import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/health/data/services/health_connect_service.dart';
import 'package:emerge_app/features/health/data/services/screen_time_service.dart';
import 'package:emerge_app/features/health/data/repositories/health_repository_impl.dart';
import 'package:emerge_app/features/health/domain/health_repository.dart';

final healthServiceProvider = Provider<HealthConnectService>((ref) {
  return HealthConnectService();
});

final screenTimeServiceProvider = Provider<ScreenTimeService>((ref) {
  return ScreenTimeService();
});

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  final health = ref.watch(healthServiceProvider);
  final screenTime = ref.watch(screenTimeServiceProvider);
  return HealthRepositoryImpl(
    healthService: health,
    screenTimeService: screenTime,
  );
});

final healthConnectionProvider = Provider<HealthConnectionState>((ref) {
  return const HealthConnectionState(
    healthConnected: false,
    screenTimeConnected: false,
  );
});

class HealthConnectionState {
  final bool healthConnected;
  final bool screenTimeConnected;

  const HealthConnectionState({
    required this.healthConnected,
    required this.screenTimeConnected,
  });

  HealthConnectionState copyWith({
    bool? healthConnected,
    bool? screenTimeConnected,
  }) {
    return HealthConnectionState(
      healthConnected: healthConnected ?? this.healthConnected,
      screenTimeConnected: screenTimeConnected ?? this.screenTimeConnected,
    );
  }
}
