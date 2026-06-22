import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
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
  static const int _seedVersion = 2;

  Future<void> seedBlueprintsIfEmpty() async {
    try {
      // Check if v2 seed data already exists
      final v2Check = await _firestore
          .collection('blueprints')
          .doc('morning_1')
          .get();

      if (v2Check.exists) {
        AppLogger.i(
          'BlueprintRepository: Blueprints already seeded (v$_seedVersion).',
        );
        return;
      }

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
              'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: [
            'Wake Up at 6 AM',
            'Drink 500ml Water',
            '10 Min Sunlight Exposure',
          ],
        ),
        _createSeed(
          id: 'morning_2',
          category: 'Morning',
          title: 'Power Morning',
          description: 'An energizing morning routine to dominate your day.',
          image:
              'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Cold Shower', 'Stretch Routine', 'High-Protein Breakfast'],
        ),
        _createSeed(
          id: 'morning_3',
          category: 'Morning',
          title: 'Mindful Awakening',
          description: 'Ease into the day with calm and clarity.',
          image:
              'https://images.unsplash.com/photo-1545205597-3d9d02e29597?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['5 Min Meditation', 'Gratitude Journal', 'Herbal Tea'],
        ),
        _createSeed(
          id: 'morning_4',
          category: 'Morning',
          title: 'Early Bird Stack',
          description: 'Rise before the world and claim your quiet hours.',
          image:
              'https://images.unsplash.com/photo-1490818387583-1baba5e638af?w=800',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['Wake at 5 AM', 'Deep Work Block', 'No Phone for 1 Hour'],
        ),
        _createSeed(
          id: 'morning_5',
          category: 'Morning',
          title: 'Morning Mobility',
          description: 'Loosen up and prepare your body for the day ahead.',
          image:
              'https://images.unsplash.com/photo-1552196563-55cd4e45efb3?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Dynamic Stretching', 'Foam Rolling', 'Posture Check'],
        ),

        // PRODUCTIVITY
        _createSeed(
          id: 'productivity_1',
          category: 'Productivity',
          title: 'Deep Work Protocol',
          description: 'Train your focus for uninterrupted deep work sessions.',
          image:
              'https://images.unsplash.com/photo-1483058712412-4245e9b90334?w=800',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['90 Min Deep Work', 'Phone on DND', 'Task Batching'],
        ),
        _createSeed(
          id: 'productivity_2',
          category: 'Productivity',
          title: 'The Ivy Lee Method',
          description:
              'A century-old productivity system for daily prioritization.',
          image:
              'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: [
            'Write Top 6 Tasks',
            'Prioritize by Importance',
            'Complete One at a Time',
          ],
        ),
        _createSeed(
          id: 'productivity_3',
          category: 'Productivity',
          title: 'Time Block Master',
          description: 'Schedule every hour of your day with purpose.',
          image:
              'https://images.unsplash.com/photo-1506784983877-45594efa4cbe?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: [
            'Plan Tomorrow Tonight',
            'Time Block Calendar',
            'Review & Reflect',
          ],
        ),
        _createSeed(
          id: 'productivity_4',
          category: 'Productivity',
          title: 'Digital Declutter',
          description: 'Clear digital noise and reclaim your attention.',
          image:
              'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Unsubscribe from Junk', 'Organize Files', 'App Purge'],
        ),
        _createSeed(
          id: 'productivity_5',
          category: 'Productivity',
          title: 'Pomodoro Flow',
          description: 'Harness the Pomodoro technique for sustained output.',
          image:
              'https://images.unsplash.com/photo-1499750310107-5fef28a66643?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['25 Min Focus Sprint', '5 Min Break', 'Track Pomodoros'],
        ),

        // FITNESS
        _createSeed(
          id: 'fitness_1',
          category: 'Fitness',
          title: 'Bodyweight Foundation',
          description: 'Build strength with just your body weight.',
          image:
              'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Push-Ups', 'Bodyweight Squats', 'Plank Hold'],
        ),
        _createSeed(
          id: 'fitness_2',
          category: 'Fitness',
          title: 'Cardio Builder',
          description: 'Improve cardiovascular endurance step by step.',
          image:
              'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['20 Min Run', 'Jump Rope', 'Cool Down Stretch'],
        ),
        _createSeed(
          id: 'fitness_3',
          category: 'Fitness',
          title: 'Flexibility & Mobility',
          description: 'Increase range of motion and prevent injury.',
          image:
              'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Hamstring Stretch', 'Hip Openers', 'Spine Twists'],
        ),
        _createSeed(
          id: 'fitness_4',
          category: 'Fitness',
          title: 'Iron Will',
          description: 'A progressive strength training blueprint.',
          image:
              'https://images.unsplash.com/photo-1532029837206-abbe2b7620e3?w=800',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['Deadlifts', 'Overhead Press', 'Pull-Ups'],
        ),
        _createSeed(
          id: 'fitness_5',
          category: 'Fitness',
          title: 'Active Recovery',
          description: 'Rest days that keep you moving and healing.',
          image:
              'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Brisk Walk', 'Light Yoga', 'Hydration Focus'],
        ),

        // MINDFULNESS
        _createSeed(
          id: 'mindfulness_1',
          category: 'Mindfulness',
          title: 'Daily Meditation',
          description: 'Build a consistent meditation practice from scratch.',
          image:
              'https://images.unsplash.com/photo-1508672019048-805c876b67e2?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['5 Min Breath Focus', 'Body Scan', 'Loving Kindness'],
        ),
        _createSeed(
          id: 'mindfulness_2',
          category: 'Mindfulness',
          title: 'Digital Sabbath',
          description: 'Weekly disconnection to recharge your mind.',
          image:
              'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?w=800',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['No Screens for 4 Hours', 'Nature Walk', 'Analog Activity'],
        ),
        _createSeed(
          id: 'mindfulness_3',
          category: 'Mindfulness',
          title: 'Gratitude Practice',
          description: 'Rewire your brain for appreciation and abundance.',
          image:
              'https://images.unsplash.com/photo-1489710437720-ebb67ec84dd2?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Write 3 Gratitudes', 'Thank Someone', 'Savor a Moment'],
        ),
        _createSeed(
          id: 'mindfulness_4',
          category: 'Mindfulness',
          title: 'Stress Shield',
          description: 'Daily practices to build resilience against stress.',
          image:
              'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: ['Box Breathing', 'Progressive Relaxation', 'Journaling'],
        ),
        _createSeed(
          id: 'mindfulness_5',
          category: 'Mindfulness',
          title: 'Evening Wind Down',
          description:
              'A calming ritual to signal your body it is time to rest.',
          image:
              'https://images.unsplash.com/photo-1511295742362-92c96b1cf484?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: [
            'No Screens 30 Min Before Bed',
            'Tidy Your Space',
            'Read Fiction',
          ],
        ),

        // LEARNING
        _createSeed(
          id: 'learning_1',
          category: 'Learning',
          title: 'Daily Reader',
          description: 'Read consistently and compound knowledge.',
          image:
              'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: ['Read 20 Pages', 'Take Notes', 'Summarize Key Idea'],
        ),
        _createSeed(
          id: 'learning_2',
          category: 'Learning',
          title: 'Skill Sprint',
          description: 'Learn a new skill with focused daily practice.',
          image:
              'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: [
            '30 Min Deliberate Practice',
            'Track Progress',
            'Review Mistakes',
          ],
        ),
        _createSeed(
          id: 'learning_3',
          category: 'Learning',
          title: 'Curious Mind',
          description: 'Feed your curiosity across diverse topics.',
          image:
              'https://images.unsplash.com/photo-1507842217343-583bb7270b66?w=800',
          difficulty: BlueprintDifficulty.beginner,
          habits: [
            'Watch a Documentary',
            'Read One Article',
            'Discuss What You Learned',
          ],
        ),
        _createSeed(
          id: 'learning_4',
          category: 'Learning',
          title: 'Memory Master',
          description: 'Strengthen recall with spaced repetition.',
          image:
              'https://images.unsplash.com/photo-1517077304055-6e89abbf09b0?w=800',
          difficulty: BlueprintDifficulty.intermediate,
          habits: [
            'Review Flashcards',
            'Teach Someone',
            'Active Recall Session',
          ],
        ),
        _createSeed(
          id: 'learning_5',
          category: 'Learning',
          title: 'Course Completer',
          description:
              'Finish online courses with structure and accountability.',
          image:
              'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800',
          difficulty: BlueprintDifficulty.advanced,
          habits: ['Watch One Lesson', 'Do the Assignment', 'Write Reflection'],
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
      creatorArchetype: 'Emerge',
      title: title,
      description: description,
      habits: habits.map((h) => BlueprintHabit(title: h)).toList(),
      createdAt: DateTime.now(),
      imageUrl: image,
      category: category,
      difficulty: difficulty,
    );
  }

  /// Seeds 6 creator-authored blueprints (one per creator seeded by
  /// [CreatorRepository.seedCreatorsIfEmpty]). Each blueprint references
  /// its creator's userId and is flagged `isCreatorBlueprint: true`.
  ///
  /// Safe to call multiple times: it short-circuits when any creator
  /// blueprint already exists.
  Future<void> seedCreatorBlueprintsIfEmpty() async {
    try {
      final existing = await _firestore
          .collection('blueprints')
          .where('isCreatorBlueprint', isEqualTo: true)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        AppLogger.i(
          'BlueprintRepository: creator blueprints already seeded.',
        );
        return;
      }

      final List<Blueprint> seedData = [
        Blueprint(
          id: 'cb_aria_deep_work',
          creatorUserId: 'creator_aria_chen',
          creatorName: 'Aria Chen',
          creatorArchetype: 'Scholar',
          title: 'Scholar\'s Deep Work Stack',
          description:
              'Three habits for entering a focused, low-friction work block. '
              'Designed for knowledge workers who want depth without burning '
              'out before noon.',
          habits: const [
            BlueprintHabit(
              title: 'Morning Pages',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.intellect,
            ),
            BlueprintHabit(
              title: '90 Min Deep Work Block',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.focus,
            ),
            BlueprintHabit(
              title: 'Evening Reading Session',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.intellect,
            ),
          ],
          createdAt: DateTime.now(),
          category: 'Productivity',
          difficulty: BlueprintDifficulty.intermediate,
          isCreatorBlueprint: true,
          specialityTags: const ['Deep Work', 'Reading', 'Note Systems'],
        ),
        Blueprint(
          id: 'cb_marcus_morning',
          creatorUserId: 'creator_marcus_okafor',
          creatorName: 'Marcus Okafor',
          creatorArchetype: 'Athlete',
          title: 'Athlete\'s Morning Prep',
          description:
              'A short, repeatable morning stack that primes your nervous '
              'system for the day. Built for athletes, parents, and anyone '
              'who needs to feel capable before 9am.',
          habits: const [
            BlueprintHabit(
              title: '10 Min Mobility Flow',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.vitality,
            ),
            BlueprintHabit(
              title: '20 Min Strength Block',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.strength,
            ),
            BlueprintHabit(
              title: 'Protein-First Breakfast',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.vitality,
            ),
          ],
          createdAt: DateTime.now(),
          category: 'Fitness',
          difficulty: BlueprintDifficulty.intermediate,
          isCreatorBlueprint: true,
          specialityTags: const ['Strength', 'Mobility', 'Recovery'],
        ),
        Blueprint(
          id: 'cb_sora_creative',
          creatorUserId: 'creator_sora_tanaka',
          creatorName: 'Sora Tanaka',
          creatorArchetype: 'Creator',
          title: 'Creator\'s Studio Ritual',
          description:
              'A studio-ready ritual for designers, writers, and makers. '
              'Each habit is small enough to survive a bad day and '
              'structured enough to compound into real output.',
          habits: const [
            BlueprintHabit(
              title: '30 Min Sketch Block',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.creativity,
            ),
            BlueprintHabit(
              title: 'Idea Capture (3 Notes)',
              timeOfDay: 'Afternoon',
              attribute: HabitAttribute.creativity,
            ),
            BlueprintHabit(
              title: 'Studio Reset',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.focus,
            ),
          ],
          createdAt: DateTime.now(),
          category: 'Creativity',
          difficulty: BlueprintDifficulty.beginner,
          isCreatorBlueprint: true,
          specialityTags: const ['Creative', 'Studio', 'Constraints'],
        ),
        Blueprint(
          id: 'cb_julian_calm',
          creatorUserId: 'creator_julian_cross',
          creatorName: 'Julian Cross',
          creatorArchetype: 'Stoic',
          title: 'Stoic Anchor Day',
          description:
              'Three drop-in habits to build a calmer baseline: a short '
              'morning reflection, a midday control check, and a brief '
              'evening review. Works alongside any workload.',
          habits: const [
            BlueprintHabit(
              title: 'Morning Reflection',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.spirit,
            ),
            BlueprintHabit(
              title: 'Midday Control Check',
              timeOfDay: 'Afternoon',
              attribute: HabitAttribute.focus,
            ),
            BlueprintHabit(
              title: 'Evening Review',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.spirit,
            ),
          ],
          createdAt: DateTime.now(),
          category: 'Mindfulness',
          difficulty: BlueprintDifficulty.beginner,
          isCreatorBlueprint: true,
          specialityTags: const ['Mindfulness', 'Journaling', 'Equanimity'],
        ),
        Blueprint(
          id: 'cb_naia_devotion',
          creatorUserId: 'creator_naia_singh',
          creatorName: 'Naia Singh',
          creatorArchetype: 'Zealot',
          title: 'Devoted Day',
          description:
              'A sacred-ritual stack for practitioners who want their '
              'beliefs to show up in their calendar. Combines prayer, '
              'mission-aligned work, and a daily act of service.',
          habits: const [
            BlueprintHabit(
              title: 'Sacred Morning Ritual',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.spirit,
            ),
            BlueprintHabit(
              title: 'Mission-Aligned Work Block',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.focus,
            ),
            BlueprintHabit(
              title: 'Act of Service',
              timeOfDay: 'Afternoon',
              attribute: HabitAttribute.spirit,
            ),
          ],
          createdAt: DateTime.now(),
          category: 'Faith',
          difficulty: BlueprintDifficulty.intermediate,
          isCreatorBlueprint: true,
          specialityTags: const ['Devotion', 'Discipline', 'Service'],
        ),
        Blueprint(
          id: 'cb_elias_studio',
          creatorUserId: 'creator_elias_vance',
          creatorName: 'Elias Vance',
          creatorArchetype: 'Creator',
          title: 'Daily Sketch Studio',
          description:
              'For people who insist they "aren\'t creative." Twenty minutes '
              'of sketching, one photo, one written reflection. '
              'Compounds into a real art practice in 30 days.',
          habits: const [
            BlueprintHabit(
              title: '20 Min Sketch',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.creativity,
            ),
            BlueprintHabit(
              title: 'Visual Journal Capture',
              timeOfDay: 'Afternoon',
              attribute: HabitAttribute.creativity,
            ),
            BlueprintHabit(
              title: 'Written Reflection',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.intellect,
            ),
          ],
          createdAt: DateTime.now(),
          category: 'Creativity',
          difficulty: BlueprintDifficulty.beginner,
          isCreatorBlueprint: true,
          specialityTags: const ['Sketching', 'Visual', 'Practice'],
        ),
      ];

      final batch = _firestore.batch();
      for (final bp in seedData) {
        final docRef = _firestore.collection('blueprints').doc(bp.id);
        batch.set(docRef, bp.toMap());
      }
      await batch.commit();

      // Bump each creator's blueprintCount so the leaderboard strip
      // reflects the freshly-seeded blueprints. A second batch is used
      // because the first was already committed.
      final countBatch = _firestore.batch();
      for (final bp in seedData) {
        final creatorRef = _firestore
            .collection('creator_profiles')
            .doc(bp.creatorUserId);
        countBatch.set(creatorRef, {
          'userId': bp.creatorUserId,
          'blueprintCount': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }
      await countBatch.commit();

      AppLogger.i(
        'BlueprintRepository: seeded ${seedData.length} creator blueprints.',
      );
    } catch (e, st) {
      AppLogger.e(
        'BlueprintRepository: seeding creator blueprints failed',
        e,
        st,
      );
    }
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
