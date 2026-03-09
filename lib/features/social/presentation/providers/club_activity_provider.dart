import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the ClubActivityService singleton.
///
/// This service handles logging user activities (habit completions, level ups,
/// challenge completions) to their archetype club's activity feed.
final clubActivityServiceProvider = Provider<ClubActivityService>((ref) {
  return ClubActivityService(firestore: FirebaseFirestore.instance);
});

/// Real-time stream of activity feed for a given club.
///
/// Takes a [clubId] as parameter and streams the activity collection,
/// ordered by timestamp descending, limited to 20 items.
///
/// Usage:
/// ```dart
/// final activityAsync = ref.watch(clubActivityStreamProvider('athlete_club'));
/// activityAsync.when(
///   data: (activities) => ActivityListWidget(activities),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => ErrorWidget(err),
/// )
/// ```
final clubActivityStreamProvider =
    StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, clubId) {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('tribes')
        .doc(clubId)
        .collection('activity')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => doc.data()).toList(),
        );
  },
);

/// Real-time stream of top contributors for a given club.
///
/// Takes a [clubId] as parameter and streams the contributors collection,
/// ordered by contributionCount descending (or xp if field exists),
/// limited to 10 items.
///
/// Usage:
/// ```dart
/// final contributorsAsync = ref.watch(clubContributorsStreamProvider('athlete_club'));
/// contributorsAsync.when(
///   data: (contributors) => ContributorsListWidget(contributors),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => ErrorWidget(err),
/// )
/// ```
final clubContributorsStreamProvider =
    StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, clubId) {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('tribes')
        .doc(clubId)
        .collection('contributors')
        .orderBy('contributionCount', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => doc.data()).toList(),
        );
  },
);
