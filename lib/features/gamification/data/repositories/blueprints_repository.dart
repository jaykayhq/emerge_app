import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/gamification/domain/models/blueprint.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlueprintsRepository {
  final FirebaseFirestore _firestore;

  BlueprintsRepository(this._firestore);

  final List<Blueprint> _fallbackBlueprints = [
    // --- ATHLETE ---
    const Blueprint(
      id: 'athlete_1',
      title: 'The Iron Morning',
      description: 'Start your day with intense physical activation to build momentum.',
      category: 'Athlete',
      imageUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.intermediate,
      habits: [
        BlueprintHabit(title: 'Zone 2 Cardio', timeOfDay: 'Morning', frequency: 'Daily'),
        BlueprintHabit(title: 'Cold Shower', timeOfDay: 'Morning', frequency: 'Daily'),
        BlueprintHabit(title: 'Hydration Target', timeOfDay: 'Morning', frequency: 'Daily'),
      ],
    ),
    const Blueprint(
      id: 'athlete_2',
      title: 'Unbreakable Core',
      description: 'A 30-day protocol for core strength and posture.',
      category: 'Athlete',
      imageUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.advanced,
      habits: [
        BlueprintHabit(title: 'Core Stability', timeOfDay: 'Morning', frequency: 'Daily'),
        BlueprintHabit(title: 'Mobility Flow', timeOfDay: 'Afternoon', frequency: 'Daily'),
      ],
    ),
    const Blueprint(
      id: 'athlete_3',
      title: 'Sleep Optimization',
      description: 'Maximize recovery through deliberate evening routines.',
      category: 'Athlete',
      imageUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.beginner,
      habits: [
        BlueprintHabit(title: 'Sleep Optimization', timeOfDay: 'Evening', frequency: 'Daily'),
        BlueprintHabit(title: 'Active Recovery', timeOfDay: 'Evening', frequency: 'Daily'),
      ],
    ),
    const Blueprint(
      id: 'athlete_4',
      title: 'HIIT Protocol',
      description: 'Build explosive energy and cardiovascular health.',
      category: 'Athlete',
      imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.advanced,
      habits: [
        BlueprintHabit(title: 'Sprint Intervals', timeOfDay: 'Morning', frequency: '3x Week'),
        BlueprintHabit(title: 'Stretching', timeOfDay: 'Afternoon', frequency: 'Daily'),
      ],
    ),
    const Blueprint(
      id: 'athlete_5',
      title: 'Nutrition Base',
      description: 'Solidify your dietary foundation for sustained performance.',
      category: 'Athlete',
      imageUrl: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.intermediate,
      habits: [
        BlueprintHabit(title: 'Meal Prep', timeOfDay: 'Evening', frequency: 'Weekends'),
        BlueprintHabit(title: 'Protein Tracking', timeOfDay: 'Any', frequency: 'Daily'),
      ],
    ),

    // --- CREATOR ---
    const Blueprint(
      id: 'creator_1',
      title: 'The Flow State',
      description: 'Enter deep creative flow and produce without distraction.',
      category: 'Creator',
      imageUrl: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.advanced,
      habits: [
        BlueprintHabit(title: 'Deep Work Block', timeOfDay: 'Morning', frequency: 'Weekdays'),
        BlueprintHabit(title: 'Analog Hour', timeOfDay: 'Evening', frequency: 'Daily'),
      ],
    ),
    const Blueprint(
      id: 'creator_2',
      title: 'Idea Machine',
      description: 'Train your brain to generate ideas consistently.',
      category: 'Creator',
      imageUrl: 'https://images.unsplash.com/photo-1499750310107-5fef28a66643?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.beginner,
      habits: [
        BlueprintHabit(title: 'Idea Capture', timeOfDay: 'Morning', frequency: 'Daily'),
        BlueprintHabit(title: 'Morning Pages', timeOfDay: 'Morning', frequency: 'Daily'),
      ],
    ),
    const Blueprint(
      id: 'creator_3',
      title: 'Shipping Fast',
      description: 'Overcome perfectionism by publishing daily.',
      category: 'Creator',
      imageUrl: 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.intermediate,
      habits: [
        BlueprintHabit(title: 'Ugly First Draft', timeOfDay: 'Morning', frequency: 'Daily'),
        BlueprintHabit(title: 'Ship Something', timeOfDay: 'Evening', frequency: 'Daily'),
      ],
    ),
    const Blueprint(
      id: 'creator_4',
      title: 'Visual Aesthetic',
      description: 'Improve your eye for design and beauty.',
      category: 'Creator',
      imageUrl: 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.intermediate,
      habits: [
        BlueprintHabit(title: 'Visual Journal', timeOfDay: 'Evening', frequency: 'Daily'),
        BlueprintHabit(title: 'Swipe File', timeOfDay: 'Any', frequency: 'Daily'),
      ],
    ),
    const Blueprint(
      id: 'creator_5',
      title: 'Master Craftsman',
      description: 'Deliberate practice to sharpen your core skills.',
      category: 'Creator',
      imageUrl: 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.advanced,
      habits: [
        BlueprintHabit(title: 'Skill Practice', timeOfDay: 'Afternoon', frequency: 'Daily'),
        BlueprintHabit(title: 'Feedback Request', timeOfDay: 'Any', frequency: 'Weekly'),
      ],
    ),

    // --- SCHOLAR ---
    const Blueprint(
      id: 'scholar_1',
      title: 'Syntopic Immersion',
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
      id: 'scholar_2',
      title: 'Memory Palace',
      description: 'Build long-term retention using active recall.',
      category: 'Scholar',
      imageUrl: 'https://images.unsplash.com/photo-1532012197267-da84d127e765?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.intermediate,
      habits: [
        BlueprintHabit(title: 'Spaced Repetition', timeOfDay: 'Morning', frequency: 'Daily'),
        BlueprintHabit(title: 'Feynman Technique', timeOfDay: 'Afternoon', frequency: 'Daily'),
      ],
    ),
    const Blueprint(
      id: 'scholar_3',
      title: 'Analytical Mind',
      description: 'Sharpen your logic and quantitative reasoning.',
      category: 'Scholar',
      imageUrl: 'https://images.unsplash.com/photo-1509228468518-180dd4864904?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.advanced,
      habits: [
        BlueprintHabit(title: 'Mathematical Thinking', timeOfDay: 'Morning', frequency: 'Daily'),
        BlueprintHabit(title: 'Mental Models', timeOfDay: 'Any', frequency: 'Daily'),
      ],
    ),
    const Blueprint(
      id: 'scholar_4',
      title: 'Linguist Protocol',
      description: 'Immerse yourself in a new language or vocabulary.',
      category: 'Scholar',
      imageUrl: 'https://images.unsplash.com/photo-1457369804613-52c61a468e7d?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.beginner,
      habits: [
        BlueprintHabit(title: 'Language Practice', timeOfDay: 'Morning', frequency: 'Daily'),
        BlueprintHabit(title: 'Vocabulary Expansion', timeOfDay: 'Any', frequency: 'Daily'),
      ],
    ),
    const Blueprint(
      id: 'scholar_5',
      title: 'Academic Output',
      description: 'Consistent writing and peer review.',
      category: 'Scholar',
      imageUrl: 'https://images.unsplash.com/photo-1513475382585-d06e73b22b28?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.intermediate,
      habits: [
        BlueprintHabit(title: 'Academic Writing', timeOfDay: 'Morning', frequency: 'Daily'),
        BlueprintHabit(title: 'Thesis Review', timeOfDay: 'Weekend', frequency: 'Weekly'),
      ],
    ),

    // --- STOIC ---
    const Blueprint(
      id: 'stoic_1',
      title: 'The Stoic Morning',
      description: 'Start your day with clarity and ancient practices.',
      category: 'Stoic',
      imageUrl: 'https://images.unsplash.com/photo-1519834785169-98be25ec3f84?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.intermediate,
      habits: [
        BlueprintHabit(title: 'Premeditatio Malorum', timeOfDay: 'Morning', frequency: 'Daily'),
        BlueprintHabit(title: 'Journaling (Aurelius)', timeOfDay: 'Morning', frequency: 'Daily'),
      ],
    ),
    const Blueprint(
      id: 'stoic_2',
      title: 'Emotional Armor',
      description: 'Train your mind to remain unaffected by externals.',
      category: 'Stoic',
      imageUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.advanced,
      habits: [
        BlueprintHabit(title: 'Dichotomy of Control', timeOfDay: 'Any', frequency: 'Daily'),
        BlueprintHabit(title: 'Pause Response', timeOfDay: 'Any', frequency: 'Daily'),
      ],
    ),
    const Blueprint(
      id: 'stoic_3',
      title: 'Voluntary Discomfort',
      description: 'Build resilience by seeking out mild hardship.',
      category: 'Stoic',
      imageUrl: 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.advanced,
      habits: [
        BlueprintHabit(title: 'Endurance Hold', timeOfDay: 'Morning', frequency: 'Daily'),
        BlueprintHabit(title: 'Minimalist Day', timeOfDay: 'Any', frequency: 'Weekly'),
      ],
    ),
    const Blueprint(
      id: 'stoic_4',
      title: 'Evening Reflection',
      description: 'End the day with objective self-assessment.',
      category: 'Stoic',
      imageUrl: 'https://images.unsplash.com/photo-1472289065668-ce650ac443d2?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.beginner,
      habits: [
        BlueprintHabit(title: 'Evening Examen', timeOfDay: 'Evening', frequency: 'Daily'),
        BlueprintHabit(title: 'Amor Fati', timeOfDay: 'Evening', frequency: 'Daily'),
      ],
    ),
    const Blueprint(
      id: 'stoic_5',
      title: 'Cosmic Perspective',
      description: 'Zoom out from daily anxieties.',
      category: 'Stoic',
      imageUrl: 'https://images.unsplash.com/photo-1464802686167-b939a6910659?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.intermediate,
      habits: [
        BlueprintHabit(title: 'View from Above', timeOfDay: 'Evening', frequency: 'Daily'),
        BlueprintHabit(title: 'Memento Mori', timeOfDay: 'Morning', frequency: 'Daily'),
      ],
    ),

    // --- ZEALOT ---
    const Blueprint(
      id: 'zealot_1',
      title: 'Absolute Devotion',
      description: 'Center your life around your core mission or faith.',
      category: 'Zealot',
      imageUrl: 'https://images.unsplash.com/photo-1494586419766-c956fb400a08?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.advanced,
      habits: [
        BlueprintHabit(title: 'Sacred Ritual', timeOfDay: 'Morning', frequency: 'Daily'),
        BlueprintHabit(title: 'Scripture/Text Study', timeOfDay: 'Evening', frequency: 'Daily'),
      ],
    ),
    const Blueprint(
      id: 'zealot_2',
      title: 'Purification Fire',
      description: 'Cleanse the body and mind of distractions.',
      category: 'Zealot',
      imageUrl: 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.intermediate,
      habits: [
        BlueprintHabit(title: 'Fasting Block', timeOfDay: 'Any', frequency: 'Daily'),
        BlueprintHabit(title: 'Digital Detox', timeOfDay: 'Weekend', frequency: 'Weekly'),
      ],
    ),
    const Blueprint(
      id: 'zealot_3',
      title: 'Unwavering Output',
      description: 'Channel intense focus into your most vital work.',
      category: 'Zealot',
      imageUrl: 'https://images.unsplash.com/photo-1483366774565-c783b9f70e2c?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.advanced,
      habits: [
        BlueprintHabit(title: 'Unwavering Focus', timeOfDay: 'Morning', frequency: 'Daily'),
        BlueprintHabit(title: 'High-Intensity Output', timeOfDay: 'Afternoon', frequency: 'Daily'),
      ],
    ),
    const Blueprint(
      id: 'zealot_4',
      title: 'The Evangelist',
      description: 'Share your mission and align with your community.',
      category: 'Zealot',
      imageUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.intermediate,
      habits: [
        BlueprintHabit(title: 'Community Service', timeOfDay: 'Weekend', frequency: 'Weekly'),
        BlueprintHabit(title: 'Charismatic Speaking', timeOfDay: 'Morning', frequency: 'Daily'),
      ],
    ),
    const Blueprint(
      id: 'zealot_5',
      title: 'Vow of Simplicity',
      description: 'Strip away the unnecessary to focus on the essential.',
      category: 'Zealot',
      imageUrl: 'https://images.unsplash.com/photo-1473448912268-2022ce9509d8?auto=format&fit=crop&q=80',
      difficulty: BlueprintDifficulty.beginner,
      habits: [
        BlueprintHabit(title: 'Vow of Simplicity', timeOfDay: 'Any', frequency: 'Daily'),
        BlueprintHabit(title: 'Mission Alignment', timeOfDay: 'Morning', frequency: 'Daily'),
      ],
    ),
  ];

  Future<List<Blueprint>> getBlueprints({String? category}) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('blueprints');

      if (category != null && category != 'All') {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        // Fallback to local data if Firestore is empty (e.g., seeding not performed)
        if (category == null || category == 'All') {
          return _fallbackBlueprints;
        }
        return _fallbackBlueprints
            .where((b) => b.category == category)
            .toList();
      }

      return snapshot.docs
          .map((doc) => Blueprint.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      // On error, return fallback data
      if (category == null || category == 'All') {
        return _fallbackBlueprints;
      }
      return _fallbackBlueprints.where((b) => b.category == category).toList();
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('blueprints').get();
      final categories = snapshot.docs
          .map((doc) => doc.data()['category'] as String? ?? 'General')
          .toSet()
          .toList();

      if (!categories.contains('All')) {
        categories.insert(0, 'All');
      }
      return categories.isEmpty
          ? ['All', 'Athlete', 'Creator', 'Scholar', 'Stoic', 'Zealot']
          : categories;
    } catch (e) {
      return ['All', 'Athlete', 'Creator', 'Scholar', 'Stoic', 'Zealot'];
    }
  }
}

final blueprintsRepositoryProvider = Provider<BlueprintsRepository>((ref) {
  return BlueprintsRepository(FirebaseFirestore.instance);
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
