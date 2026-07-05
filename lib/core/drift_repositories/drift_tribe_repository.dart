import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/social/data/repositories/tribe_repository.dart';
import 'package:emerge_app/features/social/data/seeds/official_clubs_seed.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:flutter/foundation.dart';

class DriftTribeRepository implements TribeRepository {
  final AppDatabase _db;
  final EnhancedSyncEngine _syncEngine;
  final FirebaseFirestore _firestore;

  DriftTribeRepository(
    this._db,
    this._syncEngine, [
    FirebaseFirestore? firestore,
  ]) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Tribe?> getArchetypeClub(String archetypeId) async {
    final rows = await _db.tribeStatsDao.getAll();
    var tribe = rows.where((r) => r.archetypeId == archetypeId).firstOrNull;
    if (tribe != null) return _rowToTribe(tribe);

    await _seedLocalClubs();
    final seeded = await _db.tribeStatsDao.getAll();
    tribe = seeded.where((r) => r.archetypeId == archetypeId).firstOrNull;
    if (tribe != null) return _rowToTribe(tribe);
    return null;
  }

  @override
  Future<List<Tribe>> getArchetypeClubs() async {
    var rows = await _db.tribeStatsDao.getAll();
    if (rows.isEmpty) {
      await _seedLocalClubs();
      rows = await _db.tribeStatsDao.getAll();
    }
    return rows.map(_rowToTribe).toList();
  }

  @override
  Stream<List<Tribe>> watchArchetypeClubs() {
    final controller = StreamController<List<Tribe>>();

    StreamSubscription<List<TribeStatsTableData>>? localSub;
    StreamSubscription<QuerySnapshot>? remoteSub;

    var remoteDocs = <String, Map<String, dynamic>>{};

    Future<void> emitMerged() async {
      final localRows = await _db.tribeStatsDao.getAll();
      final tribes = localRows.map((row) {
        final remote = remoteDocs[row.tribeId];
        final memberCount =
            (remote?['memberCount'] as num?)?.toInt() ?? row.memberCount;
        final totalXp = (remote?['totalXp'] as num?)?.toInt() ?? row.totalXp;
        final totalHabits =
            (remote?['totalHabitsCompleted'] as num?)?.toInt() ??
            row.totalHabitsCompleted;
        final totalChallenges =
            (remote?['totalChallengesCompleted'] as num?)?.toInt() ??
            row.totalChallengesCompleted;
        final tribeName = (remote?['name'] as String?)?.isNotEmpty == true
            ? remote!['name'] as String
            : row.tribeName ?? '';
        final description = remote?['description'] as String? ?? '';
        final imageUrl = remote?['imageUrl'] as String? ?? '';

        return Tribe(
          id: row.tribeId,
          name: tribeName,
          description: description,
          imageUrl: imageUrl,
          ownerId: remote?['ownerId'] as String? ?? '',
          tags: List<String>.from(remote?['tags'] ?? const []),
          levelRequirement: 0,
          rank: 0,
          totalXp: totalXp,
          memberCount: memberCount,
          archetypeId: row.archetypeId,
          isVerified: remote?['isVerified'] as bool? ?? false,
          totalHabitsCompleted: totalHabits,
          totalChallengesCompleted: totalChallenges,
        );
      }).toList();

      if (!controller.isClosed) controller.add(tribes);
    }

    // Bootstrap: seed local if empty, then start subscriptions
    _db.tribeStatsDao
        .getAll()
        .then((rows) async {
          if (rows.isEmpty) await _seedLocalClubs();

          // Emit local data immediately
          await emitMerged();

          // Listen to local changes
          localSub = _db.tribeStatsDao.watchAll().listen(
            (_) => emitMerged(),
            onError: controller.addError,
          );

          // Remote: background sync, never blocks
          remoteSub = _firestore
              .collection('tribes')
              .where('type', isEqualTo: TribeType.official.name)
              .snapshots()
              .listen(
                (snapshot) {
                  remoteDocs = {
                    for (final doc in snapshot.docs) doc.id: doc.data(),
                  };
                  emitMerged();
                },
                onError: (Object err) {
                  AppLogger.e('Firestore tribe sync failed', err);
                },
              );
        })
        .catchError((Object e) {
          controller.addError(e);
          return null;
        });

    controller.onCancel = () {
      localSub?.cancel();
      remoteSub?.cancel();
    };

    return controller.stream;
  }

