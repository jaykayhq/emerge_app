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

  factory BlueprintHabit.fromMap(Map<String, dynamic> map) {
    return BlueprintHabit(
      title: map['title'] as String? ?? '',
      timeOfDay: map['timeOfDay'] as String? ?? 'Anytime',
      frequency: map['frequency'] as String? ?? 'Daily',
    );
  }

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

  factory Blueprint.fromMap(String id, Map<String, dynamic> map) {
    BlueprintDifficulty difficulty;
    final diffStr = (map['difficulty'] as String? ?? 'beginner').toLowerCase();
    if (diffStr == 'advanced' ||
        diffStr == 'legendary' ||
        diffStr == 'hard' ||
        diffStr == 'epic') {
      difficulty = BlueprintDifficulty.advanced;
    } else if (diffStr == 'intermediate' ||
        diffStr == 'rare' ||
        diffStr == 'medium') {
      difficulty = BlueprintDifficulty.intermediate;
    } else {
      difficulty = BlueprintDifficulty.beginner;
    }

    return Blueprint(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      imageUrl: map['imageUrl'] as String? ?? '',
      difficulty: difficulty,
      habits:
          (map['habits'] as List<dynamic>?)
              ?.map((h) => BlueprintHabit.fromMap(h as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

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

  static String getDefaultImageForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'morning':
        return 'https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?w=800';
      case 'focus':
        return 'https://images.unsplash.com/photo-1484480974693-6ca0a78fb36b?w=800';
      case 'health':
        return 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800';
      case 'fitness':
        return 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800';
      case 'mindset':
        return 'https://images.unsplash.com/photo-1499750310107-5fef28a66643?w=800';
      case 'learning':
        return 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=800';
      case 'business':
        return 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800';
      case 'creativity':
        return 'https://images.unsplash.com/photo-1452802447250-470a88ac82bc?w=800';
      case 'productivity':
        return 'https://images.unsplash.com/photo-1497032628192-86f99bcd76bc?w=800';
      default:
        return 'https://images.unsplash.com/photo-1519834785169-98be25ec3f84?w=800';
    }
  }
}
