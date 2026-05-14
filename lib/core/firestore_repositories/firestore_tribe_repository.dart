import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/data/seeds/official_clubs_seed.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/data/repositories/tribe_repository.dart';

/// Firestore-backed implementation of [TribeRepository].
///
/// Used on web platforms where Drift/SQLite is not available.
/// Operates directly on the `tribes` Firestore collection and its
/// `contributors` / `activity` subcollections, with no local
/// database layer.
///
/// Matches the interface of [DriftTribeRepository] but reads/writes
/// directly to Firestore using atomic batches where appropriate.
class FirestoreTribeRepository implements TribeRepository {
  final FirebaseFirestore _firestore;
  bool _seeded = false;

  FirestoreTribeRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

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
    final tribeRef = _firestore.collection('tribes').doc(tribeId);

    // Verify the club exists before joining
    final snapshot = await tribeRef.get();
    if (!snapshot.exists) {
      throw Exception('Club does not exist!');
    }

    final batch = _firestore.batch();

    // 1. Write contributor record
    final contributorRef = tribeRef.collection('contributors').doc(userId);
    batch.set(contributorRef, {
      'userId': userId,
      'joinedAt': FieldValue.serverTimestamp(),
      'contributionCount': 0,
      'totalHabitsCompleted': 0,
      'totalXpContributed': 0,
    }, SetOptions(merge: true));

    // 2. Record membership in the user's subcollection
    final userTribeRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('tribes')
        .doc(tribeId);
    batch.set(userTribeRef, {
      'tribeId': tribeId,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    // 3. Update Tribe document atomically
    batch.update(tribeRef, {
      'members': FieldValue.arrayUnion([userId]),
      'memberCount': FieldValue.increment(1),
      'lastStatsSync': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Future<void> leaveClub(String userId, String tribeId) async {
    final tribeRef = _firestore.collection('tribes').doc(tribeId);

    // 1. Remove user's tribe membership record
    final userTribeRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('tribes')
        .doc(tribeId);
    await userTribeRef.delete();

    // 2. Update Tribe document atomically
    await tribeRef.update({
      'members': FieldValue.arrayRemove([userId]),
      'memberCount': FieldValue.increment(-1),
      'lastStatsSync': FieldValue.serverTimestamp(),
    });
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
  Future<void> seedTribesIfEmpty() async {
    if (_seeded) return;

    final snapshot = await _firestore.collection('tribes').limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      _seeded = true;
      return;
    }

    final seedData = OfficialClubsSeed.getOfficialClubsMap();
    final batch = _firestore.batch();
    for (final entry in seedData.entries) {
      final docRef = _firestore.collection('tribes').doc(entry.key);
      batch.set(docRef, entry.value);
    }
    await batch.commit();
    _seeded = true;
  }
}
