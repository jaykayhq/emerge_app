import 'package:equatable/equatable.dart';

class HabitCompletionEntity extends Equatable {
  final String id;
  final String habitId;
  final String attribute;
  final int xpGained;
  final DateTime completedAt;

  const HabitCompletionEntity({
    required this.id,
    required this.habitId,
    required this.attribute,
    required this.xpGained,
    required this.completedAt,
  });

  @override
  List<Object?> get props => [id, habitId, attribute, xpGained, completedAt];
}
