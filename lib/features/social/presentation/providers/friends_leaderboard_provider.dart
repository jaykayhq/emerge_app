import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/presentation/widgets/friends_leaderboard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Real-time friends leaderboard with LIVE stats from user_stats
/// This replaces the stale friend data with actual current XP/level
///
/// COST: Only queries user_stats for friends you already have
/// One read per friend, cached by Firestore
final friendsLeaderboardProvider =
    StreamProvider.autoDispose<List<FriendRankEntry>>((ref) {
  ref.onDispose(() => AppLogger.d('Disposing friendsLeaderboardProvider'));

  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value([]);

  final firestore = FirebaseFirestore.instance;

  // First, get the friends list
  return firestore
      .collection('users')
      .doc(user.id)
      .collection('friends')
      .snapshots()
      .asyncMap((friendsSnapshot) async {
    if (friendsSnapshot.docs.isEmpty) return [];

    // Extract friend IDs
    final friendIds = friendsSnapshot.docs.map((d) => d.id).toList();

    // Query user_stats in batches (Firestore limit: 30 per query)
    final List<FriendRankEntry> entries = [];
    const batchSize = 30;

    for (var i = 0; i < friendIds.length; i += batchSize) {
      final batch = friendIds.skip(i).take(batchSize).toList();

      try {
        final statsSnapshot = await firestore
            .collection('user_stats')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in statsSnapshot.docs) {
          final data = doc.data();

          // Find friend doc safely without firstWhereOrNull
          DocumentSnapshot? friendDoc;
          try {
            friendDoc = friendsSnapshot.docs.firstWhere((d) => d.id == doc.id);
          } catch (_) {
            friendDoc = null;
          }

          if (friendDoc == null) {
            AppLogger.w('Friend ${doc.id} found in user_stats but not in friends collection - skipping');
            continue;
          }

          final friendData = friendDoc.data() as Map<String, dynamic>?;
          if (friendData == null) {
            AppLogger.w('Friend ${doc.id} has no data - skipping');
            continue;
          }

          // Extract XP from avatarStats (primary source)
          final avatarStats = data['avatarStats'] as Map<String, dynamic>?;
          int totalXp = 0;

          if (avatarStats != null) {
            // Add type validation for each attribute
            totalXp += _safeInt(avatarStats['strengthXp'], doc.id, 'strengthXp');
            totalXp += _safeInt(avatarStats['intellectXp'], doc.id, 'intellectXp');
            totalXp += _safeInt(avatarStats['vitalityXp'], doc.id, 'vitalityXp');
            totalXp += _safeInt(avatarStats['creativityXp'], doc.id, 'creativityXp');
            totalXp += _safeInt(avatarStats['focusXp'], doc.id, 'focusXp');
            totalXp += _safeInt(avatarStats['spiritXp'], doc.id, 'spiritXp');
          }

          // Fallback to totalXp if present
          final directTotalXp = data['totalXp'] as int?;
          if (directTotalXp != null && directTotalXp > 0 && totalXp == 0) {
            totalXp = directTotalXp;
          }

          entries.add(FriendRankEntry(
            id: doc.id,
            name: friendData['name'] ?? 'Unknown',
            xp: totalXp,
            streak: (avatarStats != null ? _safeInt(avatarStats['streak'], doc.id, 'streak') : 0)
                .clamp(0, 1000), // Sanity check for streak
            isYou: false,
          ));
        }
      } catch (e, stack) {
        AppLogger.e('Error loading friends leaderboard batch', e, stack);
        // Continue with next batch instead of failing entirely
      }
    }

    // Add current user to the mix for comparison
    try {
      final myStatsRef = await firestore.collection('user_stats').doc(user.id).get();
      if (myStatsRef.exists) {
        final myData = myStatsRef.data()!;
        final myAvatarStats = myData['avatarStats'] as Map<String, dynamic>?;
        int myXp = 0;

        if (myAvatarStats != null) {
          myXp += _safeInt(myAvatarStats['strengthXp'], user.id, 'strengthXp');
          myXp += _safeInt(myAvatarStats['intellectXp'], user.id, 'intellectXp');
          myXp += _safeInt(myAvatarStats['vitalityXp'], user.id, 'vitalityXp');
          myXp += _safeInt(myAvatarStats['creativityXp'], user.id, 'creativityXp');
          myXp += _safeInt(myAvatarStats['focusXp'], user.id, 'focusXp');
          myXp += _safeInt(myAvatarStats['spiritXp'], user.id, 'spiritXp');
        }

        // Get user's display name
        final userDoc = await firestore.collection('users').doc(user.id).get();
        final userName = userDoc.data()?['displayName'] ?? 'You';

        entries.add(FriendRankEntry(
          id: user.id,
          name: userName,
          xp: myXp,
          streak: (myAvatarStats != null ? _safeInt(myAvatarStats['streak'], user.id, 'streak') : 0)
              .clamp(0, 1000),
          isYou: true,
        ));
      }
    } catch (e, stack) {
      AppLogger.e('Error loading current user stats for leaderboard', e, stack);
    }

    // Sort by XP descending
    entries.sort((a, b) => b.xp.compareTo(a.xp));
    return entries;
  });
});

/// Safely extract integer value with validation and error logging
int _safeInt(dynamic value, String userId, String fieldName) {
  if (value == null) return 0;
  if (value is int) {
    if (value < 0) {
      AppLogger.w('Negative $fieldName for user $userId: $value');
      return 0;
    }
    if (value > 1000000000) { // Sanity check: 1 billion XP
      AppLogger.w('Unreasonably high $fieldName for user $userId: $value');
      return 0;
    }
    return value;
  }
  AppLogger.w('Invalid type for $fieldName for user $userId: ${value.runtimeType}');
  return 0;
}
