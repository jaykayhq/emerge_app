import 'dart:async';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

class DriftUserStatsRepository {
  final AppDatabase _db;

  DriftUserStatsRepository(this._db);

  Future<void> saveUserStats(UserProfile profile) async {
    await _db.userStatsDao.upsertFromFirebase(profile.uid, {
      'totalXp': profile.avatarStats.totalXp,
      'level': profile.avatarStats.level,
      'streak': profile.avatarStats.streak,
      'strengthXp': profile.avatarStats.strengthXp,
      'intellectXp': profile.avatarStats.intellectXp,
      'vitalityXp': profile.avatarStats.vitalityXp,
      'creativityXp': profile.avatarStats.creativityXp,
      'focusXp': profile.avatarStats.focusXp,
      'spiritXp': profile.avatarStats.spiritXp,
      'challengeXp': profile.avatarStats.challengeXp,
      'worldHealthScore': profile.worldState.worldHealth,
      'archetype': profile.archetype.name,
      'updatedAt': DateTime.now().toIso8601String(),
      'avatarJson': profile.avatarStats.toMap().toString(),
      'worldStateJson': profile.worldState.toMap().toString(),
    });
  }

  Future<void> updateWorldHealth(String uid, int score) async {
    await _db.userStatsDao.updateWorldHealth(uid, score / 100.0);
  }

  Future<void> syncUserIdentity(UserProfile profile) async {
    await saveUserStats(profile);
  }

  Stream<UserProfile> watchUserStats(String uid) {
    return _db.userStatsDao.watchStats(uid).map((row) {
      if (row == null) return UserProfile(uid: uid);
      return _rowToProfile(row);
    });
  }

  Future<UserProfile> getUserStats(String uid) async {
    final row = await _db.userStatsDao.getStats(uid);
    if (row == null) return UserProfile(uid: uid);
    return _rowToProfile(row);
  }

  UserProfile _rowToProfile(UserStatsTableData row) {
    return UserProfile(
      uid: row.userId,
      archetype: UserArchetype.values.firstWhere(
        (e) => e.name == (row.archetype ?? 'none'),
        orElse: () => UserArchetype.none,
      ),
      avatarStats: UserAvatarStats(
        strengthXp: row.strengthXp,
        intellectXp: row.intellectXp,
        vitalityXp: row.vitalityXp,
        creativityXp: row.creativityXp,
        focusXp: row.focusXp,
        spiritXp: row.spiritXp,
        challengeXp: row.challengeXp,
        level: row.level,
        streak: row.streak,
      ),
      worldState: UserWorldState(
        entropy: 1.0 - row.worldHealthScore,
      ),
    );
  }
}
