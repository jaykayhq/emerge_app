import 'package:emerge_app/core/services/local_cache_service.dart';
import 'package:emerge_app/features/insights/data/repositories/insights_repository.dart';
import 'package:emerge_app/features/insights/domain/entities/insights_entities.dart';
import 'package:emerge_app/core/utils/app_logger.dart';

class CacheAwareInsightsRepository implements InsightsRepository {
  final InsightsRepository _remoteRepository;
  final LocalCacheService _cacheService;

  CacheAwareInsightsRepository(this._remoteRepository, this._cacheService);

  @override
  Future<Recap> getLatestRecap(String userId) async {
    try {
      final remote = await _remoteRepository.getLatestRecap(userId);
      if (remote.id != 'empty') {
        await _cacheService.saveLatestRecap(remote.toMap());
        return remote;
      }
    } catch (e) {
      AppLogger.w('Failed to fetch latest recap from remote: $e');
    }

    final localData = _cacheService.getLatestRecap();
    if (localData != null) {
      return Recap.fromMap(localData);
    }

    return const Recap(
      id: 'empty',
      period: 'No Data',
      dateRange: '',
      habitsCompleted: 0,
      perfectDays: 0,
      xpGained: 0,
      focusTime: '0h',
      summary: 'No recap available yet.',
      consistencyChange: 0.0,
    );
  }

  @override
  Future<List<Reflection>> getReflections(String userId) async {
    try {
      final remote = await _remoteRepository.getReflections(userId);
      if (remote.isNotEmpty) {
        await _cacheService.saveReflections(remote.map((e) => e.toMap()).toList());
        return remote;
      }
    } catch (e) {
      AppLogger.w('Failed to fetch reflections from remote: $e');
    }

    final localData = _cacheService.getReflections();
    if (localData != null) {
      return localData.map((e) => Reflection.fromMap(e)).toList();
    }

    return [];
  }

  @override
  Future<void> saveReflection(String userId, Reflection reflection) async {
    // 1. Queue for sync
    await _cacheService.enqueueMutation(
      collectionPath: 'user_stats/$userId/reflections',
      documentId: reflection.id,
      data: reflection.toMap(useServerTimestamp: true),
      operation: 'set',
    );

    // 2. Optimistic local update (add to the cached list)
    final existingReflections = _cacheService.getReflections() ?? [];
    final updatedList = [reflection.toMap(), ...existingReflections];
    await _cacheService.saveReflections(updatedList);

    // 3. Attempt remote update
    _remoteRepository.saveReflection(userId, reflection).catchError((e) {
      AppLogger.w('Remote saveReflection failed: $e');
    });
  }
}
