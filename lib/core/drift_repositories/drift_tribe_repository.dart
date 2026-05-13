import 'package:drift/drift.dart' show Value;
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/features/social/data/repositories/tribe_repository.dart';
import 'package:emerge_app/features/social/data/seeds/official_clubs_seed.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';

class DriftTribeRepository implements TribeRepository {
  final AppDatabase _db;
  final EnhancedSyncEngine _syncEngine;

  DriftTribeRepository(this._db, this._syncEngine);

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
  Stream<List<Tribe>> watchArchetypeClubs() async* {
    var rows = await _db.tribeStatsDao.getAll();
    if (rows.isEmpty) {
      await _seedLocalClubs();
      rows = await _db.tribeStatsDao.getAll();
    }
    yield rows.map(_rowToTribe).toList();
    await for (final updatedRows in _db.tribeStatsDao.watchAll()) {
      yield updatedRows.map(_rowToTribe).toList();
    }
  }

  Future<void> _seedLocalClubs() async {
    final clubsMap = OfficialClubsSeed.getOfficialClubsMap();
    for (final entry in clubsMap.entries) {
      final data = entry.value;
      final archetypeId = data['archetypeId'] as String? ?? '';
      final clubId = entry.key;
      await _db.tribeStatsDao.upsertStats(TribeStatsTableCompanion(
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
      ));
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getClubContributors(String tribeId, {int limit = 10}) async {
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getClubActivity(String tribeId, {int limit = 20}) async {
    return [];
  }

  @override
  Future<void> joinClub(String userId, String tribeId) async {
    await _db.tribeStatsDao.incrementMemberCount(tribeId, delta: 1);
    await _syncEngine.enqueueUpdate(
      collectionPath: 'users/$userId/tribes',
      documentId: tribeId,
      data: {'joinedAt': DateTime.now().toIso8601String()},
    );
  }

  @override
  Future<void> leaveClub(String userId, String tribeId) async {
    await _db.tribeStatsDao.incrementMemberCount(tribeId, delta: -1);
    await _syncEngine.enqueueMutation(
      collectionPath: 'users/$userId/tribes',
      documentId: tribeId,
      operation: 'delete',
    );
  }

  @override
  Future<List<Tribe>> getUserTribes(String userId) async {
    final rows = await _db.tribeStatsDao.getAll();
    return rows.map(_rowToTribe).toList();
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
