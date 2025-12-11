import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  static const String appGroupId =
      'group.com.emerge_app'; // Replace with actual App Group ID
  static const String androidWidgetName =
      'HabitWidget'; // Replace with actual Android Widget class name
  static const String iOSWidgetName =
      'HabitWidget'; // Replace with actual iOS Widget kind

  Future<void> updateNextHabitWidget(Habit habit) async {
    try {
      await HomeWidget.saveWidgetData<String>('habit_title', habit.title);
      await HomeWidget.saveWidgetData<String>('habit_cue', habit.cue);

      final timeString =
          '${habit.reminderTime?.hour.toString().padLeft(2, '0')}:${habit.reminderTime?.minute.toString().padLeft(2, '0')}';
      await HomeWidget.saveWidgetData<String>(
        'habit_time',
        habit.reminderTime != null ? timeString : 'Today',
      );

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (e) {
      // Handle error (e.g., log it)
      debugPrint('Error updating home widget: $e');
    }
  }

  Future<void> clearWidget() async {
    try {
      await HomeWidget.saveWidgetData<String>('habit_title', 'All done!');
      await HomeWidget.saveWidgetData<String>('habit_cue', 'Great job today.');
      await HomeWidget.saveWidgetData<String>('habit_time', '');

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (e) {
      debugPrint('Error clearing home widget: $e');
    }
  }
}
