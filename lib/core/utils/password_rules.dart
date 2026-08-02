/// Single source of truth for password rules.
///
/// `AppValidators.validatePassword` and the `PasswordRequirementChecklist`
/// both consume these — a rules change can never desync the UI from
/// validation.
class PasswordRule {
  final String label;
  final bool Function(String value) passes;
  const PasswordRule({required this.label, required this.passes});
}

abstract final class PasswordRules {
  static const int minLength = 12;
  static const int maxLength = 128;
  static const int minCharacterClasses = 3;

  static final RegExp _uppercase = RegExp(r'[A-Z]');
  static final RegExp _lowercase = RegExp(r'[a-z]');
  static final RegExp _digits = RegExp(r'[0-9]');
  static final RegExp _special = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
  static final RegExp _repeated = RegExp(r'(.)\1{2,}');

  static bool hasUpper(String v) => _uppercase.hasMatch(v);
  static bool hasLower(String v) => _lowercase.hasMatch(v);
  static bool hasDigit(String v) => _digits.hasMatch(v);
  static bool hasSpecial(String v) => _special.hasMatch(v);

  static int characterClasses(String v) => [
        hasUpper(v),
        hasLower(v),
        hasDigit(v),
        hasSpecial(v),
      ].where((b) => b).length;

  static final Set<String> _commonPasswords = {
    'password', '123456', '12345678', 'qwerty', 'abc123', 'password1',
    '123456789', '1234567', '12345', '1234567890', 'iloveyou', 'princess',
    'admin', 'welcome', '666666', 'football', '111111', '123123', '654321',
    'password123', 'qwerty123', 'qwertyuiop', 'asdfgh', 'zxcvbnm', 'letmein',
    'monkey', 'dragon', 'baseball', 'superman', 'master', '2019', '2020',
    '2021', '2022', '2023', '2024', '2025', '11111111', '00000000',
    'aaaaaaaa', 'passw0rd', 'admin123',
  };

  static bool isCommon(String value) {
    final normalized = value.toLowerCase();
    if (_commonPasswords.contains(normalized)) return true;
    for (final common in _commonPasswords.take(50)) {
      if (normalized.contains(common) &&
          common.length >= normalized.length * 0.5) {
        return true;
      }
    }
    return false;
  }

  static bool hasSequentialChars(String value) {
    final lower = value.toLowerCase();
    for (int i = 0; i <= lower.length - 3; i++) {
      final c1 = lower.codeUnitAt(i);
      final c2 = lower.codeUnitAt(i + 1);
      final c3 = lower.codeUnitAt(i + 2);
      if (c2 == c1 + 1 && c3 == c2 + 1) return true;
      if (c2 == c1 - 1 && c3 == c2 - 1) return true;
    }
    return false;
  }

  static bool hasRepeatedChars(String value) => _repeated.hasMatch(value);

  static bool isValid(String value) =>
      value.length >= minLength &&
      value.length <= maxLength &&
      !isCommon(value) &&
      characterClasses(value) >= minCharacterClasses &&
      !hasSequentialChars(value) &&
      !hasRepeatedChars(value);

  static final List<PasswordRule> checklistItems = [
    PasswordRule(
      label: 'At least 12 characters',
      passes: (v) => v.length >= minLength,
    ),
    PasswordRule(
      label: '3 of 4 character types',
      passes: (v) => characterClasses(v) >= minCharacterClasses,
    ),
    PasswordRule(
      label: 'No common or sequential passwords',
      passes: (v) => !isCommon(v) && !hasSequentialChars(v),
    ),
    PasswordRule(
      label: 'No repeated characters',
      passes: (v) => !hasRepeatedChars(v),
    ),
  ];
}
