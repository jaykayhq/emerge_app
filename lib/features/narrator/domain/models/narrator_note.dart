import 'package:equatable/equatable.dart';

/// Types of observations the Narrator can record.
enum NarratorNoteType {
  /// AI-generated insight about the user's habits
  aiInsight,

  /// User logged a daily reflection
  reflectionLogged,

  /// User completed a habit
  habitCompleted,

  /// User leveled up
  levelUp,

  /// User reached a streak milestone
  streakMilestone,

  /// User completed an onboarding step
  onboardingStep,

  /// Extended absence detected
  absenceDetected,

  /// Morning brief was shown
  morningBrief,

  /// Weekly recap was shown
  weeklyRecap,

  /// User visited a screen for the first time
  screenVisit,
}

/// A single observation logged by the Narrator system.
///
/// Each note captures what the Narrator observed, when it happened,
/// and any associated data (e.g. habit ID, XP gained, etc.).
class NarratorNote extends Equatable {
  final String id;
  final NarratorNoteType type;
  final Map<String, dynamic> data;
  final DateTime recordedAt;
  final String? habitId;

  const NarratorNote({
    required this.id,
    required this.type,
    required this.data,
    required this.recordedAt,
    this.habitId,
  });

  @override
  List<Object?> get props => [id, type, data, recordedAt, habitId];

  /// Creates a copy of this note with the given fields replaced.
  NarratorNote copyWith({
    String? id,
    NarratorNoteType? type,
    Map<String, dynamic>? data,
    DateTime? recordedAt,
    String? habitId,
  }) {
    return NarratorNote(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      recordedAt: recordedAt ?? this.recordedAt,
      habitId: habitId ?? this.habitId,
    );
  }
}
