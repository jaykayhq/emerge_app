import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/utils/app_logger.dart';

/// Pulls the user's latest data from Firestore into local Drift.
/// Called on auth state change and app startup.
class IncomingSyncService {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  IncomingSyncService(this._db, this._firestore);

  Future<void> pullRemoteData(String userId) async {
    try {
      // Pull user_stats
      final statsSnap =
          await _firestore.collection('user_stats').doc(userId).get();
      if (statsSnap.exists) {
        final stats = statsSnap.data()!;
        await _db.into(_db.userStatsTable).insert(
              UserStatsTableCompanion(
                userId: Value(userId),
                displayName: Value(stats['displayName'] as String?),
                photoUrl: Value(stats['photoUrl'] as String?),
                totalXp: Value((stats['totalXp'] as num?)?.toInt() ?? 0),
                level: Value((stats['level'] as num?)?.toInt() ?? 1),
                streak: Value((stats['streak'] as num?)?.toInt() ?? 0),
                strengthXp:
                    Value((stats['strengthXp'] as num?)?.toInt() ?? 0),
                intellectXp:
                    Value((stats['intellectXp'] as num?)?.toInt() ?? 0),
                vitalityXp:
                    Value((stats['vitalityXp'] as num?)?.toInt() ?? 0),
                creativityXp:
                    Value((stats['creativityXp'] as num?)?.toInt() ?? 0),
                focusXp: Value((stats['focusXp'] as num?)?.toInt() ?? 0),
                spiritXp: Value((stats['spiritXp'] as num?)?.toInt() ?? 0),
                challengeXp:
                    Value((stats['challengeXp'] as num?)?.toInt() ?? 0),
                worldHealthScore: Value(
                    (stats['worldHealthScore'] as num?)?.toDouble() ?? 1.0),
                archetype: Value(stats['archetype'] as String?),
                characterClass: Value(stats['characterClass'] as String?),
                motive: Value(stats['motive'] as String?),
                why: Value(stats['why'] as String?),
                anchorsJson: Value(stats['anchorsJson'] as String?),
                habitStacksJson: Value(stats['habitStacksJson'] as String?),
                skippedOnboardingStepsJson:
                    Value(stats['skippedOnboardingStepsJson'] as String?),
                settingsJson: Value(stats['settingsJson'] as String?),
                avatarJson: Value(stats['avatarJson'] as String?),
                worldStateJson: Value(stats['worldStateJson'] as String?),
                updatedAt: Value(stats['updatedAt']?.toString() ?? ''),
                syncedAt: Value(DateTime.now().toIso8601String()),
                onboardingProgress:
                    Value((stats['onboardingProgress'] as num?)?.toInt() ?? 0),
                onboardingCompletedAt:
                    Value(stats['onboardingCompletedAt'] as String?),
                onboardingStartedAt:
                    Value(stats['onboardingStartedAt'] as String?),
                hasEmerged:
                    Value((stats['hasEmerged'] as bool?) ?? false),
                momentumScore: Value(
                    (stats['momentumScore'] as num?)?.toDouble() ?? 0.5),
                lastCelebratedLevel: Value(
                    (stats['lastCelebratedLevel'] as num?)?.toInt() ?? 0),
                interestsCsv: Value(stats['interestsCsv'] as String?),
                joinedClubId: Value(stats['joinedClubId'] as String?),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }

      // Pull recent completions (last 7 days) to ensure streak accuracy
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final completionsSnap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habit_completions')
          .where('completedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .get();

      for (final doc in completionsSnap.docs) {
        final data = doc.data();
        await _db.into(_db.habitCompletionsTable).insert(
              HabitCompletionsTableCompanion(
                id: Value(doc.id),
                userId: Value(userId),
                habitId: Value(data['habitId'] as String? ?? ''),
                completedAt: Value(data['completedAt'] is Timestamp
                    ? (data['completedAt'] as Timestamp).toDate().toIso8601String()
                    : data['completedAt']?.toString() ?? ''),
                xpGained: Value((data['xpGained'] as num?)?.toInt() ?? 0),
                attribute: Value(data['attribute'] as String?),
                momentumAtCompletion:
                    Value((data['momentumAtCompletion'] as num?)?.toInt()),
                streakDay: Value((data['streakDay'] as num?)?.toInt() ?? 0),
                wasRecovery: Value((data['wasRecovery'] as num?)?.toInt() ?? 0),
                syncedAt: Value(DateTime.now().toIso8601String()),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }

      AppLogger.d(
          '[IncomingSync] Pulled ${completionsSnap.docs.length} recent completions');
    } catch (e, st) {
      AppLogger.e('[IncomingSync] Failed to pull remote data: $e', e, st);
      // Non-fatal — local data still works
    }
  }
}
