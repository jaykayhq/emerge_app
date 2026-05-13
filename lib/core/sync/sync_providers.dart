import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';

final enhancedSyncEngineProvider = Provider<EnhancedSyncEngine>((ref) {
  final mutationQueue = ref.watch(mutationQueueDaoProvider);
  return EnhancedSyncEngine(mutationQueue, FirebaseFirestore.instance);
});

final pendingSyncCountProvider = StreamProvider<int>((ref) {
  final dao = ref.watch(mutationQueueDaoProvider);
  return dao.watchPending().map((list) => list.length);
});
