import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/domain/models/challenge_catalog.dart';
import 'package:emerge_app/features/social/domain/repositories/challenge_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Firestore-backed implementation of [ChallengeRepository].
///
/// Used on web platforms where Drift/SQLite is not available.
/// Reads challenge templates from the `challenges` collection and
/// user progress from `users/{userId}/challenges`.
/// Falls back to [ChallengeCatalog] for static templates when the
/// Firestore collection is empty.
class FirestoreChallengeRepository implements ChallengeRepository {
  final FirebaseFirestore _firestore;
  bool _seeded = false;

  FirestoreChallengeRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<List<Challenge>> getChallenges({bool featuredOnly = false}) async {
    try {
      final challengesRef = _firestore.collection('challenges');
      Query<Map<String, dynamic>> query = challengesRef;
      if (featuredOnly) {
        query = query.where('isFeatured', isEqualTo: true);
      }
      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) {
          return Challenge.fromMap(doc.data(), id: doc.id);
        }).toList();
      }

      // Fallback to static catalog if Firestore is empty
      await seedChallengesIfEmpty();
      return ChallengeCatalog.getFeatured();
    } catch (_) {
      // If Firestore is unreachable, use catalog
      return ChallengeCatalog.getFeatured();
    }
  }

  @override
  Future<List<Challenge>> getUserChallenges(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('challenges')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Enrich with template data from catalog
        final template = ChallengeCatalog.getChallengeById(doc.id);
        return Challenge(
          id: doc.id,
          title: data['title'] as String? ?? template?.title ?? '',
          description: template?.description ?? '',
          imageUrl: template?.imageUrl ?? '',
          reward: template?.reward ?? '',
          participants: template?.participants ?? 0,
          daysLeft: (data['totalDays'] as int? ?? 14) -
              (data['currentDay'] as int? ?? 0),
          totalDays: data['totalDays'] as int? ?? 14,
          currentDay: data['currentDay'] as int? ?? 0,
          status: ChallengeStatus.values.firstWhere(
            (e) => e.name == (data['status'] as String? ?? 'active'),
            orElse: () => ChallengeStatus.active,
          ),
          xpReward: data['xpReward'] as int? ?? template?.xpReward ?? 0,
          steps: template?.steps ?? [],
          archetypeId: template?.archetypeId,
          category: template?.category ?? ChallengeCategory.all,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Either<Failure, Unit>> joinChallenge(
    String userId,
    String challengeId,
  ) async {
    try {
      // Verify challenge exists
      final challenge = ChallengeCatalog.getChallengeById(challengeId);
      if (challenge == null) {
        return const Left(ServerFailure('Challenge not found'));
      }

      final now = DateTime.now();
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('challenges')
          .doc(challengeId)
          .set({
        'challengeId': challengeId,
        'userId': userId,
        'title': challenge.title,
        'totalDays': challenge.totalDays,
        'xpReward': challenge.xpReward,
        'joinedAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'status': 'active',
        'currentDay': 0,
      });

      // Add participant to challenge
      await _firestore
          .collection('challenges')
          .doc(challengeId)
          .collection('participants')
          .doc(userId)
          .set({
        'userId': userId,
        'joinedAt': Timestamp.fromDate(now),
        'currentDay': 0,
        'status': 'active',
      });

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateProgress(
    String userId,
    String challengeId,
    int progress,
  ) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('challenges')
          .doc(challengeId);

      final doc = await docRef.get();
      if (!doc.exists) {
        return const Left(ServerFailure('Challenge not found'));
      }

      final data = doc.data()!;
      final totalDays = data['totalDays'] as int? ?? 14;
      final xpReward = data['xpReward'] as int? ?? 0;
      final currentDay = data['currentDay'] as int? ?? 0;
      final newDay = (currentDay + progress).clamp(0, totalDays);
      final isCompleted = newDay >= totalDays;
      final status = isCompleted ? 'completed' : 'active';
      final rewardAwarded = isCompleted ? xpReward : 0;

      await docRef.update({
        'currentDay': newDay,
        'status': status,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update participant progress in challenge
      await _firestore
          .collection('challenges')
          .doc(challengeId)
          .collection('participants')
          .doc(userId)
          .update({
        'currentDay': newDay,
        'status': status,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Award XP if completed
      if (rewardAwarded > 0) {
        final statsRef = _firestore.collection('user_stats').doc(userId);
        await statsRef.set({
          'totalXp': FieldValue.increment(rewardAwarded),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        }, SetOptions(merge: true));
      }

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> completeChallengeWithReward(
    String userId,
    String challengeId,
  ) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('challenges')
          .doc(challengeId);

      final doc = await docRef.get();
      if (!doc.exists) {
        return const Left(ServerFailure('Challenge not found'));
      }

      final xpReward = doc.data()!['xpReward'] as int? ?? 0;
      await docRef.update({
        'status': 'completed',
        'currentDay': FieldValue.increment(0),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Award XP
      if (xpReward > 0) {
        await _firestore.collection('user_stats').doc(userId).set({
          'totalXp': FieldValue.increment(xpReward),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        }, SetOptions(merge: true));
      }

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<List<Challenge>> getChallengesByArchetype(String archetypeId) async {
    try {
      final snapshot = await _firestore
          .collection('challenges')
          .where('archetypeId', isEqualTo: archetypeId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => Challenge.fromMap(doc.data(), id: doc.id))
            .toList();
      }
    } catch (_) {
      // Fall through to catalog
    }
    return ChallengeCatalog.getAvailableChallenges(archetypeId);
  }

  @override
  Future<Challenge?> getWeeklySpotlight({String? archetypeId}) async {
    if (archetypeId == null) return null;

    try {
      final snapshot = await _firestore
          .collection('challenges')
          .where('archetypeId', isEqualTo: archetypeId)
          .where('isFeatured', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Challenge.fromMap(snapshot.docs.first.data(),
            id: snapshot.docs.first.id);
      }
    } catch (_) {
      // Fall through to catalog
    }
    return ChallengeCatalog.getWeeklySpotlight(archetypeId);
  }

  @override
  Future<Challenge?> getChallengeById(String id) async {
    try {
      final doc = await _firestore.collection('challenges').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return Challenge.fromMap(doc.data()!, id: doc.id);
      }
    } catch (_) {
      // Fall through to catalog
    }
    return ChallengeCatalog.getChallengeById(id);
  }

  @override
  Future<List<Map<String, dynamic>>> getLeaderboard(
    String challengeId, {
    int limit = 3,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('challenges')
          .doc(challengeId)
          .collection('participants')
          .orderBy('currentDay', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> completeChallenge(String userId, String challengeId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('challenges')
        .doc(challengeId)
        .update({
      'status': 'completed',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> createSoloChallenge(String userId, Challenge challenge) async {
    final now = DateTime.now();
    final nowTimestamp = Timestamp.fromDate(now);

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('challenges')
        .doc(challenge.id)
        .set({
      'challengeId': challenge.id,
      'userId': userId,
      'title': challenge.title,
      'totalDays': challenge.totalDays,
      'xpReward': challenge.xpReward,
      'joinedAt': nowTimestamp,
      'updatedAt': nowTimestamp,
      'status': 'active',
      'currentDay': 0,
      'isSolo': true,
    });
  }

  @override
  Future<void> seedChallengesIfEmpty() async {
    if (_seeded) return;

    try {
      final snapshot = await _firestore.collection('challenges').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        _seeded = true;
        return;
      }

      // Seed from static catalog
      final batch = _firestore.batch();
      final challenges = ChallengeCatalog.getFeatured();
      for (final challenge in challenges) {
        final docRef = _firestore.collection('challenges').doc(challenge.id);
        batch.set(docRef, {
          ...challenge.toMap(),
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      // Also seed archetype-specific challenges
      final archetypeIds = [
        'athlete',
        'creator',
        'scholar',
        'stoic',
        'zealot',
      ];
      for (final archetypeId in archetypeIds) {
        final archetypeChallenges =
            ChallengeCatalog.getAvailableChallenges(archetypeId);
        for (final challenge in archetypeChallenges) {
          if (!challenges.any((c) => c.id == challenge.id)) {
            final docRef =
                _firestore.collection('challenges').doc(challenge.id);
            batch.set(docRef, {
              ...challenge.toMap(),
              'createdAt': Timestamp.fromDate(DateTime.now()),
            });
          }
        }
      }

      await batch.commit();
      _seeded = true;
    } catch (_) {
      // Silently handle — will fall back to catalog
      _seeded = true;
    }
  }
}
