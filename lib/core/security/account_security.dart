import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

class AccountSecurity {
  static final AccountSecurity _instance = AccountSecurity._internal();
  factory AccountSecurity() => _instance;
  AccountSecurity._internal();

  final Map<String, LoginAttemptData> _loginAttempts = {};
  final Map<String, AccountLockData> _lockedAccounts = {};
  Timer? _cleanupTimer;

  // Configuration
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const Duration attemptWindow = Duration(minutes: 5);
  static const Duration cleanupInterval = Duration(minutes: 1);

  void initialize() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(cleanupInterval, (_) => _cleanupExpiredData());
  }

  void dispose() {
    _cleanupTimer?.cancel();
  }

  // Record a failed login attempt
  void recordFailedAttempt(String email) {
    final normalizedEmail = email.toLowerCase().trim();
    final now = DateTime.now();

    final attempt = _loginAttempts[normalizedEmail] ?? LoginAttemptData();

    // Remove attempts outside the window
    attempt.attempts.removeWhere((timestamp) =>
        now.difference(timestamp) > attemptWindow);

    // Add new attempt
    attempt.attempts.add(now);
    _loginAttempts[normalizedEmail] = attempt;

    // Check if account should be locked
    if (attempt.attempts.length >= maxFailedAttempts) {
      _lockAccount(normalizedEmail);
    }
  }

  // Record a successful login
  void recordSuccessfulLogin(String email) {
    final normalizedEmail = email.toLowerCase().trim();
    _loginAttempts.remove(normalizedEmail);
    _lockedAccounts.remove(normalizedEmail);
  }

  // Check if account is locked
  bool isAccountLocked(String email) {
    final normalizedEmail = email.toLowerCase().trim();
    final lockData = _lockedAccounts[normalizedEmail];

    if (lockData == null) return false;

    // Check if lockout has expired
    if (DateTime.now().isAfter(lockData.lockUntil)) {
      _lockedAccounts.remove(normalizedEmail);
      return false;
    }

    return true;
  }

  // Get remaining lockout time
  Duration? getRemainingLockoutTime(String email) {
    final normalizedEmail = email.toLowerCase().trim();
    final lockData = _lockedAccounts[normalizedEmail];

    if (lockData == null) return null;

    final now = DateTime.now();
    if (now.isAfter(lockData.lockUntil)) {
      _lockedAccounts.remove(normalizedEmail);
      return null;
    }

    return lockData.lockUntil.difference(now);
  }

  // Get number of failed attempts
  int getFailedAttempts(String email) {
    final normalizedEmail = email.toLowerCase().trim();
    final attempt = _loginAttempts[normalizedEmail];

    if (attempt == null) return 0;

    final now = DateTime.now();
    // Remove attempts outside the window
    attempt.attempts.removeWhere((timestamp) =>
        now.difference(timestamp) > attemptWindow);

    return attempt.attempts.length;
  }

  // Lock an account
  void _lockAccount(String email) {
    final lockUntil = DateTime.now().add(lockoutDuration);
    _lockedAccounts[email] = AccountLockData(lockUntil: lockUntil);

    if (kDebugMode) {
      print('Account locked: $email until $lockUntil');
    }
  }

  // Clean up expired data
  void _cleanupExpiredData() {
    final now = DateTime.now();

    // Clean up old login attempts
    _loginAttempts.removeWhere((email, attempt) {
      attempt.attempts.removeWhere((timestamp) =>
          now.difference(timestamp) > attemptWindow);
      return attempt.attempts.isEmpty;
    });

    // Clean up expired locks
    _lockedAccounts.removeWhere((email, lockData) =>
        now.isAfter(lockData.lockUntil));
  }

  // Generate secure session token
  String generateSessionToken() {
    final bytes = List<int>.generate(32, (_) => Random().nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // Check if session is valid (placeholder for actual implementation)
  bool isSessionValid(String token) {
    // In a real implementation, this would check against a database
    // and verify the token hasn't expired or been revoked
    return token.isNotEmpty && token.length == 64;
  }

  // Get security status for debugging
  Map<String, dynamic> getSecurityStatus() {
    return {
      'activeLoginAttempts': _loginAttempts.length,
      'lockedAccounts': _lockedAccounts.length,
      'maxFailedAttempts': maxFailedAttempts,
      'lockoutDurationMinutes': lockoutDuration.inMinutes,
      'attemptWindowMinutes': attemptWindow.inMinutes,
    };
  }
}

class LoginAttemptData {
  List<DateTime> attempts = [];

  LoginAttemptData();
}

class AccountLockData {
  final DateTime lockUntil;

  AccountLockData({required this.lockUntil});
}