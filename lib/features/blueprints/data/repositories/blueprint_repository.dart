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

    return query.snapshots().map(
      (snap) =>
          snap.docs.map((d) => Blueprint.fromMap(d.id, d.data())).toList(),
    );
  }

  /// Single-doc fetch for deep-link navigation (e.g. notifications or shared
  /// URLs that arrive without a pre-resolved Blueprint object).
  /// Prefer this over [getBlueprints] when you only need one row — it avoids
  /// streaming the entire `blueprints` collection.
  Future<Blueprint?> getBlueprintById(String id) async {
    final snap = await _firestore.collection('blueprints').doc(id).get();
    if (!snap.exists) return null;
    return Blueprint.fromMap(snap.id, snap.data()!);
  }

  Future<void> incrementAdoptionCount(String blueprintId) async {
    final docRef = _firestore.collection('blueprints').doc(blueprintId);
    await docRef.update({'adoptionCount': FieldValue.increment(1)});
  }

  Future<String> createBlueprint(Blueprint blueprint) async {
    try {
      final collectionRef = _firestore.collection('blueprints');
      final docRef = blueprint.id.isNotEmpty ? collectionRef.doc(blueprint.id) : collectionRef.doc();
      
      final blueprintToSave = blueprint.copyWith(id: docRef.id);
      await docRef.set(blueprintToSave.toMap());
      
      AppLogger.i('BlueprintRepository: Created blueprint ${docRef.id}');
      return docRef.id;
    } catch (e) {
      AppLogger.e('BlueprintRepository: Failed to create blueprint', e);
      rethrow;
    }
  }

  /// Current seed version — bump when seed data changes to force re-seed
  static const int _seedVersion = 4;

  Future<void> seedBlueprintsIfEmpty() async {
    try {
      // Skip only when the sentinel doc exists AND already carries v4
      // artwork. A v3 doc (remote Unsplash image) must be backfilled so
      // every install renders the bundled blueprint images.
      final v4Check = await _firestore
          .collection('blueprints')
          .doc('morning_1')
          .get();
      final isV4 = v4Check.exists &&
          (v4Check.data()?['imageUrl'] as String? ?? '')
              .startsWith('assets/images/blueprints/');

      if (isV4) {
        AppLogger.i(
          'BlueprintRepository: Blueprints already seeded (v$_seedVersion).',
        );
        return;
      }

      // Backfilling existing docs: merge must not clobber live-doc adoption
      // counts or creation timestamps, so increment(0) is a no-op for
      // counters and createdAt is left untouched on existing docs.
      final backfilling = v4Check.exists;

      // Note: Old archetype blueprints (v1) remain in Firestore but are
      // filtered out in the UI by allowed categories list. Server-side
      // cleanup via Firebase Console or Cloud Function recommended for production.

      final List<Blueprint> seedData = [
        // MORNING
        _createSeed(
          id: 'morning_1',
          category: 'Morning',
          title: 'Sunrise Ritual',
          description: 'Start your day with intention, light, and hydration.',
          image:
              'assets/images/blueprints/morning_1.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: [
            'Wake Up at 6 AM',
            'Drink 500ml Water',
            '10 Min Sunlight Exposure',
          ],
          recommendedArchetypes: const ['athlete', 'stoic'],
        ),
        _createSeed(
          id: 'morning_2',
          category: 'Morning',
          title: 'Power Morning',
          description: 'An energizing morning routine to dominate your day.',
          image:
              'assets/images/blueprints/morning_2.webp',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Cold Shower', 'Stretch Routine', 'High-Protein Breakfast'],
          recommendedArchetypes: const ['athlete'],
        ),
        _createSeed(
          id: 'morning_3',
          category: 'Morning',
          title: 'Mindful Awakening',
          description: 'Ease into the day with calm and clarity.',
          image:
              'assets/images/blueprints/morning_3.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['5 Min Meditation', 'Gratitude Journal', 'Herbal Tea'],
          recommendedArchetypes: const ['stoic'],
        ),
        _createSeed(
          id: 'morning_4',
          category: 'Morning',
          title: 'Early Bird Stack',
          description: 'Rise before the world and claim your quiet hours.',
          image:
              'assets/images/blueprints/morning_4.webp',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['Wake at 5 AM', 'Deep Work Block', 'No Phone for 1 Hour'],
          recommendedArchetypes: const ['scholar', 'zealot'],
        ),
        _createSeed(
          id: 'morning_5',
          category: 'Morning',
          title: 'Morning Mobility',
          description: 'Loosen up and prepare your body for the day ahead.',
          image:
              'assets/images/blueprints/morning_5.webp',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Dynamic Stretching', 'Foam Rolling', 'Posture Check'],
          recommendedArchetypes: const ['athlete'],
        ),

        // PRODUCTIVITY
        _createSeed(
          id: 'productivity_1',
          category: 'Productivity',
          title: 'Deep Work Protocol',
          description: 'Train your focus for uninterrupted deep work sessions.',
          image:
              'assets/images/blueprints/productivity_1.webp',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['90 Min Deep Work', 'Phone on DND', 'Task Batching'],
          recommendedArchetypes: const ['scholar', 'zealot'],
        ),
        _createSeed(
          id: 'productivity_2',
          category: 'Productivity',
          title: 'The Ivy Lee Method',
          description:
              'A century-old productivity system for daily prioritization.',
          image:
              'assets/images/blueprints/productivity_2.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: [
            'Write Top 6 Tasks',
            'Prioritize by Importance',
            'Complete One at a Time',
          ],
          recommendedArchetypes: const ['scholar', 'zealot'],
        ),
        _createSeed(
          id: 'productivity_3',
          category: 'Productivity',
          title: 'Time Block Master',
          description: 'Schedule every hour of your day with purpose.',
          image:
              'assets/images/blueprints/productivity_3.webp',
          difficulty: BlueprintDifficulty.intermediate,
          habits: [
            'Plan Tomorrow Tonight',
            'Time Block Calendar',
            'Review & Reflect',
          ],
          recommendedArchetypes: const ['scholar', 'zealot'],
        ),
        _createSeed(
          id: 'productivity_4',
          category: 'Productivity',
          title: 'Digital Declutter',
          description: 'Clear digital noise and reclaim your attention.',
          image:
              'assets/images/blueprints/productivity_4.webp',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Unsubscribe from Junk', 'Organize Files', 'App Purge'],
          recommendedArchetypes: const ['stoic', 'scholar'],
        ),
        _createSeed(
          id: 'productivity_5',
          category: 'Productivity',
          title: 'Pomodoro Flow',
          description: 'Harness the Pomodoro technique for sustained output.',
          image:
              'assets/images/blueprints/productivity_5.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['25 Min Focus Sprint', '5 Min Break', 'Track Pomodoros'],
          recommendedArchetypes: const ['scholar', 'athlete'],
        ),

        // FITNESS
        _createSeed(
          id: 'fitness_1',
          category: 'Fitness',
          title: 'Bodyweight Foundation',
          description: 'Build strength with just your body weight.',
          image:
              'assets/images/blueprints/fitness_1.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Push-Ups', 'Bodyweight Squats', 'Plank Hold'],
          recommendedArchetypes: const ['athlete'],
        ),
        _createSeed(
          id: 'fitness_2',
          category: 'Fitness',
          title: 'Cardio Builder',
          description: 'Improve cardiovascular endurance step by step.',
          image:
              'assets/images/blueprints/fitness_2.webp',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['20 Min Run', 'Jump Rope', 'Cool Down Stretch'],
          recommendedArchetypes: const ['athlete'],
        ),
        _createSeed(
          id: 'fitness_3',
          category: 'Fitness',
          title: 'Flexibility & Mobility',
          description: 'Increase range of motion and prevent injury.',
          image:
              'assets/images/blueprints/fitness_3.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Hamstring Stretch', 'Hip Openers', 'Spine Twists'],
          recommendedArchetypes: const ['athlete', 'stoic'],
        ),
        _createSeed(
          id: 'fitness_4',
          category: 'Fitness',
          title: 'Iron Will',
          description: 'A progressive strength training blueprint.',
          image:
              'assets/images/blueprints/fitness_4.webp',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['Deadlifts', 'Overhead Press', 'Pull-Ups'],
          recommendedArchetypes: const ['athlete', 'zealot'],
        ),
        _createSeed(
          id: 'fitness_5',
          category: 'Fitness',
          title: 'Active Recovery',
          description: 'Rest days that keep you moving and healing.',
          image:
              'assets/images/blueprints/fitness_5.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Brisk Walk', 'Light Yoga', 'Hydration Focus'],
          recommendedArchetypes: const ['athlete', 'stoic'],
        ),

        // MINDFULNESS
        _createSeed(
          id: 'mindfulness_1',
          category: 'Mindfulness',
          title: 'Daily Meditation',
          description: 'Build a consistent meditation practice from scratch.',
          image:
              'assets/images/blueprints/mindfulness_1.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['5 Min Breath Focus', 'Body Scan', 'Loving Kindness'],
          recommendedArchetypes: const ['stoic'],
        ),
        _createSeed(
          id: 'mindfulness_2',
          category: 'Mindfulness',
          title: 'Digital Sabbath',
          description: 'Weekly disconnection to recharge your mind.',
          image:
              'assets/images/blueprints/mindfulness_2.webp',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['No Screens for 4 Hours', 'Nature Walk', 'Analog Activity'],
          recommendedArchetypes: const ['stoic', 'scholar'],
        ),
        _createSeed(
          id: 'mindfulness_3',
          category: 'Mindfulness',
          title: 'Gratitude Practice',
          description: 'Rewire your brain for appreciation and abundance.',
          image:
              'assets/images/blueprints/mindfulness_3.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Write 3 Gratitudes', 'Thank Someone', 'Savor a Moment'],
          recommendedArchetypes: const ['stoic', 'zealot'],
        ),
        _createSeed(
          id: 'mindfulness_4',
          category: 'Mindfulness',
          title: 'Stress Shield',
          description: 'Daily practices to build resilience against stress.',
          image:
              'assets/images/blueprints/mindfulness_4.webp',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Box Breathing', 'Progressive Relaxation', 'Journaling'],
          recommendedArchetypes: const ['stoic'],
        ),
        _createSeed(
          id: 'mindfulness_5',
          category: 'Mindfulness',
          title: 'Evening Wind Down',
          description:
              'A calming ritual to signal your body it is time to rest.',
          image:
              'assets/images/blueprints/mindfulness_5.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: [
            'No Screens 30 Min Before Bed',
            'Tidy Your Space',
            'Read Fiction',
          ],
          recommendedArchetypes: const ['stoic', 'scholar'],
        ),

        // LEARNING
        _createSeed(
          id: 'learning_1',
          category: 'Learning',
          title: 'Daily Reader',
          description: 'Read consistently and compound knowledge.',
          image:
              'assets/images/blueprints/learning_1.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Read 20 Pages', 'Take Notes', 'Summarize Key Idea'],
          recommendedArchetypes: const ['scholar'],
        ),
        _createSeed(
          id: 'learning_2',
          category: 'Learning',
          title: 'Skill Sprint',
          description: 'Learn a new skill with focused daily practice.',
          image:
              'assets/images/blueprints/learning_2.webp',
          difficulty: BlueprintDifficulty.intermediate,
          habits: [
            '30 Min Deliberate Practice',
            'Track Progress',
            'Review Mistakes',
          ],
          recommendedArchetypes: const ['scholar', 'creator'],
        ),
        _createSeed(
          id: 'learning_3',
          category: 'Learning',
          title: 'Curious Mind',
          description: 'Feed your curiosity across diverse topics.',
          image:
              'assets/images/blueprints/learning_3.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: [
            'Watch a Documentary',
            'Read One Article',
            'Discuss What You Learned',
          ],
          recommendedArchetypes: const ['scholar', 'creator'],
        ),
        _createSeed(
          id: 'learning_4',
          category: 'Learning',
          title: 'Memory Master',
          description: 'Strengthen recall with spaced repetition.',
          image:
              'assets/images/blueprints/learning_4.webp',
          difficulty: BlueprintDifficulty.intermediate,
          habits: [
            'Review Flashcards',
            'Teach Someone',
            'Active Recall Session',
          ],
          recommendedArchetypes: const ['scholar'],
        ),
        _createSeed(
          id: 'learning_5',
          category: 'Learning',
          title: 'Course Completer',
          description:
              'Finish online courses with structure and accountability.',
          image:
              'assets/images/blueprints/learning_5.webp',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['Watch One Lesson', 'Do the Assignment', 'Write Reflection'],
          recommendedArchetypes: const ['scholar', 'zealot'],
        ),
      ];

      final batch = _firestore.batch();
      for (final bp in seedData) {
        final docRef = _firestore.collection('blueprints').doc(bp.id);
        final data = bp.toMap();
        if (backfilling) {
          data['adoptionCount'] = FieldValue.increment(0);
          data.remove('createdAt');
        }
        batch.set(docRef, data, SetOptions(merge: true));
      }
      await batch.commit();
      AppLogger.i(
        'BlueprintRepository: Seeding complete (v$_seedVersion).',
      );
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
    required List<String> recommendedArchetypes,
  }) {
    return Blueprint(
      id: id,
      creatorUserId: 'system',
      creatorName: 'Emerge Official',
      creatorArchetype: 'Emerge',
      title: title,
      description: description,
      habits: habits.map((h) => BlueprintHabit(title: h)).toList(),
      createdAt: DateTime.now(),
      imageUrl: image,
      category: category,
      difficulty: difficulty,
      recommendedArchetypes: recommendedArchetypes,
    );
  }
}

final blueprintRepositoryProvider = Provider<BlueprintRepository>((ref) {
  return BlueprintRepository(FirebaseFirestore.instance);
});

final blueprintsStreamProvider =
    StreamProvider.autoDispose.family<List<Blueprint>, String?>((ref, category) {
      final repo = ref.watch(blueprintRepositoryProvider);
      return repo.getBlueprints(category: category);
    });

final allBlueprintsStreamProvider = StreamProvider.autoDispose<List<Blueprint>>((ref) {
  final repo = ref.watch(blueprintRepositoryProvider);
  return repo.getBlueprints();
});

/// Single-doc fetch for deep-link navigation (notifications, shared URLs).
/// Returns null when the doc doesn't exist.
final blueprintByIdProvider =
    FutureProvider.autoDispose.family<Blueprint?, String>((ref, id) {
  final repo = ref.watch(blueprintRepositoryProvider);
  return repo.getBlueprintById(id);
});
