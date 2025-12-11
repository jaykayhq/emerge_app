import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/social/data/repositories/social_repository.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:emerge_app/features/social/domain/models/social_post.dart';
import 'package:fpdart/fpdart.dart';

class FirestoreSocialRepository implements SocialRepository {
  final FirebaseFirestore _firestore;

  FirestoreSocialRepository(this._firestore);

  @override
  Future<Either<Failure, List<Tribe>>> getTribes({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      var query = _firestore
          .collection('tribes')
          .orderBy('memberCount', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final tribes = snapshot.docs.map((doc) {
        final data = doc.data();
        return Tribe(
          id: doc.id,
          name: (data['name'] as String?) ?? 'Unknown Tribe',
          description: (data['description'] as String?) ?? '',
          memberCount: (data['memberCount'] as int?) ?? 0,
          imageUrl: (data['imageUrl'] as String?) ?? '',
        );
      }).toList();
      return Right(tribes);
    } catch (e, s) {
      AppLogger.e('Get tribes failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Challenge>>> getActiveChallenges({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      var query = _firestore
          .collection('challenges')
          .where('isActive', isEqualTo: true)
          .orderBy('participants', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final challenges = snapshot.docs.map((doc) {
        final data = doc.data();
        return Challenge(
          id: doc.id,
          title: (data['title'] as String?) ?? 'Unknown Challenge',
          description: (data['description'] as String?) ?? '',
          participants: (data['participants'] as int?) ?? 0,
          daysLeft: (data['daysLeft'] as int?) ?? 0,
          imageUrl: (data['imageUrl'] as String?) ?? '',
        );
      }).toList();
      return Right(challenges);
    } catch (e, s) {
      AppLogger.e('Get active challenges failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> joinTribe(String tribeId, String userId) async {
    try {
      // Transaction to increment member count and add user to tribe members subcollection
      final tribeRef = _firestore.collection('tribes').doc(tribeId);
      final memberRef = tribeRef.collection('members').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final tribeSnapshot = await transaction.get(tribeRef);
        if (!tribeSnapshot.exists) {
          throw Exception("Tribe does not exist!");
        }

        transaction.set(memberRef, {'joinedAt': FieldValue.serverTimestamp()});
        transaction.update(tribeRef, {'memberCount': FieldValue.increment(1)});
      });
      return const Right(unit);
    } catch (e, s) {
      AppLogger.e('Join tribe failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> joinChallenge(
    String challengeId,
    String userId,
  ) async {
    try {
      final challengeRef = _firestore.collection('challenges').doc(challengeId);
      final participantRef = challengeRef
          .collection('participants')
          .doc(userId);

      await _firestore.runTransaction((transaction) async {
        final challengeSnapshot = await transaction.get(challengeRef);
        if (!challengeSnapshot.exists) {
          throw Exception("Challenge does not exist!");
        }

        transaction.set(participantRef, {
          'joinedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(challengeRef, {
          'participants': FieldValue.increment(1),
        });
      });
      return const Right(unit);
    } catch (e, s) {
      AppLogger.e('Join challenge failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<List<SocialPost>> getFeed() async {
    // Return mock data for now to satisfy the requirement
    // In a real app, this would query the 'posts' collection
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      SocialPost.mock(),
      SocialPost.mock().copyWith(
        id: '2',
        userName: 'David Goggins',
        content: 'Stay hard! 10 mile run completed.',
        likes: 450,
        type: PostType.habitCompletion,
      ),
    ];
  }

  @override
  Future<void> likePost(String postId) async {
    // Stub implementation
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> createPost(String content) async {
    // Stub implementation
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
