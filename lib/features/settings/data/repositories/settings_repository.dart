import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

class SettingsRepository {
  // In a real app, use SharedPreferences or Hive here.
  // For now, we'll use in-memory storage or mock it.

  bool _notificationsEnabled = true;
  bool _darkMode = true;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkMode => _darkMode;

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    // await prefs.setBool('notifications_enabled', value);
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    // await prefs.setBool('dark_mode', value);
  }
}
