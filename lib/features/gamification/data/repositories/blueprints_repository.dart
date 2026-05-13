import 'package:emerge_app/features/gamification/domain/models/blueprint.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final blueprintsRepositoryProvider = Provider<BlueprintsRepository>((ref) {
  return BlueprintsRepository();
});

class BlueprintsRepository {
  final List<Blueprint> _fallbackBlueprints = [
    const Blueprint(
      id: 'athlete_1', title: 'The Iron Morning',
      description: 'Start your day with intense physical activation.',
      category: 'Athlete',
      imageUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.intermediate,
      habits: [
        BlueprintHabit(title: 'Zone 2 Cardio', timeOfDay: 'Morning', frequency: 'Daily'),
        BlueprintHabit(title: 'Cold Shower', timeOfDay: 'Morning', frequency: 'Daily'),
      ],
    ),
    const Blueprint(
      id: 'creator_1', title: 'The Flow State',
      description: 'Enter deep creative flow.',
      category: 'Creator',
      imageUrl: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.advanced,
      habits: [
        BlueprintHabit(title: 'Deep Work Block', timeOfDay: 'Morning', frequency: 'Weekdays'),
        BlueprintHabit(title: 'Analog Hour', timeOfDay: 'Evening', frequency: 'Daily'),
      ],
    ),
    const Blueprint(
      id: 'scholar_1', title: 'Syntopic Immersion',
      description: 'Read deeply and cross-reference knowledge.',
      category: 'Scholar',
      imageUrl: 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.advanced,
      habits: [
        BlueprintHabit(title: 'Syntopic Reading', timeOfDay: 'Evening', frequency: 'Daily'),
        BlueprintHabit(title: 'Zettelkasten', timeOfDay: 'Evening', frequency: 'Daily'),
      ],
    ),
    const Blueprint(
      id: 'stoic_1', title: 'The Stoic Morning',
      description: 'Start your day with clarity.',
      category: 'Stoic',
      imageUrl: 'https://images.unsplash.com/photo-1519834785169-98be25ec3f84?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.intermediate,
      habits: [
        BlueprintHabit(title: 'Premeditatio Malorum', timeOfDay: 'Morning', frequency: 'Daily'),
        BlueprintHabit(title: 'Journaling', timeOfDay: 'Morning', frequency: 'Daily'),
      ],
    ),
  ];

  Future<List<Blueprint>> getBlueprints({String? category}) async {
    if (category == null || category == 'All') return _fallbackBlueprints;
    return _fallbackBlueprints.where((b) => b.category == category).toList();
  }

  Future<List<String>> getCategories() async {
    return ['All', 'Athlete', 'Creator', 'Scholar', 'Stoic'];
  }
}
