import 'package:shared_preferences/shared_preferences.dart';

class LocalSettingsRepository {
  static const _keyIsFirstLaunch = 'isFirstLaunch';
  static const _keyThemeMode = 'themeMode';
  static const _keyTutorialsEnabled = 'tutorialsEnabled';
  static const _keyTutorialAutoShow = 'tutorialAutoShow';
  static const _keyLastChallengeRefreshDate = 'lastChallengeRefreshDate';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    return _prefs!;
  }

  bool get isFirstLaunch {
    return _p.getBool(_keyIsFirstLaunch) ?? true;
  }

  Future<void> completeOnboarding() async {
    await _p.setBool(_keyIsFirstLaunch, false);
    await _p.setBool(_keyTutorialsEnabled, true);
    await _p.setBool(_keyTutorialAutoShow, true);
  }

  Future<void> resetOnboarding() async {
    await _p.setBool(_keyIsFirstLaunch, true);
  }

  String get themeMode {
    return _p.getString(_keyThemeMode) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    await _p.setString(_keyThemeMode, mode);
  }

  bool get tutorialsEnabled {
    return _p.getBool(_keyTutorialsEnabled) ?? false;
  }

  Future<void> setTutorialsEnabled(bool enabled) async {
    await _p.setBool(_keyTutorialsEnabled, enabled);
    if (enabled) {
      await _p.setBool(_keyTutorialAutoShow, true);
    }
  }

  bool get tutorialAutoShow {
    return _p.getBool(_keyTutorialAutoShow) ?? false;
  }

  Future<void> disableTutorialAutoShow() async {
    await _p.setBool(_keyTutorialAutoShow, false);
  }

  Future<void> enableTutorialAutoShow() async {
    await _p.setBool(_keyTutorialAutoShow, true);
  }

  bool isTutorialCompleted(String tutorialId) {
    return _p.getBool('tutorial_$tutorialId') ?? false;
  }

  Future<void> completeTutorial(String tutorialId) async {
    await _p.setBool('tutorial_$tutorialId', true);
  }

  Future<void> resetTutorials() async {
    final keys = _p.getKeys().where((k) => k.startsWith('tutorial_'));
    for (final key in keys) {
      await _p.remove(key);
    }
    await _p.setBool(_keyTutorialAutoShow, true);
  }

  String getLastChallengeRefreshDate() {
    return _p.getString(_keyLastChallengeRefreshDate) ?? '';
  }

  Future<void> saveLastChallengeRefreshDate(String date) async {
    await _p.setString(_keyLastChallengeRefreshDate, date);
  }
}
