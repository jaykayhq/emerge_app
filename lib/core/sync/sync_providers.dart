import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/services/connectivity_service.dart';
import 'package:emerge_app/core/sync/sync_engine_barrel.dart';
import 'package:emerge_app/core/sync/sync_trigger_service.dart';

final enhancedSyncEngineProvider = Provider<EnhancedSyncEngine?>((ref) {
  if (kIsWeb) return null;
  final mutationQueue = ref.watch(mutationQueueDaoProvider)!;
  return EnhancedSyncEngine(mutationQueue, FirebaseFirestore.instance);
});

final pendingSyncCountProvider = StreamProvider<int>((ref) {
  if (kIsWeb) {
    return Stream.periodic(const Duration(seconds: 2), (_) => 0);
  }
  final dao = ref.watch(mutationQueueDaoProvider)!;
  return Stream.periodic(
    const Duration(seconds: 2),
    (_) => dao.getAllPending().then((l) => l.length),
  ).asyncMap((f) => f);
});

final syncTriggerServiceProvider = Provider<SyncTriggerService?>((ref) {
  if (kIsWeb) return null;
  final syncEngine = ref.watch(enhancedSyncEngineProvider)!;
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