  Future<void> _seedLocalClubs() async {
    final clubsMap = OfficialClubsSeed.getOfficialClubsMap();
    for (final entry in clubsMap.entries) {
      final data = entry.value;
      final archetypeId = data['archetypeId'] as String? ?? '';
      final clubId = entry.key;
      await _db.tribeStatsDao.upsertStats(
        TribeStatsTableCompanion(
          tribeId: Value(clubId),
          tribeName: Value(data['name'] as String? ?? ''),
          archetypeId: Value(archetypeId),
          memberCount: const Value(0),
          totalXp: const Value(0),
          totalHabitsCompleted: const Value(0),
          totalChallengesCompleted: const Value(0),
          userContributionXp: const Value(0),
          userHabitsCompleted: const Value(0),
          userChallengesCompleted: const Value(0),
          updatedAt: Value(DateTime.now().toIso8601String()),
        ),
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getClubContributors(
    String tribeId, {
    int limit = 10,
  }) async {
    final rows = await _db.leaderboardEntriesDao.getForTribe(tribeId);
    return rows
        .take(limit)
        .map(
          (r) => {
            'userId': r.userId,
            'userName': r.userName,
            'xp': r.xp,
            'level': r.level,
            'archetype': r.archetype,
          },
        )
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getClubActivity(
    String tribeId, {
    int limit = 20,
  }) async {
    final rows = await _db.tribeActivityDao.getTribeActivity(tribeId);
    return rows
        .take(limit)
        .map(
          (r) => {
            'id': r.id,
            'userId': r.userId,
            'userName': r.userName,
            'type': r.type,
            'description': r.description,
            'timestamp': r.timestamp,
          },
        )
        .toList();
  }

  int _timestampToMs(dynamic ts) {
    if (ts == null) return 0;
    if (ts is Timestamp) return ts.millisecondsSinceEpoch;
    if (ts is String) {
      final parsed = DateTime.tryParse(ts);
      return parsed?.millisecondsSinceEpoch ?? 0;
    }
    return 0;
  }

  String _timestampToString(dynamic ts) {
    if (ts is Timestamp) return ts.toDate().toIso8601String();
    if (ts is String) return ts;
    return DateTime.now().toIso8601String();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchClubActivity(
    String tribeId, {
    int limit = 20,
  }) {
    final controller = StreamController<List<Map<String, dynamic>>>();

    StreamSubscription? localSub;
    StreamSubscription<QuerySnapshot>? remoteSub;

    void emitMerged(
      List<Map<String, dynamic>> localList,
      List<Map<String, dynamic>> remoteList,
    ) {
      final seen = <String>{};
      final merged = <Map<String, dynamic>>[];
      for (final entry in [...remoteList, ...localList]) {
        final id = entry['id'] as String? ?? '';
        if (id.isNotEmpty && seen.add(id)) {
          final normalized = Map<String, dynamic>.from(entry);
          normalized['timestamp'] = _timestampToString(normalized['timestamp']);
          merged.add(normalized);
        }
      }
      merged.sort((a, b) {
        return _timestampToMs(
          b['timestamp'],
        ).compareTo(_timestampToMs(a['timestamp']));
      });
      if (!controller.isClosed) {
        controller.add(merged.take(limit).toList());
      }
    }

    var localData = <Map<String, dynamic>>[];
    var remoteData = <Map<String, dynamic>>[];
    var localReady = false;
    var remoteReady = false;

    localSub = _db.tribeActivityDao.watchTribeActivity(tribeId).listen((rows) {
      localData = rows
          .map(
            (r) => <String, dynamic>{
              'id': r.id,
              'userId': r.userId,
              'userName': r.userName,
              'type': r.type,
              'description': r.description,
              'timestamp': r.timestamp,
            },
          )
          .toList();
      localReady = true;
      if (remoteReady) emitMerged(localData, remoteData);
    }, onError: controller.addError);

    remoteSub = _firestore
        .collection('tribes')
        .doc(tribeId)
        .collection('activity')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .listen((snapshot) {
          remoteData = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          remoteReady = true;
          if (localReady) emitMerged(localData, remoteData);
        }, onError: controller.addError);

    controller.onCancel = () {
      localSub?.cancel();
      remoteSub?.cancel();
    };

    return controller.stream;
  }

  @override
  Stream<List<Map<String, dynamic>>> watchGlobalActivity({int limit = 30}) {
    final controller = StreamController<List<Map<String, dynamic>>>();

    StreamSubscription? localSub;
    StreamSubscription<QuerySnapshot>? remoteSub;

    void emitMerged(
      List<Map<String, dynamic>> localList,
      List<Map<String, dynamic>> remoteList,
    ) {
      final seen = <String>{};
      final merged = <Map<String, dynamic>>[];
      for (final entry in [...remoteList, ...localList]) {
        final id = entry['id'] as String? ?? '';
        if (id.isNotEmpty && seen.add(id)) {
          final normalized = Map<String, dynamic>.from(entry);
          normalized['timestamp'] = _timestampToString(normalized['timestamp']);
          merged.add(normalized);
        }
      }
      merged.sort((a, b) {
        return _timestampToMs(
          b['timestamp'],
        ).compareTo(_timestampToMs(a['timestamp']));
      });
      if (!controller.isClosed) {
        controller.add(merged.take(limit).toList());
      }
    }

    var localData = <Map<String, dynamic>>[];
    var remoteData = <Map<String, dynamic>>[];
    var localReady = false;
    var remoteReady = false;

    localSub = _db.tribeActivityDao.watchGlobalActivity().listen((rows) {
      localData = rows
          .map(
            (r) => <String, dynamic>{
              'id': r.id,
              'userId': r.userId,
              'userName': r.userName,
              'type': r.type,
              'description': r.description,
              'timestamp': r.timestamp,
            },
          )
          .toList();
      localReady = true;
      if (remoteReady) emitMerged(localData, remoteData);
    }, onError: controller.addError);

    remoteSub = _firestore
        .collection('global_activities')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .listen((snapshot) {
          remoteData = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          remoteReady = true;
          if (localReady) emitMerged(localData, remoteData);
        }, onError: controller.addError);

    controller.onCancel = () {
      localSub?.cancel();
      remoteSub?.cancel();
    };

    return controller.stream;
  }

  @override
  Future<void> joinClub(String userId, String tribeId) async {
    // 1. Update local Drift database
    await _db.tribeStatsDao.incrementMemberCount(tribeId, delta: 1);

    // 2. Enqueue multi-path sync to Firestore

    // Path A: User's membership subcollection
    await _syncEngine.enqueueSet(
      collectionPath: 'users/$userId/tribes',
      documentId: tribeId,
      data: {
        'tribeId': tribeId,
        'joinedAt': {'__type__': 'serverTimestamp'},
      },
    );

    // Path B: Tribe's contributor subcollection
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

    // Path C: Tribe master document (atomic members and count)
    await _syncEngine.enqueueUpdate(
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
  }

  @override
  Future<void> leaveClub(String userId, String tribeId) async {
    // 1. Update local Drift database
    await _db.tribeStatsDao.incrementMemberCount(tribeId, delta: -1);

    // 2. Enqueue multi-path sync to Firestore

    // Path A: Remove from user's tribes
    await _syncEngine.enqueueMutation(
      collectionPath: 'users/$userId/tribes',
      documentId: tribeId,
      operation: 'delete',
    );

    // Path B: Update Tribe master document (atomic remove and decrement)
    await _syncEngine.enqueueUpdate(
      collectionPath: 'tribes',
      documentId: tribeId,
      data: {
        'members': {
          '__type__': 'arrayRemove',
          'values': [userId],
        },
        'memberCount': {'__type__': 'increment', 'value': -1},
        'lastStatsSync': {'__type__': 'serverTimestamp'},
      },
    );
  }

  @override
  Future<List<Tribe>> getUserTribes(String userId) async {
    try {
      final tribeDocs = await _firestore
          .collection('tribes')
          .where('members', arrayContains: userId)
          .get();

      if (tribeDocs.docs.isEmpty) return [];

      final tribeIds = tribeDocs.docs.map((doc) => doc.id).toSet();
      final rows = await _db.tribeStatsDao.getAll();

      return rows
          .where((row) => tribeIds.contains(row.tribeId))
          .map(_rowToTribe)
          .toList();
    } catch (e) {
      debugPrint('Error getting user tribes for $userId: $e');
      return [];
    }
  }

  @override
  Future<void> seedTribesIfEmpty() async {
    final rows = await _db.tribeStatsDao.getAll();
    if (rows.isEmpty) {
      await _seedLocalClubs();
    }
  }

  Tribe _rowToTribe(TribeStatsTableData row) {
    return Tribe(
      id: row.tribeId,
      name: row.tribeName ?? '',
      description: '',
      imageUrl: '',
      ownerId: '',
      tags: const [],
      levelRequirement: 0,
      rank: 0,
      totalXp: row.totalXp,
      memberCount: row.memberCount,
      archetypeId: row.archetypeId,
      isVerified: false,
      totalHabitsCompleted: row.totalHabitsCompleted,
      totalChallengesCompleted: row.totalChallengesCompleted,
    );
  }
}
