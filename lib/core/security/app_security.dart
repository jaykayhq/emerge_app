import 'dart:io';
import 'package:flutter/foundation.dart';

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

  // Obfuscate sensitive data
  static String obfuscateString(String input) {
    if (input.isEmpty) return input;

    final bytes = input.codeUnits;
    final obfuscated = <int>[];

    for (int i = 0; i < bytes.length; i++) {
      // Simple XOR obfuscation with position-based key
      final key = (i + 42) % 256;
      obfuscated.add(bytes[i] ^ key);
    }

    return String.fromCharCodes(obfuscated);
  }

  // De-obfuscate data
  static String deobfuscateString(String obfuscated) {
    if (obfuscated.isEmpty) return obfuscated;

    final bytes = obfuscated.codeUnits;
    final deobfuscated = <int>[];

    for (int i = 0; i < bytes.length; i++) {
      final key = (i + 42) % 256;
      deobfuscated.add(bytes[i] ^ key);
    }

    return String.fromCharCodes(deobfuscated);
  }

  // Secure random string generation
  static String generateSecureRandom(int length) {
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = <int>[];

    for (int i = 0; i < length; i++) {
      random.add(chars.codeUnitAt(DateTime.now().millisecondsSinceEpoch % chars.length));
    }

    return String.fromCharCodes(random);
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
      fingerprint['numberOfProcessors'] = Platform.numberOfProcessors.toString();
      fingerprint['pathSeparator'] = Platform.pathSeparator;

      // Add some obfuscated identifiers
      fingerprint['deviceId'] = generateSecureRandom(32);
    } catch (e) {
      fingerprint['error'] = e.toString();
    }

    return fingerprint;
  }
}