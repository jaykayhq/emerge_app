import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/data/seeds/official_clubs_seed.dart';

/// Repository for archetype-based clubs (tribes).
/// Users are auto-assigned to their archetype club — no user creation.
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

  /// Seeds official clubs if collection is empty.
  Future<void> seedTribesIfEmpty();
}

class FirestoreTribeRepository implements TribeRepository {
  final FirebaseFirestore _firestore;

  FirestoreTribeRepository(this._firestore);

  @override
  Future<void> seedTribesIfEmpty() async {
    final snapshot = await _firestore.collection('tribes').limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final seedData = OfficialClubsSeed.getOfficialClubsMap();
    final batch = _firestore.batch();
    for (final entry in seedData.entries) {
      final docRef = _firestore.collection('tribes').doc(entry.key);
      batch.set(docRef, entry.value);
    }
    await batch.commit();
    AppLogger.i('Seeded official tribes');
  }

  @override
  Future<Tribe?> getArchetypeClub(String archetypeId) async {
    final snapshot = await _firestore
        .collection('tribes')
        .where('archetypeId', isEqualTo: archetypeId)
        .where('type', isEqualTo: TribeType.official.name)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Tribe.fromMap(snapshot.docs.first.data());
  }

  @override
  Future<List<Tribe>> getArchetypeClubs() async {
    final snapshot = await _firestore
        .collection('tribes')
        .where('type', isEqualTo: TribeType.official.name)
        .orderBy('archetypeId')
        .get();

    return snapshot.docs.map((doc) => Tribe.fromMap(doc.data())).toList();
  }

  @override
  Stream<List<Tribe>> watchArchetypeClubs() {
    return _firestore
        .collection('tribes')
        .where('type', isEqualTo: TribeType.official.name)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Tribe.fromMap(doc.data())).toList(),
        );
  }

  @override
  Future<List<Map<String, dynamic>>> getClubContributors(
    String tribeId, {
    int limit = 10,
  }) async {
    final snapshot = await _firestore
        .collection('tribes')
        .doc(tribeId)
        .collection('contributors')
        .orderBy('xp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getClubActivity(
    String tribeId, {
    int limit = 20,
  }) async {
    final snapshot = await _firestore
        .collection('tribes')
        .doc(tribeId)
        .collection('activity')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchClubActivity(
    String tribeId, {
    int limit = 20,
  }) {
    return _firestore
        .collection('tribes')
        .doc(tribeId)
        .collection('activity')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  @override
  Stream<List<Map<String, dynamic>>> watchGlobalActivity({int limit = 30}) {
    return _firestore
        .collection('global_activities')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  @override
  Future<void> joinClub(String userId, String tribeId) async {
    try {
      final tribeRef = _firestore.collection('tribes').doc(tribeId);

      // Verify the club exists before joining
      final snapshot = await tribeRef.get();
      if (!snapshot.exists) {
        AppLogger.e('Tribe $tribeId does not exist!');
        throw Exception('Club does not exist!');
      }

      final batch = _firestore.batch();

      // 1. Write contributor record (allowed: auth.uid == memberId)
      final contributorRef = tribeRef.collection('contributors').doc(userId);
      batch.set(contributorRef, {
        'userId': userId,
        'joinedAt': FieldValue.serverTimestamp(),
        'contributionCount': 0,
        'totalHabitsCompleted': 0,
        'totalXpContributed': 0,
      }, SetOptions(merge: true));

      // 2. Record membership in the user's own subcollection (allowed: isOwner)
      final userTribeRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tribes')
          .doc(tribeId);
      batch.set(userTribeRef, {
        'tribeId': tribeId,
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // 3. Update Tribe document atomically (allowed by new firestore.rules)
      batch.update(tribeRef, {
        'members': FieldValue.arrayUnion([userId]),
        'memberCount': FieldValue.increment(1),
        'lastStatsSync': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      AppLogger.i('User $userId joined tribe $tribeId successfully');
    } catch (e) {
      AppLogger.e('Error joining tribe $tribeId', e);
      rethrow;
    }
  }

  @override
  Future<List<Tribe>> getUserTribes(String userId) async {
    final snapshot = await _firestore
        .collection('tribes')
        .where('members', arrayContains: userId)
        .get();

    return snapshot.docs.map((doc) => Tribe.fromMap(doc.data())).toList();
  }

  @override
  Future<void> leaveClub(String userId, String tribeId) async {
    // 1. Remove user's own tribe membership record (allowed: isOwner)
    final userTribeRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('tribes')
        .doc(tribeId);
    await userTribeRef.delete();

    // 2. Update Tribe document atomically (allowed by new firestore.rules)
    final tribeRef = _firestore.collection('tribes').doc(tribeId);
    await tribeRef.update({
      'members': FieldValue.arrayRemove([userId]),
      'memberCount': FieldValue.increment(-1),
      'lastStatsSync': FieldValue.serverTimestamp(),
    });
  }
}
