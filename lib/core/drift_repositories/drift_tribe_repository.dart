import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/features/social/data/repositories/tribe_repository.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';

class DriftTribeRepository implements TribeRepository {
  final AppDatabase _db;
  final EnhancedSyncEngine _syncEngine;

  DriftTribeRepository(this._db, this._syncEngine);

  @override
  Future<Tribe?> getArchetypeClub(String archetypeId) async {
    final tribe = await _db.tribeStatsDao.getStats(archetypeId);
    if (tribe == null) return null;
    return _rowToTribe(tribe);
  }

  @override
  Future<List<Tribe>> getArchetypeClubs() async {
    final rows = await (select(_db.tribeStatsTable)).get();
    return rows.map(_rowToTribe).toList();
  }

  @override
  Stream<List<Tribe>> watchArchetypeClubs() {
    return (select(_db.tribeStatsTable)).watch().map((rows) {
      return rows.map(_rowToTribe).toList();
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getClubContributors(
    String tribeId, {int limit = 10},
  ) async {
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getClubActivity(
    String tribeId, {int limit = 20},
  ) async {
    return [];
  }

  @override
  Future<void> joinClub(String userId, String tribeId) async {
    await _syncEngine.enqueueUpdate(
      collectionPath: 'users/$userId/tribes',
      documentId: tribeId,
      data: {'joinedAt': DateTime.now().toIso8601String()},
    );
  }

  @override
  Future<void> leaveClub(String userId, String tribeId) async {
    await _syncEngine.enqueueMutation(
      collectionPath: 'users/$userId/tribes',
      documentId: tribeId,
      operation: 'delete',
    );
  }

  @override
  Future<List<Tribe>> getUserTribes(String userId) async {
    return [];
  }

  @override
  Future<void> seedTribesIfEmpty() async {}

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
