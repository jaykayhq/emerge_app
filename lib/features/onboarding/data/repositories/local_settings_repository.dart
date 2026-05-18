import 'package:shared_preferences/shared_preferences.dart';

class LocalSettingsRepository {
  static const _keyIsFirstLaunch = 'isFirstLaunch';
  static const _keyThemeMode = 'themeMode';
  static const _keyTutorialsEnabled = 'tutorialsEnabled';
  static const _keyTutorialAutoShow = 'tutorialAutoShow';
  static const _keyLastChallengeRefreshDate = 'lastChallengeRefreshDate';

  static SharedPreferences? _prefs;
  static final Map<String, Object> _fallback = {
    _keyIsFirstLaunch: true,
    _keyThemeMode: 'system',
    _keyTutorialsEnabled: false,
    _keyTutorialAutoShow: false,
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

  Set<String> _getKeys() => _prefs?.getKeys() ?? _fallback.keys.toSet();

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

  Future<void> _remove(String key) async {
    if (_prefs != null) {
      await _prefs!.remove(key);
    } else {
      _fallback.remove(key);
    }
  }

  // --- public API ---------------------------------------------------------

  bool get isFirstLaunch => _getBool(_keyIsFirstLaunch, defaultValue: true);

  Future<void> completeOnboarding() async {
    await _setBool(_keyIsFirstLaunch, false);
    await _setBool(_keyTutorialsEnabled, true);
    await _setBool(_keyTutorialAutoShow, true);
  }

  Future<void> resetOnboarding() async {
    await _setBool(_keyIsFirstLaunch, true);
  }

  String get themeMode => _getString(_keyThemeMode, defaultValue: 'system');

  Future<void> setThemeMode(String mode) async {
    await _setString(_keyThemeMode, mode);
  }

  bool get tutorialsEnabled => _getBool(_keyTutorialsEnabled);

  Future<void> setTutorialsEnabled(bool enabled) async {
    await _setBool(_keyTutorialsEnabled, enabled);
    if (enabled) {
      await _setBool(_keyTutorialAutoShow, true);
    }
  }

  bool get tutorialAutoShow => _getBool(_keyTutorialAutoShow);

  Future<void> disableTutorialAutoShow() async {
    await _setBool(_keyTutorialAutoShow, false);
  }

  Future<void> enableTutorialAutoShow() async {
    await _setBool(_keyTutorialAutoShow, true);
  }

  bool isTutorialCompleted(String tutorialId) {
    return _getBool('tutorial_$tutorialId');
  }

  Future<void> completeTutorial(String tutorialId) async {
    await _setBool('tutorial_$tutorialId', true);
  }

  Future<void> resetTutorials() async {
    final keys = _getKeys().where((k) => k.startsWith('tutorial_'));
    for (final key in keys) {
      await _remove(key);
    }
    await _setBool(_keyTutorialAutoShow, true);
  }

  String getLastChallengeRefreshDate() {
    return _getString(_keyLastChallengeRefreshDate);
  }

  Future<void> saveLastChallengeRefreshDate(String date) async {
    await _setString(_keyLastChallengeRefreshDate, date);
  }
}
