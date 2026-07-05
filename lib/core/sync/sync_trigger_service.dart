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

  SyncTriggerService(this._syncEngine, this._onListen);

  void start() {
    _onListen(onConnectivityChanged);
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
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
