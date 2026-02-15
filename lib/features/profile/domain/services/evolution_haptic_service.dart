import 'package:flutter/services.dart';

/// Haptic feedback patterns for evolution-related events
/// Uses escalating intensity to reinforce progression psychology
class EvolutionHapticService {
  /// Singleton instance
  static final EvolutionHapticService _instance = EvolutionHapticService._();
  factory EvolutionHapticService() => _instance;
  EvolutionHapticService._();

  /// Light pulse for breathing/idle animations
  /// Called during silhouette "heartbeat" moments
  void breathPulse() {
    HapticFeedback.selectionClick();
  }

  /// Compression phase start - building tension
  /// Single medium impact as silhouette shrinks
  void compressionStart() {
    HapticFeedback.mediumImpact();
  }

  /// Flash moment - peak transformation
  /// Heavy impact for dramatic "breakthrough" feel
  void flashImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Expansion phase - release and growth
  /// Light rumble effect as energy expands
  Future<void> expansionRumble() async {
    // Triple light impacts with short delays for rumble effect
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    HapticFeedback.lightImpact();
  }

  /// Phase evolution complete - celebration
  /// Victory pattern: medium-heavy-light sequence
  Future<void> evolutionComplete() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.lightImpact();
  }

  /// Artifact unlock - rewarding click
  /// Distinctive double-tap pattern for equipment gain
  Future<void> artifactUnlock() async {
    HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 80));
    HapticFeedback.mediumImpact();
  }

  /// Entropy decay warning - negative feedback
  /// Quick staccato pulses indicating degradation
  Future<void> entropyWarning() async {
    HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 40));
    HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 40));
    HapticFeedback.selectionClick();
  }

  /// Streak milestone celebration
  /// Escalating triple impact for achievement
  Future<void> streakMilestone() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.heavyImpact();
  }

  /// Habit vote registered - identity reinforcement
  /// Single satisfying click confirming action
  void habitVoteRegistered() {
    HapticFeedback.mediumImpact();
  }

  /// Tap on silhouette - exploration feedback
  void silhouetteTap() {
    HapticFeedback.selectionClick();
  }

  /// Full evolution transition sequence
  /// Orchestrated haptics for phase 1→2→3→4 animation
  Future<void> runEvolutionSequence({
    required Duration compressionDuration,
    required Duration flashDuration,
    required Duration expansionDuration,
  }) async {
    // Compression phase
    compressionStart();
    await Future.delayed(compressionDuration);

    // Flash phase
    flashImpact();
    await Future.delayed(flashDuration * 0.5);

    // Expansion phase
    await expansionRumble();
    await Future.delayed(expansionDuration);

    // Completion celebration
    await evolutionComplete();
  }
}
