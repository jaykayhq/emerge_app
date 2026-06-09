import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    // Will be wired to auto-complete in Task 10
  }
}
