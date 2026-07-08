import 'package:emerge_app/features/narrator/domain/models/narrator_note.dart';

/// Triggers for the Narrator system.
///
/// Each enum value represents a specific event or condition that can cause
/// the Narrator to appear and deliver a message.
enum NarratorTrigger {
  /// Shown right after onboarding archetype selection
  onboardingPostArchetype,

  /// Morning brief during the first few days of habit building
  morningBriefEarlyDays,

  /// First time a streak is broken (consecutive miss > 0)
  streakBreakFirstMiss,

  /// User is "on fire" — high momentum / consecutive active days
  onFireState,

  /// User leveled up
  levelUp,

  /// Weekly recap trigger (Pro only — gated)
  weeklyRecap,

  /// User has been absent for several days
  longAbsence,

  /// Evening reflection prompt
  eveningReflection,

  /// User explicitly tapped the narrator avatar or "Ask narrator" CTA
  askNarrator;

  /// Maps this trigger to the corresponding [NarratorNoteType] for persistence.
  NarratorNoteType toNoteType() {
    return switch (this) {
      NarratorTrigger.onboardingPostArchetype =>
        NarratorNoteType.onboardingStep,
      NarratorTrigger.morningBriefEarlyDays =>
        NarratorNoteType.morningBrief,
      NarratorTrigger.streakBreakFirstMiss =>
        NarratorNoteType.absenceDetected,
      NarratorTrigger.onFireState => NarratorNoteType.streakMilestone,
      NarratorTrigger.levelUp => NarratorNoteType.levelUp,
      NarratorTrigger.weeklyRecap => NarratorNoteType.weeklyRecap,
      NarratorTrigger.longAbsence => NarratorNoteType.absenceDetected,
      NarratorTrigger.eveningReflection =>
        NarratorNoteType.reflectionLogged,
      NarratorTrigger.askNarrator => NarratorNoteType.aiInsight,
    };
  }
}
