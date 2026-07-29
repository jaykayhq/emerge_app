import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/social/data/repositories/tribe_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/sync/sync_providers.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_tab_content.dart';

class TribeMembershipService {
  // ignore: unused_field — injected for future use by consumers
  final TribeRepository _repository;
  final TribeMembershipDao _dao;
  final EnhancedSyncEngine _syncEngine;
  final Ref? _ref;

  TribeMembershipService(
    this._repository,
    this._dao,
    this._syncEngine, [
    this._ref,
  ]);

  Future<Either<Failure, void>> joinTribe({
    required String userId,
    required String tribeId,
    required String type,
  }) async {
    try {
      // 1. Check not already in a tribe
      final existing = await _dao.watchActiveMembership(userId).first;
      if (existing != null) {
        return Left(UnknownFailure('Already in tribe ${existing.tribeId}'));
      }

      // 2. Drift: deactivate all (safety) + upsert active
      await _dao.deactivateAll(userId);
      await _dao.upsertMembership(UserTribeTableCompanion(
        userId: Value(userId),
        tribeId: Value(tribeId),
        membershipType: Value(type),
        joinedAt: Value(DateTime.now().toIso8601String()),
        isActive: const Value(true),
      ));

      // 3. Sync: enqueue Firestore writes
      await _syncEngine.enqueueSet(
        collectionPath: 'users/$userId/tribes',
        documentId: tribeId,
        data: {
          'tribeId': tribeId,
          'joinedAt': {'__type__': 'serverTimestamp'},
          'membershipType': type,
        },
      );
      await _syncEngine.enqueueSet(
        collectionPath: 'tribes/$tribeId/contributors',
        documentId: userId,
        data: {
          'userId': userId,
          'joinedAt': {'__type__': 'serverTimestamp'},
          'contributionCount': 0,
          'totalHabitsCompleted': 0,
          'totalXpContributed': 0,
        },
      );
      await _syncEngine.enqueueSet(
        collectionPath: 'tribes',
        documentId: tribeId,
        data: {
          'members': {
            '__type__': 'arrayUnion',
            'values': [userId],
          },
          'memberCount': {'__type__': 'increment', 'value': 1},
          'lastStatsSync': {'__type__': 'serverTimestamp'},
        },
      );

      // 4. Invalidate providers (if Ref available)
      _ref?.invalidate(hasClubProvider);
      _ref?.invalidate(discoveryClubsProvider);

      return const Right(null);
    } catch (e, s) {
      AppLogger.e('joinTribe failed', e, s);
      return Left(UnknownFailure('Failed to join tribe: $e'));
    }
  }

  Future<Either<Failure, void>> leaveTribe(String userId) async {
    try {
      final active = await _dao.watchActiveMembership(userId).first;
      if (active == null) {
        return const Left(UnknownFailure('Not in a tribe'));
      }

      final tribeId = active.tribeId;
      await _dao.deactivateAll(userId);

      await _syncEngine.enqueueMutation(
        collectionPath: 'users/$userId/tribes',
        documentId: tribeId,
        operation: 'delete',
      );
      await _syncEngine.enqueueSet(
        collectionPath: 'tribes',
        documentId: tribeId,
        data: {
          'members': {
            '__type__': 'arrayRemove',
            'values': [userId],
          },
          'memberCount': {'__type__': 'increment', 'value': -1},
        },
      );

      _ref?.invalidate(hasClubProvider);
      _ref?.invalidate(discoveryClubsProvider);

      return const Right(null);
    } catch (e, s) {
      AppLogger.e('leaveTribe failed', e, s);
      return Left(UnknownFailure('Failed to leave tribe: $e'));
    }
  }

  Future<bool> isInTribe(String userId) async {
    final membership = await _dao.watchActiveMembership(userId).first;
    return membership != null;
  }

  Stream<UserTribeTableData?> watchActiveMembership(String userId) {
    return _dao.watchActiveMembership(userId);
  }
}

final tribeMembershipServiceProvider = Provider<TribeMembershipService>((ref) {
  final repository = ref.watch(tribeRepositoryProvider);
  final dao = ref.watch(tribeMembershipDaoProvider);
  final syncEngine = ref.watch(enhancedSyncEngineProvider);
  return TribeMembershipService(repository, dao, syncEngine, ref);
});
