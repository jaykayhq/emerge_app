import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/services/habit_time_slots.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('timelineSlotKeyFor', () {
    test('maps 4:00–11:59 to morning', () {
      expect(
        timelineSlotKeyFor(const TimeOfDay(hour: 4, minute: 0)),
        'morning',
      );
      expect(
        timelineSlotKeyFor(const TimeOfDay(hour: 11, minute: 59)),
        'morning',
      );
    });

    test('maps 12:00–16:59 to afternoon', () {
      expect(
        timelineSlotKeyFor(const TimeOfDay(hour: 12, minute: 0)),
        'afternoon',
      );
      expect(
        timelineSlotKeyFor(const TimeOfDay(hour: 16, minute: 59)),
        'afternoon',
      );
    });

    test('maps 17:00–20:59 to evening', () {
      expect(
        timelineSlotKeyFor(const TimeOfDay(hour: 17, minute: 0)),
        'evening',
      );
      expect(
        timelineSlotKeyFor(const TimeOfDay(hour: 20, minute: 59)),
        'evening',
      );
    });

    test('maps 21:00–3:59 and no time to anytime (Before Bed)', () {
      expect(
        timelineSlotKeyFor(const TimeOfDay(hour: 21, minute: 0)),
        'anytime',
      );
      expect(
        timelineSlotKeyFor(const TimeOfDay(hour: 3, minute: 59)),
        'anytime',
      );
      expect(timelineSlotKeyFor(null), 'anytime');
    });
  });

  group('timelineSlotKeyForCue', () {
    test('recognizes wake/breakfast/morning keywords', () {
      expect(timelineSlotKeyForCue('After waking up'), 'morning');
      expect(timelineSlotKeyForCue('After breakfast'), 'morning');
      expect(timelineSlotKeyForCue('Morning coffee'), 'morning');
      expect(timelineSlotKeyForCue('Before workout'), 'morning');
      expect(timelineSlotKeyForCue('Before training'), 'morning');
    });

    test('recognizes lunch/afternoon keywords', () {
      expect(timelineSlotKeyForCue('After lunch'), 'afternoon');
    });

    test('recognizes work/dinner/evening keywords', () {
      expect(timelineSlotKeyForCue('After work'), 'evening');
      expect(timelineSlotKeyForCue('Before dinner'), 'evening');
    });

    test('recognizes bed/night/reflection keywords', () {
      expect(timelineSlotKeyForCue('Before bed'), 'anytime');
      expect(timelineSlotKeyForCue('Evening reflection'), 'anytime');
    });

    test('defaults to morning when no keyword matches', () {
      expect(timelineSlotKeyForCue('During your run'), 'morning');
      expect(timelineSlotKeyForCue(''), 'morning');
      expect(timelineSlotKeyForCue('   '), 'morning');
    });
  });

  group('timeOfDayPreferenceFrom', () {
    test('maps each slot key to the persisted enum value', () {
      expect(timeOfDayPreferenceFrom('morning'), TimeOfDayPreference.morning);
      expect(
        timeOfDayPreferenceFrom('afternoon'),
        TimeOfDayPreference.afternoon,
      );
      expect(timeOfDayPreferenceFrom('evening'), TimeOfDayPreference.evening);
      expect(timeOfDayPreferenceFrom('anytime'), TimeOfDayPreference.anytime);
      expect(timeOfDayPreferenceFrom(null), TimeOfDayPreference.morning);
    });
  });
}
