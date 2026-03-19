import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/data/repositories/tribe_repository.dart';
import 'package:flutter/foundation.dart';

/// Service to sync existing users to their archetype tribes.
///
/// This is needed for users who:
/// - Created accounts before tribe joining was implemented
/// - Had issues during onboarding that prevented tribe joining
/// - Need to be re-synced due to data migration
class TribeSyncService {
  final FirebaseFirestore _firestore;
  final TribeRepository _tribeRepository;

  TribeSyncService({
    FirebaseFirestore? firestore,
    TribeRepository? tribeRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _tribeRepository =
           tribeRepository ??
           FirestoreTribeRepository(FirebaseFirestore.instance);

  /// Syncs a single user to their archetype tribe
  Future<bool> syncUserToTribe(String userId) async {
    try {
      // Get user's profile to determine archetype
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        debugPrint('❌ User $userId does not exist');
        return false;
      }

      final userData = userDoc.data()!;
      final archetype = userData['archetype'] as String?;
      if (archetype == null || archetype == 'none') {
        debugPrint('⚠️ User $userId has no archetype set');
        return false;
      }

      // Get the tribe for this archetype
      final tribe = await _tribeRepository.getArchetypeClub(archetype);
      if (tribe == null) {
        debugPrint('❌ Tribe not found for archetype: $archetype');
        return false;
      }

      // Check if user is already a member
      final tribeDoc = await _firestore
          .collection('tribes')
          .doc(tribe.id)
          .get();
      if (!tribeDoc.exists) {
        debugPrint('❌ Tribe document ${tribe.id} does not exist');
        return false;
      }

      final members = tribeDoc.data()?['members'] as List<dynamic>? ?? [];
      if (members.contains(userId)) {
        debugPrint('ℹ️ User $userId is already a member of ${tribe.id}');
        return true; // Already synced
      }

      // Add user to tribe
      await _tribeRepository.joinClub(userId, tribe.id);
      debugPrint('✅ Synced user $userId to tribe ${tribe.id} ($archetype)');
      return true;
    } catch (e) {
      debugPrint('❌ Error syncing user $userId: $e');
      return false;
    }
  }

  /// Syncs all users to their archetype tribes
  ///
  /// Returns a map of results: {successCount, failedCount, skippedCount}
  Future<Map<String, int>> syncAllUsersToTribes() async {
    int successCount = 0;
    int failedCount = 0;
    int skippedCount = 0;

    try {
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      debugPrint('🔍 Found ${usersSnapshot.docs.length} users to sync');

      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final result = await syncUserToTribe(userId);

        if (result) {
          successCount++;
        } else {
          // Check if it was skipped (no archetype) or failed
          final userData = userDoc.data();
          final archetype = userData['archetype'] as String?;
          if (archetype == null || archetype == 'none') {
            skippedCount++;
          } else {
            failedCount++;
          }
        }
      }

      debugPrint(
        '✅ Tribe sync complete: $successCount synced, $skippedCount skipped (no archetype), $failedCount failed',
      );

      return {
        'success': successCount,
        'skipped': skippedCount,
        'failed': failedCount,
      };
    } catch (e) {
      debugPrint('❌ Error during bulk tribe sync: $e');
      return {
        'success': successCount,
        'skipped': skippedCount,
        'failed': failedCount,
      };
    }
  }

  /// Manually adds a user to a specific tribe (bypassing archetype check)
  Future<bool> addUserToTribe(String userId, String tribeId) async {
    try {
      await _tribeRepository.joinClub(userId, tribeId);
      debugPrint('✅ Manually added user $userId to tribe $tribeId');
      return true;
    } catch (e) {
      debugPrint('❌ Error manually adding user $userId to tribe $tribeId: $e');
      return false;
    }
  }

  /// Recalculates and updates the memberCount field for a tribe
  Future<bool> recalculateTribeMemberCount(String tribeId) async {
    try {
      final tribeDoc = await _firestore.collection('tribes').doc(tribeId).get();
      if (!tribeDoc.exists) {
        debugPrint('❌ Tribe $tribeId does not exist');
        return false;
      }

      final members = tribeDoc.data()?['members'] as List<dynamic>? ?? [];
      final actualCount = members.length;
      final storedCount = tribeDoc.data()?['memberCount'] as int? ?? 0;

      if (actualCount != storedCount) {
        await _firestore.collection('tribes').doc(tribeId).update({
          'memberCount': actualCount,
        });
        debugPrint(
          '✅ Updated memberCount for $tribeId: $storedCount → $actualCount',
        );
      } else {
        debugPrint('ℹ️ memberCount already correct for $tribeId: $actualCount');
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error recalculating member count for $tribeId: $e');
      return false;
    }
  }
}
