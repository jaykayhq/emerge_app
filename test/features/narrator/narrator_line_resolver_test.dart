import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/domain/services/narrator_line_resolver.dart';
import 'package:emerge_app/features/narrator/domain/services/narrator_trigger_engine.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeResolver extends NarratorLineResolver {
  _FakeResolver({required this.isPremium});
  final bool isPremium;

  @override
  bool get isPro => isPremium;

  @override
  Future<PersonalLine> generatePersonal({
    required NarratorTrigger trigger,
    required NarratorUserStats stats,
  }) async {
    return PersonalLine(
      text: 'personal: ${trigger.name}',
      dataBasis: 'fake',
    );
  }

  @override
  GenericLine pickGeneric(NarratorTrigger trigger) {
    return GenericLine('generic: ${trigger.name}');
  }
}

NarratorUserStats _stats() => const NarratorUserStats(
      momentumScore: 0.5,
      consecutiveActiveDays: 1,
      totalHabitsToday: 3,
      completedHabitsToday: 1,
      currentLevel: 1,
      previousLevel: 1,
      hasStreakBreak: false,
      currentStreak: 5,
      longestStreak: 5,
      consecutiveMisses: 0,
      hasCompletedEveningReflectionToday: false,
      hasCompletedOnboarding: true,
      archetypeSelected: true,
    );

void main() {
  group('NarratorLineResolver', () {
    test('free user gets GenericLine for non-gated trigger', () async {
      final r = _FakeResolver(isPremium: false);
      final line = await r.resolve(
        trigger: NarratorTrigger.streakBreakFirstMiss,
        stats: _stats(),
      );
      expect(line, isA<GenericLine>());
      expect(line.text, contains('generic'));
    });

    test('pro user gets PersonalLine for non-gated trigger', () async {
      final r = _FakeResolver(isPremium: true);
      final line = await r.resolve(
        trigger: NarratorTrigger.streakBreakFirstMiss,
        stats: _stats(),
      );
      expect(line, isA<PersonalLine>());
      expect(line.text, contains('personal'));
    });

    test('weeklyRecap returns GatedResult for free user', () async {
      final r = _FakeResolver(isPremium: false);
      final result = await r.resolveGated(
        trigger: NarratorTrigger.weeklyRecap,
        stats: _stats(),
      );
      expect(result, isA<WeeklyRecapGated>());
    });

    test('weeklyRecap returns WeeklyRecapLine for pro user', () async {
      final r = _FakeResolver(isPremium: true);
      final result = await r.resolveGated(
        trigger: NarratorTrigger.weeklyRecap,
        stats: _stats(),
      );
      expect(result, isA<WeeklyRecapLine>());
    });
  });
}