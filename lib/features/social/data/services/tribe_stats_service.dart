import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for calculating real-time tribe statistics from actual user data.
/// 
/// This service aggregates data from tribe members to provide accurate:
/// - Member counts (from members array)
/// - Total XP (sum of all members' XP)
/// - Total habits completed (from tribe document counters)
/// - Total challenges completed (from tribe document counters)
class TribeStatsService {
  final FirebaseFirestore _firestore;

  TribeStatsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Calculates the real member count from the tribe's members array
  Future<int> getMemberCount(String tribeId) async {
    try {
      final tribeDoc = await _firestore.collection('tribes').doc(tribeId).get();
      if (!tribeDoc.exists) return 0;

      final members = tribeDoc.data()?['members'] as List<dynamic>?;
      return members?.length ?? 0;
    } catch (e) {
      debugPrint('Error getting member count for tribe $tribeId: $e');
      return 0;
    }
  }

  /// Calculates the total XP from all tribe members
  /// 
  /// This queries the user_stats collection for all tribe members
  /// and sums their totalXp values.
  Future<int> getTotalXp(String tribeId) async {
    try {
      final tribeDoc = await _firestore.collection('tribes').doc(tribeId).get();
      if (!tribeDoc.exists) return 0;

      final members = tribeDoc.data()?['members'] as List<dynamic>?;
      if (members == null || members.isEmpty) return 0;

      // Query user_stats for all tribe members
      final memberIds = members.cast<String>();
      
      // Firestore 'in' query limit is 30, so we batch if needed
      int totalXp = 0;
      const batchSize = 30;
      
      for (var i = 0; i < memberIds.length; i += batchSize) {
        final batch = memberIds.skip(i).take(batchSize).toList();
        final userStatsSnapshot = await _firestore
            .collection('user_stats')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in userStatsSnapshot.docs) {
          final data = doc.data();
          // Sum XP from avatarStats - only sum attribute XP fields
          final avatarStats = data['avatarStats'] as Map<String, dynamic>?;
          if (avatarStats != null) {
            // Only sum the 6 attribute XP fields (exclude level, streak, attributeXp map)
            totalXp += avatarStats['strengthXp'] as int? ?? 0;
            totalXp += avatarStats['intellectXp'] as int? ?? 0;
            totalXp += avatarStats['vitalityXp'] as int? ?? 0;
            totalXp += avatarStats['creativityXp'] as int? ?? 0;
            totalXp += avatarStats['focusXp'] as int? ?? 0;
            totalXp += avatarStats['spiritXp'] as int? ?? 0;

            // Also sum any custom attribute XP from the attributeXp map
            final customAttributeXp = avatarStats['attributeXp'] as Map<String, dynamic>?;
            if (customAttributeXp != null) {
              for (final value in customAttributeXp.values) {
                if (value is int) totalXp += value;
              }
            }
          }

          // Also check for direct totalXp field (fallback)
          final directTotalXp = data['totalXp'] as int?;
          if (directTotalXp != null) {
            totalXp += directTotalXp;
          }
        }
      }

      return totalXp;
    } catch (e) {
      debugPrint('Error getting total XP for tribe $tribeId: $e');
      return 0;
    }
  }

  /// Gets the total habits completed from the tribe document
  Future<int> getTotalHabitsCompleted(String tribeId) async {
    try {
      final tribeDoc = await _firestore.collection('tribes').doc(tribeId).get();
      if (!tribeDoc.exists) return 0;

      return tribeDoc.data()?['totalHabitsCompleted'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error getting habits completed for tribe $tribeId: $e');
      return 0;
    }
  }

  /// Gets the total challenges completed from the tribe document
  Future<int> getTotalChallengesCompleted(String tribeId) async {
    try {
      final tribeDoc = await _firestore.collection('tribes').doc(tribeId).get();
      if (!tribeDoc.exists) return 0;

      return tribeDoc.data()?['totalChallengesCompleted'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error getting challenges completed for tribe $tribeId: $e');
      return 0;
    }
  }

  /// Gets all tribe stats in a single call
  Future<Map<String, dynamic>> getTribeStats(String tribeId) async {
    try {
      final tribeDoc = await _firestore.collection('tribes').doc(tribeId).get();
      if (!tribeDoc.exists) {
        return {
          'memberCount': 0,
          'totalXp': 0,
          'totalHabitsCompleted': 0,
          'totalChallengesCompleted': 0,
        };
      }

      final data = tribeDoc.data()!;
      final members = data['members'] as List<dynamic>?;
      final memberCount = members?.length ?? 0;

      // Calculate total XP from members
      int totalXp = 0;
      if (members != null && members.isNotEmpty) {
        final memberIds = members.cast<String>();
        final userStatsSnapshot = await _firestore
            .collection('user_stats')
            .where(FieldPath.documentId, whereIn: memberIds.take(30))
            .get();

        for (final doc in userStatsSnapshot.docs) {
          final userData = doc.data();
          final avatarStats = userData['avatarStats'] as Map<String, dynamic>?;
          if (avatarStats != null) {
            // Only sum the 6 attribute XP fields (exclude level, streak, attributeXp map)
            totalXp += avatarStats['strengthXp'] as int? ?? 0;
            totalXp += avatarStats['intellectXp'] as int? ?? 0;
            totalXp += avatarStats['vitalityXp'] as int? ?? 0;
            totalXp += avatarStats['creativityXp'] as int? ?? 0;
            totalXp += avatarStats['focusXp'] as int? ?? 0;
            totalXp += avatarStats['spiritXp'] as int? ?? 0;

            // Also sum any custom attribute XP from the attributeXp map
            final customAttributeXp = avatarStats['attributeXp'] as Map<String, dynamic>?;
            if (customAttributeXp != null) {
              for (final value in customAttributeXp.values) {
                if (value is int) totalXp += value;
              }
            }
          }
          final directTotalXp = userData['totalXp'] as int?;
          if (directTotalXp != null) totalXp += directTotalXp;
        }
      }

      return {
        'memberCount': memberCount,
        'totalXp': totalXp,
        'totalHabitsCompleted': data['totalHabitsCompleted'] as int? ?? 0,
        'totalChallengesCompleted': data['totalChallengesCompleted'] as int? ?? 0,
      };
    } catch (e) {
      debugPrint('Error getting tribe stats for $tribeId: $e');
      return {
        'memberCount': 0,
        'totalXp': 0,
        'totalHabitsCompleted': 0,
        'totalChallengesCompleted': 0,
      };
    }
  }

  /// Updates the tribe document with calculated stats
  /// 
  /// This should be called periodically or triggered by user actions
  /// to keep the tribe document's cached values in sync with reality.
  Future<void> syncTribeStats(String tribeId) async {
    try {
      final stats = await getTribeStats(tribeId);
      
      await _firestore.collection('tribes').doc(tribeId).update({
        'memberCount': stats['memberCount'],
        'totalXp': stats['totalXp'],
        'totalHabitsCompleted': stats['totalHabitsCompleted'],
        'totalChallengesCompleted': stats['totalChallengesCompleted'],
        'lastStatsSync': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Synced stats for tribe $tribeId: ${stats['memberCount']} members, ${stats['totalXp']} XP');
    } catch (e) {
      debugPrint('❌ Error syncing tribe stats for $tribeId: $e');
    }
  }
}
