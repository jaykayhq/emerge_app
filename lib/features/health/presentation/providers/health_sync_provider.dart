import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/health/data/services/health_auto_complete_service.dart';
import 'package:emerge_app/features/health/data/repositories/health_repository_impl.dart';
import 'package:emerge_app/features/health/data/services/health_connect_service.dart';
import 'package:emerge_app/features/health/data/services/screen_time_service.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';

final healthSyncProvider = NotifierProvider<HealthSyncNotifier, bool>(
  HealthSyncNotifier.new,
);

class HealthSyncNotifier extends Notifier<bool> {
  Timer? _timer;

  @override
  bool build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return false;
  }

  void startSync() {
    state = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      _syncHealthData();
    });
  }

  void stopSync() {
    state = false;
    _timer?.cancel();
  }

  Future<void> _syncHealthData() async {
    try {
      final healthService = HealthConnectService();
      final screenTimeService = ScreenTimeService();
      final repository = HealthRepositoryImpl(
        healthService: healthService,
        screenTimeService: screenTimeService,
      );
      final autoComplete = HealthAutoCompleteService(
        healthRepository: repository,
      );

      final habits = await ref.read(habitsProvider.future);
      final ids = await autoComplete.getHabitIdsToAutoComplete(habits);

      for (final id in ids) {
        await ref.read(completeHabitProvider(id).future);
      }
    } catch (_) {
      // Health sync is best-effort — silently handle errors
    }
  }
}
