import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/services/event_bus.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/models/habit_activity.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:fpdart/fpdart.dart';

class FirestoreHabitRepository implements HabitRepository {
  final FirebaseFirestore _firestore;

  FirestoreHabitRepository(this._firestore);

  /// Defensive mapping from a Firestore document to a [Habit] entity.
  /// Uses null coalescing on all fields to prevent crashes on malformed data.
  Habit _mapDocToHabit(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Habit(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      cue: (data['cue'] as String?) ?? '',
      routine: (data['routine'] as String?) ?? '',
      reward: (data['reward'] as String?) ?? '',
      frequency: HabitFrequency.values.firstWhere(
        (e) => e.toString() == data['frequency'],
        orElse: () => HabitFrequency.daily,
      ),
      specificDays:
          (data['specificDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      difficulty: HabitDifficulty.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => HabitDifficulty.medium,
      ),
      reminderTime: data['reminderTime'] != null
          ? TimeOfDay(
              hour:
                  (data['reminderTime'] as Map<String, dynamic>)['hour']
                      as int? ??
                  0,
              minute:
                  (data['reminderTime'] as Map<String, dynamic>)['minute']
                      as int? ??
                  0,
            )
          : null,
      location: data['location'] as String?,
      isArchived: (data['isArchived'] as bool?) ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      currentStreak: data['currentStreak'] as int? ?? 0,
      longestStreak: data['longestStreak'] as int? ?? 0,
      lastCompletedDate: data['lastCompletedDate'] != null
          ? (data['lastCompletedDate'] as Timestamp).toDate()
          : null,
      attribute: HabitAttribute.values.firstWhere(
        (e) => e.name == data['attribute'],
        orElse: () => HabitAttribute.vitality,
      ),
      imageUrl: data['imageUrl'] as String?,
      timeOfDayPreference: data['timeOfDayPreference'] != null
          ? TimeOfDayPreference.values.firstWhere(
              (e) => e.name == data['timeOfDayPreference'],
              orElse: () => TimeOfDayPreference.anytime,
            )
          : null,
      impact: HabitImpact.values.firstWhere(
        (e) => e.name == data['impact'],
        orElse: () => HabitImpact.neutral,
      ),
      order: data['order'] as int? ?? 0,
      anchorHabitId: data['anchorHabitId'] as String?,
      identityTags:
          (data['identityTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      timerDurationMinutes: data['timerDurationMinutes'] as int? ?? 2,
      customRules:
          (data['customRules'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  @override
  Stream<List<Habit>> watchHabits(String userId) {
    // ENHANCED: Optimized query with better filtering and ordering
    return _firestore
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .where(
          'isArchived',
          isEqualTo: false,
        ) // Filter at source for efficiency
        .orderBy('order') // Order by custom sort field
        .orderBy('createdAt', descending: true) // Secondary sort
        .limit(50) // Reduced limit for better performance
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => _mapDocToHabit(doc)).toList();
        });
  }

  @override
  Future<Either<Failure, Unit>> createHabit(Habit habit) async {
    try {
      await _firestore.collection('habits').doc(habit.id).set({
        'userId': habit.userId,
        'title': habit.title,
        'cue': habit.cue,
        'routine': habit.routine,
        'reward': habit.reward,
        'frequency': habit.frequency.toString(),
        'specificDays': habit.specificDays,
        'difficulty': habit.difficulty.name,
        'reminderTime': habit.reminderTime != null
            ? {
                'hour': habit.reminderTime!.hour,
                'minute': habit.reminderTime!.minute,
              }
            : null,
        'location': habit.location,
        'isArchived': habit.isArchived,
        'createdAt': Timestamp.fromDate(habit.createdAt),
        'currentStreak': habit.currentStreak,
        'longestStreak': habit.longestStreak,
        'lastCompletedDate': habit.lastCompletedDate != null
            ? Timestamp.fromDate(habit.lastCompletedDate!)
            : null,
        'attribute': habit.attribute.name,
        'imageUrl': habit.imageUrl,
        'timeOfDayPreference': habit.timeOfDayPreference?.name,
        'impact': habit.impact.name,
        'order': habit.order,
        'anchorHabitId': habit.anchorHabitId,
        'identityTags': habit.identityTags,
        'timerDurationMinutes': habit.timerDurationMinutes,
        'customRules': habit.customRules,
        'twoMinuteVersion': habit.twoMinuteVersion,
      });

      // Log success for debugging
      AppLogger.i(
        'Successfully created habit: ${habit.id} for user: ${habit.userId}',
      );

      return const Right(unit);
    } catch (e, s) {
      AppLogger.e('Create habit failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateHabit(Habit habit) async {
    try {
      await _firestore.collection('habits').doc(habit.id).update({
        'title': habit.title,
        'cue': habit.cue,
        'routine': habit.routine,
        'reward': habit.reward,
        'frequency': habit.frequency.toString(),
        'specificDays': habit.specificDays,
        'difficulty': habit.difficulty.name,
        'reminderTime': habit.reminderTime != null
            ? {
                'hour': habit.reminderTime!.hour,
                'minute': habit.reminderTime!.minute,
              }
            : null,
        'location': habit.location,
        'isArchived': habit.isArchived,
        'attribute': habit.attribute.name,
        'imageUrl': habit.imageUrl,
        'timeOfDayPreference': habit.timeOfDayPreference?.name,
        'impact': habit.impact.name,
        'order': habit.order,
        'anchorHabitId': habit.anchorHabitId,
        'identityTags': habit.identityTags,
        'timerDurationMinutes': habit.timerDurationMinutes,
        'customRules': habit.customRules,
        'twoMinuteVersion': habit.twoMinuteVersion,
      });
      return const Right(unit);
    } catch (e, s) {
      AppLogger.e('Update habit failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteHabit(String habitId) async {
    try {
      await _firestore.collection('habits').doc(habitId).delete();
      return const Right(unit);
    } catch (e, s) {
      AppLogger.e('Delete habit failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> completeHabit(
    String habitId,
    DateTime date,
  ) async {
    try {
      final docRef = _firestore.collection('habits').doc(habitId);
      String? userId;

      final completionData = await _firestore.runTransaction((
        transaction,
      ) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception('Habit not found');
        }

        final data = snapshot.data()!;
        userId = data['userId'] as String;
        final lastCompletedTimestamp = data['lastCompletedDate'] as Timestamp?;
        final currentStreak = data['currentStreak'] as int? ?? 0;
        final longestStreak = data['longestStreak'] as int? ?? 0;

        final lastCompletedDate = lastCompletedTimestamp?.toDate();
        final isCompletedToday =
            lastCompletedDate != null &&
            lastCompletedDate.year == date.year &&
            lastCompletedDate.month == date.month &&
            lastCompletedDate.day == date.day;

        if (isCompletedToday) {
          // Undo completion
          transaction.update(docRef, {
            'currentStreak': currentStreak > 0 ? currentStreak - 1 : 0,
            'lastCompletedDate': null,
          });
          return null; // Signals undo
        } else {
          // Complete
          final newCurrentStreak = currentStreak + 1;
          final newLongestStreak = newCurrentStreak > longestStreak
              ? newCurrentStreak
              : longestStreak;

          transaction.update(docRef, {
            'currentStreak': newCurrentStreak,
            'longestStreak': newLongestStreak,
            'lastCompletedDate': Timestamp.fromDate(date),
          });

          return {
            'userId': userId,
            'difficulty': data['difficulty'],
            'attribute': data['attribute'],
            'streakDay': newCurrentStreak,
          };
        }
      });

      if (completionData != null) {
        final uid = completionData['userId'] as String;
        EventBus().fire(
          HabitCompleted(habitId: habitId, userId: uid, date: date),
        );

        try {
          await _firestore.collection('user_activity').add({
            'userId': uid,
            'habitId': habitId,
            'date': Timestamp.fromDate(date),
            'type': 'habit_completion',
            'difficulty': completionData['difficulty'],
            'attribute': completionData['attribute'],
            'streakDay': completionData['streakDay'],
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (activityError, activityStack) {
          AppLogger.e(
            'Failed to log activity for habit completion',
            activityError,
            activityStack,
          );
        }
      }

      AppLogger.i('Successfully completed habit: $habitId for user: $userId');
      return Right(completionData != null);
    } catch (e, s) {
      AppLogger.e('Complete habit failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Habit?> getHabit(String habitId) async {
    try {
      final doc = await _firestore.collection('habits').doc(habitId).get();
      if (doc.exists && doc.data() != null) {
        return _mapDocToHabit(doc);
      }
      return null;
    } catch (e, s) {
      AppLogger.e('Get habit failed', e, s);
      return null;
    }
  }

  @override
  Future<List<Habit>> getHabitsByAnchor(String anchorHabitId) async {
    try {
      final snapshot = await _firestore
          .collection('habits')
          .where('anchorHabitId', isEqualTo: anchorHabitId)
          .get();

      return snapshot.docs.map((doc) => _mapDocToHabit(doc)).toList();
    } catch (e, s) {
      AppLogger.e('Get habits by anchor failed', e, s);
      return [];
    }
  }

  @override
  Future<List<HabitActivity>> getActivity(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('user_activity')
          .where('userId', isEqualTo: userId)
          // Set start to beginning of day
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime(start.year, start.month, start.day),
            ),
          )
          // Set end to end of day
          .where(
            'date',
            isLessThanOrEqualTo: Timestamp.fromDate(
              DateTime(end.year, end.month, end.day, 23, 59, 59),
            ),
          )
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return HabitActivity.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e, s) {
      AppLogger.e('Get activity failed', e, s);
      return [];
    }
  }
}
