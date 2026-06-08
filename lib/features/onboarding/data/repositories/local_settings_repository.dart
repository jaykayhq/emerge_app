import 'package:shared_preferences/shared_preferences.dart';

class LocalSettingsRepository {
  static const _keyIsFirstLaunch = 'isFirstLaunch';
  static const _keyThemeMode = 'themeMode';
  static const _keyLastChallengeRefreshDate = 'lastChallengeRefreshDate';

  static SharedPreferences? _prefs;
  static final Map<String, Object> _fallback = {
    _keyIsFirstLaunch: true,
    _keyThemeMode: 'system',
  };

  Future<void> init() async {
    if (_prefs != null) return;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // In-memory fallback when SharedPreferences fails
      // (e.g., Brave blocking localStorage on web)
    }
  }

  // --- helpers ------------------------------------------------------------

  bool _getBool(String key, {bool defaultValue = false}) {
    return _prefs?.getBool(key) ?? (_fallback[key] as bool? ?? defaultValue);
  }

  String _getString(String key, {String defaultValue = ''}) {
    return _prefs?.getString(key) ?? (_fallback[key] as String? ?? defaultValue);
  }



  Future<void> _setBool(String key, bool value) async {
    if (_prefs != null) {
      await _prefs!.setBool(key, value);
    } else {
      _fallback[key] = value;
    }
  }

  Future<void> _setString(String key, String value) async {
    if (_prefs != null) {
      await _prefs!.setString(key, value);
    } else {
      _fallback[key] = value;
    }
  }



  // --- public API ---------------------------------------------------------

  bool get isFirstLaunch => _getBool(_keyIsFirstLaunch, defaultValue: true);

  Future<void> completeOnboarding() async {
    await _setBool(_keyIsFirstLaunch, false);
  }

  Future<void> resetOnboarding() async {
    await _setBool(_keyIsFirstLaunch, true);
  }

  String get themeMode => _getString(_keyThemeMode, defaultValue: 'system');

  Future<void> setThemeMode(String mode) async {
    await _setString(_keyThemeMode, mode);
  }

  String getLastChallengeRefreshDate() {
    return _getString(_keyLastChallengeRefreshDate);
  }

  Future<void> saveLastChallengeRefreshDate(String date) async {
    await _setString(_keyLastChallengeRefreshDate, date);
  }

  Future<bool> getHasSeenNodeGuide(String nodeId) async {
    return _getBool('hasSeenNodeGuide_$nodeId');
  }

  Future<void> setHasSeenNodeGuide(String nodeId) async {
    await _setBool('hasSeenNodeGuide_$nodeId', true);
  }
}
