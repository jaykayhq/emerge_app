import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocalSettingsRepository {
  static const _boxName = 'settings';
  static const _keyIsFirstLaunch = 'isFirstLaunch';
  static const _keyThemeMode = 'themeMode';
  static const _keyTutorialsEnabled = 'tutorialsEnabled';
  static const _keyTutorialAutoShow = 'tutorialAutoShow';
  static const _secureStorageKey = 'hive_encryption_key';
  static const _keyLastChallengeRefreshDate = 'lastChallengeRefreshDate';

  Future<void> init() async {
    await Hive.initFlutter();

    const secureStorage = FlutterSecureStorage();
    // Check if key exists
    String? encryptionKeyString = await secureStorage.read(
      key: _secureStorageKey,
    );

    if (encryptionKeyString == null) {
      // Generate a new key
      final key = Hive.generateSecureKey();
      encryptionKeyString = base64UrlEncode(key);
      await secureStorage.write(
        key: _secureStorageKey,
        value: encryptionKeyString,
      );
    }

    final encryptionKeyUint8List = base64Url.decode(encryptionKeyString);

    try {
      await Hive.openBox(
        _boxName,
        encryptionCipher: HiveAesCipher(encryptionKeyUint8List),
      );
    } catch (e) {
      // If opening fails (e.g. wrong key or corrupted), delete and recreate
      await Hive.deleteBoxFromDisk(_boxName);
      await Hive.openBox(
        _boxName,
        encryptionCipher: HiveAesCipher(encryptionKeyUint8List),
      );
    }
  }

  bool get isFirstLaunch {
    final box = Hive.box(_boxName);
    return box.get(_keyIsFirstLaunch, defaultValue: true);
  }

  Future<void> completeOnboarding() async {
    final box = Hive.box(_boxName);
    await box.put(_keyIsFirstLaunch, false);
    // Enable tutorials after onboarding completion
    await box.put(_keyTutorialsEnabled, true);
    // Enable auto-show for tutorials (will show once per screen visit)
    await box.put(_keyTutorialAutoShow, true);
  }

  /// Resets the onboarding state to allow re-triggering the flow.
  /// Used for testing or if user wants to redo onboarding.
  Future<void> resetOnboarding() async {
    final box = Hive.box(_boxName);
    await box.put(_keyIsFirstLaunch, true);
  }

  String get themeMode {
    final box = Hive.box(_boxName);
    return box.get(_keyThemeMode, defaultValue: 'system');
  }

  Future<void> setThemeMode(String mode) async {
    final box = Hive.box(_boxName);
    await box.put(_keyThemeMode, mode);
  }

  bool get tutorialsEnabled {
    final box = Hive.box(_boxName);
    return box.get(_keyTutorialsEnabled, defaultValue: false);
  }

  Future<void> setTutorialsEnabled(bool enabled) async {
    final box = Hive.box(_boxName);
    await box.put(_keyTutorialsEnabled, enabled);
    // When enabling tutorials, also enable auto-show
    if (enabled) {
      await box.put(_keyTutorialAutoShow, true);
    }
  }

  /// Returns true if tutorials should auto-show on screen visit (one-time behavior)
  bool get tutorialAutoShow {
    final box = Hive.box(_boxName);
    return box.get(_keyTutorialAutoShow, defaultValue: false);
  }

  /// Disables the auto-show behavior after a tutorial has been shown
  Future<void> disableTutorialAutoShow() async {
    final box = Hive.box(_boxName);
    await box.put(_keyTutorialAutoShow, false);
  }

  /// Re-enables auto-show for tutorials (called when user re-enables in settings)
  Future<void> enableTutorialAutoShow() async {
    final box = Hive.box(_boxName);
    await box.put(_keyTutorialAutoShow, true);
  }

  bool isTutorialCompleted(String tutorialId) {
    final box = Hive.box(_boxName);
    return box.get('tutorial_$tutorialId', defaultValue: false);
  }

  Future<void> completeTutorial(String tutorialId) async {
    final box = Hive.box(_boxName);
    await box.put('tutorial_$tutorialId', true);
  }

  Future<void> resetTutorials() async {
    final box = Hive.box(_boxName);
    final keys = box.keys.where((k) => k.toString().startsWith('tutorial_'));
    for (final key in keys) {
      await box.delete(key);
    }
    // Re-enable auto-show when resetting tutorials
    await box.put(_keyTutorialAutoShow, true);
  }

  /// Get the last date challenges were refreshed (format: 'YYYY-M-D')
  String getLastChallengeRefreshDate() {
    final box = Hive.box(_boxName);
    return box.get(_keyLastChallengeRefreshDate, defaultValue: '');
  }

  /// Save the last date challenges were refreshed
  Future<void> saveLastChallengeRefreshDate(String date) async {
    final box = Hive.box(_boxName);
    await box.put(_keyLastChallengeRefreshDate, date);
  }
}
