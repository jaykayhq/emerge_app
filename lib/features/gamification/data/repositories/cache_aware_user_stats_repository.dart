import 'dart:async';
import 'package:emerge_app/core/services/local_cache_service.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:rxdart/rxdart.dart';

class CacheAwareUserStatsRepository implements UserStatsRepository {
  final UserStatsRepository _remoteRepository;
  final LocalCacheService _cacheService;

  CacheAwareUserStatsRepository(this._remoteRepository, this._cacheService);

  @override
  Future<void> saveUserStats(UserProfile profile) async {
    // 1. Optimistic local update
    await _cacheService.saveUserProfile(profile.toMap());

    // 2. Queue for remote sync
    await _cacheService.enqueueMutation(
      collectionPath: 'user_stats',
      documentId: profile.uid,
      data: profile.toMap(),
      operation: 'set',
    );

    // 3. Attempt remote update (fire and forget, errors are handled by queue)
    _remoteRepository.saveUserStats(profile).catchError((e) {
      AppLogger.w('Remote saveUserStats failed, will retry later: $e');
    });
  }

  @override
  Future<void> updateWorldHealth(String uid, int score) async {
    // This is a partial update, but we can treat it as a full profile update locally
    // or just queue the partial update. For simplicity, let's queue the partial update.
    
    final currentLocal = await getUserStats(uid);
    final entropy = (1.0 - (score / 100.0)).clamp(0.0, 1.0);
    
    final updatedLocal = currentLocal.copyWith(
      avatarStats: currentLocal.avatarStats.copyWith(momentumScore: score),
      worldState: currentLocal.worldState.copyWith(entropy: entropy),
    );
    
    await _cacheService.saveUserProfile(updatedLocal.toMap());

    await _cacheService.enqueueMutation(
      collectionPath: 'user_stats',
      documentId: uid,
      data: {
        'worldHealthScore': score,
        'worldState': {'entropy': entropy},
        'avatarStats': {'momentumScore': score},
      },
      operation: 'update',
    );

    _remoteRepository.updateWorldHealth(uid, score).catchError((e) {
      AppLogger.w('Remote updateWorldHealth failed: $e');
    });
  }

  @override
  Future<void> syncUserIdentity(UserProfile profile) async {
    await _cacheService.saveUserProfile(profile.toMap());

    await _cacheService.enqueueMutation(
      collectionPath: 'user_stats', // We sync to both, but sync engine can handle multiple if needed
      documentId: profile.uid,
      data: profile.toMap(),
      operation: 'set',
    );

    _remoteRepository.syncUserIdentity(profile).catchError((e) {
      AppLogger.w('Remote syncUserIdentity failed: $e');
    });
  }

  @override
  Stream<UserProfile> watchUserStats(String uid) {
    // Merge local cache and remote stream
    final localData = _cacheService.getUserProfile();
    final localProfile = localData != null 
        ? UserProfile.fromMap(localData) 
        : UserProfile(uid: uid);

    return Rx.combineLatest2<UserProfile, UserProfile, UserProfile>(
      Stream.value(localProfile).concatWith([const Stream.empty()]),
      _remoteRepository.watchUserStats(uid),
      (local, remote) {
        // If remote has data, it's the source of truth, 
        // but we might want to overlay pending local changes if we had a way to track them.
        // For now, remote wins if connected.
        if (remote.uid.isNotEmpty) {
           _cacheService.saveUserProfile(remote.toMap());
           return remote;
        }
        return local;
      },
    ).distinct();
  }

  @override
  Future<UserProfile> getUserStats(String uid) async {
    final localData = _cacheService.getUserProfile();
    if (localData != null) {
      return UserProfile.fromMap(localData);
    }
    
    final remote = await _remoteRepository.getUserStats(uid);
    if (remote.uid.isNotEmpty) {
      await _cacheService.saveUserProfile(remote.toMap());
    }
    return remote;
  }

  @override
  Future<void> logActivity({
    required String userId,
    required String type,
    String? habitId,
    String? sourceId,
    required DateTime date,
    String? difficulty,
    String? attribute,
    int? streakDay,
  }) async {
    // Queue the mutation locally with only non-null fields
    final data = <String, dynamic>{
      'userId': userId,
      'date': date.toIso8601String(),
      'type': type,
    };
    if (habitId != null) data['habitId'] = habitId;
    if (sourceId != null) data['sourceId'] = sourceId;
    if (difficulty != null) data['difficulty'] = difficulty;
    if (attribute != null) data['attribute'] = attribute;
    if (streakDay != null) data['streakDay'] = streakDay;

    await _cacheService.enqueueMutation(
      collectionPath: 'user_activity',
      documentId: 'auto_${DateTime.now().millisecondsSinceEpoch}',
      data: data,
      operation: 'add',
    );

    _remoteRepository.logActivity(
      userId: userId,
      type: type,
      habitId: habitId,
      sourceId: sourceId,
      date: date,
      difficulty: difficulty,
      attribute: attribute,
      streakDay: streakDay,
    ).catchError((e) {
      AppLogger.w('Remote logActivity failed: $e');
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getWeeklyActivity(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    return _remoteRepository.getWeeklyActivity(userId, start, end);
  }

  @override
  Future<Map<String, dynamic>?> getLatestRecap(String userId) async {
    final local = _cacheService.getLatestRecap();
    if (local != null) return local;

    final remote = await _remoteRepository.getLatestRecap(userId);
    if (remote != null) {
      await _cacheService.saveLatestRecap(remote);
    }
    return remote;
  }

  @override
  Future<Map<String, dynamic>?> getRecap(String userId, String recapId) {
    return _remoteRepository.getRecap(userId, recapId);
  }

  @override
  Future<List<Map<String, dynamic>>> getRecaps(String userId, {int limit = 10}) {
    return _remoteRepository.getRecaps(userId, limit: limit);
  }

  @override
  Future<void> saveRecap(String userId, Map<String, dynamic> recapData) async {
    await _cacheService.saveLatestRecap(recapData);
    await _remoteRepository.saveRecap(userId, recapData);
  }
}
