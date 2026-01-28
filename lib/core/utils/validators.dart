class AppValidators {
  // Email validation with enhanced security
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // Remove leading/trailing whitespace
    final email = value.trim();

    // Basic format validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    // Additional security checks
    if (email.length > 254) {
      return 'Email address is too long';
    }

    if (email.startsWith('.') || email.endsWith('.')) {
      return 'Email address cannot start or end with a dot';
    }

    if (email.contains('..')) {
      return 'Email address cannot contain consecutive dots';
    }

    // Block suspicious domains
    final suspiciousDomains = [
      'tempmail.com',
      '10minutemail.com',
      'guerrillamail.com',
    ];
    final domain = email.split('@').last.toLowerCase();
    if (suspiciousDomains.any((suspicious) => domain.contains(suspicious))) {
      return 'Please use a legitimate email address';
    }

    return null;
  }

  // Password validation with enhanced security
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    // ENHANCED: Minimum 12 characters (NIST guidelines - up from 8)
    if (value.length < 12) {
      return 'Password must be at least 12 characters long';
    }

    // Maximum length requirement
    if (value.length > 128) {
      return 'Password is too long';
    }

    // ENHANCED: Check for common weak passwords from leaked databases
    if (_isCommonPassword(value)) {
      return 'This password is too common. Please choose a stronger one.';
    }

    // Check for character variety
    bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = value.contains(RegExp(r'[a-z]'));
    bool hasDigits = value.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = value.contains(
      RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
    );

    int strengthScore = 0;
    if (hasUppercase) strengthScore++;
    if (hasLowercase) strengthScore++;
    if (hasDigits) strengthScore++;
    if (hasSpecialCharacters) strengthScore++;

    if (strengthScore < 3) {
      return 'Password must include at least 3 of: uppercase, lowercase, numbers, special characters';
    }

    // Check for sequential characters (e.g., "abc", "123")
    if (_hasSequentialChars(value)) {
      return 'Password cannot contain sequential characters (e.g., "abc", "123")';
    }

    // ENHANCED: Check for repeated characters (e.g., "aaa", "111")
    if (_hasRepeatedChars(value)) {
      return 'Password cannot contain repeated characters (e.g., "aaa", "111")';
    }

    return null;
  }

  // Username validation with security checks
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }

    final username = value.trim();

    if (username.length < 3) {
      return 'Username must be at least 3 characters long';
    }

    if (username.length > 30) {
      return 'Username is too long';
    }

    // Only allow alphanumeric characters, underscores, and hyphens
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!usernameRegex.hasMatch(username)) {
      return 'Username can only contain letters, numbers, underscores, and hyphens';
    }

    // Block inappropriate usernames
    final blockedUsernames = [
      'admin',
      'administrator',
      'root',
      'system',
      'moderator',
      'support',
      'help',
      'info',
      'contact',
      'api',
      'test',
      'user',
      'guest',
      'anonymous',
      'null',
      'undefined',
    ];

    if (blockedUsernames.contains(username.toLowerCase())) {
      return 'This username is not allowed';
    }

    // Block usernames that start with special patterns
    if (username.startsWith('_') ||
        username.startsWith('-') ||
        username.endsWith('_') ||
        username.endsWith('-')) {
      return 'Username cannot start or end with underscore or hyphen';
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  // General text validation with security
  static String? validateText(
    String? value, {
    required String fieldName,
    int minLength = 1,
    int maxLength = 1000,
    bool allowEmpty = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      return allowEmpty ? null : '$fieldName is required';
    }

    final text = value.trim();

    if (text.length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }

    if (text.length > maxLength) {
      return '$fieldName is too long (max $maxLength characters)';
    }

    // Check for potentially dangerous content
    if (text.contains(
      RegExp(r'<script|javascript:|onload=|onerror=', caseSensitive: false),
    )) {
      return 'Invalid content detected';
    }

    // Check for excessive repetition (possible DoS attempt)
    if (_hasExcessiveRepetition(text)) {
      return 'Invalid content format';
    }

    return null;
  }

  // ENHANCED: Check against common password database (top 100 from leaked databases)
  static bool _isCommonPassword(String password) {
    final normalizedPassword = password.toLowerCase();

    final commonPasswords = {
      'password', '123456', '12345678', 'qwerty', 'abc123',
      'password1', '123456789', '1234567', '12345', '1234567890',
      'iloveyou', 'princess', 'admin', 'welcome', '666666',
      'football', '111111', '123123', '654321', 'password123',
      'qwerty123', 'qwertyuiop', 'asdfgh', 'zxcvbnm', 'letmein',
      'monkey', 'dragon', 'baseball', 'superman', 'master',
      '2019', '2020', '2021', '2022', '2023', '2024', '2025',
      '11111111', '00000000', 'aaaaaaaa', 'passw0rd', 'admin123',
    };

    if (commonPasswords.contains(normalizedPassword)) {
      return true;
    }

    for (final common in commonPasswords.take(50)) {
      if (normalizedPassword.contains(common) &&
          common.length >= normalizedPassword.length * 0.5) {
        return true;
      }
    }

    return false;
  }

  // ENHANCED: Check for repeated characters (e.g., "aaa", "111")
  static bool _hasRepeatedChars(String password) {
    return RegExp(r'(.)\1{2,}').hasMatch(password);
  }

  // Check for sequential characters in password
  static bool _hasSequentialChars(String password) {
    password = password.toLowerCase();

    // Check for 3+ consecutive characters
    for (int i = 0; i <= password.length - 3; i++) {
      int char1 = password.codeUnitAt(i);
      int char2 = password.codeUnitAt(i + 1);
      int char3 = password.codeUnitAt(i + 2);

      // Check for ascending sequence (abc, 123)
      if (char2 == char1 + 1 && char3 == char2 + 1) {
        return true;
      }

      // Check for descending sequence (cba, 321)
      if (char2 == char1 - 1 && char3 == char2 - 1) {
        return true;
      }
    }

    return false;
  }

  // Check for excessive repetition
  static bool _hasExcessiveRepetition(String text) {
    // Check for the same character repeated 5+ times
    if (RegExp(r'(.)\1{4,}').hasMatch(text)) {
      return true;
    }

    // Check for the same word repeated 3+ times
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    if (words.length >= 3) {
      for (int i = 0; i <= words.length - 3; i++) {
        if (words[i] == words[i + 1] &&
            words[i] == words[i + 2] &&
            words[i].length > 2) {
          return true;
        }
      }
    }

    return false;
  }

  // Sanitize input text
  static String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(
          RegExp(r'javascript:', caseSensitive: false),
          '',
        ) // Remove javascript protocol
        .replaceAll(
          RegExp(r'on\w+\s*=', caseSensitive: false),
          '',
        ); // Remove event handlers
  }

  // Validate URL format
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
      caseSensitive: false,
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    return null;
  }
}
