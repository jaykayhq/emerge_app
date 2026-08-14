import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/social/data/repositories/tribe_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/sync/sync_providers.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

class TribeMembershipService {
  // ignore: unused_field — injected for future use by consumers
  final TribeRepository _repository;
  final TribeMembershipDao _dao;
  final TribeStatsDao _tribeStatsDao;
  // ignore: unused_field — kept for constructor compatibility
  final EnhancedSyncEngine _syncEngine;
  final FirebaseFirestore _firestore;
  final Ref? _ref;

  TribeMembershipService(
    this._repository,
    this._dao,
    this._tribeStatsDao,
    this._syncEngine,
    this._firestore, [
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

      // SP-G D1/B2: the Drift-only guard above misses users whose Firestore
      // membership survived a reinstall. Check Firestore first.
      final existingDocs = await _firestore
          .collection('users').doc(userId).collection('tribes')
          .limit(1)
          .get();
      if (existingDocs.docs.isNotEmpty) {
        return Left(UnknownFailure(
            'Already in tribe ${existingDocs.docs.first.id}'));
      }

      // 2. Firestore transaction FIRST (authoritative source of truth).
      //    If this fails, Drift is never written — no ghost membership.
      //    NOTE: the tribe doc (memberCount/members) is NOT touched here —
      //    it is server-owned (Cloud Function trigger on the membership
      //    doc). Client tribe-doc writes dead-letter against the rules.
      await _firestore.runTransaction((transaction) async {
        // All reads before any writes (Firestore transaction constraint).
        final tribeRef = _firestore.collection('tribes').doc(tribeId);
        final tribeSnap = await transaction.get(tribeRef);
        if (!tribeSnap.exists) throw Exception('Tribe not found');

        // SP-G D3/B11: rejoining must never wipe previously contributed
        // totals — read the contributor doc now, branch on existence below.
        final contributorRef = _firestore
            .collection('tribes').doc(tribeId).collection('contributors').doc(userId);
        final contributorSnap = await transaction.get(contributorRef);

        // Write the user's membership subcollection atomically
        transaction.set(
          _firestore.collection('users').doc(userId).collection('tribes').doc(tribeId),
          {
            'tribeId': tribeId,
            'joinedAt': FieldValue.serverTimestamp(),
            'membershipType': type,
            'isActive': true,
          },
        );

        // Write contributor doc: preserve existing totals on rejoin, zeroed
        // create for a first join. The existing doc's fields are spread back
        // (read in this same transaction, so the write is a safe overwrite) —
        // fake_cloud_firestore ignores SetOptions.merge in transactions.
        if (contributorSnap.exists) {
          transaction.set(contributorRef, {
            ...(contributorSnap.data() ?? {}),
            'userId': userId,
            'joinedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(contributorRef, {
            'userId': userId,
            'joinedAt': FieldValue.serverTimestamp(),
            'contributionCount': 0,
            'totalHabitsCompleted': 0,
            'totalXpContributed': 0,
          });
        }
      });

      // 3. Drift write AFTER Firestore succeeds (local cache)
      await _dao.deactivateAll(userId);
      await _dao.upsertMembership(UserTribeTableCompanion(
        userId: Value(userId),
        tribeId: Value(tribeId),
        membershipType: Value(type),
        joinedAt: Value(DateTime.now().toIso8601String()),
        isActive: const Value(true),
      ));
      // Reflect the +1 locally until the server trigger's count arrives via
      // the sync/stream path.
      await _tribeStatsDao.incrementMemberCount(tribeId, delta: 1);

      // 4. Invalidate providers (if Ref available)
      _ref?.invalidate(hasClubProvider);
      _ref?.invalidate(discoveryClubsProvider);

      return const Right(null);
    } catch (e, s) {
      // Firestore failed — Drift was never written, so no rollback needed.
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

      // 1. Firestore transaction FIRST (authoritative).
      //    If this fails, Drift is never modified — no drift.
      //    Tribe doc memberCount/members are server-owned — only the
      //    membership doc is removed here (the trigger decrements).
      await _firestore.runTransaction((transaction) async {
        // Remove the user's membership subcollection doc
        transaction.delete(
          _firestore.collection('users').doc(userId).collection('tribes').doc(tribeId),
        );
      });

      // 2. Drift AFTER Firestore success (local cache)
      await _dao.deactivateAll(userId);
      await _tribeStatsDao.incrementMemberCount(tribeId, delta: -1);

      _ref?.invalidate(hasClubProvider);
      _ref?.invalidate(discoveryClubsProvider);

      return const Right(null);
    } catch (e, s) {
      // Firestore failed — Drift was never modified, so no rollback needed.
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
  final tribeStatsDao = ref.watch(tribeStatsDaoProvider);
  final syncEngine = ref.watch(enhancedSyncEngineProvider);
  return TribeMembershipService(repository, dao, tribeStatsDao, syncEngine, FirebaseFirestore.instance, ref);
});
