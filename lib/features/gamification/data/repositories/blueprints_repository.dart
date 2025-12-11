import 'package:emerge_app/features/gamification/domain/models/blueprint.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlueprintsRepository {
  final List<Blueprint> _mockBlueprints = [
    const Blueprint(
      id: '1',
      title: 'The Stoic Morning',
      description:
          'Start your day with clarity and purpose using ancient Stoic practices.',
      category: 'Morning',
      imageUrl:
          'https://images.unsplash.com/photo-1519834785169-98be25ec3f84?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.intermediate,
      habits: [
        BlueprintHabit(
          title: 'Read Stoic Philosophy',
          timeOfDay: 'Morning',
          frequency: 'Daily',
        ),
        BlueprintHabit(
          title: 'Cold Shower',
          timeOfDay: 'Morning',
          frequency: 'Daily',
        ),
        BlueprintHabit(
          title: 'Journal Reflections',
          timeOfDay: 'Morning',
          frequency: 'Daily',
        ),
      ],
    ),
    const Blueprint(
      id: '2',
      title: 'Deep Work Protocol',
      description:
          'Maximize your productivity and focus with this proven routine.',
      category: 'Focus',
      imageUrl:
          'https://images.unsplash.com/photo-1497032628192-86f99bcd76bc?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.advanced,
      habits: [
        BlueprintHabit(
          title: '90 Min Deep Work Block',
          timeOfDay: 'Morning',
          frequency: 'Weekdays',
        ),
        BlueprintHabit(
          title: 'No Phone First Hour',
          timeOfDay: 'Morning',
          frequency: 'Daily',
        ),
        BlueprintHabit(
          title: 'Plan Tomorrow',
          timeOfDay: 'Evening',
          frequency: 'Daily',
        ),
      ],
    ),
    const Blueprint(
      id: '3',
      title: 'Sleep Hygiene 101',
      description: 'Optimize your sleep for better recovery and energy.',
      category: 'Health',
      imageUrl:
          'https://images.unsplash.com/photo-1511296933631-18b5f0008d7b?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.beginner,
      habits: [
        BlueprintHabit(
          title: 'No Screens 1hr Before Bed',
          timeOfDay: 'Evening',
          frequency: 'Daily',
        ),
        BlueprintHabit(
          title: 'Read Fiction',
          timeOfDay: 'Evening',
          frequency: 'Daily',
        ),
        BlueprintHabit(
          title: 'Dark Room',
          timeOfDay: 'Evening',
          frequency: 'Daily',
        ),
      ],
    ),
    const Blueprint(
      id: '4',
      title: 'Fitness Foundation',
      description: 'Build a solid base of physical health.',
      category: 'Fitness',
      imageUrl:
          'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.beginner,
      habits: [
        BlueprintHabit(
          title: '30 Min Walk',
          timeOfDay: 'Anytime',
          frequency: 'Daily',
        ),
        BlueprintHabit(
          title: 'Drink 2L Water',
          timeOfDay: 'Anytime',
          frequency: 'Daily',
        ),
        BlueprintHabit(
          title: 'Stretch',
          timeOfDay: 'Morning',
          frequency: 'Daily',
        ),
      ],
    ),
    const Blueprint(
      id: '5',
      title: 'Monk Mode',
      description: 'Extreme focus and discipline for high achievers.',
      category: 'Focus',
      imageUrl:
          'https://images.unsplash.com/photo-1518531933037-9a847635508f?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.advanced,
      habits: [
        BlueprintHabit(
          title: 'Deep Work (2h)',
          timeOfDay: 'Morning',
          frequency: 'Daily',
        ),
        BlueprintHabit(
          title: 'Meditation (20m)',
          timeOfDay: 'Morning',
          frequency: 'Daily',
        ),
        BlueprintHabit(
          title: 'No Social Media',
          timeOfDay: 'All Day',
          frequency: 'Daily',
        ),
      ],
    ),
    const Blueprint(
      id: '6',
      title: 'The 5 AM Club',
      description: 'Own your morning, elevate your life.',
      category: 'Morning',
      imageUrl:
          'https://images.unsplash.com/photo-1506784335131-e6999423b659?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.advanced,
      habits: [
        BlueprintHabit(
          title: 'Move (20m)',
          timeOfDay: '5:00 AM',
          frequency: 'Daily',
        ),
        BlueprintHabit(
          title: 'Reflect (20m)',
          timeOfDay: '5:20 AM',
          frequency: 'Daily',
        ),
        BlueprintHabit(
          title: 'Grow (20m)',
          timeOfDay: '5:40 AM',
          frequency: 'Daily',
        ),
      ],
    ),
    const Blueprint(
      id: '7',
      title: 'Dopamine Detox',
      description: 'Reset your brain\'s reward system.',
      category: 'Mindset',
      imageUrl:
          'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.intermediate,
      habits: [
        BlueprintHabit(
          title: 'No Screens (1h)',
          timeOfDay: 'Morning',
          frequency: 'Daily',
        ),
        BlueprintHabit(
          title: 'Nature Walk (30m)',
          timeOfDay: 'Afternoon',
          frequency: 'Daily',
        ),
        BlueprintHabit(
          title: 'Reading (30m)',
          timeOfDay: 'Evening',
          frequency: 'Daily',
        ),
      ],
    ),
    const Blueprint(
      id: '8',
      title: 'Evening Wind-Down',
      description: 'Prepare your mind and body for deep sleep.',
      category: 'Health',
      imageUrl:
          'https://images.unsplash.com/photo-1515890497046-27927f19627c?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.beginner,
      habits: [
        BlueprintHabit(
          title: 'No Tech (1h)',
          timeOfDay: 'Evening',
          frequency: 'Daily',
        ),
        BlueprintHabit(
          title: 'Journaling (15m)',
          timeOfDay: 'Evening',
          frequency: 'Daily',
        ),
        BlueprintHabit(
          title: 'Reading (30m)',
          timeOfDay: 'Evening',
          frequency: 'Daily',
        ),
      ],
    ),
    const Blueprint(
      id: '9',
      title: 'Social Butterfly',
      description: 'Strengthen your relationships and social skills.',
      category: 'Mindset',
      imageUrl:
          'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.beginner,
      habits: [
        BlueprintHabit(
          title: 'Call a Friend',
          timeOfDay: 'Evening',
          frequency: 'Weekly',
        ),
        BlueprintHabit(
          title: 'Networking Event',
          timeOfDay: 'Anytime',
          frequency: 'Monthly',
        ),
        BlueprintHabit(
          title: 'Compliment Someone',
          timeOfDay: 'Anytime',
          frequency: 'Daily',
        ),
      ],
    ),
    const Blueprint(
      id: '10',
      title: 'Eco-Warrior',
      description: 'Live sustainably and protect the planet.',
      category: 'Mindset',
      imageUrl:
          'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.intermediate,
      habits: [
        BlueprintHabit(
          title: 'Zero Waste Day',
          timeOfDay: 'All Day',
          frequency: 'Weekly',
        ),
        BlueprintHabit(
          title: 'Compost',
          timeOfDay: 'Evening',
          frequency: 'Daily',
        ),
        BlueprintHabit(
          title: 'Plant-Based Meal',
          timeOfDay: 'Lunch',
          frequency: 'Daily',
        ),
      ],
    ),
  ];

  Future<List<Blueprint>> getBlueprints({String? category}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (category == null || category == 'All') {
      return _mockBlueprints;
    }
    return _mockBlueprints.where((b) => b.category == category).toList();
  }

  Future<List<String>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return ['All', 'Morning', 'Focus', 'Health', 'Fitness', 'Mindset'];
  }
}

final blueprintsRepositoryProvider = Provider<BlueprintsRepository>((ref) {
  return BlueprintsRepository();
});

final blueprintCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(blueprintsRepositoryProvider);
  return repo.getCategories();
});

final blueprintsProvider = FutureProvider.family<List<Blueprint>, String?>((
  ref,
  category,
) async {
  final repo = ref.watch(blueprintsRepositoryProvider);
  return repo.getBlueprints(category: category);
});
