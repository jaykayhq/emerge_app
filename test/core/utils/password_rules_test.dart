import 'package:emerge_app/core/utils/password_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordRules predicates', () {
    test('length rules', () {
      expect(PasswordRules.minLength, 12);
      expect(PasswordRules.maxLength, 128);
      expect(PasswordRules.hasUpper('aBc'), isTrue);
      expect(PasswordRules.hasLower('aBc'), isTrue);
      expect(PasswordRules.hasDigit('a1c'), isTrue);
      expect(PasswordRules.hasSpecial('a@c'), isTrue);
    });

    test('characterClasses counts the 4 classes', () {
      expect(PasswordRules.characterClasses('abc'), 1);
      expect(PasswordRules.characterClasses('abc1'), 2);
      expect(PasswordRules.characterClasses('aB1@'), 4);
    });

    test('isCommon catches leaked passwords and substrings', () {
      expect(PasswordRules.isCommon('password123'), isTrue);
      expect(PasswordRules.isCommon('Tr0ub4dor&3!'), isFalse);
    });

    test('hasSequentialChars catches abc and 321', () {
      expect(PasswordRules.hasSequentialChars('abcdef'), isTrue);
      expect(PasswordRules.hasSequentialChars('cba'), isTrue);
      expect(PasswordRules.hasSequentialChars('Tr0ub4dor&3!'), isFalse);
    });

    test('hasRepeatedChars catches aaa', () {
      expect(PasswordRules.hasRepeatedChars('paaaword'), isTrue);
      expect(PasswordRules.hasRepeatedChars('Tr0ub4dor&3!'), isFalse);
    });
  });

  group('checklistItems', () {
    test('items match the validator contract', () {
      // Every checklist item must have a label and a predicate, and a
      // password that fails ONLY that item must exist so the checklist can
      // never drift from validatePassword.
      expect(PasswordRules.checklistItems, hasLength(4));
      for (final item in PasswordRules.checklistItems) {
        expect(item.label, isNotEmpty);
        expect(item.passes('Tr0ub4dor&3!'), isTrue);
      }
    });

    test('each rule maps to exactly one checklist item (no drift)', () {
      // A password failing exactly one rule must flip exactly that item —
      // if a rule is added to the validator without a checklist entry (or
      // vice versa), the per-predicate candidates below stop being
      // single-failure and this test fails.
      const singleFailurePasswords = <String, String>{
        'At least 12 characters': 'Ab1!aA2bB3c',
        '3 of 4 character types': 'a1a1a1a1a1a1',
        'No common or sequential passwords': 'Abcdef123!@#',
        'No repeated characters': 'aaaa1111BBB!',
      };
      expect(
        PasswordRules.checklistItems,
        hasLength(singleFailurePasswords.length),
      );
      for (final entry in singleFailurePasswords.entries) {
        for (final item in PasswordRules.checklistItems) {
          expect(
            item.passes(entry.value),
            item.label != entry.key,
            reason: 'candidate for "${entry.key}" must fail ONLY that item '
                '(${item.label} expected ${item.label != entry.key})',
          );
        }
      }
    });

    test('isValid requires every checklist item', () {
      expect(PasswordRules.isValid('Tr0ub4dor&3!'), isTrue);
      expect(PasswordRules.isValid('short'), isFalse);
      expect(PasswordRules.isValid('aaaaaaaaaaaa'), isFalse); // repeated
    });
  });
}
