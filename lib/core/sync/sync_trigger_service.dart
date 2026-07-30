import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emerge_app/core/sync/sync_engine_barrel.dart';

typedef ConnectivityListener =
    Future<void> Function(List<ConnectivityResult> results);

class SyncTriggerService {
  final EnhancedSyncEngine _syncEngine;
  final void Function(ConnectivityListener) _onListen;
  bool _isSyncInProgress = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _periodicTimer;

  SyncTriggerService(this._syncEngine, this._onListen) {
    startPeriodicSync();
    // Revive dead letters on initialization (app startup)
    _syncEngine.reviveDeadLetters();
  }

  void start() {
    _onListen(onConnectivityChanged);
  }

  void startPeriodicSync() {
    _periodicTimer ??= Timer.periodic(const Duration(seconds: 30), (_) {
      _triggerSyncIfPending();
    });
  }

  void _triggerSyncIfPending() {
    if (!_isSyncInProgress) {
      triggerSync();
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    stop();
  }

  Future<void> onConnectivityChanged(List<ConnectivityResult> results) async {
    final isConnected = results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn ||
          result == ConnectivityResult.other,
    );

    if (isConnected && !_isSyncInProgress) {
      // Revive dead-lettered mutations on connectivity restore
      await _syncEngine.reviveDeadLetters();
      await triggerSync();
    }
  }

  Future<void> triggerSync() async {
    if (_isSyncInProgress) return;
    _isSyncInProgress = true;
    try {
      await _syncEngine.processMutationQueue();
    } catch (e) {
      // Error is logged in processMutationQueue
    } finally {
      _isSyncInProgress = false;
    }
  }
}
