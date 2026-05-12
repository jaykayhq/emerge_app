import 'dart:async';
import 'package:emerge_app/core/services/local_cache_service.dart';
import 'package:emerge_app/features/social/data/repositories/tribe_repository.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:rxdart/rxdart.dart';

class CacheAwareTribeRepository implements TribeRepository {
  final TribeRepository _remoteRepository;
  final LocalCacheService _cacheService;

  CacheAwareTribeRepository(this._remoteRepository, this._cacheService);

  @override
  Future<Tribe?> getArchetypeClub(String archetypeId) async {
    try {
      final remote = await _remoteRepository.getArchetypeClub(archetypeId);
      if (remote != null) {
        // Update local cache if needed
        return remote;
      }
    } catch (e) {
      AppLogger.w('Failed to fetch archetype club from remote: $e');
    }

    final tribes = await getArchetypeClubs();
    return tribes.cast<Tribe?>().firstWhere(
      (t) => t?.archetypeId == archetypeId,
      orElse: () => null,
    );
  }

  @override
  Future<List<Tribe>> getArchetypeClubs() async {
    try {
      final remote = await _remoteRepository.getArchetypeClubs();
      if (remote.isNotEmpty) {
        await _cacheService.saveTribes(remote.map((e) => e.toMap()).toList());
        return remote;
      }
    } catch (e) {
      AppLogger.w('Failed to fetch archetype clubs from remote: $e');
    }

    final localData = _cacheService.getTribes();
    if (localData != null) {
      return localData.map((e) => Tribe.fromMap(e)).toList();
    }
    return [];
  }

  @override
  Stream<List<Tribe>> watchArchetypeClubs() {
    final localData = _cacheService.getTribes();
    final localTribes = localData != null 
        ? localData.map((e) => Tribe.fromMap(e)).toList() 
        : <Tribe>[];

    return Rx.combineLatest2<List<Tribe>, List<Tribe>, List<Tribe>>(
      Stream.value(localTribes).concatWith([const Stream.empty()]),
      _remoteRepository.watchArchetypeClubs(),
      (local, remote) {
        if (remote.isNotEmpty) {
          _cacheService.saveTribes(remote.map((e) => e.toMap()).toList());
          return remote;
        }
        return local;
      },
    ).distinct();
  }

  @override
  Future<List<Map<String, dynamic>>> getClubContributors(String tribeId, {int limit = 10}) {
    return _remoteRepository.getClubContributors(tribeId, limit: limit);
  }

  @override
  Future<List<Map<String, dynamic>>> getClubActivity(String tribeId, {int limit = 20}) {
    return _remoteRepository.getClubActivity(tribeId, limit: limit);
  }

  @override
  Future<void> joinClub(String userId, String tribeId) async {
    // 1. Queue for sync using serializable sentinel markers (no FieldValue in Hive)
    //    SyncEngine._expandSentinelMarkers() converts these back to real FieldValues on flush.
    await _cacheService.enqueueMutationWithSentinels(
      collectionPath: 'users/$userId/tribes',
      documentId: tribeId,
      data: {'joinedAt': DateTime.now().toIso8601String()},
      // Note: root tribe doc writes are now blocked by Firestore rules.
      // Tribe membership is tracked only in the user's sub-collection.
    );

    // 2. Attempt remote update
    _remoteRepository.joinClub(userId, tribeId).catchError((e) {
      AppLogger.w('Remote joinClub failed: $e');
    });
  }

  @override
  Future<void> leaveClub(String userId, String tribeId) async {
    // Queue user-side sub-collection delete (root tribe doc is server-managed)
    await _cacheService.enqueueMutation(
      collectionPath: 'users/$userId/tribes',
      documentId: tribeId,
      data: {},
      operation: 'delete',
    );

    _remoteRepository.leaveClub(userId, tribeId).catchError((e) {
      AppLogger.w('Remote leaveClub failed: $e');
    });
  }

  @override
  Future<List<Tribe>> getUserTribes(String userId) {
    return _remoteRepository.getUserTribes(userId);
  }

  @override
  Future<void> seedTribesIfEmpty() {
    return _remoteRepository.seedTribesIfEmpty();
  }
}
