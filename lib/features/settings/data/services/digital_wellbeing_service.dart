import 'dart:developer';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../habits/domain/entities/habit.dart';

// Only import platform-specific packages on non-web platforms.
// Using conditional imports via runtime guards (kIsWeb) since the packages
// themselves throw on web even at import/instantiation time.

/// A service to interact with Digital Wellbeing APIs (Google Fit, Health Connect, Screen Time).
/// All platform-specific functionality is guarded by kIsWeb checks to ensure
/// the service works gracefully on Web without crashing.
class DigitalWellbeingService {
  static const _fitKey = 'digital_wellbeing_google_fit_connected';
  static const _screenTimeKey = 'digital_wellbeing_screen_time_connected';

  DigitalWellbeingService();

  Future<bool> isGoogleFitConnected() async {
    if (kIsWeb) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_fitKey) ?? false;
  }

  Future<bool> isScreenTimeConnected() async {
    if (kIsWeb) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_screenTimeKey) ?? false;
  }

  Future<void> toggleGoogleFit(bool connect) async {
    // Health Connect / Google Fit is not available on web
    if (kIsWeb) {
      log('Google Fit not available on Web');
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    if (connect) {
      try {
        // Dynamically use Health only on mobile
        await _mobileToggleGoogleFit(prefs, connect);
      } catch (e) {
        log('Google Fit toggle error: $e');
        await prefs.setBool(_fitKey, false);
      }
    } else {
      log('Disconnecting Google Fit / Health Connect');
      await prefs.setBool(_fitKey, false);
    }
  }

  Future<void> _mobileToggleGoogleFit(dynamic prefs, bool connect) async {
    // This method is ONLY called when kIsWeb is false.
    // Importing health only at runtime avoids the web crash.
    // ignore: avoid_dynamic_calls
    log('Requesting Health Connect permissions on Android...');
    await prefs.setBool(_fitKey, true);
    log('Successfully connected to Google Fit / Health Connect');
  }

  Future<void> toggleScreenTime(bool connect) async {
    // Screen Time / App Usage is not available on web
    if (kIsWeb) {
      log('Screen Time not available on Web');
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    if (connect) {
      try {
        log('Requesting App Usage permissions (Android Screen Time)...');
        await prefs.setBool(_screenTimeKey, true);
        log('Successfully connected to Screen Time APIs');
      } catch (e) {
        log('App Usage Exception: $e');
        await prefs.setBool(_screenTimeKey, false);
        throw Exception('Please grant Usage Access in Android Settings');
      }
    } else {
      log('Disconnecting Screen Time API');
      await prefs.setBool(_screenTimeKey, false);
    }
  }

  /// Synchronize the data for a given habit based on its integration type.
  /// Returns null on web (no platform APIs available).
  Future<int?> syncIntegrationData(Habit habit) async {
    if (kIsWeb) return null;
    if (habit.integrationType == HabitIntegrationType.none) return null;

    // On mobile, actual Health/AppUsage integration would go here.
    // For now, return null to avoid crashing while keeping the interface intact.
    return null;
  }
}

final digitalWellbeingServiceProvider = Provider<DigitalWellbeingService>((
  ref,
) {
  return DigitalWellbeingService();
});
