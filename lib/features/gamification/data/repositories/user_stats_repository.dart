import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift_repositories/repositories_barrel.dart';
import 'package:emerge_app/core/firestore_repositories/firestore_user_stats_repository.dart';
import 'package:emerge_app/core/sync/sync_providers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userStatsRepositoryProvider = Provider<DriftUserStatsRepository>((ref) {
  if (kIsWeb) {
    return FirestoreUserStatsRepository(firestore: FirebaseFirestore.instance);
  }
  final db = ref.watch(appDatabaseProvider)!;
  final syncEngine = ref.watch(enhancedSyncEngineProvider)!;
  return DriftUserStatsRepository(db, syncEngine);
});
