import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/services/narrator_line_resolver.dart';
import 'package:emerge_app/features/narrator/domain/services/narrator_trigger_engine.dart';

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

@Riverpod(keepAlive: true)
NarratorLineResolver lineResolver(Ref ref) {
  final isPremium = ref.watch(isPremiumProvider).value ?? false;
  return LlmNarratorLineResolver(
    isPro: isPremium,
    llmGeneratePersonal: (trigger, stats) async {
      // TODO(task-22): swap stub for real Groq call
      return PersonalLine(
        text: '${trigger.name} personal line for momentum=${stats.momentumScore.toStringAsFixed(2)}',
        dataBasis: 'momentumScore',
      );
    },
  );
}

/// Pending narrator line awaiting display in the slide-up card.
@riverpod
class PendingMilestone extends _$PendingMilestone {
  @override
  NarratorLine? build() => null;

  void set(NarratorLine line) => state = line;
  void clear() => state = null;
}

