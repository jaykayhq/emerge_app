import 'package:emerge_app/features/habits/domain/entities/habit.dart';

/// Type of next identity vote returned by the engine.
enum NextVoteType {
  actionable,
  harmonized,
  empty,
}

/// Data model representing the Next Best Action (NBA) / Identity Vote
/// to be showcased on the World Map Stoking Dock.
class NextIdentityVote {
  final NextVoteType type;
  final Habit? habit;
  final HabitAttribute? attribute;
  final int vitalityImpactPercent;
  final bool isRecovery;

  const NextIdentityVote._({
    required this.type,
    this.habit,
    this.attribute,
    this.vitalityImpactPercent = 0,
    this.isRecovery = false,
  });

  /// An actionable habit offering that can be stoked right now.
  factory NextIdentityVote.actionable({
    required Habit habit,
    required HabitAttribute attribute,
    required int vitalityImpactPercent,
    bool isRecovery = false,
  }) => NextIdentityVote._(
    type: NextVoteType.actionable,
    habit: habit,
    attribute: attribute,
    vitalityImpactPercent: vitalityImpactPercent,
    isRecovery: isRecovery,
  );

  /// All daily habit offerings completed; realm is harmonized.
  factory NextIdentityVote.harmonized() => const NextIdentityVote._(
    type: NextVoteType.harmonized,
  );

  /// No habits have been created yet.
  factory NextIdentityVote.empty() => const NextIdentityVote._(
    type: NextVoteType.empty,
  );

  /// True if there is an active habit to vote on.
  bool get isActionable => type == NextVoteType.actionable && habit != null;

  /// True if all daily habits have been completed.
  bool get isHarmonized => type == NextVoteType.harmonized;

  /// True if no habits exist in the realm.
  bool get isEmpty => type == NextVoteType.empty;

  NextIdentityVote copyWith({
    NextVoteType? type,
    Habit? habit,
    HabitAttribute? attribute,
    int? vitalityImpactPercent,
    bool? isRecovery,
  }) {
    return NextIdentityVote._(
      type: type ?? this.type,
      habit: habit ?? this.habit,
      attribute: attribute ?? this.attribute,
      vitalityImpactPercent:
          vitalityImpactPercent ?? this.vitalityImpactPercent,
      isRecovery: isRecovery ?? this.isRecovery,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NextIdentityVote &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          habit == other.habit &&
          attribute == other.attribute &&
          vitalityImpactPercent == other.vitalityImpactPercent &&
          isRecovery == other.isRecovery;

  @override
  int get hashCode => Object.hash(
        type,
        habit,
        attribute,
        vitalityImpactPercent,
        isRecovery,
      );

  @override
  String toString() =>
      'NextIdentityVote(type: $type, habit: ${habit?.title}, attribute: $attribute, vitalityImpactPercent: $vitalityImpactPercent, isRecovery: $isRecovery)';
}
