import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/models/completion_source.dart';
import 'package:emerge_app/features/habits/domain/models/habit_completion_result.dart';
import 'package:emerge_app/features/habits/domain/repositories/habit_repository.dart';
import 'package:emerge_app/features/habits/domain/services/momentum_service.dart';
import 'package:emerge_app/features/habits/domain/services/variable_reward_service.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_note.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/data/datasources/narrator_local_datasource.dart';

/// Single source of truth for habit completion across all entry points.
///
/// Every completion path (Timeline tap, widget tap, notification action,
/// voice, health sync) MUST go through this service so the Narrator
/// engine receives a consistent observation stream.
class HabitCompletionService {
  final HabitRepository _habitRepo;
  final MomentumService _momentumService;
  final NarratorLocalDatasource _narratorDs;

  HabitCompletionService({
    required HabitRepository habitRepo,
    required MomentumService momentumService,
    required NarratorLocalDatasource narratorDs,
  }) : _habitRepo = habitRepo,
       _momentumService = momentumService,
       _narratorDs = narratorDs;

  /// Marks a habit as completed and returns a rich result.
  ///
  /// In addition to persisting the completion, this method:
  /// - Records a [NarratorNote] observation
  /// - Evaluates whether the Narrator should trigger (streak break, on fire,
  ///   level up, etc.)
  Future<HabitCompletionResult> markComplete(
    String habitId, {
    required CompletionSource source,
    DateTime? completedAt,
    String? activeTribeId,
  }) async {
    final now = completedAt ?? DateTime.now();

    final result = await _habitRepo.completeHabit(
      habitId,
      now,
      activeTribeId: activeTribeId,
    );

    return result.fold(
      (failure) {
        AppLogger.e(
          'HabitCompletionService.markComplete failed',
          failure,
          StackTrace.current,
        );
        return HabitCompletionResult.empty();
      },
      (isCompleted) async {
        final habit = await _habitRepo.getHabit(habitId);
        if (habit == null) return HabitCompletionResult.empty();

        final newStreak = isCompleted ? habit.currentStreak + 1 : habit.currentStreak;
        final wasRecovery = habit.consecutiveMisses > 0 && isCompleted;
        final newMomentumScore = _computeMomentum(isCompleted, habit);
        final isMilestone = isCompleted
            ? VariableRewardService.isStreakMilestone(newStreak)
            : false;

        // Record the observation for the Narrator.
        await _narratorDs.recordNote(
          type: NarratorNoteType.habitCompleted,
          data: {
            'source': source.name,
            'isCompleted': isCompleted,
            'wasRecovery': wasRecovery,
            'newStreak': newStreak,
            'momentumScore': newMomentumScore,
            'timeOfDay': now.hour,
            'dayOfWeek': now.weekday,
          },
          habitId: habitId,
        );

        // Determine if Narrator needs to appear after this completion.
        final narratorTrigger = _evaluateNarratorTrigger(
          habit,
          isCompleted,
          wasRecovery,
          newStreak,
          isMilestone,
        );

        AppLogger.i(
          'HabitCompletionService: $habitId completed via ${source.name}. '
          'Streak: $newStreak, Momentum: $newMomentumScore, '
          'Recovery: $wasRecovery, Milestone: $isMilestone, '
          'Narrator: ${narratorTrigger?.name ?? 'none'}',
        );

        return HabitCompletionResult(
          habitId: habitId,
          xpEarned: _computeXp(habit, newStreak, isMilestone),
          newStreak: newStreak,
          newMomentumScore: newMomentumScore,
          isStreakMilestone: isMilestone,
          isUndo: !isCompleted,
          wasRecovery: wasRecovery,
          narratorTrigger: narratorTrigger,
        );
      },
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────

  int _computeMomentum(bool isCompleted, Habit habit) {
    if (isCompleted) {
      final updated = _momentumService.applyCompletion(habit);
      return updated.momentumScore;
    }
    return habit.momentumScore; // unchanged on undo
  }

  int _computeXp(Habit habit, int newStreak, bool isMilestone) {
    final difficultyMultiplier = switch (habit.difficulty) {
      HabitDifficulty.easy => 1.0,
      HabitDifficulty.medium => 1.5,
      HabitDifficulty.hard => 2.0,
    };
    var xp = (10 * difficultyMultiplier).toInt();

    if (newStreak > 0) {
      xp += (newStreak ~/ 7) * 10; // bonus every 7 days
    }
    if (isMilestone) {
      xp += 25;
    }
    return xp;
  }

  NarratorTrigger? _evaluateNarratorTrigger(
    Habit habit,
    bool isCompleted,
    bool wasRecovery,
    int newStreak,
    bool isMilestone,
  ) {
    if (!isCompleted) return null;
    if (wasRecovery) return NarratorTrigger.streakBreakFirstMiss;
    if (newStreak >= 7 && newStreak % 7 == 0) return NarratorTrigger.onFireState;
    return null;
  }
}
