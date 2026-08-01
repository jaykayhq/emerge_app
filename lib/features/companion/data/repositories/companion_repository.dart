import 'package:shared_preferences/shared_preferences.dart';

class CompanionRepository {
  static const _keyCompanionEnabled = 'companion_enabled';
  static const _keyLastCheckin = 'companion_last_checkin';

  static SharedPreferences? _prefs;
  static final Map<String, Object> _fallback = {_keyCompanionEnabled: true};

  Future<void> init() async {
    if (_prefs != null) return;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {}
  }

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

  // --- Dismissal tracking ---

  bool isMessageDismissed(String messageId) =>
      _getBool('companion_dismissed_$messageId');

  Future<void> dismissMessage(String messageId) async {
    await _setBool('companion_dismissed_$messageId', true);
  }

  // --- Daily check-in ---

  bool hasCheckedInToday() {
    final date = _getString(_keyLastCheckin);
    if (date.isEmpty) return false;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return date == today;
  }

  Future<void> markCheckInDone() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _setString(_keyLastCheckin, today);
  }

  // --- Cooldown ---

  bool isCooldownActive() {
    return false;
  }

  // --- Companion enabled ---

  bool isCompanionEnabled() =>
      _getBool(_keyCompanionEnabled, defaultValue: true);

  Future<void> setCompanionEnabled(bool enabled) async {
    await _setBool(_keyCompanionEnabled, enabled);
  }
}
