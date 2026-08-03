import 'package:emerge_app/features/social/domain/models/tribe.dart';

/// Repository for archetype-based clubs (tribes).
/// Users are auto-assigned to their archetype club — no user creation.
///
/// The only implementation is [DriftTribeRepository] (offline-first, bound
/// by `tribeRepositoryProvider`). The legacy FirestoreTribeRepository
/// implementation was deleted: it had zero instantiations in lib/test and
/// carried two latent bugs (joinClub writing zero contribution totals that
/// clobbered existing totals on rejoin, and getClubContributors ordering
/// contributors by a non-existent `xp` field).
abstract class TribeRepository {
  /// Get the official club for a specific archetype.
  Future<Tribe?> getArchetypeClub(String archetypeId);

  /// Get all official archetype clubs.
  Future<List<Tribe>> getArchetypeClubs();

  /// Watch all official archetype clubs.
  Stream<List<Tribe>> watchArchetypeClubs();

  /// Get top contributors for a club.
  Future<List<Map<String, dynamic>>> getClubContributors(
    String tribeId, {
    int limit = 10,
  });

  /// Get recent activity feed for a club.
  Future<List<Map<String, dynamic>>> getClubActivity(
    String tribeId, {
    int limit = 20,
  });

  /// Watch recent activity feed for a club.
  Stream<List<Map<String, dynamic>>> watchClubActivity(
    String tribeId, {
    int limit = 20,
  });

  /// Watch global activity feed.
  Stream<List<Map<String, dynamic>>> watchGlobalActivity({int limit = 30});

  /// Join a club (auto-called when user selects archetype).
  Future<void> joinClub(String userId, String tribeId);

  /// Leave a club (when user changes archetype).
  Future<void> leaveClub(String userId, String tribeId);

/// Get tribes that the user is a member of.
  Future<List<Tribe>> getUserTribes(String userId);

  /// Watch tribes that the user is a member of.
  Stream<List<Tribe>> watchUserTribes(String userId);

  /// Seeds official tribes if collection is empty.
  Future<void> seedTribesIfEmpty();
}
