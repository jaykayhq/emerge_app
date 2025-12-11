import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/services/event_bus.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:fpdart/fpdart.dart';

class FirestoreHabitRepository implements HabitRepository {
  final FirebaseFirestore _firestore;

  FirestoreHabitRepository(this._firestore);

  @override
  Stream<List<Habit>> watchHabits(String userId) {
    return _firestore
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Habit(
              id: doc.id,
              userId: data['userId'] as String,
              title: data['title'] as String,
              cue: data['cue'] as String,
              routine: data['routine'] as String,
              reward: data['reward'] as String,
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
                          (data['reminderTime']
                              as Map<String, dynamic>)['hour'],
                      minute:
                          (data['reminderTime']
                              as Map<String, dynamic>)['minute'],
                    )
                  : null,
              location: data['location'] as String?,
              isArchived: data['isArchived'] as bool,
              createdAt: (data['createdAt'] as Timestamp).toDate(),
              currentStreak: data['currentStreak'] as int? ?? 0,
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
            );
          }).toList();
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
      });
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

      final result = await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception('Habit not found');
        }

        final data = snapshot.data()!;
        userId = data['userId'] as String;
        final lastCompletedTimestamp = data['lastCompletedDate'] as Timestamp?;
        final currentStreak = data['currentStreak'] as int? ?? 0;

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
          return false;
        } else {
          // Complete
          transaction.update(docRef, {
            'currentStreak': currentStreak + 1,
            'lastCompletedDate': Timestamp.fromDate(date),
          });
          return true;
        }
      });

      if (result && userId != null) {
        EventBus().fire(
          HabitCompleted(habitId: habitId, userId: userId!, date: date),
        );
      }

      return Right(result);
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
        final data = doc.data()!;
        return Habit(
          id: doc.id,
          userId: data['userId'] as String,
          title: data['title'] as String,
          cue: data['cue'] as String,
          routine: data['routine'] as String,
          reward: data['reward'] as String,
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
          isArchived: data['isArchived'] as bool,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          currentStreak: data['currentStreak'] as int? ?? 0,
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
          anchorHabitId: data['anchorHabitId'] as String?,
          identityTags:
              (data['identityTags'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
        );
      }
      return null;
    } catch (e, s) {
      AppLogger.e('Get habit failed', e, s);
      return null;
    }
  }
}
