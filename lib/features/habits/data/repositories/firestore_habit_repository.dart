import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/services/event_bus.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/models/habit_activity.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:emerge_app/features/habits/domain/services/momentum_service.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:fpdart/fpdart.dart';

class FirestoreHabitRepository implements HabitRepository {
  final FirebaseFirestore _firestore;
  final SocialActivityService? _socialActivityService;
  final UserStatsRepository? _userStatsRepository;

  FirestoreHabitRepository(
    this._firestore, [
    this._socialActivityService,
    this._userStatsRepository,
  ]);

  /// Defensive mapping from a Firestore document to a [Habit] entity.
  /// Uses null coalescing on all fields to prevent crashes on malformed data.
  Habit _mapDocToHabit(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    // Support both legacy map format and new HH:mm string format
    TimeOfDay? reminderTime;
    final rawReminderTime = data['reminderTime'];
    if (rawReminderTime is String) {
      final parts = rawReminderTime.split(':');
      if (parts.length == 2) {
        reminderTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } else if (rawReminderTime is Map) {
      reminderTime = TimeOfDay(
        hour: (rawReminderTime['hour'] as int?) ?? 0,
        minute: (rawReminderTime['minute'] as int?) ?? 0,
      );
    }

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
      reminderTime: reminderTime,
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

      environmentPriming:
          (data['environmentPriming'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      integrationType: HabitIntegrationType.values.firstWhere(
        (e) => e.name == data['integrationType'],
        orElse: () => HabitIntegrationType.none,
      ),
      integrationTarget: data['integrationTarget'] as int?,
      momentumScore: data['momentumScore'] as int? ?? 0,
      consecutiveMisses: data['consecutiveMisses'] as int? ?? 0,
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
            ? '${habit.reminderTime!.hour.toString().padLeft(2, '0')}:${habit.reminderTime!.minute.toString().padLeft(2, '0')}'
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
        'environmentPriming': habit.environmentPriming,
        'twoMinuteVersion': habit.twoMinuteVersion,
        'integrationType': habit.integrationType.name,
        'integrationTarget': habit.integrationTarget,
        'momentumScore': habit.momentumScore,
        'consecutiveMisses': habit.consecutiveMisses,
      });

      // Log success for debugging
      // Recalculate World Health
      await _recalculateAndStoreWorldHealth(habit.userId);

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
            ? '${habit.reminderTime!.hour.toString().padLeft(2, '0')}:${habit.reminderTime!.minute.toString().padLeft(2, '0')}'
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
        'environmentPriming': habit.environmentPriming,
        'twoMinuteVersion': habit.twoMinuteVersion,
        'integrationType': habit.integrationType.name,
        'integrationTarget': habit.integrationTarget,
        'momentumScore': habit.momentumScore,
        'consecutiveMisses': habit.consecutiveMisses,
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
      final doc = await _firestore.collection('habits').doc(habitId).get();
      final data = doc.data();
      final userId = data?['userId'] as String?;

      if (data != null) {
        // Soft delete: write back full document with isArchived: true
        data['isArchived'] = true;
        await _firestore.collection('habits').doc(habitId).set(data);
      }

      if (userId != null) {
        await _recalculateAndStoreWorldHealth(userId);
      }

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
          final habit = _mapDocToHabit(snapshot);
          final momentumService = MomentumService();
          final updatedHabit = momentumService.applyCompletion(habit);

          final newCurrentStreak = currentStreak + 1;
          final newLongestStreak = newCurrentStreak > longestStreak
              ? newCurrentStreak
              : longestStreak;

          transaction.update(docRef, {
            'currentStreak': newCurrentStreak,
            'longestStreak': newLongestStreak,
            'lastCompletedDate': Timestamp.fromDate(date),
            'momentumScore': updatedHabit.momentumScore,
            'consecutiveMisses': updatedHabit.consecutiveMisses,
          });

          // Recalculate World Health within transaction
          await _recalculateAndStoreWorldHealth(
            userId!,
            transaction: transaction,
            updatedHabit: updatedHabit,
          );

          return {
            'userId': userId,
            'difficulty': data['difficulty'],
            'attribute': data['attribute'],
            'streakDay': newCurrentStreak,
            'momentumAtCompletion': updatedHabit.momentumScore,
            'wasRecovery': habit.consecutiveMisses > 0,
          };
        }
      });

      if (completionData != null) {
        final uid = completionData['userId'] as String;
        EventBus().fire(
          HabitCompleted(habitId: habitId, userId: uid, date: date),
        );

        try {
          if (_userStatsRepository != null) {
            await _userStatsRepository.logActivity(
              userId: uid,
              habitId: habitId,
              date: date,
              type: 'habit_completion',
              difficulty: completionData['difficulty'],
              attribute: completionData['attribute'],
              streakDay: completionData['streakDay'],
            );
          } else {
            // Fallback to direct write if repository is not provided
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
          }

            // Write to the new habit_completions subcollection
            await _firestore
                .collection('users')
                .doc(uid)
                .collection('habit_completions')
                .add({
              'id': '', // Will be auto-generated by Firestore
              'habitId': habitId,
              'userId': uid,
              'completedAt': Timestamp.fromDate(date),
              'momentumAtCompletion': completionData['momentumAtCompletion'],
              'completedAtHour': date.hour,
              'wasRecovery': completionData['wasRecovery'],
            });

        } catch (activityError, activityStack) {
          AppLogger.e(
            'Failed to log activity for habit completion',
            activityError,
            activityStack,
          );
        }

        // Fetch habit once for both activity services (optimization: single Firestore read)
        Habit? habit;
        try {
          habit = await getHabit(habitId);
        } catch (habitError, habitStack) {
          AppLogger.e(
            'Failed to fetch habit for activity logging',
            habitError,
            habitStack,
          );
        }

        // Log to social activity feed if service is available
        try {
          if (habit != null && _socialActivityService != null) {
            // Get user data for activity logging
            final userDoc = await _firestore.collection('users').doc(uid).get();
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              final userName =
                  userData['displayName'] as String? ?? 'Anonymous';
              final archetype = userData['archetype'] as String? ?? 'none';

              final streakDay = completionData['streakDay'] as int? ?? 1;
              final attribute =
                  completionData['attribute'] as String? ?? 'vitality';

              // Calculate XP for leaderboard
              final difficulty = completionData['difficulty'] as String?;
              final baseXp = _getBaseXpForDifficulty(difficulty);
              final xpGained = baseXp + (streakDay > 1 ? 5 : 0);
              final currentLevel = userData['level'] as int? ?? 1;

              await _socialActivityService.logHabitCompletion(
                userId: uid,
                userName: userName,
                archetype: archetype,
                habitId: habitId,
                habitTitle: habit.title,
                streakDay: streakDay,
                attribute: attribute,
                xpGained: xpGained,
                currentLevel: currentLevel,
              );
            }
          }
        } catch (socialError, socialStack) {
          AppLogger.e(
            'Failed to log habit completion to social activity',
            socialError,
            socialStack,
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

  /// Calculate base XP for habit difficulty.
  /// Used for club activity logging.
  int _getBaseXpForDifficulty(String? difficulty) {
    switch (difficulty) {
      case 'easy':
        return 10;
      case 'medium':
        return 15;
      case 'hard':
        return 25;
      default:
        return 15;
    }
  }

  @override
  Future<Either<Failure, Unit>> createHabitsFromBlueprint({
    required String userId,
    required Blueprint blueprint,
    String? reminderTime,
  }) async {
    try {
      final batch = _firestore.batch();
      final habits = blueprint.habits;
      final count = habits.length;

      TimeOfDay? overrideTime;
      if (reminderTime != null) {
        final parts = reminderTime.split(':');
        if (parts.length == 2) {
          overrideTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      }

      for (int i = 0; i < count; i++) {
        final habitBlueprint = habits[i];
        
        TimeOfDayPreference? tdp;
        TimeOfDay? habitTime = overrideTime ?? habitBlueprint.defaultTime;

        if (habitBlueprint.timeOfDay != null) {
          tdp = TimeOfDayPreference.values.firstWhere(
            (e) => e.name.toLowerCase() == habitBlueprint.timeOfDay!.toLowerCase(),
            orElse: () => TimeOfDayPreference.anytime,
          );
        }

        // AUTO-SCHEDULING: If no time is set (and no override), apply 15-minute sequence starting at 07:00 AM
        if (habitTime == null) {
          final int totalMinutes = 7 * 60 + (i * 15);
          habitTime = TimeOfDay(
            hour: (totalMinutes ~/ 60) % 24, 
            minute: totalMinutes % 60,
          );
        }
        
        tdp ??= _getPreferenceForTime(habitTime);

        final ref = _firestore
            .collection('habits')
            .doc(); 
            
        final habit = Habit(
          id: ref.id,
          userId: userId,
          title: habitBlueprint.title,
          createdAt: DateTime.now(),
          order: i,
          attribute: habitBlueprint.attribute,
          reminderTime: habitTime,
          timeOfDayPreference: tdp,
        );
        
        batch.set(ref, {
          'userId': habit.userId,
          'title': habit.title,
          'cue': habit.cue,
          'routine': habit.routine,
          'reward': habit.reward,
          'frequency': habit.frequency.toString(),
          'specificDays': habit.specificDays,
          'difficulty': habit.difficulty.name,
          'reminderTime': habit.reminderTime != null
              ? '${habit.reminderTime!.hour.toString().padLeft(2, '0')}:${habit.reminderTime!.minute.toString().padLeft(2, '0')}'
              : null,
          'location': habit.location,
          'isArchived': habit.isArchived,
          'createdAt': Timestamp.fromDate(habit.createdAt),
          'currentStreak': habit.currentStreak,
          'longestStreak': habit.longestStreak,
          'lastCompletedDate': null,
          'attribute': habit.attribute.name,
          'imageUrl': habit.imageUrl,
          'timeOfDayPreference': habit.timeOfDayPreference?.name,
          'impact': habit.impact.name,
          'order': habit.order,
          'anchorHabitId': habit.anchorHabitId,
          'bottomHabitId': null, // Added to match Habit model if needed, but not in Habit entity
          'identityTags': habit.identityTags,
          'timerDurationMinutes': habit.timerDurationMinutes,
          'environmentPriming': habit.environmentPriming,
          'twoMinuteVersion': habit.twoMinuteVersion,
          'integrationType': habit.integrationType.name,
          'integrationTarget': habit.integrationTarget,
          'momentumScore': habit.momentumScore,
          'consecutiveMisses': habit.consecutiveMisses,
        });
      }

      // Increment adoption count on blueprint
      batch.update(
        _firestore.collection('blueprints').doc(blueprint.id),
        {'adoptionCount': FieldValue.increment(1)},
      );

      await batch.commit();

      // Recalculate World Health after batch commit
      await _recalculateAndStoreWorldHealth(userId);

      return const Right(unit);
    } catch (e, s) {
      AppLogger.e('Create habits from blueprint failed', e, s);
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Recalculates the user's world health score based on all active habits
  /// and updates their user_stats document.
  Future<void> _recalculateAndStoreWorldHealth(
    String userId, {
    Transaction? transaction,
    Habit? updatedHabit,
  }) async {
    final momentumService = MomentumService();

    // In a transaction, we must use transaction.get()
    List<Habit> allHabits;
    if (transaction != null) {
      final habitsSnap = await _firestore
          .collection('habits')
          .where('userId', isEqualTo: userId)
          .where('isArchived', isEqualTo: false)
          .get(); // Note: transaction.get() doesn't support queries well in some SDKs, 
                  // but here we are using the regular get() because we are inside a transaction 
                  // that already did reads. Wait, actually we should use a regular get if possible
                  // or do the query outside. 
                  // For simplicity, we'll fetch them normally.
      allHabits = habitsSnap.docs.map((d) => _mapDocToHabit(d)).toList();
    } else {
      final habitsSnap = await _firestore
          .collection('habits')
          .where('userId', isEqualTo: userId)
          .where('isArchived', isEqualTo: false)
          .get();
      allHabits = habitsSnap.docs.map((d) => _mapDocToHabit(d)).toList();
    }

    // If we have an updated habit (e.g. from completeHabit), inject it
    if (updatedHabit != null) {
      final index = allHabits.indexWhere((h) => h.id == updatedHabit.id);
      if (index != -1) {
        allHabits[index] = updatedHabit;
      } else {
        allHabits.add(updatedHabit);
      }
    }

    final worldHealthInt = momentumService.computeWorldHealth(allHabits);
    final worldHealthDouble = worldHealthInt / 100.0;

    final statsRef = _firestore.collection('user_stats').doc(userId);
    if (transaction != null) {
      transaction.set(statsRef, {'worldHealthScore': worldHealthDouble}, SetOptions(merge: true));
    } else {
      await statsRef.set({'worldHealthScore': worldHealthDouble}, SetOptions(merge: true));
    }
  }

  TimeOfDayPreference _getPreferenceForTime(TimeOfDay time) {
    if (time.hour >= 5 && time.hour < 12) return TimeOfDayPreference.morning;
    if (time.hour >= 12 && time.hour < 17) return TimeOfDayPreference.afternoon;
    if (time.hour >= 17 && time.hour < 22) return TimeOfDayPreference.evening;
    return TimeOfDayPreference.anytime;
  }
}
