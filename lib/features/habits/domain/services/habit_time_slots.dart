import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';

/// Canonical timeline slot keys. These match the grouping keys used by
/// `timeline_screen.dart` and `habit_timeline_section.dart`.
const List<String> timelineSlotKeys = [
  'morning',
  'afternoon',
  'evening',
  'anytime',
];

/// Keyword table for `StarterHabitBlueprint.shortCue` → slot.
const Map<String, List<String>> _cueKeywords = {
  'anytime': ['bed', 'night', 'reflection', 'journal', 'relax', 'sleep'],
  'morning': [
    'wake',
    'breakfast',
    'coffee',
    'morning',
    'shower',
    'sunrise',
    'rise',
    'workout',
    'train',
  ],
  'afternoon': ['lunch', 'noon', 'midday', 'afternoon'],
  'evening': ['work', 'dinner', 'evening', 'commute'],
};

/// Slot lookup order, highest priority first. 'anytime' is checked first so
/// cues like "Evening reflection" land in "Before Bed", not "After Work".
/// 'morning' precedes 'evening' so "Before workout" resolves to 'morning'
/// rather than matching the 'work' in 'workout'.
const List<String> _cueKeywordOrder = [
  'anytime',
  'morning',
  'afternoon',
  'evening',
];

/// Maps a clock time to the timeline slot key:
/// 4:00–11:59 morning · 12:00–16:59 afternoon · 17:00–20:59 evening ·
/// 21:00–3:59 (and no time) → 'anytime' (displayed as "Before Bed").
String timelineSlotKeyFor(TimeOfDay? time) {
  if (time == null) return 'anytime';
  final h = time.hour;
  if (h >= 4 && h < 12) return 'morning';
  if (h >= 12 && h < 17) return 'afternoon';
  if (h >= 17 && h < 21) return 'evening';
  return 'anytime';
}

/// Maps a starter-habit `shortCue` ("After breakfast", "Before bed") to a
/// timeline slot via keyword match; falls back to 'morning'.
String timelineSlotKeyForCue(String shortCue) {
  final cue = shortCue.toLowerCase();
  // Iterate in explicit priority order (see `_cueKeywordOrder`) rather than
  // relying on map insertion order.
  for (final slot in _cueKeywordOrder) {
    for (final keyword in _cueKeywords[slot]!) {
      if (cue.contains(keyword)) return slot;
    }
  }
  return 'morning';
}

/// Maps a timeline slot key onto the persisted `TimeOfDayPreference` enum.
/// 'anytime' is the stored value for the "Before Bed" rest slot.
TimeOfDayPreference timeOfDayPreferenceFrom(String? slotKey) {
  switch (slotKey) {
    case 'afternoon':
      return TimeOfDayPreference.afternoon;
    case 'evening':
      return TimeOfDayPreference.evening;
    case 'anytime':
      return TimeOfDayPreference.anytime;
    case 'morning':
    default:
      return TimeOfDayPreference.morning;
  }
}
