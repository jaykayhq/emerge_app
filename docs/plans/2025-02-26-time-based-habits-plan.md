# Time-Based Habits Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace abstract time anchors with specific action-oriented triggers and implement time-based filtering for anytime habits on the timeline.

**Architecture:** Contextual time anchor system (e.g., "after you wake up" instead of "morning"), current time detection for showing relevant habits, persistent time slot user preferences.

**Tech Stack:** Flutter, Dart, Riverpod (state management), SharedPreferences (for wake time storage)

---

## Current State Analysis

**Already Implemented:**
- `TimeOfDayPreference` enum exists: `morning`, `afternoon`, `evening`, `anytime`
- `Habit.timeOfDayPreference` field exists
- Timeline groups habits by time of day
- All 4 time slots show if they have habits

**Needs Implementation:**
- Specific time anchor strings ("after you wake up" vs "morning")
- User wake time storage
- Current time detection
- Show only ONE active time slot at a time
- Time slot transitions throughout the day

---

## Phase 1: Time Anchor Strings & Display

### Task 1.1: Create Time Anchor Service

**Files:**
- Create: `lib/features/habits/domain/services/time_anchor_service.dart`

**Step 1: Create time anchor service**

Create `lib/features/habits/domain/services/time_anchor_service.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// Time anchor types with contextual, action-oriented labels
enum TimeSlot {
  morning,    // After you wake up
  afternoon,  // During/after lunch
  evening,    // Before bed / wind down
  anytime;    // Flexible
}

/// Service for managing time-based habit anchors with contextual labels
class TimeAnchorService {
  static const String _wakeTimeKey = 'user_wake_time';
  static const String _lunchTimeKey = 'user_lunch_time';

  /// Get contextual display text for a time slot
  static String getTimeSlotLabel(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.morning:
        return 'After You Wake Up';
      case TimeSlot.afternoon:
        return 'During Lunch';
      case TimeSlot.evening:
        return 'Before Bed';
      case TimeSlot.anytime:
        return 'Anytime Today';
    }
  }

  /// Get description for a time slot
  static String getTimeSlotDescription(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.morning:
        return 'Start your day with identity votes';
      case TimeSlot.afternoon:
        return 'Maintain momentum mid-day';
      case TimeSlot.evening:
        return 'Wind down intentionally';
      case TimeSlot.anytime:
        return 'Complete whenever fits your schedule';
    }
  }

  /// Get icon for a time slot
  static IconData getTimeSlotIcon(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.morning:
        return Icons.wb_sunny;
      case TimeSlot.afternoon:
        return Icons.wb_cloudy;
      case TimeSlot.evening:
        return Icons.bedtime;
      case TimeSlot.anytime:
        return Icons.access_time;
    }
  }

  /// Convert TimeOfDayPreference to TimeSlot
  static TimeSlot fromPreference(String? preference) {
    switch (preference?.toLowerCase()) {
      case 'morning':
        return TimeSlot.morning;
      case 'afternoon':
        return TimeSlot.afternoon;
      case 'evening':
        return TimeSlot.evening;
      default:
        return TimeSlot.anytime;
    }
  }

  /// Convert TimeSlot to TimeOfDayPreference string
  static String toPreference(TimeSlot slot) {
    return slot.name;
  }

  /// Get user's wake time (default 7:00 AM)
  static Future<TimeOfDay> getWakeTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('$_wakeTimeKey\_hour') ?? 7;
    final minute = prefs.getInt('$_wakeTimeKey\_minute') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Save user's wake time
  static Future<void> setWakeTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_wakeTimeKey\_hour', time.hour);
    await prefs.setInt('$_wakeTimeKey\_minute', time.minute);
  }

  /// Get user's lunch time (default 12:30 PM)
  static Future<TimeOfDay> getLunchTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('$_lunchTimeKey\_hour') ?? 12;
    final minute = prefs.getInt('$_lunchTimeKey\_minute') ?? 30;
    return TimeOfDay(hour: hour, minute: 0);
  }

  /// Save user's lunch time
  static Future<void> setLunchTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_lunchTimeKey\_hour', time.hour);
    await prefs.setInt('$_lunchTimeKey\_minute', time.minute);
  }

  /// Determine current time slot based on actual time
  static Future<TimeSlot> getCurrentTimeSlot() async {
    final now = DateTime.now();
    final hour = now.hour;

    final wakeTime = await getWakeTime();
    final lunchTime = await getLunchTime();
    final wakeHour = wakeTime.hour;
    final lunchHour = lunchTime.hour;

    // Morning: from wake time until lunch time
    if (hour >= wakeHour && hour < lunchHour) {
      return TimeSlot.morning;
    }
    // Afternoon: from lunch time until 6 PM
    if (hour >= lunchHour && hour < 18) {
      return TimeSlot.afternoon;
    }
    // Evening: from 6 PM until wake time next day
    if (hour >= 18 || hour < wakeHour) {
      return TimeSlot.evening;
    }

    return TimeSlot.anytime;
  }

  /// Get time range string for a slot
  static String getTimeRange(TimeSlot slot) async {
    final wakeTime = await getWakeTime();
    final lunchTime = await getLunchTime();

    switch (slot) {
      case TimeSlot.morning:
        return '${_formatTime(wakeTime)} - ${_formatTime(lunchTime)}';
      case TimeSlot.afternoon:
        return '${_formatTime(lunchTime)} - 6:00 PM';
      case TimeSlot.evening:
        return '6:00 PM - ${_formatTime(wakeTime)}';
      case TimeSlot.anytime:
        return 'All day';
    }
  }

  static String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }
}
```

