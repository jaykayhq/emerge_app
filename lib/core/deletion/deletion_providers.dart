import 'package:emerge_app/core/deletion/deletion_audit.dart';
import 'package:emerge_app/core/deletion/deletion_service.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/sync/sync_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deletionServiceProvider = Provider<DeletionService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final engine = ref.watch(enhancedSyncEngineProvider);
  return DeletionService(db: db, syncEngine: engine, audit: DeletionAudit());
});
