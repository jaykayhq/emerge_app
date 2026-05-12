import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/domain/entities/weekly_recap.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:emerge_app/core/utils/app_logger.dart';

part 'recap_hub_provider.g.dart';

@riverpod
Future<List<UserWeeklyRecap>> historicalRecaps(Ref ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return [];
  final userId = user.id;

  try {
    final repository = ref.read(userStatsRepositoryProvider);
    final maps = await repository.getRecaps(userId, limit: 20);
    
    final recaps = <UserWeeklyRecap>[];
    for (final m in maps) {
      try {
        recaps.add(UserWeeklyRecap.fromMap(m));
      } catch (e) {
        AppLogger.w('Error parsing recap: $e. Data: $m');
      }
    }
    return recaps;
  } catch (e) {
    AppLogger.e('Error fetching historical recaps', e);
    return [];
  }
}
