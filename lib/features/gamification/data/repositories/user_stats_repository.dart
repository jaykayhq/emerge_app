import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/drift_repositories/drift_user_stats_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userStatsRepositoryProvider = Provider<DriftUserStatsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftUserStatsRepository(db);
});
