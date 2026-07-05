import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/domain/services/narrator_trigger_engine.dart';

/// Result for weeklyRecap: gated (show paywall) or a real line.
sealed class WeeklyRecapResult {
  const WeeklyRecapResult();
}

class WeeklyRecapGated extends WeeklyRecapResult {
  const WeeklyRecapGated();
}

class WeeklyRecapLine extends WeeklyRecapResult {
  final NarratorLine line;
  const WeeklyRecapLine(this.line);
}

/// Resolves a [NarratorTrigger] + [NarratorUserStats] into a [NarratorLine]
/// (or a paywall gate for weeklyRecap on free users).
abstract class NarratorLineResolver {
  bool get isPro;

  /// Resolve a non-gated trigger. Always returns a line.
  Future<NarratorLine> resolve({
    required NarratorTrigger trigger,
    required NarratorUserStats stats,
  }) async {
    if (isPro) {
      return generatePersonal(trigger: trigger, stats: stats);
    }
    return pickGeneric(trigger);
  }

  /// Resolve weeklyRecap: gated for free users.
  Future<WeeklyRecapResult> resolveGated({
    required NarratorTrigger trigger,
    required NarratorUserStats stats,
  }) async {
    assert(
      trigger == NarratorTrigger.weeklyRecap,
      'resolveGated only for weeklyRecap',
    );
    if (!isPro) return const WeeklyRecapGated();
    return WeeklyRecapLine(
      await generatePersonal(trigger: trigger, stats: stats),
    );
  }

  Future<PersonalLine> generatePersonal({
    required NarratorTrigger trigger,
    required NarratorUserStats stats,
  });

  GenericLine pickGeneric(NarratorTrigger trigger);
}

/// Concrete resolver implementation backed by [isPremium] and the LLM.
class LlmNarratorLineResolver extends NarratorLineResolver {
  LlmNarratorLineResolver({
    required this.isPro,
    required this.llmGeneratePersonal,
  });

  final bool isPro;
  final Future<PersonalLine> Function(NarratorTrigger, NarratorUserStats)
      llmGeneratePersonal;

  @override
  Future<PersonalLine> generatePersonal({
    required NarratorTrigger trigger,
    required NarratorUserStats stats,
  }) =>
      llmGeneratePersonal(trigger, stats);

  @override
  GenericLine pickGeneric(NarratorTrigger trigger) {
    return GenericLine(_fallbackFor(trigger));
  }

  String _fallbackFor(NarratorTrigger trigger) => switch (trigger) {
        NarratorTrigger.streakBreakFirstMiss =>
          'One miss is a slip. Two is a pattern. What got in the way?',
        NarratorTrigger.onFireState =>
          "You're on fire this week.",
        NarratorTrigger.levelUp => 'You leveled up.',
        NarratorTrigger.longAbsence =>
          'Welcome back. Pick one small habit today.',
        NarratorTrigger.eveningReflection => 'How did today go?',
        NarratorTrigger.morningBriefEarlyDays =>
          'Small start, big difference.',
        NarratorTrigger.onboardingPostArchetype => 'A path begins.',
        NarratorTrigger.weeklyRecap => 'Your week, in numbers.',
        NarratorTrigger.askNarrator =>
          "You called — what's on your mind?",
      };
}