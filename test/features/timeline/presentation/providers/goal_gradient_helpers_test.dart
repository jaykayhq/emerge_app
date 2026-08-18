import 'package:emerge_app/features/timeline/presentation/providers/goal_gradient_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestHabit implements HasCompletion {
  const _TestHabit(this.isCompleted);
  @override
  final bool isCompleted;
}

void main() {
  group('computeCompletionFraction', () {
    test('returns 0.0 when no habits exist', () {
      expect(computeCompletionFraction<_TestHabit>([]), 0.0);
    });

    test('returns 1.0 when all habits completed', () {
      final habits = const [_TestHabit(true), _TestHabit(true)];
      expect(computeCompletionFraction(habits), 1.0);
    });

    test('returns 0.5 when half habits completed', () {
      final habits = const [_TestHabit(true), _TestHabit(false)];
      expect(computeCompletionFraction(habits), 0.5);
    });

    test('returns 0.0 when none completed', () {
      final habits = const [_TestHabit(false), _TestHabit(false)];
      expect(computeCompletionFraction(habits), 0.0);
    });
  });

  group('computeIncompleteCount', () {
    test('returns 0 when all habits completed', () {
      final habits = const [_TestHabit(true)];
      expect(computeIncompleteCount(habits), 0);
    });

    test('returns count of incomplete habits', () {
      final habits = const [
        _TestHabit(true),
        _TestHabit(false),
        _TestHabit(false),
      ];
      expect(computeIncompleteCount(habits), 2);
    });
  });

  group('ringColorValue', () {
    test('green at >=0.8', () {
      expect(ringColorValue(1.0), 0xFF2BEE79);
      expect(ringColorValue(0.8), 0xFF2BEE79);
    });
    test('amber at 0.5-0.79', () {
      expect(ringColorValue(0.5), 0xFFFFC107);
      expect(ringColorValue(0.79), 0xFFFFC107);
    });
    test('coral below 0.5', () {
      expect(ringColorValue(0.0), 0xFFFF6B6B);
      expect(ringColorValue(0.49), 0xFFFF6B6B);
    });
  });

  group('momentumColorValue', () {
    test('green at >=7', () {
      expect(momentumColorValue(7), 0xFF2BEE79);
      expect(momentumColorValue(21), 0xFF2BEE79);
    });
    test('amber at 3-6', () {
      expect(momentumColorValue(3), 0xFFFFC107);
      expect(momentumColorValue(6), 0xFFFFC107);
    });
    test('coral below 3', () {
      expect(momentumColorValue(0), 0xFFFF6B6B);
      expect(momentumColorValue(2), 0xFFFF6B6B);
    });
  });

  group('shouldPulseIncompleteBadge', () {
    test('false when nothing incomplete', () {
      expect(shouldPulseIncompleteBadge(0, DateTime(2026, 7, 26, 18)), isFalse);
    });
    test('true in final 2 hours of daylight (17-19)', () {
      expect(shouldPulseIncompleteBadge(2, DateTime(2026, 7, 26, 18)), isTrue);
    });
    test('false before 17:00 even with incomplete habits', () {
      expect(shouldPulseIncompleteBadge(3, DateTime(2026, 7, 26, 12)), isFalse);
    });
    test('false at/after 19:00', () {
      expect(shouldPulseIncompleteBadge(3, DateTime(2026, 7, 26, 19)), isFalse);
    });
  });
}
