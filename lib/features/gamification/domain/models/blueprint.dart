import 'package:equatable/equatable.dart';

enum BlueprintDifficulty { beginner, intermediate, advanced }

class BlueprintHabit extends Equatable {
  final String title;
  final String timeOfDay;
  final String frequency;

  const BlueprintHabit({
    required this.title,
    required this.timeOfDay,
    required this.frequency,
  });

  @override
  List<Object?> get props => [title, timeOfDay, frequency];
}

class Blueprint extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final BlueprintDifficulty difficulty;
  final List<BlueprintHabit> habits;

  const Blueprint({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.difficulty,
    required this.habits,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    category,
    imageUrl,
    difficulty,
    habits,
  ];
}
