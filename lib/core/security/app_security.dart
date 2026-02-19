import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../utils/app_logger.dart';

class AppSecurity {
  // Anti-tampering checks
  static bool isAppIntegrityValid() {
    if (kDebugMode) return true; // Skip checks in debug mode

    try {
      // Check if app is running in emulator/simulator
      if (_isRunningInEmulator()) {
        if (kDebugMode) {
          print('WARNING: App running in emulator');
        }
        return false;
      }

      // Check for rooted device (Android)
      if (Platform.isAndroid && _isDeviceRooted()) {
        if (kDebugMode) {
          print('WARNING: Device is rooted');
        }
        return false;
      }

      // Check for jailbroken device (iOS)
      if (Platform.isIOS && _isDeviceJailbroken()) {
        if (kDebugMode) {
          print('WARNING: Device is jailbroken');
        }
        return false;
      }

      // Check for debugger attached
      if (_isDebuggerAttached()) {
        if (kDebugMode) {
          print('WARNING: Debugger detected');
        }
        return false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error in integrity check: $e');
      }
      return false;
    }
  }

  // Check if running in emulator
  static bool _isRunningInEmulator() {
    try {
      if (Platform.isAndroid) {
        return _checkAndroidEmulator();
      } else if (Platform.isIOS) {
        return _checkIOSEmulator();
      }
      return false;
    } catch (e) {
      return true; // Assume emulator if check fails
    }
  }

  static bool _checkAndroidEmulator() {
    // Check build fingerprint
    try {
      // This would require platform-specific implementation
      // For now, return false (assume real device)
      return false;
    } catch (e) {
      return true;
    }
  }

  static bool _checkIOSEmulator() {
    // Check for simulator-specific properties
    try {
      // This would require platform-specific implementation
      // For now, return false (assume real device)
      return false;
    } catch (e) {
      return true;
    }
  }

  // Check for rooted device (Android)
  static bool _isDeviceRooted() {
    // This is a basic check - real implementation would be more comprehensive
    final rootFiles = [
      '/system/app/Superuser.apk',
      '/system/xbin/su',
      '/system/bin/su',
      '/data/local/tmp/su',
    ];

    for (final file in rootFiles) {
      try {
        if (File(file).existsSync()) {
          return true;
        }
      } catch (e) {
        // Continue checking other files
      }
    }

    return false;
  }

  // Check for jailbroken device (iOS)
  static bool _isDeviceJailbroken() {
    final jailbreakIndicators = [
      '/Applications/Cydia.app',
      '/usr/sbin/sshd',
      '/etc/apt',
      '/private/var/lib/apt',
    ];

    for (final path in jailbreakIndicators) {
      try {
        if (Directory(path).existsSync()) {
          return true;
        }
      } catch (e) {
        // Continue checking other paths
      }
    }

    return false;
  }

  // Check if debugger is attached
  static bool _isDebuggerAttached() {
    try {
      // Basic debugger check - in debug mode this will return true
      bool inDebugMode = false;
      assert(() {
        inDebugMode = true;
        return true;
      }());
      return inDebugMode;
    } catch (e) {
      return false;
    }
  }

  // SECURE: Proper AES-256 encryption using FlutterSecureStorage
  // FlutterSecureStorage internally uses:
  // - iOS: Keychain Services with AES-256-GCM
  // - Android: Encrypted SharedPreferences (AES-256-GCM)
  // - Web: EncryptedLocalStorage (AES-256-CBC)
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // Use AES-256 encryption on Android
    ),
  );

  /// SECURE: Encrypt sensitive data using platform-native secure storage
  /// Uses AES-256-GCM on iOS/Android, not simple obfuscation
  static Future<void> encryptAndStore(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      AppLogger.e('Encryption error', e);
      rethrow;
    }
  }

  /// SECURE: Retrieve and decrypt sensitive data
  static Future<String?> decryptAndRetrieve(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      AppLogger.e('Decryption error', e);
      return null;
    }
  }

  /// SECURE: Delete encrypted data
  static Future<void> deleteEncryptedData(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      AppLogger.e('Delete encrypted data error', e);
    }
  }

  /// SECURE: Cryptographically secure random string generation
  /// Uses Random.secure() which provides cryptographically strong random numbers
  static String generateSecureRandom(int length) {
    final chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final secureRandom = Random.secure();
    final random = <int>[];

    for (int i = 0; i < length; i++) {
      random.add(chars.codeUnitAt(secureRandom.nextInt(chars.length)));
    }

    return String.fromCharCodes(random);
  }

  /// SECURE: Generate a cryptographically strong token for sessions
  /// Uses SHA-256 hash of secure random bytes + timestamp
  static String generateSecureToken() {
    final secureRandom = Random.secure();
    final bytes = List<int>.generate(32, (_) => secureRandom.nextInt(256));
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final combined = utf8.encode('$timestamp:${base64Encode(bytes)}');
    final hash = sha256.convert(combined);

    return hash.toString(); // 64-character hex string (256 bits)
  }

  // Clear sensitive data from memory
  static void clearSensitiveData(List<String> sensitiveData) {
    for (int i = 0; i < sensitiveData.length; i++) {
      if (sensitiveData[i].isNotEmpty) {
        // Overwrite the string with random data
        sensitiveData[i] = generateSecureRandom(sensitiveData[i].length);
      }
    }
  }

  // Memory pressure detection
  static Future<bool> isMemoryPressureHigh() async {
    try {
      // Basic memory check - real implementation would use platform channels
      return false;
    } catch (e) {
      return false;
    }
  }

  // Check for app tampering (signature verification)
  static bool isAppSignatureValid() {
    // This would involve checking the app's signature against expected values
    // Real implementation would require platform-specific code
    if (kDebugMode) return true;

    try {
      // Placeholder for signature verification
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Signature verification failed: $e');
      }
      return false;
    }
  }

  // Security configuration validation
  static bool validateSecurityConfig() {
    if (kDebugMode) return true;

    final checks = [
      isAppIntegrityValid(),
      isAppSignatureValid(),
      !isRunningInDebugMode(),
    ];

    return checks.every((check) => check);
  }

  // Check if running in debug mode
  static bool isRunningInDebugMode() {
    bool inDebugMode = false;
    assert(() {
      inDebugMode = true;
      return true;
    }());
    return inDebugMode;
  }

  // Get device fingerprint for anti-fraud
  static Map<String, String> getDeviceFingerprint() {
    final fingerprint = <String, String>{};

    try {
      fingerprint['platform'] = Platform.operatingSystem;
      fingerprint['version'] = Platform.operatingSystemVersion;
      fingerprint['localHostname'] = Platform.localHostname;
      fingerprint['numberOfProcessors'] = Platform.numberOfProcessors
          .toString();
      fingerprint['pathSeparator'] = Platform.pathSeparator;

      // Add some obfuscated identifiers
      fingerprint['deviceId'] = generateSecureRandom(32);
    } catch (e) {
      fingerprint['error'] = e.toString();
    }

    return fingerprint;
  }
}
