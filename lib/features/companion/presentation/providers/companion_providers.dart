import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/ai/data/services/groq_ai_service.dart';
import 'package:emerge_app/features/companion/data/repositories/companion_repository.dart';
import 'package:emerge_app/features/companion/domain/entities/companion_message.dart';
import 'package:emerge_app/features/companion/domain/entities/persona_config.dart';
import 'package:emerge_app/features/companion/domain/enums/companion_enums.dart';
import 'package:emerge_app/features/companion/domain/services/persona_engine.dart';
import 'package:emerge_app/features/companion/domain/services/trigger_manager.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/core/utils/app_logger.dart';

class CompanionState {
  final CompanionMessage? message;
  final CompanionMode mode;
  final CompanionEventType? eventType;
  final GlobalKey? targetKey;
  final bool visible;
  final PersonaConfig? persona;
  final bool companionEnabled;

  const CompanionState({
    this.message,
    this.mode = CompanionMode.inlineCard,
    this.eventType,
    this.targetKey,
    this.visible = false,
    this.persona,
    this.companionEnabled = true,
  });

  CompanionState copyWith({
    CompanionMessage? message,
    CompanionMode? mode,
    CompanionEventType? eventType,
    GlobalKey? targetKey,
    bool? visible,
    PersonaConfig? persona,
    bool? companionEnabled,
  }) {
    return CompanionState(
      message: message ?? this.message,
      mode: mode ?? this.mode,
      eventType: eventType ?? this.eventType,
      targetKey: targetKey ?? this.targetKey,
      visible: visible ?? this.visible,
      persona: persona ?? this.persona,
      companionEnabled: companionEnabled ?? this.companionEnabled,
    );
  }
}

class CompanionEngine extends Notifier<CompanionState> {
  final GroqAiService _groqService = GroqAiService();

  int _proactiveCount = 0;
  DateTime? _lastDismissTime;

  @override
  CompanionState build() {
    final repo = ref.read(companionRepositoryProvider);
    repo.migrateFromTutorials();
    return CompanionState(
      companionEnabled: repo.isCompanionEnabled(),
      persona: _loadPersona(),
    );
  }

  CompanionRepository get _repository => ref.read(companionRepositoryProvider);

  PersonaConfig? _loadPersona() {
    final profile = ref
        .read(userStatsStreamProvider)
        .maybeWhen(data: (p) => p, orElse: () => null);
    final archetype = profile?.archetype.name.toLowerCase() ?? '';
    if (archetype.isEmpty) return null;
    return PersonaEngine.getPersona(archetype);
  }

  Future<void> triggerEvent({
    required CompanionEventType eventType,
    Map<String, dynamic>? userContext,
    GlobalKey? targetKey,
  }) async {
    if (!state.companionEnabled &&
        eventType != CompanionEventType.userInitiated) {
      return;
    }

    if (eventType != CompanionEventType.userInitiated) {
      if (_proactiveCount >= 1) return;
      if (_lastDismissTime != null) {
        final elapsed = DateTime.now().difference(_lastDismissTime!);
        if (elapsed.inMinutes < 10) return;
      }
      _proactiveCount++;
    }

    final persona = _loadPersona() ?? state.persona;
    if (persona == null) return;

    final mode = TriggerManager.resolveMode(eventType);
    final userContextMap = userContext ?? {};
    final archetype = persona.name.toLowerCase().contains('coach')
        ? 'athlete'
        : persona.name.toLowerCase().contains('sage')
        ? 'scholar'
        : persona.name.toLowerCase().contains('muse')
        ? 'creator'
        : persona.name.toLowerCase().contains('philosopher')
        ? 'stoic'
        : 'zealot';

    final result = await _groqService.getCompanionMessage(
      archetype: archetype,
      eventType: eventType.name,
      userContext: userContextMap,
    );

    final message = CompanionMessage(
      message: result['message'] as String,
      tone: result['tone'] as String? ?? 'neutral',
      suggestions: result['suggestions'] as List<String>?,
    );

    state = state.copyWith(
      message: message,
      mode: mode,
      eventType: eventType,
      targetKey: targetKey,
      visible: true,
      persona: persona,
    );

    AppLogger.i('Companion: ${eventType.name} triggered in ${mode.name} mode');
  }

  void dismiss() {
    _lastDismissTime = DateTime.now();
    state = state.copyWith(visible: false, message: null, targetKey: null);
  }

  void markVisited(String route) {
    _repository.markVisited(route);
  }

  Future<void> setCompanionEnabled(bool enabled) async {
    await _repository.setCompanionEnabled(enabled);
    state = state.copyWith(companionEnabled: enabled);
  }

  Future<void> openPanel() async {
    await triggerEvent(eventType: CompanionEventType.userInitiated);
  }

  void checkDailyCheckIn() {
    if (!_repository.hasCheckedInToday()) {
      _repository.markCheckInDone();
      triggerEvent(eventType: CompanionEventType.dailyCheckIn);
    }
  }
}

final companionRepositoryProvider = Provider<CompanionRepository>((ref) {
  return CompanionRepository();
});

final companionEngineProvider =
    NotifierProvider<CompanionEngine, CompanionState>(CompanionEngine.new);

final companionPersonaProvider = Provider<PersonaConfig?>((ref) {
  return ref.watch(companionEngineProvider.select((s) => s.persona));
});

final companionVisibilityProvider = Provider<CompanionState?>((ref) {
  final state = ref.watch(companionEngineProvider);
  return state.visible ? state : null;
});
