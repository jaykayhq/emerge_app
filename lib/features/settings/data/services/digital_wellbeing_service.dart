import 'dart:developer';

import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:app_usage/app_usage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../habits/domain/entities/habit.dart';

/// A service to interact with Digital Wellbeing APIs (Google Fit, Health Connect, Screen Time).
/// In 2025 production, this would use `health` or `flutter_health_connect` packages.
/// For this implementation, we simulate the async connection securely with robust state management
/// and local caching to prevent UI breaking and ensure it's "production ready" mechanically.
class DigitalWellbeingService {
  static const _fitKey = 'digital_wellbeing_google_fit_connected';
  static const _screenTimeKey = 'digital_wellbeing_screen_time_connected';

  final Health _health = Health();

  DigitalWellbeingService() {
    _health
        .configure(); // health package uses default configure inside the constructor
  }

  Future<bool> isGoogleFitConnected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_fitKey) ?? false;
  }

  Future<bool> isScreenTimeConnected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_screenTimeKey) ?? false;
  }

  Future<void> toggleGoogleFit(bool connect) async {
    final prefs = await SharedPreferences.getInstance();

    if (connect && Platform.isAndroid) {
      log('Requesting Health Connect permissions...');
      final types = [HealthDataType.STEPS, HealthDataType.SLEEP_AWAKE];
      final permissions = [HealthDataAccess.READ, HealthDataAccess.READ];

      bool hasPermissions =
          await _health.hasPermissions(types, permissions: permissions) ??
          false;

      if (!hasPermissions) {
        try {
          final requested = await _health.requestAuthorization(
            types,
            permissions: permissions,
          );
          if (!requested) {
            log('Health permissions denied by user.');
            await prefs.setBool(_fitKey, false);
            throw Exception('Health permissions denied');
          }
        } catch (e) {
          log('Health Authorization Exception: $e');
          await prefs.setBool(_fitKey, false);
          return;
        }
      }

      log('Successfully connected to Google Fit / Health Connect');
      await prefs.setBool(_fitKey, true);
    } else {
      log('Disconnecting Google Fit / Health Connect');
      await prefs.setBool(_fitKey, false);
    }
  }

  Future<void> toggleScreenTime(bool connect) async {
    final prefs = await SharedPreferences.getInstance();

    if (connect && Platform.isAndroid) {
      log('Requesting App Usage permissions (Android Screen Time)...');
      try {
        // AppUsage package implicitly prompts the user to open settings to grant
        // Usage Access permissions if they haven't already.
        DateTime endDate = DateTime.now();
        DateTime startDate = endDate.subtract(const Duration(hours: 1));
        await AppUsage().getAppUsage(startDate, endDate);

        log('Successfully connected to Screen Time APIs');
        await prefs.setBool(_screenTimeKey, true);
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

  /// Synchronize the data for a given habit based on its integration type
  Future<int?> syncIntegrationData(Habit habit) async {
    if (habit.integrationType == HabitIntegrationType.none) return null;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    if (habit.integrationType == HabitIntegrationType.healthSteps) {
      if (!await isGoogleFitConnected()) return null;
      try {
        final steps = await _health.getTotalStepsInInterval(startOfDay, now);
        return steps;
      } catch (e) {
        log('Error reading steps: $e');
        return null;
      }
    }

    if (habit.integrationType == HabitIntegrationType.screenTimeLimit &&
        Platform.isAndroid) {
      if (!await isScreenTimeConnected()) return null;
      try {
        final usageList = await AppUsage().getAppUsage(startOfDay, now);
        int totalSeconds = 0;
        for (var info in usageList) {
          totalSeconds += info.usage.inSeconds;
        }
        // Return total minutes of screen time
        return totalSeconds ~/ 60;
      } catch (e) {
        log('Error reading app usage: $e');
        return null;
      }
    }

    return null;
  }
}

final digitalWellbeingServiceProvider = Provider<DigitalWellbeingService>((
  ref,
) {
  return DigitalWellbeingService();
});
