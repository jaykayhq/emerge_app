import 'package:emerge_app/core/domain/entities/cue.dart';
import 'package:emerge_app/core/services/cue_engine.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cueEngineProvider = Provider<CueEngine>((ref) {
  final engine = CueEngine();
  return engine;
});

class CueNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> initialize(UserArchetype archetype) async {
    final engine = ref.read(cueEngineProvider);
    await engine.initialize(archetype: archetype);
  }

  Future<void> queueHabitCue(Habit habit) async {
    final engine = ref.read(cueEngineProvider);
    final cue = engine.createHabitInitiationCue(habit);
    await engine.queueCue(cue);
  }

  Future<void> queueRecoveryCue(Habit habit) async {
    final engine = ref.read(cueEngineProvider);
    final cue = engine.createRecoveryCue(habit);
    await engine.queueCue(cue);
  }

  Future<void> queueMilestoneCue(Habit habit, int milestoneDays) async {
    final engine = ref.read(cueEngineProvider);
    final cue = engine.createMilestoneCue(habit, milestoneDays);
    await engine.queueCue(cue);
  }

  void markActionTaken(String cueId, {Duration? timeToAction}) {
    final engine = ref.read(cueEngineProvider);
    engine.markActionTaken(cueId, timeToAction: timeToAction);
  }

  void markDismissed(String cueId) {
    final engine = ref.read(cueEngineProvider);
    engine.markDismissed(cueId);
  }

  Future<void> setQuietHours(TimeWindow window) async {
    final engine = ref.read(cueEngineProvider);
    await engine.setQuietHours(window);
  }

  CueEngagementMetrics? getMetrics(String cueId) {
    final engine = ref.read(cueEngineProvider);
    return engine.getMetrics(cueId);
  }

  Map<String, dynamic> getOverallPerformance() {
    final engine = ref.read(cueEngineProvider);
    return engine.getOverallPerformance();
  }
}

final cueNotifierProvider = NotifierProvider<CueNotifier, void>(CueNotifier.new);

final cueMetricsProvider = Provider.family<CueEngagementMetrics?, String>((ref, cueId) {
  final engine = ref.watch(cueEngineProvider);
  return engine.getMetrics(cueId);
});

final cuePerformanceProvider = Provider<Map<String, dynamic>>((ref) {
  final engine = ref.watch(cueEngineProvider);
  return engine.getOverallPerformance();
});