import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feedback_repository.g.dart';

/// Persists low-rating feedback to feedback/{uid}. One doc per user (upsert).
class FeedbackRepository {
  final FirebaseFirestore _firestore;

  FeedbackRepository(this._firestore);

  Future<Either<Failure, void>> submitFeedback({
    required String userId,
    required int rating,
    required String message,
    String? appVersion,
    String? platform,
  }) async {
    try {
      // Null fields are rejected by Firestore, so optional metadata is only
      // included when present.
      await _firestore.collection('feedback').doc(userId).set({
        'userId': userId,
        'rating': rating,
        'message': message.trim(),
        'appVersion': ?appVersion,
        'platform': ?platform,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

@riverpod
FeedbackRepository feedbackRepository(Ref ref) {
  return FeedbackRepository(FirebaseFirestore.instance);
}
