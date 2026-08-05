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
        final description = remote?['description'] as String? ??
            (OfficialClubsSeed.getOfficialClubsMap()[row.tribeId]?['description']
                    as String? ??
                '');
        // Distinct per-tribe image: remote first, then the seed catalog.
        // Legacy Unsplash links (written by the old server seed) count as
        // stale — the bundled seed artwork wins for official clubs, so the
        // curated per-club assets actually render. Real custom images (any
        // other URL) still take precedence.
        final seedImage = OfficialClubsSeed
            .getOfficialClubsMap()[row.tribeId]?['imageUrl'] as String?;
        final remoteImage = remote?['imageUrl'] as String?;
        final isLegacyRemote = remoteImage == null ||
            remoteImage.isEmpty ||
            remoteImage.startsWith('https://images.unsplash.com/');
        final imageUrl =
            isLegacyRemote ? (seedImage ?? '') : remoteImage!;
        final members = List<String>.from(remote?['members'] ?? const []);

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
          members: members,
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

          // Remote: background sync, never blocks.
          // Capped at 20 docs — the official club set is small and bounded;
          // this prevents a runaway download if the collection ever grows.
          remoteSub = _firestore
              .collection('tribes')
              .where('type', isEqualTo: TribeType.official.name)
              .limit(20)
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
    // SP-G D1: idempotence. Never join twice — the onboarding flow calls
    // joinTribe (Firestore transaction) and this method back-to-back, and a
    // reinstall can leave Firestore membership without local Drift state.
    final localMembership =
        await _db.tribeMembershipDao.watchActiveMembership(userId).first;
    if (localMembership != null && localMembership.isActive) return;

    var remoteExists = false;
    try {
      remoteExists = await _firestore
          .collection('users').doc(userId).collection('tribes').doc(tribeId)
          .get()
          .then((s) => s.exists);
    } catch (_) {
      remoteExists = false; // offline: Drift check only (best-effort guard)
    }
    if (localMembership != null || remoteExists) return;

    // 1. Update local Drift database
    await _db.tribeStatsDao.incrementMemberCount(tribeId, delta: 1);
    await _db.tribeMembershipDao.upsertMembership(UserTribeTableCompanion(
      userId: Value(userId),
      tribeId: Value(tribeId),
      membershipType: const Value('archetype'),
      joinedAt: Value(DateTime.now().toIso8601String()),
      isActive: const Value(true),
    ));

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

    // Path B: Tribe's contributor subcollection.
    // SP-G D3: omit zero totals — the sync engine applies merge-sets, so
    // explicit zeros would overwrite existing totals on rejoin.
    await _syncEngine.enqueueSet(
      collectionPath: 'tribes/$tribeId/contributors',
      documentId: userId,
      data: {
        'userId': userId,
        'joinedAt': {'__type__': 'serverTimestamp'},
      },
    );

    // Path C: Tribe master document (atomic members and count).
    // Use a merge-set: `update` fails if the tribe doc doesn't exist
    // remotely yet (locally-seeded clubs), dead-lettering the mutation.
    // NOTE: `type` is deliberately NOT written here — it is owned by the
    // tribe's creator (server seed/admin for official clubs, the creator
    // flow for creator tribes). A join must never overwrite it: writing
    // 'official' here would silently re-type a creator tribe joined
    // through this path.
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

    // Path B: Update Tribe master document (atomic remove and decrement).
    // Merge-set for the same reason as joinClub Path C.
    await _syncEngine.enqueueSet(
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
    // Gather local data first so we can fall back to it on Firestore failure
    List<Tribe> localTribes = [];
    final membership =
        await _db.tribeMembershipDao.watchActiveMembership(userId).first;
    if (membership != null) {
      final row = await _db.tribeStatsDao.getStats(membership.tribeId);
      if (row != null) localTribes = [_rowToTribe(row)];
    }

    if (localTribes.isNotEmpty) return localTribes;

    try {
      final tribeDocs = await _firestore
          .collection('tribes')
          .where('members', arrayContains: userId)
          .get();
      if (tribeDocs.docs.isEmpty) return [];
      final tribes =
          tribeDocs.docs.map((doc) => Tribe.fromMap(doc.data())).toList();
      for (final tribe in tribes) {
        await _db.tribeMembershipDao.upsertMembership(UserTribeTableCompanion(
          userId: Value(userId),
          tribeId: Value(tribe.id),
          membershipType:
              Value(tribe.archetypeId != null ? 'archetype' : 'creator'),
          joinedAt: Value(DateTime.now().toIso8601String()),
          isActive: const Value(true),
        ));
      }
      return tribes;
    } catch (e, st) {
      debugPrint('[TribeRepo] getUserTribes Firestore fallback failed: $e\n$st');
      // Return local data only - don't silently return empty
      return localTribes;
    }
  }

  @override
  Stream<List<Tribe>> watchUserTribes(String userId) {
    final controller = StreamController<List<Tribe>>();

    StreamSubscription<UserTribeTableData?>? membershipSub;
    StreamSubscription<TribeStatsTableData?>? tribeStatsSub;
    StreamSubscription<QuerySnapshot>? tribesSub;

    String? currentTribeId;
    TribeStatsTableData? localTribeStats;
    Map<String, dynamic>? remoteTribeData;

    void emitTribe() {
      if (controller.isClosed) return;

      final tribe = _mergeTribeData(currentTribeId, localTribeStats, remoteTribeData);
      if (tribe != null) {
        controller.add([tribe]);
      } else {
        controller.add([]);
      }
    }

    // Listen to user's active membership in Drift
    membershipSub = _db.tribeMembershipDao.watchActiveMembership(userId).listen(
      (membership) {
        final newTribeId = membership?.tribeId;
        if (newTribeId != currentTribeId) {
          // Tribe ID changed, clean up old tribe stats subscription
          tribeStatsSub?.cancel();
          tribeStatsSub = null;
          localTribeStats = null;
          currentTribeId = newTribeId;

          // Subscribe to new tribe's stats if we have a tribeId
          if (newTribeId != null) {
tribeStatsSub = _db.tribeStatsDao
                .watchStats(newTribeId)
                .listen((stats) {
                  localTribeStats = stats;
                  emitTribe();
                }, onError: (error) {
                  AppLogger.e('Error watching tribe stats for $newTribeId', error);
});
          }
        }
        emitTribe();
      },
      onError: (error) {
        AppLogger.e('Error watching user membership for $userId', error);
      },
    );

    // Listen to tribes in Firestore where user is a member
    tribesSub = _firestore
        .collection('tribes')
        .where('members', arrayContains: userId)
        .snapshots()
        .listen((snapshot) {
          // We expect at most one tribe for the current user (based on current design)
          // but handle multiple just in case
          if (snapshot.docs.isNotEmpty) {
            // Take the first tribe (should be only one in current design)
            final doc = snapshot.docs.first;
            remoteTribeData = doc.data();
            emitTribe();
          } else {
            // No tribes found for user in Firestore
            remoteTribeData = null;
            emitTribe();
          }
        }, onError: (error) {
          AppLogger.e('Error watching user tribes in Firestore for $userId', error);
        });

    // Initialize: try to get initial state from Drift
    _db.tribeMembershipDao.watchActiveMembership(userId).first.then((membership) {
      if (!controller.isClosed) {
        final tribeId = membership?.tribeId;
        if (tribeId != null) {
          currentTribeId = tribeId;
          // Try to get initial tribe stats from Drift
          _db.tribeStatsDao
              .watchStats(tribeId)
              .first
              .then((stats) {
                if (!controller.isClosed) {
                  localTribeStats = stats;
                  emitTribe();
                }
              })
              .catchError((error) {
                if (!controller.isClosed) {
                  AppLogger.e('Error getting initial tribe stats for $tribeId', error);
                }
              });
        }
        emitTribe();
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        AppLogger.e('Error getting initial membership for $userId', error);
        emitTribe(); // Emit empty list on error
      }
    });

    controller.onCancel = () {
      membershipSub?.cancel();
      tribeStatsSub?.cancel();
      tribesSub?.cancel();
    };

    return controller.stream;
  }

  Tribe? _mergeTribeData(
      String? tribeId,
      TribeStatsTableData? localStats,
      Map<String, dynamic>? remoteData) {
    if (tribeId == null) return null;

    // Start with default values
    String name = '';
    String description = '';
    String imageUrl = '';
    String ownerId = '';
    List<String> tags = [];
    int levelRequirement = 0;
    int rank = 0;
    int totalXp = 0;
    int memberCount = 0;
    int totalHabitsCompleted = 0;
    int totalChallengesCompleted = 0;
    bool isVerified = false;
    String? archetypeId;

    // Apply local Drift data (for real-time updates like XP)
    if (localStats != null) {
      name = localStats.tribeName ?? '';
      totalXp = localStats.totalXp;
      memberCount = localStats.memberCount;
      totalHabitsCompleted = localStats.totalHabitsCompleted;
      totalChallengesCompleted = localStats.totalChallengesCompleted;
      archetypeId = localStats.archetypeId;
    }

    // Overlay/merge with remote Firestore data (source of truth for most fields)
    if (remoteData != null) {
      name = (remoteData['name'] as String? ?? '').isNotEmpty
          ? (remoteData['name'] as String)
          : name;
      description = (remoteData['description'] as String?) ?? description;
      imageUrl = (remoteData['imageUrl'] as String? ?? '')
          .isNotEmpty
          ? (remoteData['imageUrl'] as String)
          : imageUrl;
      ownerId = (remoteData['ownerId'] as String?) ?? ownerId;
      tags = List<String>.from(remoteData['tags'] ?? const []);
      levelRequirement = (remoteData['levelRequirement'] as int? ?? 0);
      rank = (remoteData['rank'] as int? ?? 0);
      // SP-G D4: tribe totals are recalc-only (server-authoritative D10) —
      // prefer remote over local, matching watchArchetypeClubs.emitMerged.
      // Local Drift keeps updating for instant UI; stale/inflated local
      // values must never override the recalc'd Firestore numbers.
      totalXp = (remoteData['totalXp'] as num?)?.toInt() ?? totalXp;
      memberCount = (remoteData['memberCount'] as num?)?.toInt() ?? memberCount;
      totalHabitsCompleted =
          (remoteData['totalHabitsCompleted'] as num?)?.toInt() ??
          totalHabitsCompleted;
      totalChallengesCompleted =
          (remoteData['totalChallengesCompleted'] as num?)?.toInt() ??
          totalChallengesCompleted;

      isVerified = (remoteData['isVerified'] as bool? ?? false);
      archetypeId = (remoteData['archetypeId'] as String?) ?? archetypeId;
    }

    return Tribe(
      id: tribeId,
      name: name,
      description: description,
      imageUrl: imageUrl,
      ownerId: ownerId,
      tags: tags,
      levelRequirement: levelRequirement,
      rank: rank,
      totalXp: totalXp,
      memberCount: memberCount,
      totalHabitsCompleted: totalHabitsCompleted,
      totalChallengesCompleted: totalChallengesCompleted,
      isVerified: isVerified,
      archetypeId: archetypeId,
    );
  }

  @override
  Future<void> seedTribesIfEmpty() async {
    final rows = await _db.tribeStatsDao.getAll();
    if (rows.isEmpty) {
      await _seedLocalClubs();
    }
  }

  Tribe _rowToTribe(TribeStatsTableData row) {
    // Surface the seed catalog's per-club imagery/description so the Drift
    // path matches the Firestore/All-Tribes path (previously _rowToTribe
    // dropped imageUrl/description to '', causing the onboarding vs
    // All-Tribes club-image mismatch).
    final seed = OfficialClubsSeed.getOfficialClubsMap()[row.tribeId];
    final seedImage = seed?['imageUrl'] as String?;
    final seedDescription = seed?['description'] as String?;
    return Tribe(
      id: row.tribeId,
      name: row.tribeName ?? '',
      description: (seedDescription != null && seedDescription.isNotEmpty)
          ? seedDescription
          : '',
      imageUrl: (seedImage != null && seedImage.isNotEmpty) ? seedImage : '',
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
