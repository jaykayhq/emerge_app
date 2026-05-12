import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlueprintRepository {
  final FirebaseFirestore _firestore;

  BlueprintRepository(this._firestore);

  Stream<List<Blueprint>> getBlueprints({String? category}) {
    Query<Map<String, dynamic>> query = _firestore.collection('blueprints');

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snap) =>
        snap.docs.map((d) => Blueprint.fromMap(d.id, d.data())).toList());
  }

  Future<void> adoptBlueprint(String blueprintId) async {
    final docRef = _firestore.collection('blueprints').doc(blueprintId);
    await docRef.update({
      'adoptionCount': FieldValue.increment(1),
    });
  }

  Future<void> seedBlueprintsIfEmpty() async {
    try {
      final existing = await _firestore
          .collection('blueprints')
          .where('creatorUserId', isEqualTo: 'system')
          .limit(25)
          .get();
          
      if (existing.docs.length >= 25) {
        AppLogger.i('BlueprintRepository: Blueprints already seeded.');
        return;
      }

      final List<Blueprint> seedData = [
        // ATHLETE
        _createSeed(
          id: 'athlete_1',
          category: 'Athlete',
          title: 'The Iron Morning',
          description: 'Start your day with intense physical activation.',
          image: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Zone 2 Cardio', 'Cold Shower', 'Hydration Target'],
        ),
        _createSeed(
          id: 'athlete_2',
          category: 'Athlete',
          title: 'Unbreakable Core',
          description: 'A 30-day protocol for core strength and posture.',
          image: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['Core Stability', 'Mobility Flow'],
        ),
        _createSeed(
          id: 'athlete_3',
          category: 'Athlete',
          title: 'Sleep Optimization',
          description: 'Maximize recovery through deliberate evening routines.',
          image: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Sleep Optimization', 'Active Recovery'],
        ),
        _createSeed(
          id: 'athlete_4',
          category: 'Athlete',
          title: 'HIIT Protocol',
          description: 'Build explosive energy and cardiovascular health.',
          image: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['Sprint Intervals', 'Stretching'],
        ),
        _createSeed(
          id: 'athlete_5',
          category: 'Athlete',
          title: 'Nutrition Base',
          description: 'Solidify your dietary foundation.',
          image: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Meal Prep', 'Protein Tracking'],
        ),

        // CREATOR
        _createSeed(
          id: 'creator_1',
          category: 'Creator',
          title: 'The Flow State',
          description: 'Enter deep creative flow and produce without distraction.',
          image: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['Deep Work Block', 'Analog Hour'],
        ),
        _createSeed(
          id: 'creator_2',
          category: 'Creator',
          title: 'Idea Machine',
          description: 'Train your brain to generate ideas consistently.',
          image: 'https://images.unsplash.com/photo-1499750310107-5fef28a66643?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Idea Capture', 'Morning Pages'],
        ),
        _createSeed(
          id: 'creator_3',
          category: 'Creator',
          title: 'Shipping Fast',
          description: 'Overcome perfectionism by publishing daily.',
          image: 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Ugly First Draft', 'Ship Something'],
        ),
        _createSeed(
          id: 'creator_4',
          category: 'Creator',
          title: 'Visual Aesthetic',
          description: 'Improve your eye for design and beauty.',
          image: 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Visual Journal', 'Swipe File'],
        ),
        _createSeed(
          id: 'creator_5',
          category: 'Creator',
          title: 'Master Craftsman',
          description: 'Deliberate practice to sharpen your core skills.',
          image: 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?w=800',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['Skill Practice', 'Feedback Request'],
        ),

        // SCHOLAR
        _createSeed(
          id: 'scholar_1',
          category: 'Scholar',
          title: 'Syntopic Immersion',
          description: 'Read deeply and cross-reference knowledge.',
          image: 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=800',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['Syntopic Reading', 'Zettelkasten'],
        ),
        _createSeed(
          id: 'scholar_2',
          category: 'Scholar',
          title: 'Memory Palace',
          description: 'Build long-term retention using active recall.',
          image: 'https://images.unsplash.com/photo-1532012197267-da84d127e765?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Spaced Repetition', 'Feynman Technique'],
        ),
        _createSeed(
          id: 'scholar_3',
          category: 'Scholar',
          title: 'Analytical Mind',
          description: 'Sharpen your logic and quantitative reasoning.',
          image: 'https://images.unsplash.com/photo-1509228468518-180dd4864904?w=800',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['Mathematical Thinking', 'Mental Models'],
        ),
        _createSeed(
          id: 'scholar_4',
          category: 'Scholar',
          title: 'Linguist Protocol',
          description: 'Immerse yourself in a new language or vocabulary.',
          image: 'https://images.unsplash.com/photo-1457369804613-52c61a468e7d?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Language Practice', 'Vocabulary Expansion'],
        ),
        _createSeed(
          id: 'scholar_5',
          category: 'Scholar',
          title: 'Academic Output',
          description: 'Consistent writing and peer review.',
          image: 'https://images.unsplash.com/photo-1513475382585-d06e73b22b28?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Academic Writing', 'Thesis Review'],
        ),

        // STOIC
        _createSeed(
          id: 'stoic_1',
          category: 'Stoic',
          title: 'The Stoic Morning',
          description: 'Start your day with clarity and ancient practices.',
          image: 'https://images.unsplash.com/photo-1519834785169-98be25ec3f84?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Premeditatio Malorum', 'Journaling (Aurelius)'],
        ),
        _createSeed(
          id: 'stoic_2',
          category: 'Stoic',
          title: 'Emotional Armor',
          description: 'Train your mind to remain unaffected by externals.',
          image: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['Dichotomy of Control', 'Pause Response'],
        ),
        _createSeed(
          id: 'stoic_3',
          category: 'Stoic',
          title: 'Voluntary Discomfort',
          description: 'Build resilience by seeking out mild hardship.',
          image: 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['Endurance Hold', 'Minimalist Day'],
        ),
        _createSeed(
          id: 'stoic_4',
          category: 'Stoic',
          title: 'Evening Reflection',
          description: 'End the day with objective self-assessment.',
          image: 'https://images.unsplash.com/photo-1472289065668-ce650ac443d2?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Evening Examen', 'Amor Fati'],
        ),
        _createSeed(
          id: 'stoic_5',
          category: 'Stoic',
          title: 'Cosmic Perspective',
          description: 'Zoom out from daily anxieties.',
          image: 'https://images.unsplash.com/photo-1464802686167-b939a6910659?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['View from Above', 'Memento Mori'],
        ),

        // ZEALOT
        _createSeed(
          id: 'zealot_1',
          category: 'Zealot',
          title: 'Absolute Devotion',
          description: 'Center your life around your core mission.',
          image: 'https://images.unsplash.com/photo-1507692049790-de58290a4334?w=800',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['Sacred Ritual', 'Scripture Study'],
        ),
        _createSeed(
          id: 'zealot_2',
          category: 'Zealot',
          title: 'Purification Fire',
          description: 'Cleanse the body and mind of distractions.',
          image: 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Fasting Block', 'Digital Detox'],
        ),
        _createSeed(
          id: 'zealot_3',
          category: 'Zealot',
          title: 'Unwavering Output',
          description: 'Channel intense focus into your vital work.',
          image: 'https://images.unsplash.com/photo-1483366774565-c783b9f70e2c?w=800',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['Unwavering Focus', 'High-Intensity Output'],
        ),
        _createSeed(
          id: 'zealot_4',
          category: 'Zealot',
          title: 'The Evangelist',
          description: 'Share your mission and align with community.',
          image: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Community Service', 'Charismatic Speaking'],
        ),
        _createSeed(
          id: 'zealot_5',
          category: 'Zealot',
          title: 'Vow of Simplicity',
          description: 'Strip away the unnecessary.',
          image: 'https://images.unsplash.com/photo-1473448912268-2022ce9509d8?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Vow of Simplicity', 'Mission Alignment'],
        ),
      ];

      final batch = _firestore.batch();
      for (final bp in seedData) {
        final docRef = _firestore.collection('blueprints').doc(bp.id);
        batch.set(docRef, bp.toMap());
      }
      await batch.commit();
      AppLogger.i('BlueprintRepository: Seeding complete.');
    } catch (e) {
      AppLogger.e('BlueprintRepository: Seeding failed', e);
    }
  }

  Blueprint _createSeed({
    required String id,
    required String category,
    required String title,
    required String description,
    required String image,
    required BlueprintDifficulty difficulty,
    required List<String> habits,
  }) {
    return Blueprint(
      id: id,
      creatorUserId: 'system',
      creatorName: 'Emerge Official',
      creatorArchetype: category,
      title: title,
      description: description,
      habits: habits.map((h) => BlueprintHabit(title: h)).toList(),
      createdAt: DateTime.now(),
      imageUrl: image,
      category: category,
      difficulty: difficulty,
    );
  }
}

final blueprintRepositoryProvider = Provider<BlueprintRepository>((ref) {
  return BlueprintRepository(FirebaseFirestore.instance);
});

final blueprintsStreamProvider = StreamProvider.family<List<Blueprint>, String?>((ref, category) {
  final repo = ref.watch(blueprintRepositoryProvider);
  return repo.getBlueprints(category: category);
});

final allBlueprintsStreamProvider = StreamProvider<List<Blueprint>>((ref) {
  final repo = ref.watch(blueprintRepositoryProvider);
  return repo.getBlueprints();
});