**Step 2: Add shared_preferences to pubspec.yaml**

```bash
flutter pub add shared_preferences
```

**Step 3: Commit**

```bash
git add lib/features/habits/domain/services/time_anchor_service.dart pubspec.yaml
git commit -m "feat: add time anchor service with contextual labels"
```

---

## Phase 2: Update Timeline with New Time Anchors

### Task 2.1: Replace abstract time labels with specific anchors

**Files:**
- Modify: `lib/features/timeline/presentation/screens/timeline_screen.dart`

**Step 1: Update time slot display info**

Replace the `_getTimeOfDayInfo` method:

```dart
/// Get time-of-day display info with specific, action-oriented labels
({String title, String description, IconData icon}) _getTimeOfDayInfo(
  String key,
) {
  final slot = TimeAnchorService.fromPreference(key);

  return (
    title: TimeAnchorService.getTimeSlotLabel(slot),
    description: TimeAnchorService.getTimeSlotDescription(slot),
    icon: TimeAnchorService.getTimeSlotIcon(slot),
  );
}
```

**Step 2: Add import for TimeAnchorService**

```dart
import 'package:emerge_app/features/habits/domain/services/time_anchor_service.dart';
```

**Step 3: Commit**

```bash
git add lib/features/timeline/presentation/screens/timeline_screen.dart
git commit -m "feat: use specific time anchors in timeline"
```

---

## Phase 3: Current Time-Based Slot Filtering

### Task 3.1: Show only the current time slot

**Files:**
- Modify: `lib/features/timeline/presentation/screens/timeline_screen.dart`

**Step 1: Add state for current time slot**

In `_TimelineScreenState`, add:

```dart
TimeSlot _currentTimeSlot = TimeSlot.anytime;

@override
void initState() {
  super.initState();
  _loadAiInsight();
  _checkTutorial();
  _updateCurrentTimeSlot();
}

void _updateCurrentTimeSlot() async {
  final slot = await TimeAnchorService.getCurrentTimeSlot();
  if (mounted) {
    setState(() {
      _currentTimeSlot = slot;
    });
  }
}

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  // Update time slot when dependencies change
  _updateCurrentTimeSlot();
}
```

**Step 2: Update slot filtering logic**

Replace the activeSlots filtering:

```dart
// Show only current time slot, or all if anytime
final currentTimeSlotName = TimeAnchorService.toPreference(_currentTimeSlot);

// Get the current slot's habits
final currentSlotHabits = grouped[currentTimeSlotName] ?? [];

// Always show anytime habits
final anytimeHabits = grouped['anytime'] ?? [];

// Combine current slot habits with anytime
final displayHabits = [...currentSlotHabits, ...anytimeHabits];

// Determine which slot to show
final activeSlots = displayHabits.isEmpty
    ? [] // No habits to show
    : (currentSlotHabits.isEmpty && anytimeHabits.isNotEmpty)
        ? ['anytime'] // Only anytime habits
        : [currentTimeSlotName, ...(anytimeHabits.isNotEmpty ? ['anytime'] : [])];
```

**Step 3: Add slot switcher UI**

