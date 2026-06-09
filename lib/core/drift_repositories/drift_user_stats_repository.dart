import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';

class DriftUserStatsRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore;
  final EnhancedSyncEngine _syncEngine;

  DriftUserStatsRepository(
    this._db,
    this._syncEngine, [
    FirebaseFirestore? firestore,
  ]) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> saveUserStats(UserProfile profile) async {
    // 1. Update local Drift database
    await _db.userStatsDao.upsertFromFirebase(profile.uid, {
      'displayName': profile.displayName,
      'photoUrl': profile.photoUrl,
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
      'characterClass': profile.characterClass,
      'motive': profile.motive,
      'why': profile.why,
      'anchorsJson': jsonEncode(profile.anchors),
      'habitStacksJson': jsonEncode(
        profile.habitStacks.map((e) => e.toMap()).toList(),
      ),
      'skippedOnboardingStepsJson': jsonEncode(profile.skippedOnboardingSteps),
      'settingsJson': jsonEncode(profile.settings.toMap()),
      'avatarJson': jsonEncode(profile.avatarStats.toMap()),
      'worldStateJson': jsonEncode(profile.worldState.toMap()),
      'onboardingProgress': profile.onboardingProgress,
      'onboardingCompletedAt': profile.onboardingCompletedAt?.toIso8601String(),
      'onboardingStartedAt': profile.onboardingStartedAt?.toIso8601String(),
      'hasEmerged': profile.hasEmerged,
      'momentumScore': profile.momentumScore,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // 2. Enqueue sync to Firestore
    final profileMap = profile.toMap();

    // Sync to user_stats (detailed metrics used by game loop)
    await _syncEngine.enqueueSet(
      collectionPath: 'user_stats',
      documentId: profile.uid,
      data: profileMap,
    );

    // Sync to users (master profile used by tribe recalculation and social)
    await _syncEngine.enqueueUpdate(
      collectionPath: 'users',
      documentId: profile.uid,
      data: {
        'archetype': profile.archetype.name,
        'level': profile.avatarStats.level,
        'streak': profile.avatarStats.streak,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Future<void> updateWorldHealth(String uid, int score) async {
    final healthPercent = score / 100.0;

    // 1. Update local Drift database
    await _db.userStatsDao.updateWorldHealth(uid, healthPercent);

    // 2. Enqueue sync to Firestore
    await _syncEngine.enqueueUpdate(
      collectionPath: 'users',
      documentId: uid,
      data: {
        'worldState.entropy': 1.0 - healthPercent,
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
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

  Future<Map<String, dynamic>?> getLatestRecap(String userId) async {
    final snapshot = await _firestore
        .collection('user_stats')
        .doc(userId)
        .collection('recaps')
        .orderBy('endDate', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data();
  }

  Future<Map<String, dynamic>?> getRecap(String userId, String recapId) async {
    final doc = await _firestore
        .collection('user_stats')
        .doc(userId)
        .collection('recaps')
        .doc(recapId)
        .get();
    return doc.data();
  }

  Future<List<Map<String, dynamic>>> getRecaps(
    String userId, {
    int limit = 10,
  }) async {
    final snapshot = await _firestore
        .collection('user_stats')
        .doc(userId)
        .collection('recaps')
        .orderBy('endDate', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> saveRecap(String userId, Map<String, dynamic> recapData) async {
    // Use sync engine for offline-first recap persistence
    await _syncEngine.enqueueSet(
      collectionPath: 'user_stats',
      documentId: '$userId/recaps/${recapData['id']}',
      data: recapData,
    );
  }

  Future<List<Map<String, dynamic>>> getWeeklyActivity(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _firestore
        .collection('user_activity')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

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
    final nowStr = date.toIso8601String();
    final data = <String, dynamic>{
      'userId': userId,
      'date': nowStr,
      'type': type,
      'createdAt': nowStr,
    };
    if (habitId != null) data['habitId'] = habitId;
    if (sourceId != null) data['sourceId'] = sourceId;
    if (difficulty != null) data['difficulty'] = difficulty;
    if (attribute != null) data['attribute'] = attribute;
    if (streakDay != null) data['streakDay'] = streakDay;

    final docId = '${userId}_${type}_${date.millisecondsSinceEpoch}';
    await _syncEngine.enqueueSet(
      collectionPath: 'user_activity',
      documentId: docId,
      data: data,
    );
  }

  UserWorldState _parseWorldState(UserStatsTableData row) {
    if (row.worldStateJson == null || row.worldStateJson!.isEmpty) {
      return UserWorldState(
        entropy: 1.0 - ((row.worldHealthScore as double?) ?? 1.0),
      );
    }
    try {
      final map = jsonDecode(row.worldStateJson!) as Map<String, dynamic>;
      return UserWorldState.fromMap(map);
    } catch (_) {
      return UserWorldState(
        entropy: 1.0 - ((row.worldHealthScore as double?) ?? 1.0),
      );
    }
  }

  UserProfile _rowToProfile(UserStatsTableData row) {
    List<String> anchors = [];
    if (row.anchorsJson != null) {
      try {
        anchors = List<String>.from(jsonDecode(row.anchorsJson!));
      } catch (_) {}
    }

    List<HabitStack> habitStacks = [];
    if (row.habitStacksJson != null) {
      try {
        final list = jsonDecode(row.habitStacksJson!) as List;
        habitStacks = list
            .map((e) => HabitStack.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    List<String> skippedOnboardingSteps = [];
    if (row.skippedOnboardingStepsJson != null) {
      try {
        skippedOnboardingSteps = List<String>.from(
          jsonDecode(row.skippedOnboardingStepsJson!),
        );
      } catch (_) {}
    }

    UserSettings settings = const UserSettings();
    if (row.settingsJson != null) {
      try {
        settings = UserSettings.fromMap(
          jsonDecode(row.settingsJson!) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    return UserProfile(
      uid: row.userId,
      displayName: row.displayName,
      photoUrl: row.photoUrl,
      archetype: UserArchetype.values.firstWhere(
        (e) => e.name == (row.archetype ?? 'none'),
        orElse: () => UserArchetype.none,
      ),
      characterClass: row.characterClass,
      motive: row.motive,
      why: row.why,
      anchors: anchors,
      habitStacks: habitStacks,
      onboardingProgress: (row.onboardingProgress as int?) ?? 0,
      skippedOnboardingSteps: skippedOnboardingSteps,
      onboardingStartedAt: row.onboardingStartedAt != null
          ? DateTime.tryParse(row.onboardingStartedAt!)
          : null,
      onboardingCompletedAt: row.onboardingCompletedAt != null
          ? DateTime.tryParse(row.onboardingCompletedAt!)
          : null,
      settings: settings,
      hasEmerged: (row.hasEmerged as bool?) ?? false,
      momentumScore: (row.momentumScore as double?) ?? 0.5,
      avatarStats: UserAvatarStats(
        strengthXp: (row.strengthXp as int?) ?? 0,
        intellectXp: (row.intellectXp as int?) ?? 0,
        vitalityXp: (row.vitalityXp as int?) ?? 0,
        creativityXp: (row.creativityXp as int?) ?? 0,
        focusXp: (row.focusXp as int?) ?? 0,
        spiritXp: (row.spiritXp as int?) ?? 0,
        challengeXp: (row.challengeXp as int?) ?? 0,
        level: (row.level as int?) ?? 1,
        streak: (row.streak as int?) ?? 0,
        momentumScore: (((row.momentumScore as double?) ?? 0.5) * 100).toInt(),
      ),
      worldState: _parseWorldState(row),
    );
  }

  UserProfile rowToProfileForTest(UserStatsTableData row) => _rowToProfile(row);
}
