import 'package:shared_preferences/shared_preferences.dart';

/// Persistence for the rating prompt gate. Abstract so tests can inject a fake.
abstract class RatingPromptStore {
  Future<DateTime?> lastAskedAt();
  Future<String?> versionAskedFor();
  Future<bool> dontAskAgain();
  Future<void> recordAsked(DateTime at, String version);
  Future<void> setDontAskAgain();
}

/// SharedPreferences-backed implementation.
class SharedPreferencesRatingPromptStore implements RatingPromptStore {
  static const _kLastAsked = 'rating_prompt.lastAskedAt';
  static const _kVersion = 'rating_prompt.versionAskedFor';
  static const _kDontAskAgain = 'rating_prompt.dontAskAgain';

  @override
  Future<DateTime?> lastAskedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLastAsked);
    return raw == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(int.parse(raw));
  }

  @override
  Future<String?> versionAskedFor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kVersion);
  }

  @override
  Future<bool> dontAskAgain() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDontAskAgain) ?? false;
  }

  @override
  Future<void> recordAsked(DateTime at, String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastAsked, at.millisecondsSinceEpoch.toString());
    await prefs.setString(_kVersion, version);
  }

  @override
  Future<void> setDontAskAgain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDontAskAgain, true);
  }
}
