import 'dart:async';
import 'package:emerge_app/core/deletion/deletion_service.dart';
import 'package:emerge_app/core/services/event_bus.dart';
import 'package:emerge_app/core/drift/database.dart';
import 'package:uuid/uuid.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:emerge_app/core/error/failure.dart';
import 'package:emerge_app/core/game_loop/game_loop_engine.dart';
import 'package:emerge_app/core/sync/sync_engine.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/services/habit_time_slots.dart';
import 'package:emerge_app/features/habits/domain/models/habit_activity.dart';
import 'package:emerge_app/features/habits/domain/entities/habit_completion_entity.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/onboarding/domain/models/starter_habit_blueprint.dart';
import 'package:emerge_app/features/gamification/domain/services/completion_xp_split.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter/material.dart';

class DriftHabitRepository implements HabitRepository {
  final AppDatabase _db;
  final LocalGameLoopEngine _engine;
  final EnhancedSyncEngine _syncEngine;
  final SocialActivityService _socialService;
  final DeletionService _deletionService;

  DriftHabitRepository({
    required AppDatabase db,
    required LocalGameLoopEngine gameLoopEngine,
    required EnhancedSyncEngine syncEngine,
    required SocialActivityService socialService,
    required DeletionService deletionService,
  }) : _db = db,
       _engine = gameLoopEngine,
       _syncEngine = syncEngine,
       _socialService = socialService,
       _deletionService = deletionService;

