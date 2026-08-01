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
    // Re-fetch on every call (no early return) so per-test mock stores seeded
    // via SharedPreferences.setMockInitialValues are honored; after the first
    // load getInstance() returns the cached singleton, so this is cheap.
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
    return _prefs?.getString(key) ??
        (_fallback[key] as String? ?? defaultValue);
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

  Set<String> _getKeys() => _prefs?.getKeys() ?? _fallback.keys.toSet();

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
  }

  Future<void> resetOnboarding() async {
    await _setBool(_keyIsFirstLaunch, true);
    await _setBool(_keyEndowmentSeen, false);
  }

  // --- Endowment interstitial (one-time, post sign-up) -------------------

  static const _keyEndowmentSeen = 'endowment_interstitial_seen';

  /// Whether the one-time post-sign-up endowment interstitial has been shown.
  /// Synchronous so the router redirect can read it without awaiting.
  bool get hasSeenEndowment => _getBool(_keyEndowmentSeen);

  Future<void> markEndowmentSeen() async {
    await _setBool(_keyEndowmentSeen, true);
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

  // --- Tutorials toggle (replaces legacy per-screen tutorials) -----------

  static const _keyTutorialsEnabled = 'tutorialsEnabled';

  bool isTutorialsEnabled() =>
      _getBool(_keyTutorialsEnabled, defaultValue: true);

  Future<void> setTutorialsEnabled(bool enabled) async {
    await _setBool(_keyTutorialsEnabled, enabled);
  }

  /// Clears all per-node "seen" flags so tutorials re-appear next visit.
  Future<void> resetTutorials() async {
    final keys = _getKeys().where((k) => k.startsWith('hasSeenNodeGuide_'));
    for (final key in keys) {
      await _remove(key);
    }
  }

  /// Migrates legacy companion visited flags into the node-guide system.
  /// Idempotent: only migrates keys that exist; never overwrites already-seen
  /// node flags. The `discover` flag migrates too — its node dies with the
  /// blueprints page in SP-F.
  Future<void> migrateVisitedFlags() async {
    final keys = _getKeys().where((k) => k.startsWith('companion_visited_'));
    if (keys.isEmpty) return;

    const routeToNode = {
      '/timeline': 'timeline',
      '/world-map': 'world_map',
      '/profile': 'profile',
      '/tribes': 'tribes',
      '/profile/reflections': 'coach',
      '/challenges': 'challenges',
      '/discover': 'discover',
    };

    for (final key in keys) {
      final route = key.substring('companion_visited_'.length);
      final nodeId = routeToNode[route];
      final keyWasSeen = _getBool(key);
      final nodeAlreadySeen =
          nodeId != null && _getBool('hasSeenNodeGuide_$nodeId');
      if (nodeId != null && keyWasSeen && !nodeAlreadySeen) {
        await _setBool('hasSeenNodeGuide_$nodeId', true);
      }
      await _remove(key);
    }
  }
}
