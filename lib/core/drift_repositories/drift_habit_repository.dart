import 'dart:async';
import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/game_loop/game_loop_engine.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/models/habit_activity.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter/material.dart';

class DriftHabitRepository implements HabitRepository {
  final AppDatabase _db;
  final LocalGameLoopEngine _engine;
  final EnhancedSyncEngine _syncEngine;
  final SocialActivityService _socialService;

  DriftHabitRepository({
    required AppDatabase db,
    required LocalGameLoopEngine gameLoopEngine,
    required EnhancedSyncEngine syncEngine,
    required SocialActivityService socialService,
  }) : _db = db,
       _engine = gameLoopEngine,
       _syncEngine = syncEngine,
       _socialService = socialService;

  @override
  Stream<List<Habit>> watchHabits(String userId) {
    return _db.habitsDao.watchHabits(userId).map((rows) {
      return rows.map((row) => _rowToHabit(row)).toList();
    });
  }

  @override
  Future<Either<Failure, Unit>> createHabit(Habit habit) async {
    try {
      await _db.habitsDao.insertFromData(
        id: habit.id,
        userId: habit.userId,
        title: habit.title,
        cue: habit.cue,
        routine: habit.routine,
        reward: habit.reward,
        frequency: habit.frequency.name,
        difficulty: habit.difficulty.name,
        attribute: habit.attribute.name,
        currentStreak: habit.currentStreak,
        longestStreak: habit.longestStreak,
        momentumScore: habit.momentumScore,
        consecutiveMisses: habit.consecutiveMisses,
        isArchived: habit.isArchived ? 1 : 0,
        createdAt: habit.createdAt.toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        timeOfDayPreference: habit.timeOfDayPreference?.name,
        reminderTime: habit.reminderTime != null
            ? '${habit.reminderTime!.hour}:${habit.reminderTime!.minute.toString().padLeft(2, '0')}'
            : null,
      );

      await _syncEngine.enqueueSet(
        collectionPath: 'habits',
        documentId: habit.id,
        data: _habitToFirestoreMap(habit),
      );

      return const Right(unit);
    } catch (e, _) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateHabit(Habit habit) async {
    try {
      await _db.habitsDao.insertFromData(
        id: habit.id,
        userId: habit.userId,
        title: habit.title,
        cue: habit.cue,
        routine: habit.routine,
        reward: habit.reward,
        frequency: habit.frequency.name,
        difficulty: habit.difficulty.name,
        attribute: habit.attribute.name,
        currentStreak: habit.currentStreak,
        longestStreak: habit.longestStreak,
        momentumScore: habit.momentumScore,
        consecutiveMisses: habit.consecutiveMisses,
        isArchived: habit.isArchived ? 1 : 0,
        createdAt: habit.createdAt.toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        timeOfDayPreference: habit.timeOfDayPreference?.name,
        reminderTime: habit.reminderTime != null
            ? '${habit.reminderTime!.hour}:${habit.reminderTime!.minute.toString().padLeft(2, '0')}'
            : null,
      );

      await _syncEngine.enqueueUpdate(
        collectionPath: 'habits',
        documentId: habit.id,
        data: _habitToFirestoreMap(habit),
      );

      return const Right(unit);
    } catch (e, _) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteHabit(String habitId) async {
    try {
      final existing = await _db.habitsDao.getHabit(habitId);
      if (existing != null) {
        await _db.habitsDao.insertFromData(
          id: existing.id,
          userId: existing.userId,
          title: existing.title,
          isArchived: 1,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
        );
      }

      await _syncEngine.enqueueUpdate(
        collectionPath: 'habits',
        documentId: habitId,
        data: {'isArchived': true},
      );

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
      final habitRow = await _db.habitsDao.getHabit(habitId);
      if (habitRow == null) return Left(ServerFailure('Habit not found'));

      final statsRow = await _db.userStatsDao.getStats(habitRow.userId);
      if (statsRow == null) return Left(ServerFailure('User stats not found'));

      final lastDate = habitRow.lastCompletedDate != null
          ? DateTime.tryParse(habitRow.lastCompletedDate!)
          : null;

      final diffMultiplier = _difficultyMultiplier(habitRow.difficulty);

      final challenges = await _db.challengeProgressDao.getActive(
        habitRow.userId,
      );
      final challengeInputs = challenges
          .where(
            (c) => c.attribute == null || c.attribute == habitRow.attribute,
          )
          .map(
            (c) => ChallengeProgressInput(
              challengeId: c.challengeId,
              currentDay: c.currentDay,
              totalDays: c.totalDays,
              xpReward: c.xpReward,
              attribute: c.attribute,
            ),
          )
          .toList();

      final result = _engine.processHabitCompletion(
        currentStreak: habitRow.currentStreak,
        longestStreak: habitRow.longestStreak,
        momentumScore: habitRow.momentumScore,
        consecutiveMisses: habitRow.consecutiveMisses,
        difficultyMultiplier: diffMultiplier,
        attribute: habitRow.attribute ?? 'vitality',
        lastCompletedDate: lastDate,
        activeChallenges: challengeInputs,
      );

      if (result.xpGained == 0 && result.newStreak == habitRow.currentStreak) {
        return const Right(false);
      }

      final newTotalXp = statsRow.totalXp + result.xpGained;
      final newLevel = _engine.computeLevel(newTotalXp);
      final attr = result.attribute;

      final now = DateTime.now();
      String? tribeId;

      await _db.transaction(() async {
        await _db.habitsDao.updateStreak(
          habitId,
          result.newStreak,
          result.longestStreak,
          date.toIso8601String(),
        );
        await _db.habitsDao.updateMomentum(
          habitId,
          result.newMomentumScore,
          result.newConsecutiveMisses,
        );

        await _db.userStatsDao.updateAttributeXp(
          statsRow.userId,
          attr,
          result.xpGained,
          newLevel,
          newTotalXp,
        );
        await _db.userStatsDao.updateStreak(statsRow.userId, result.newStreak);
        await _db.userStatsDao.updateWorldHealth(
          statsRow.userId,
          (statsRow.worldHealthScore + result.worldHealthDelta).clamp(0.0, 1.0),
        );

        await _db.habitCompletionsDao.insertFromData(
          id: '${habitId}_${now.millisecondsSinceEpoch}',
          habitId: habitId,
          userId: statsRow.userId,
          completedAt: date.toIso8601String(),
          xpGained: result.xpGained,
          attribute: attr,
          momentumAtCompletion: result.newMomentumScore,
          streakDay: result.newStreak,
          wasRecovery: result.isRecovery ? 1 : 0,
        );

        // Sync habit completion to Firestore for cross-device history
        await _syncEngine.enqueueSet(
          collectionPath: 'users/${statsRow.userId}/habit_completions',
          documentId: '${habitId}_${now.millisecondsSinceEpoch}',
          data: {
            'habitId': habitId,
            'userId': statsRow.userId,
            'completedAt': date.toIso8601String(),
            'xpGained': result.xpGained,
            'attribute': attr,
            'momentumAtCompletion': result.newMomentumScore,
            'streakDay': result.newStreak,
            'wasRecovery': result.isRecovery,
          },
        );

        for (final update in result.challengeUpdates.values) {
          await _db.challengeProgressDao.updateDay(
            update.challengeId,
            update.newDay,
            update.isCompleted ? 'completed' : 'active',
          );
        }

        // Update tribe contribution stats
        if (statsRow.archetype != null && statsRow.archetype != 'none') {
          final tribeRows = await _db.tribeStatsDao.getAll();
          final userTribe = tribeRows
              .where((t) => t.archetypeId == statsRow.archetype)
              .firstOrNull;
          if (userTribe != null) {
            tribeId = userTribe.tribeId;
            await _db.tribeStatsDao.incrementContribution(
              userTribe.tribeId,
              xp: result.xpGained,
              habits: 1,
              challenges: 0,
            );
          }
        }
      });

      final nowStr = now.toIso8601String();

      // Delegate all social/global activity logging to the unified service
      // This handles: user_activity, tribes/activity, global_activities, and leaderboard updates.
      await _socialService.logHabitCompletion(
        userId: statsRow.userId,
        userName: statsRow.displayName ?? 'Anonymous',
        archetype: statsRow.archetype ?? 'none',
        habitId: habitId,
        habitTitle: habitRow.title,
        streakDay: result.newStreak,
        attribute: attr,
        xpGained: result.xpGained,
        currentLevel: newLevel,
      );

      // Enqueue user stats sync via update to preserve other fields (markers ensure atomic changes)
      await _syncEngine.enqueueUpdate(
        collectionPath: 'user_stats',
        documentId: statsRow.userId,
        data: {
          'avatarStats.totalXp': {
            '__type__': 'increment',
            'value': result.xpGained,
          },
          'avatarStats.level': newLevel,
          'avatarStats.streak': result.newStreak,
          'avatarStats.${attr}Xp': {
            '__type__': 'increment',
            'value': result.xpGained,
          },
          'worldState.entropy': {
            '__type__': 'increment',
            'value': -result.worldHealthDelta,
          }, // worldHealthDelta is positive for improvement
          'updatedAt': nowStr,
        },
      );

      // 4. Update Tribe global stats in Firestore
      if (tribeId != null) {
        await _syncEngine.enqueueUpdate(
          collectionPath: 'tribes',
          documentId: tribeId!,
          data: {
            'totalXp': {'__type__': 'increment', 'value': result.xpGained},
            'totalHabitsCompleted': {'__type__': 'increment', 'value': 1},
            'lastStatsSync': {'__type__': 'serverTimestamp'},
          },
        );

        // Update per-member contributor subcollection so other users
        // can see each other's contribution stats in the tribe
        await _syncEngine.enqueueSet(
          collectionPath: 'tribes/$tribeId/contributors',
          documentId: statsRow.userId,
          data: {
            'totalXpContributed': {
              '__type__': 'increment',
              'value': result.xpGained,
            },
            'totalHabitsCompleted': {'__type__': 'increment', 'value': 1},
            'contributionCount': {'__type__': 'increment', 'value': 1},
            'lastContributionAt': {'__type__': 'serverTimestamp'},
            'lastActivity': nowStr,
          },
        );
      }

      return const Right(true);
    } catch (e, _) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Habit?> getHabit(String habitId) async {
    final row = await _db.habitsDao.getHabit(habitId);
    return row != null ? _rowToHabit(row) : null;
  }

  @override
  Future<List<Habit>> getHabitsByAnchor(String anchorHabitId) async {
    final rows = await _db.habitsDao.getByAttribute(anchorHabitId);
    return rows.map((r) => _rowToHabit(r)).toList();
  }

  @override
  Future<List<HabitActivity>> getActivity(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _db.habitCompletionsDao.getBetweenDates(
      userId,
      start.toIso8601String(),
      end.toIso8601String(),
    );

    return rows
        .map(
          (r) => HabitActivity(
            id: r.id,
            habitId: r.habitId,
            userId: r.userId,
            date: DateTime.parse(r.completedAt),
            type: 'habit_completion',
          ),
        )
        .toList();
  }

  @override
  Future<Either<Failure, Unit>> createHabitsFromBlueprint({
    required String userId,
    required Blueprint blueprint,
    String? reminderTime,
  }) async {
    try {
      final habits = blueprint.habits;
      for (int i = 0; i < habits.length; i++) {
        final h = habits[i];
        final habitId =
            '${blueprint.id}_${i}_${DateTime.now().millisecondsSinceEpoch}';
        await _db.habitsDao.insertFromData(
          id: habitId,
          userId: userId,
          title: h.title,
          attribute: h.attribute.name,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );

        await _syncEngine.enqueueSet(
          collectionPath: 'habits',
          documentId: habitId,
          data: {
            'userId': userId,
            'title': h.title,
            'attribute': h.attribute.name,
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
      }

      _socialService.logActivity(
        type: 'blueprint_adopted',
        userId: userId,
        data: {
          'blueprintTitle': blueprint.title,
          'blueprintId': blueprint.id,
          'category': blueprint.category,
          'habitCount': blueprint.habits.length,
        },
      );

      return const Right(unit);
    } catch (e, _) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Habit _rowToHabit(HabitsTableData row) {
    TimeOfDayPreference? timePref;
    if (row.timeOfDayPreference != null) {
      timePref = TimeOfDayPreference.values.firstWhere(
        (e) => e.name == row.timeOfDayPreference,
        orElse: () => TimeOfDayPreference.anytime,
      );
    }

    TimeOfDay? remTime;
    if (row.reminderTime != null) {
      final parts = row.reminderTime!.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          remTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }

    return Habit(
      id: row.id,
      userId: row.userId,
      title: row.title,
      cue: row.cue ?? '',
      routine: row.routine ?? '',
      reward: row.reward ?? '',
      frequency: HabitFrequency.values.firstWhere(
        (e) => e.name == row.frequency,
        orElse: () => HabitFrequency.daily,
      ),
      difficulty: HabitDifficulty.values.firstWhere(
        (e) => e.name == row.difficulty,
        orElse: () => HabitDifficulty.medium,
      ),
      attribute: HabitAttribute.values.firstWhere(
        (e) => e.name == (row.attribute ?? 'vitality'),
        orElse: () => HabitAttribute.vitality,
      ),
      createdAt: DateTime.parse(row.createdAt),
      currentStreak: row.currentStreak,
      longestStreak: row.longestStreak,
      lastCompletedDate: row.lastCompletedDate != null
          ? DateTime.tryParse(row.lastCompletedDate!)
          : null,
      isArchived: row.isArchived == 1,
      momentumScore: row.momentumScore,
      consecutiveMisses: row.consecutiveMisses,
      timeOfDayPreference: timePref,
      reminderTime: remTime,
    );
  }

  Map<String, dynamic> _habitToFirestoreMap(Habit habit) {
    return {
      'userId': habit.userId,
      'title': habit.title,
      'frequency': habit.frequency.name,
      'difficulty': habit.difficulty.name,
      'attribute': habit.attribute.name,
      'currentStreak': habit.currentStreak,
      'longestStreak': habit.longestStreak,
      'isArchived': habit.isArchived,
      'createdAt': habit.createdAt.toIso8601String(),
      'timeOfDayPreference': habit.timeOfDayPreference?.name,
      'reminderTime': habit.reminderTime != null
          ? '${habit.reminderTime!.hour}:${habit.reminderTime!.minute.toString().padLeft(2, '0')}'
          : null,
    };
  }

  double _difficultyMultiplier(String? difficulty) {
    switch (difficulty) {
      case 'easy':
        return 1.0;
      case 'medium':
        return 2.0;
      case 'hard':
        return 3.0;
      default:
        return 2.0;
    }
  }
}
