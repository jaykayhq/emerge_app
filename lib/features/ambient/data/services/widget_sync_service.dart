import 'dart:convert';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/dashboard_state_provider.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:home_widget/home_widget.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:emerge_app/core/utils/app_logger.dart';

part 'widget_sync_service.g.dart';

@Riverpod(keepAlive: true)
void widgetSyncService(Ref ref) {
  // Listen to today's habits
  ref.listen(todaysHabitsProvider, (prev, next) {
    _syncHabitStack(next);
  });

  // Listen to completion rate 
  ref.listen(todayCompletionRateProvider, (prev, next) {
    _syncWorldHealth(ref.read(userStreakProvider).value ?? 0, next);
  });

  // Listen to streak
  ref.listen(userStreakProvider, (prev, next) {
    next.whenData((streak) {
       _syncWorldHealth(streak, ref.read(todayCompletionRateProvider));
    });
  });
  
  // Initial sync
  final habits = ref.read(todaysHabitsProvider);
  _syncHabitStack(habits);
  
  final streak = ref.read(userStreakProvider).value ?? 0;
  final rate = ref.read(todayCompletionRateProvider);
  _syncWorldHealth(streak, rate);
}

Future<void> _syncHabitStack(List<Habit> habits) async {
  try {
    final now = DateTime.now();
    final uncompleted = habits.where((h) {
      final last = h.lastCompletedDate;
      if (last == null) return true;
      return !(last.year == now.year && last.month == now.month && last.day == now.day);
    }).toList();
    
    final top3 = uncompleted.take(3).map((h) => h.title).toList();
    
    await HomeWidget.saveWidgetData<String>('top_habits', jsonEncode(top3));
    await HomeWidget.updateWidget(
      name: 'HabitStackWidgetProvider',
      androidName: 'HabitStackWidgetProvider',
    );
  } catch (e, s) {
    AppLogger.e('Failed to sync Habit Stack widget', e, s);
  }
}

Future<void> _syncWorldHealth(int streak, double rate) async {
  try {
    final ratePercentage = (rate * 100).toInt();
    await HomeWidget.saveWidgetData<String>('world_health_percentage', '$ratePercentage%');
    await HomeWidget.saveWidgetData<String>('momentum_streak', 'Streak: $streak');
    
    await HomeWidget.updateWidget(
      name: 'WorldHealthWidgetProvider',
      androidName: 'WorldHealthWidgetProvider',
    );
  } catch (e, s) {
    AppLogger.e('Failed to sync World Health widget', e, s);
  }
}
