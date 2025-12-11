import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final focusModeServiceProvider = Provider((ref) => FocusModeService());

final isFocusModeEnabledProvider = StateProvider<bool>((ref) => false);

class FocusModeService {
  // In a real app, this would use shared_preferences to persist the schedule
  // and a background service to trigger the mode.

  TimeOfDay? _sunsetTime;

  void setSunsetTime(TimeOfDay time) {
    _sunsetTime = time;
    // Schedule notification
    debugPrint(
      'Scheduled focus mode notification for sunset time: ${_sunsetTime?.hour}:${_sunsetTime?.minute}',
    );
  }

  bool shouldBeInFocusMode() {
    if (_sunsetTime == null) return false;

    final now = TimeOfDay.now();
    // Simple check: if now is after sunset (and before 4 AM next day, roughly)
    final nowMinutes = now.hour * 60 + now.minute;
    final sunsetMinutes = _sunsetTime!.hour * 60 + _sunsetTime!.minute;

    // Assuming focus mode lasts until 4 AM
    const endMinutes = 4 * 60;

    if (nowMinutes >= sunsetMinutes || nowMinutes < endMinutes) {
      return true;
    }
    return false;
  }
}
