import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:emerge_app/features/ai/data/services/groq_ai_service.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/domain/services/narrator_line_resolver.dart';

import 'package:emerge_app/core/drift/database.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/narrator/data/datasources/narrator_local_datasource.dart';
import 'package:emerge_app/features/narrator/data/repositories/narrator_repository.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_appearance.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_note.dart';

part 'narrator_providers.g.dart';

// ---------------------------------------------------------------------------
// Datasource provider (keep-alive singleton)
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
NarratorLocalDatasource narratorLocalDatasource(Ref ref) {
  final dao = ref.watch(narratorNotesDaoProvider);
  return NarratorLocalDatasource(dao: dao);
}

// ---------------------------------------------------------------------------
// Repository provider (keep-alive singleton)
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
NarratorRepository narratorRepository(Ref ref) {
  final datasource = ref.watch(narratorLocalDatasourceProvider);
  return NarratorRepository(datasource: datasource);
}

// ---------------------------------------------------------------------------
// Recent notes provider (auto-dispose)
// ---------------------------------------------------------------------------

@riverpod
Future<List<NarratorNote>> recentNarratorNotes(Ref ref) async {
  final repo = ref.watch(narratorRepositoryProvider);
  return repo.getRecentNotes(limit: 10);
}

// ---------------------------------------------------------------------------
// Latest insight provider (auto-dispose, for summary card)
// ---------------------------------------------------------------------------

@riverpod
Future<NarratorNote?> latestNarratorInsight(Ref ref) async {
  final repo = ref.watch(narratorRepositoryProvider);
  return repo.getLatestInsight();
}

// ---------------------------------------------------------------------------
// Narrator state notifier — currently-active appearance
// ---------------------------------------------------------------------------

/// State holder for the Narrator system.
///
/// When [appearance] is non-null, the Narrator sheet should be shown.
class NarratorState {
  final NarratorAppearance? appearance;

  const NarratorState({this.appearance});
}

/// Notifier that manages the currently active Narrator appearance.
@riverpod
class NarratorStateNotifier extends _$NarratorStateNotifier {
  @override
  NarratorState build() => const NarratorState();

  /// Dismisses the Narrator.
  void dismiss() => state = const NarratorState();
}

// ---------------------------------------------------------------------------
// Line resolver provider (keep-alive singleton)
// ---------------------------------------------------------------------------

/// Maps a Dart [NarratorTrigger] enum name (snake_case) to the camelCase
/// string expected by the `fillNarratorSlots` Cloud Function.
String _triggerToApiName(NarratorTrigger trigger) => switch (trigger) {
  NarratorTrigger.onboardingPostArchetype => 'onboardingPostArchetype',
  NarratorTrigger.morningBriefEarlyDays => 'morningBriefEarlyDays',
  NarratorTrigger.streakBreakFirstMiss => 'streakBreakFirstMiss',
  NarratorTrigger.onFireState => 'onFireState',
  NarratorTrigger.levelUp => 'levelUp',
  NarratorTrigger.weeklyRecap => 'weeklyRecap',
  NarratorTrigger.longAbsence => 'longAbsence',
  NarratorTrigger.eveningReflection => 'eveningReflection',
  NarratorTrigger.askNarrator => 'dailyInsight',
};

@Riverpod(keepAlive: true)
NarratorLineResolver lineResolver(Ref ref) {
  final isPremium = ref.watch(isPremiumProvider).value ?? false;
  final groqService = GroqAiService();
  return LlmNarratorLineResolver(
    isPro: isPremium,
    llmGeneratePersonal: (trigger, stats) async {
      try {
        final slots = await groqService.fillNarratorSlots(
          trigger: _triggerToApiName(trigger),
          context: {
            'momentumScore': stats.momentumScore,
            'currentStreak': stats.currentStreak,
            'currentLevel': stats.currentLevel,
            'completedHabits': stats.completedHabitsToday,
            'totalHabits': stats.totalHabitsToday,
          },
        );
        final text = slots.values.join(' ');
        return PersonalLine(text: text, dataBasis: 'groq_slots');
      } catch (_) {
        return PersonalLine(
          text: 'Momentum at ${stats.momentumScore.toStringAsFixed(2)}.',
          dataBasis: 'momentumScore',
        );
      }
    },
  );
}

/// A narrator line awaiting display in the slide-up card, with the trigger
/// that produced it (drives the card label).
class PendingMilestoneLine {
  final NarratorLine line;
  final NarratorTrigger trigger;

  const PendingMilestoneLine({required this.line, required this.trigger});
}

/// Pending narrator line awaiting display in the slide-up card.
@riverpod
class PendingMilestone extends _$PendingMilestone {
  @override
  PendingMilestoneLine? build() => null;

  void set(PendingMilestoneLine line) => state = line;
  void clear() => state = null;
}

/// Session-scoped: the Day Card has been dismissed for this app session.
@riverpod
class NarratorCardDismissed extends _$NarratorCardDismissed {
  @override
  bool build() => false;

  void dismiss() => state = true;
  void restore() => state = false;
}

/// Session-scoped: latched request to expand and focus the Day Card's ask
/// field (driven by the timeline header avatar tap). Stays true until the
/// card consumes it, so a bump while the card is unmounted replays on mount.
@riverpod
class NarratorAskFocus extends _$NarratorAskFocus {
  @override
  bool build() => false;

  void request() => state = true;
  void consume() => state = false;
}