```dart
// Add a horizontal slot switcher above the habits
Widget _buildSlotSwitcher(Map<String, List<Habit>> grouped) {
  final slots = TimeSlot.values;
  final currentTimeSlotName = TimeAnchorService.toPreference(_currentTimeSlot);

  return Container(
    height: 50,
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final slotName = TimeAnchorService.toPreference(slot);
        final isActive = slotName == currentTimeSlotName;
        final hasHabits = (grouped[slotName]?.length ?? 0) > 0;

        if (!hasHabits) return SizedBox.shrink();

        return Padding(
          padding: EdgeInsets.only(right: 12),
          child: FilterChip(
            label: Text(TimeAnchorService.getTimeSlotLabel(slot)),
            selected: isActive,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _currentTimeSlot = slot;
                });
              }
            },
            selectedColor: EmergeColors.teal,
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      },
    ),
  );
}
```

**Step 4: Commit**

```bash
git add lib/features/timeline/presentation/screens/timeline_screen.dart
git commit -m "feat: add current time slot filtering to timeline"
```

---

## Phase 4: Habit Creation with Time Preferences

### Task 4.1: Update habit creation to use new anchors

**Files:**
- Modify: `lib/features/habits/presentation/screens/advanced_create_habit_screen.dart`
- Modify: `lib/features/habits/presentation/widgets/habit_form_widgets.dart`

**Step 1: Create time slot picker widget**

Create `lib/features/habits/presentation/widgets/time_slot_picker.dart`:

```dart
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/services/time_anchor_service.dart';
import 'package:flutter/material.dart';

class TimeSlotPicker extends StatelessWidget {
  final TimeOfDayPreference? selected;
  final ValueChanged<TimeOfDayPreference> onChanged;

  const TimeSlotPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When will you do this habit?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        ...TimeOfDayPreference.values.map((pref) {
          final slot = TimeAnchorService.fromPreference(pref.name);
          final isSelected = selected == pref;

          return GestureDetector(
            onTap: () => onChanged(pref),
            child: Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? EmergeColors.teal.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? EmergeColors.teal
                      : Colors.white.withValues(alpha: 0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    TimeAnchorService.getTimeSlotIcon(slot),
                    color: isSelected
                        ? EmergeColors.teal
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TimeAnchorService.getTimeSlotLabel(slot),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          TimeAnchorService.getTimeSlotDescription(slot),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: EmergeColors.teal),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
```

**Step 2: Update habit creation screen**

Replace the existing time preference selector with the new `TimeSlotPicker`.

**Step 3: Commit**

```bash
git add lib/features/habits/presentation/widgets/time_slot_picker.dart
git add lib/features/habits/presentation/screens/advanced_create_habit_screen.dart
git commit -m "feat: use specific time anchors in habit creation"
```

---

## Phase 5: User Time Preferences Setup

### Task 5.1: Create time preferences setup screen

**Files:**
- Create: `lib/features/settings/presentation/screens/time_preferences_screen.dart`

**Step 1: Create time preferences screen**

```dart
import 'package:emerge_app/features/habits/domain/services/time_anchor_service.dart';
import 'package:flutter/material.dart';

class TimePreferencesScreen extends StatefulWidget {
  const TimePreferencesScreen({super.key});

  @override
  State<TimePreferencesScreen> createState() => _TimePreferencesScreenState();
}

class _TimePreferencesScreenState extends State<TimePreferencesScreen> {
  TimeOfDay? _wakeTime;
  TimeOfDay? _lunchTime;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimes();
  }

  Future<void> _loadTimes() async {
    final wake = await TimeAnchorService.getWakeTime();
    final lunch = await TimeAnchorService.getLunchTime();
    setState(() {
      _wakeTime = wake;
      _lunchTime = lunch;
      _isLoading = false;
    });
  }

  Future<void> _selectTime({required bool isWakeTime}) async {
    final now = DateTime.now();
    final initialTime = isWakeTime ? _wakeTime : _lunchTime;

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay(hour: 7, minute: 0),
    );

    if (picked != null) {
      if (isWakeTime) {
        await TimeAnchorService.setWakeTime(picked);
        setState(() => _wakeTime = picked);
      } else {
        await TimeAnchorService.setLunchTime(picked);
        setState(() => _lunchTime = picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text('Time Preferences'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            'Set your daily schedule to personalize when habits appear.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          SizedBox(height: 24),

          // Wake Time
          _TimeSelector(
            label: 'Wake Up Time',
            description: 'Habits appear "after you wake up" from this time',
            time: _wakeTime,
            onTap: () => _selectTime(isWakeTime: true),
            icon: Icons.wb_sunny,
          ),

          SizedBox(height: 16),

          // Lunch Time
          _TimeSelector(
            label: 'Lunch Time',
            description: 'Afternoon habits start around this time',
            time: _lunchTime,
            onTap: () => _selectTime(isWakeTime: false),
            icon: Icons.restaurant,
          ),
        ],
      ),
    );
  }
}

class _TimeSelector extends StatelessWidget {
  final String label;
  final String description;
  final TimeOfDay? time;
  final VoidCallback onTap;
  final IconData icon;

  const _TimeSelector({
    required this.label,
    required this.description,
    required this.time,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = time != null
        ? MaterialLocalizations.of(context).formatTime(time!)
        : 'Not set';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: EmergeColors.teal.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: EmergeColors.teal),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              timeStr,
              style: TextStyle(
                color: EmergeColors.teal,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
```

