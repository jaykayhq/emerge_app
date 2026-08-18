import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_activity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Habit _habit({
  String title = 'meditate',
  TimeOfDay? reminderTime,
  String? location,
}) => Habit(
  id: 'h1',
  userId: 'u1',
  title: title,
  reminderTime: reminderTime,
  location: location,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  group('buildIdentityStatement', () {
    test('includes title, time and location when present', () {
      final s = buildIdentityStatement(
        _habit(
          title: 'meditate',
          reminderTime: const TimeOfDay(hour: 7, minute: 5),
          location: 'living room',
        ),
      );
      expect(
        s,
        'I am the type of person who meditate at 07:05 in living room.',
      );
    });

    test('falls back to "shows up" for an empty title', () {
      final s = buildIdentityStatement(_habit(title: ''));
      expect(s, 'I am the type of person who shows up.');
    });

    test('omits time and location when absent', () {
      final s = buildIdentityStatement(_habit(title: 'read'));
      expect(s, 'I am the type of person who read.');
    });
  });
}
