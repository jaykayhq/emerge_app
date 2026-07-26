import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'habit_activity_provider.g.dart';

/// A single reflection entry for a habit.
class HabitReflection {
  final String text;
  final DateTime createdAt;
  final int mood; // 1..5

  const HabitReflection({
    required this.text,
    required this.createdAt,
    this.mood = 3,
  });
}

/// Aggregated activity data for the habit activity screen.
class HabitActivityData {
  final String habitId;
  final String title;
  final String identityStatement;
  final String emoji;
  final int currentStreak;
  final int bestStreak;
  final int totalCompletions;
  final double momentum; // 0.0-1.0
  final List<bool> heatmapData; // 90 days, index 0 = oldest
  final List<HabitReflection> reflections;

  const HabitActivityData({
    required this.habitId,
    required this.title,
    required this.identityStatement,
    required this.emoji,
    required this.currentStreak,
    required this.bestStreak,
    required this.totalCompletions,
    required this.momentum,
    required this.heatmapData,
    required this.reflections,
  });
}

/// Builds a human-readable identity statement from a habit's fields.
String buildIdentityStatement(Habit habit) {
  final buffer = StringBuffer('I am the type of person who ');
  buffer.write(habit.title.isEmpty ? 'shows up' : habit.title.toLowerCase());
  final time = habit.reminderTime;
  if (time != null) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    buffer.write(' at $h:$m');
  }
  if (habit.location != null && habit.location!.isNotEmpty) {
    buffer.write(' in ${habit.location}');
  }
  buffer.write('.');
  return buffer.toString();
}

/// Loads activity data for a single habit: heatmap, stats, and reflections.
@riverpod
Future<HabitActivityData> habitActivityData(Ref ref, String habitId) async {
  final repository = ref.watch(habitRepositoryProvider);
  final db = ref.watch(appDatabaseProvider);
  final userId = ref.watch(authStateChangesProvider).value?.id;

  final habit = await repository.getHabit(habitId);
  if (habit == null || userId == null) {
    throw Exception('Habit not found');
  }

  // ── Heatmap: ~13 weeks, Monday-aligned (index 0 = oldest Monday) ──
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  // Roughly 90 days back, then snap to the Monday on/before it so week
  // columns line up with the Mon–Sun row labels in HabitHeatmap.
  final roughStart = today.subtract(const Duration(days: 89));
  // DateTime.weekday: Mon=1..Sun=7 → shift back to Monday.
  final start = roughStart.subtract(Duration(days: roughStart.weekday - 1));
  // Pad forward to a whole number of weeks ending on/after today.
  final totalDays = today.difference(start).inDays + 1;
  final cellCount = ((totalDays + 6) ~/ 7) * 7;

  final completions = await db.habitCompletionsDao.getBetweenDates(
    userId,
    start.toIso8601String(),
    now.add(const Duration(days: 1)).toIso8601String(),
  );

  final completedDays = <int>{};
  var totalForHabit = 0;
  for (final c in completions) {
    if (c.habitId != habitId) continue;
    totalForHabit++;
    final date = DateTime.parse(c.completedAt);
    final dayOnly = DateTime(date.year, date.month, date.day);
    final dayIndex = dayOnly.difference(start).inDays;
    if (dayIndex >= 0 && dayIndex < cellCount) {
      completedDays.add(dayIndex);
    }
  }

  final heatmapData =
      List<bool>.generate(cellCount, (i) => completedDays.contains(i));

  // ── Reflections ──
  final reflectionRows = await db.habitReflectionsDao
      .watchForHabit(userId, habitId, start, now)
      .first;
  final reflections = reflectionRows
      .where((r) => r.note.isNotEmpty)
      .map((r) => HabitReflection(
            text: r.note,
            createdAt: r.localDate,
            mood: r.mood,
          ))
      .toList();

  return HabitActivityData(
    habitId: habit.id,
    title: habit.title,
    identityStatement: buildIdentityStatement(habit),
    emoji: habit.imageUrl ?? '🔥',
    currentStreak: habit.currentStreak,
    bestStreak: habit.longestStreak,
    totalCompletions: totalForHabit,
    momentum: (habit.momentumScore / 100).clamp(0.0, 1.0),
    heatmapData: heatmapData,
    reflections: reflections,
  );
}