**Step 2: Add route to router**

Update `lib/core/router/router.dart`:

```dart
GoRoute(
  path: 'time-preferences',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) => const TimePreferencesScreen(),
),
```

**Step 3: Add link from settings**

**Step 4: Commit**

```bash
git add lib/features/settings/presentation/screens/time_preferences_screen.dart
git add lib/core/router/router.dart
git commit -m "feat: add time preferences setup screen"
```

---

## Phase 6: Testing & Verification

### Task 6.1: Create tests for time anchor service

**Files:**
- Create: `test/features/habits/domain/services/time_anchor_service_test.dart`

**Step 1: Write tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/features/habits/domain/services/time_anchor_service.dart';

void main() {
  group('TimeAnchorService', () {
    test('getTimeSlotLabel returns specific labels', () {
      expect(TimeAnchorService.getTimeSlotLabel(TimeSlot.morning), 'After You Wake Up');
      expect(TimeAnchorService.getTimeSlotLabel(TimeSlot.afternoon), 'During Lunch');
      expect(TimeAnchorService.getTimeSlotLabel(TimeSlot.evening), 'Before Bed');
      expect(TimeAnchorService.getTimeSlotLabel(TimeSlot.anytime), 'Anytime Today');
    });

    test('fromPreference converts strings correctly', () {
      expect(TimeAnchorService.fromPreference('morning'), TimeSlot.morning);
      expect(TimeAnchorService.fromPreference('afternoon'), TimeSlot.afternoon);
      expect(TimeAnchorService.fromPreference('evening'), TimeSlot.evening);
      expect(TimeAnchorService.fromPreference('anytime'), TimeSlot.anytime);
      expect(TimeAnchorService.fromPreference('invalid'), TimeSlot.anytime);
    });

    test('toPreference converts TimeSlot to string', () {
      expect(TimeAnchorService.toPreference(TimeSlot.morning), 'morning');
      expect(TimeAnchorService.toPreference(TimeSlot.afternoon), 'afternoon');
    });
  });
}
```

**Step 2: Run tests**

```bash
flutter test test/features/habits/domain/services/time_anchor_service_test.dart
```

**Step 3: Commit**

```bash
git add test/features/habits/domain/services/time_anchor_service_test.dart
git commit -m "test: add time anchor service tests"
```

---

## Summary

### Files Created:
| File | Purpose |
|------|---------|
| `lib/features/habits/domain/services/time_anchor_service.dart` | Core service for time anchors |
| `lib/features/habits/presentation/widgets/time_slot_picker.dart` | UI for picking time slots |
| `lib/features/settings/presentation/screens/time_preferences_screen.dart` | User wake/lunch time setup |
| `test/features/habits/domain/services/time_anchor_service_test.dart` | Service tests |

### Files Modified:
| File | Changes |
|------|---------|
| `pubspec.yaml` | Add shared_preferences |
| `lib/features/timeline/presentation/screens/timeline_screen.dart` | Use new anchors, current time filtering |
| `lib/features/habits/presentation/screens/advanced_create_habit_screen.dart` | Use time slot picker |
| `lib/core/router/router.dart` | Add time preferences route |

### Key Features:
1. **Specific Time Anchors**: "After You Wake Up" instead of "Morning"
2. **Current Time Detection**: Shows habits for the current time of day
3. **Slot Switcher**: Users can see other time slots by tapping
4. **User Customization**: Set wake time and lunch time
5. **Persistent Preferences**: Stored via SharedPreferences

### Migration Notes:
- Existing habits with timeOfDayPreference will automatically map to new labels
- Default wake time: 7:00 AM
- Default lunch time: 12:30 PM
- "Anytime" habits always show alongside current slot