  @override
  Stream<List<Habit>> watchHabits(String userId) {
    return _db.habitsDao.watchHabits(userId).asyncMap((rows) async {
      // Check and break stale streaks on read
      final now = DateTime.now();
      for (final row in rows) {
        if (row.currentStreak > 0 && row.lastCompletedDate != null) {
          final lastDate = DateTime.tryParse(row.lastCompletedDate!);
          if (lastDate != null) {
            final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
            final today = DateTime(now.year, now.month, now.day);
            if (today.difference(lastDay).inDays > 1) {
              // Break the streak — missed at least one full day
              await _db.habitsDao.updateStreak(
                row.id,
                0,
                row.longestStreak,
                row.lastCompletedDate,
              );
              await _db.habitsDao.updateMomentum(
                row.id,
                row.momentumScore,
                row.consecutiveMisses + 1,
              );
            }
          }
        }
      }
      // Re-read to reflect any updates made above
      final updatedRows = await _db.habitsDao.watchHabits(userId).first;
      return updatedRows.map((row) => _rowToHabit(row)).toList();
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
        timerDurationMinutes: habit.timerDurationMinutes,
        integrationType: habit.integrationType.name,
        integrationTarget: habit.integrationTarget,
        imageUrl: habit.imageUrl,
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
        timerDurationMinutes: habit.timerDurationMinutes,
        integrationType: habit.integrationType.name,
        integrationTarget: habit.integrationTarget,
        imageUrl: habit.imageUrl,
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
      if (existing == null) {
        return const Left(ServerFailure('Habit not found'));
      }
      return await _deletionService.deleteHabit(
        userId: existing.userId,
        habitId: habitId,
      );
    } catch (e, _) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> completeHabit(
    String habitId,
    DateTime date, {
    String? activeTribeId,
  }) async {
    try {
      final habitRow = await _db.habitsDao.getHabit(habitId);
      if (habitRow == null) return Left(ServerFailure('Habit not found'));

      final statsRow = await _db.userStatsDao.getStats(habitRow.userId);
      if (statsRow == null) return Left(ServerFailure('User stats not found'));

      final oldLevel = _engine.computeLevel(statsRow.totalXp);

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
        // Already completed today -> this call is an UNDO.
        // Reverse the completion: drop today's completion row(s) and
        // decrement the deltas the completion had applied.
        final today = DateTime.now();
        final startOfDay =
            DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        final todays = await _db.habitCompletionsDao.getBetweenDates(
          statsRow.userId,
          startOfDay.toIso8601String(),
          endOfDay.toIso8601String(),
        );
        final todaysForHabit =
            todays.where((c) => c.habitId == habitId).toList();
        if (todaysForHabit.isEmpty) {
          // Nothing to undo locally; treat as no-op success.
          return const Right(false);
        }

        // Recompute reversed deltas from the most recent completion row.
        final last = todaysForHabit.last;
        final challengeXpToReverse = last.challengeXp;
        final xpToUndo = last.xpGained + challengeXpToReverse;
        final attr = last.attribute ?? 'vitality';
        final newStreak = (habitRow.currentStreak - 1).clamp(0, 99999);
        final newMomentum =
            (habitRow.momentumScore - 10).clamp(0, 100);
        // Restore lastCompletedDate to the day before today (so re-completing
        // today is counted as a fresh streak day).
        final prevDate = startOfDay.subtract(const Duration(days: 1));
        final newTotalXp = (statsRow.totalXp - xpToUndo).clamp(0, 1 << 30);
        final newLevel = _engine.computeLevel(newTotalXp);
        // World health reversal is handled by GamificationService via
        // the HabitCompletionUndone event (zone-based model).

        await _db.transaction(() async {
          // Delete every same-day row for this habit, but debit the stats
          // ONCE (from the most recent row below). This is safe because the
          // invariant "at most one completion row per habit per day" holds:
          // a second same-day completion is detected as a duplicate by
          // processHabitCompletion and routed back into this undo path,
          // which deletes the earlier row — so todaysForHabit never holds
          // more than one row in practice.
          for (final c in todaysForHabit) {
            await _db.habitCompletionsDao.deleteById(c.id, statsRow.userId);
          }
          await _db.habitsDao.updateStreak(
            habitId,
            newStreak,
            habitRow.longestStreak,
            prevDate.toIso8601String(),
          );
          await _db.habitsDao.updateMomentum(habitId, newMomentum,
              habitRow.consecutiveMisses);
          await _db.userStatsDao.updateAttributeXp(
            statsRow.userId,
            attr,
            -xpToUndo,
            newLevel,
            newTotalXp,
          );
          await _db.userStatsDao.updateStreak(statsRow.userId, newStreak);
          // World health reversal is delegated to GamificationService
          // via the HabitCompletionUndone event fired below.

          // Reverse challenge day progress
          if (challengeXpToReverse > 0) {
            final activeChallenges =
                await _db.challengeProgressDao.getActive(statsRow.userId);
            for (final challenge in activeChallenges) {
              if (challenge.attribute == null ||
                  challenge.attribute == habitRow.attribute) {
                await _db.challengeProgressDao
                    .decrementDay(challenge.challengeId);
              }
            }
          }

          // Sync deletion to Firestore (undo the completion record).
          for (final c in todaysForHabit) {
            await _syncEngine.enqueueMutation(
              collectionPath: 'users/${statsRow.userId}/habit_completions',
              documentId: c.id,
              operation: 'delete',
            );
          }

          // SP-G B12: mirror the credit exactly on user_stats — debit the
          // full credited amount (base + challenge XP). The split's deltas
          // are already negated for the undo side.
          final split = CompletionXpSplit.fromStoredRow(
            xpGained: last.xpGained,
            challengeXp: last.challengeXp,
          );
          await _syncEngine.enqueueUpdate(
            collectionPath: 'user_stats',
            documentId: statsRow.userId,
            data: buildUserStatsXpPayload(
              totalDelta: split.userStatsDelta,
              attr: attr,
              level: newLevel,
              streak: newStreak,
              updatedAt: DateTime.now().toIso8601String(),
            ),
          );

          // Tribe totals are NOT debited here (D4 — the server recalc owns
          // them). Only the per-member contributor record is debited, by
          // base XP only, matching what the credit path added.
          if (activeTribeId != null) {
            await _syncEngine.enqueueUpdate(
              collectionPath: 'tribes/$activeTribeId/contributors',
              documentId: statsRow.userId,
              data: {
                'totalXpContributed': {
                  '__type__': 'increment',
                  'value': split.tribeDelta,
                },
                'totalHabitsCompleted': {
                  '__type__': 'increment',
                  'value': -1
                },
                'contributionCount': {'__type__': 'increment', 'value': -1},
                'lastActivity': DateTime.now().toIso8601String(),
              },
            );
          }
        });

        // Fire undo event so GamificationService reverses world health
        // via the zone-based model (single authoritative path).
        EventBus().fire(HabitCompletionUndone(
          habitId: habitId,
          userId: statsRow.userId,
          attribute: attr,
        ));

        return const Right(false);
      }

      final attr = result.attribute;

      int challengeXpEarned = 0;
      for (final update in result.challengeUpdates.values) {
        if (update.isCompleted && update.xpReward != null) {
          challengeXpEarned += update.xpReward!;
        }
      }

      final totalXpGained = result.xpGained + challengeXpEarned;
      final newTotalXp = statsRow.totalXp + totalXpGained;
      final newLevel = _engine.computeLevel(newTotalXp);

      final now = DateTime.now();
      String? tribeId;

      await _db.transaction(() async {
        // Re-read inside transaction to prevent TOCTOU race
        final freshHabitRow = await _db.habitsDao.getHabit(habitId);
        if (freshHabitRow == null) return;
        final freshStatsRow =
            await _db.userStatsDao.getStats(freshHabitRow.userId);
        if (freshStatsRow == null) return;

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

        final totalXpToAdd = result.xpGained + challengeXpEarned;
        await _db.userStatsDao.updateAttributeXp(
          freshStatsRow.userId,
          attr,
          totalXpToAdd,
          newLevel,
          newTotalXp,
        );
        await _db.userStatsDao.updateStreak(
            freshStatsRow.userId, result.newStreak);
        // World health is NOT updated here — it is computed by the
        // GamificationService zone model via the HabitCompleted event.

        final completionId = const Uuid().v4();
        await _db.habitCompletionsDao.insertFromData(
          id: completionId,
          habitId: habitId,
          userId: freshStatsRow.userId,
          completedAt: date.toIso8601String(),
          xpGained: result.xpGained,
          attribute: attr,
          momentumAtCompletion: result.newMomentumScore,
          streakDay: result.newStreak,
          wasRecovery: result.isRecovery ? 1 : 0,
          challengeXp: challengeXpEarned,
        );

        // Sync habit completion to Firestore for cross-device history
        await _syncEngine.enqueueSet(
          collectionPath: 'users/${freshStatsRow.userId}/habit_completions',
          documentId: completionId,
          data: {
            'habitId': habitId,
            'userId': freshStatsRow.userId,
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
        if (activeTribeId != null) {
          final userTribe = await _db.tribeStatsDao.getStats(activeTribeId);
          if (userTribe != null) {
            tribeId = userTribe.tribeId;
            await _db.tribeStatsDao.incrementContribution(
              userTribe.tribeId,
              xp: result.xpGained,
              habits: 1,
              challenges: 0,
            );
          }
        } else if (statsRow.archetype != null && statsRow.archetype != 'none') {
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
        clubId: tribeId,
      );

      // Enqueue user stats sync via update to preserve other fields (markers ensure atomic changes)
      // Sync to user_activity collection for weekly recap
      await _syncEngine.enqueueSet(
        collectionPath: 'user_activity',
        documentId: const Uuid().v4(),
        data: {
          'userId': statsRow.userId,
          'type': 'habit_completion',
          'date': date.toIso8601String(),
          'xpEarned': result.xpGained,
          'habitId': habitId,
          'attribute': attr,
          'streakDay': result.newStreak,
        },
      );

      // worldState.entropy is NOT updated here — the GamificationService
      // zone model is the sole writer via UserStatsController.
      await _syncEngine.enqueueUpdate(
        collectionPath: 'user_stats',
        documentId: statsRow.userId,
        data: buildUserStatsXpPayload(
          totalDelta: totalXpGained,
          attr: attr,
          level: newLevel,
          streak: result.newStreak,
          updatedAt: nowStr,
        ),
      );

      // Tribe totals are NOT written here — Firestore rules deny client
      // writes to them; the server recalc owns tribe totals (sums
      // user_stats.totalXp). Only per-member contributor records remain
      // client-authoritative.
      if (tribeId != null) {
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

      EventBus().fire(HabitCompleted(
        habitId: habitId,
        userId: habitRow.userId,
        date: date,
        gameLoopResult: result,
        previousLevel: oldLevel,
        tribeId: activeTribeId,
        archetype: statsRow.archetype,
        userName: statsRow.displayName ?? habitRow.userId,
      ));

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
  Future<Either<Failure, List<HabitCompletionEntity>>> getCompletionsBetweenDates(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final rows = await _db.habitCompletionsDao.getBetweenDates(
        userId,
        start.toIso8601String(),
        end.toIso8601String(),
      );

      final entities = rows.map((r) => HabitCompletionEntity(
        id: r.id,
        habitId: r.habitId,
        attribute: r.attribute ?? 'vitality',
        xpGained: r.xpGained,
        completedAt: DateTime.parse(r.completedAt),
      )).toList();

      return Right(entities);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
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

        // Generate a Habit with timer and integration fields from blueprint
        final habit = Habit(
          id: habitId,
          userId: userId,
          title: h.title,
          frequency: h.frequency.toLowerCase() == 'weekly'
              ? HabitFrequency.weekly
              : HabitFrequency.daily,
          attribute: h.attribute,
          timerDurationMinutes: h.timerDurationMinutes,
          integrationType: h.integrationType,
          integrationTarget: h.integrationTarget,
          reminderTime: reminderTime != null
              ? _parseReminderTime(reminderTime)
              : null,
          createdAt: DateTime.now(),
        );

        await _db.habitsDao.insertFromData(
          id: habit.id,
          userId: habit.userId,
          title: habit.title,
          frequency: habit.frequency.name,
          attribute: habit.attribute.name,
          createdAt: habit.createdAt.toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          reminderTime: habit.reminderTime != null
              ? '${habit.reminderTime!.hour}:${habit.reminderTime!.minute.toString().padLeft(2, '0')}'
              : null,
          timerDurationMinutes: habit.timerDurationMinutes,
          integrationType: habit.integrationType.name,
          integrationTarget: habit.integrationTarget,
          imageUrl: habit.imageUrl,
        );

        // Sync to Firestore with all fields
        await _syncEngine.enqueueSet(
          collectionPath: 'habits',
          documentId: habitId,
          data: habit.toMap(),
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

  @override
  Future<Either<Failure, List<Habit>>> createStarterPack({
    required String userId,
    required List<StarterHabitBlueprint> blueprints,
    String? archetypeName,
    List<String> interestIds = const [],
    String? clubId,
  }) async {
    if (blueprints.isEmpty) {
      return const Right([]);
    }
    try {
      final now = DateTime.now();
      final created = <Habit>[];
      final tagSet = <String>{
        ?archetypeName,
        'onboarding',
        ...interestIds.map((id) => 'interest:$id'),
        if (clubId != null) 'club:$clubId',
      }.toList();

      await _db.transaction(() async {
        for (var i = 0; i < blueprints.length; i++) {
          final blueprint = blueprints[i];
          final habitId =
              '${blueprint.id}_${i}_${now.millisecondsSinceEpoch}';

          // Starter pack is intentionally simple: no reminder, no timer
          // overrides, no integration. Difficulty is hardcoded `easy` so
          // the gamification pipeline gives a low XP grant for day-1 wins.
          final habit = Habit(
            id: habitId,
            userId: userId,
            title: blueprint.title,
            cue: blueprint.shortCue,
            difficulty: HabitDifficulty.easy,
            attribute: blueprint.attribute,
            identityTags: [...tagSet, blueprint.id],
            frequency: HabitFrequency.daily,
            createdAt: now,
            timeOfDayPreference: timeOfDayPreferenceFrom(
              timelineSlotKeyForCue(blueprint.shortCue),
            ),
          );

          await _db.habitsDao.insertFromData(
            id: habit.id,
            userId: habit.userId,
            title: habit.title,
            cue: habit.cue,
            difficulty: habit.difficulty.name,
            frequency: habit.frequency.name,
            attribute: habit.attribute.name,
            createdAt: habit.createdAt.toIso8601String(),
            updatedAt: now.toIso8601String(),
            imageUrl: habit.imageUrl,
            timeOfDayPreference: habit.timeOfDayPreference?.name,
          );

          created.add(habit);
        }
      });

      // One enqueue per habit so the sync engine queues them individually;
      // cheaper than introducing a new batched-set API just for this.
      for (final habit in created) {
        await _syncEngine.enqueueSet(
          collectionPath: 'habits',
          documentId: habit.id,
          data: habit.toMap(),
        );
      }

      _socialService.logActivity(
        type: 'starter_pack_created',
        userId: userId,
        data: {
          'habitCount': blueprints.length,
          'archetype': archetypeName,
          'interestCount': interestIds.length,
          'clubId': clubId,
        },
      );

      return Right(created);
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
      timerDurationMinutes: row.timerDurationMinutes,
      integrationType: HabitIntegrationType.values.firstWhere(
        (e) => e.name == row.integrationType,
        orElse: () => HabitIntegrationType.none,
      ),
      integrationTarget: row.integrationTarget,
      imageUrl: row.imageUrl,
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
      'timerDurationMinutes': habit.timerDurationMinutes,
      'integrationType': habit.integrationType.name,
      'integrationTarget': habit.integrationTarget,
      'imageUrl': habit.imageUrl,
    };
  }

  TimeOfDay? _parseReminderTime(String reminderTime) {
    final parts = reminderTime.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    return null;
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
