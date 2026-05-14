import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/models/habit_activity.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:fpdart/fpdart.dart';

/// Firestore-backed implementation of [HabitRepository].
///
/// Used on web platforms where Drift/SQLite is not available.
/// Reads from the `habits` collection and `habit_completions`
/// subcollection, with no local game loop processing.
/// Habit completion streaks and momentum are managed server-side.
class FirestoreHabitRepository implements HabitRepository {
  final FirebaseFirestore _firestore;

  FirestoreHabitRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Stream<List<Habit>> watchHabits(String userId) {
    return _firestore
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .where('isArchived', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => _docToHabit(doc))
          .where((h) => h != null)
          .cast<Habit>()
          .toList();
    });
  }

  @override
  Future<Either<Failure, Unit>> createHabit(Habit habit) async {
    try {
      await _firestore.collection('habits').doc(habit.id).set(habit.toMap());
      return const Right(unit);
    } catch (e, _) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateHabit(Habit habit) async {
    try {
      await _firestore
          .collection('habits')
          .doc(habit.id)
          .set(habit.toMap(), SetOptions(merge: true));
      return const Right(unit);
    } catch (e, _) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteHabit(String habitId) async {
    try {
      await _firestore
          .collection('habits')
          .doc(habitId)
          .update({'isArchived': true});
      return const Right(unit);
    } catch (e, _) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> completeHabit(
    String habitId,
    DateTime date,
  ) async {
    try {
      await _firestore.collection('habit_completions').add({
        'habitId': habitId,
        'date': date,
        'type': 'habit_completion',
      });
      return const Right(true);
    } catch (e, _) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Habit?> getHabit(String habitId) async {
    final doc =
        await _firestore.collection('habits').doc(habitId).get();
    if (!doc.exists || doc.data() == null) return null;
    return _docToHabit(doc);
  }

  @override
  Future<List<Habit>> getHabitsByAnchor(String anchorHabitId) async {
    final snapshot = await _firestore
        .collection('habits')
        .where('anchorHabitId', isEqualTo: anchorHabitId)
        .get();

    return snapshot.docs
        .map((doc) => _docToHabit(doc))
        .where((h) => h != null)
        .cast<Habit>()
        .toList();
  }

  @override
  Future<List<HabitActivity>> getActivity(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _firestore
        .collectionGroup('habit_completions')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .get();

    return snapshot.docs
        .map((doc) => HabitActivity.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<Either<Failure, Unit>> createHabitsFromBlueprint({
    required String userId,
    required Blueprint blueprint,
    String? reminderTime,
  }) async {
    try {
      final batch = _firestore.batch();
      final habitsCollection = _firestore.collection('habits');

      for (int i = 0; i < blueprint.habits.length; i++) {
        final blueprintHabit = blueprint.habits[i];
        final habitId =
            '${blueprint.id}_${i}_${DateTime.now().millisecondsSinceEpoch}';
        final docRef = habitsCollection.doc(habitId);

        final data = <String, dynamic>{
          'id': habitId,
          'userId': userId,
          'title': blueprintHabit.title,
          'attribute': blueprintHabit.attribute.name,
          'isArchived': false,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'order': i,
        };

        if (reminderTime != null) {
          data['reminderTime'] = reminderTime;
        }

        batch.set(docRef, data);
      }

      await batch.commit();
      return const Right(unit);
    } catch (e, _) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Converts a Firestore [DocumentSnapshot] to a [Habit] entity.
  ///
  /// Handles Timestamp-to-string conversion for fields that
  /// [Habit.fromMap] expects as ISO-8601 strings. Works for both
  /// [DocumentSnapshot] and [QueryDocumentSnapshot] since the latter
  /// implements the former.
  Habit? _docToHabit(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;

    // Convert Timestamp fields to ISO strings for Habit.fromMap
    final processedData = Map<String, dynamic>.from(data);

    if (processedData['createdAt'] is Timestamp) {
      processedData['createdAt'] =
          (processedData['createdAt'] as Timestamp).toDate().toIso8601String();
    }

    if (processedData['lastCompletedDate'] is Timestamp) {
      processedData['lastCompletedDate'] =
          (processedData['lastCompletedDate'] as Timestamp)
              .toDate()
              .toIso8601String();
    }

    return Habit.fromMap(processedData);
  }
}
