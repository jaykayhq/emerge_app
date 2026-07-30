import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/deletion/sync_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/services/connectivity_service.dart';
import 'package:emerge_app/core/sync/sync_engine_barrel.dart';
import 'package:emerge_app/core/sync/sync_trigger_service.dart';
import 'package:emerge_app/core/sync/incoming_sync_service.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';

final enhancedSyncEngineProvider = Provider<EnhancedSyncEngine>((ref) {
  final mutationQueue = ref.watch(mutationQueueDaoProvider);
  return EnhancedSyncEngine(mutationQueue, FirebaseFirestore.instance);
});

final syncMetricsProvider = Provider<SyncMetrics>((ref) {
  final engine = ref.watch(enhancedSyncEngineProvider);
  return engine.metrics;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final engine = ref.watch(enhancedSyncEngineProvider);
  return engine.status;
});

final pendingSyncCountProvider = StreamProvider<int>((ref) {
  final dao = ref.watch(mutationQueueDaoProvider);
  return Stream.periodic(
    const Duration(seconds: 2),
    (_) => dao.getAllPending().then((l) => l.length),
  ).asyncMap((f) => f);
});

final syncTriggerServiceProvider = Provider<SyncTriggerService>((ref) {
  final syncEngine = ref.watch(enhancedSyncEngineProvider);
  final service = SyncTriggerService(syncEngine, (
    ConnectivityListener listener,
  ) {
    ref.listen(connectivityStreamProvider, (_, next) {
      next.whenData((results) => listener(results));
    });
  });
  ref.onDispose(() => service.stop());
  service.start();
  return service;
});

final incomingSyncServiceProvider = Provider<IncomingSyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return IncomingSyncService(db, FirebaseFirestore.instance);
});

/// Listens to auth state changes and pulls remote data into Drift on login.
final incomingSyncListenerProvider = Provider<void>((ref) {
  ref.listen(authStateChangesProvider, (previous, next) {
    next.whenData((user) {
      if (user.isNotEmpty) {
        ref.read(incomingSyncServiceProvider).pullRemoteData(user.id);
      }
    });
  });
});
