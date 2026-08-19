import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One seeded habit spec: title, time-of-day slot, attribute, optional
/// 'HH:mm' default clock time, and optional timer duration (0 = no timer).
typedef _SeedHabit = ({
  String title,
  String timeOfDay,
  HabitAttribute attribute,
  String? defaultTime,
  int timerDurationMinutes,
});

class BlueprintRepository {
  final FirebaseFirestore _firestore;

  BlueprintRepository(this._firestore);

  Stream<List<Blueprint>> getBlueprints({String? category}) {
    Query<Map<String, dynamic>> query = _firestore.collection('blueprints');

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map(
      (snap) => snap.docs
          .map((d) {
            try {
              return Blueprint.fromMap(d.id, d.data());
            } catch (e) {
              // One malformed doc must not kill the whole blueprints stream —
              // skip it so the rest of the catalog still renders.
              AppLogger.e(
                'BlueprintRepository: skipping malformed blueprint doc ${d.id}',
                e,
              );
              return null;
            }
          })
          .whereType<Blueprint>()
          .toList(),
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

  /// Sets the cover artwork URL on a creator-owned blueprint. The rules
  /// whitelist `imageUrl` for verified-creator updates of their own docs, so
  /// a targeted update passes without touching the rest of the doc.
  Future<void> updateBlueprintImage(
    String blueprintId,
    String imageUrl,
  ) async {
    await _firestore
        .collection('blueprints')
        .doc(blueprintId)
        .update({'imageUrl': imageUrl});
  }

  /// Renames the denormalized `creatorName` on every blueprint the given
  /// creator owns. Blueprint cards render `creatorName` directly, so a rename
  /// must reach every published stack — otherwise the old name lingers until
  /// the doc is next edited. Scoped by `creatorUserId` equality so system
  /// seeds and other creators' docs are never touched.
  Future<void> updateCreatorNameOnBlueprints(
    String creatorUserId,
    String creatorName,
  ) async {
    final snap = await _firestore
        .collection('blueprints')
        .where('creatorUserId', isEqualTo: creatorUserId)
        .get();
    if (snap.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'creatorName': creatorName});
    }
    await batch.commit();
  }

  Future<String> createBlueprint(Blueprint blueprint) async {
    try {
      final collectionRef = _firestore.collection('blueprints');
      final docRef = blueprint.id.isNotEmpty
          ? collectionRef.doc(blueprint.id)
          : collectionRef.doc();

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
  static const int _seedVersion = 6;

  Future<void> seedBlueprintsIfEmpty() async {
    try {
      // Skip only when the sentinel doc exists AND already carries v4
      // artwork, the v5 habit slot metadata (timeOfDay), and the v6
      // recommended durations. Older docs must be backfilled so every
      // install renders blueprint habits with their time-of-day and
      // recommended duration.
      final v6Check = await _firestore
          .collection('blueprints')
          .doc('morning_1')
          .get();
      final hasArtwork =
          v6Check.exists &&
          (v6Check.data()?['imageUrl'] as String? ?? '').startsWith(
            'assets/images/blueprints/',
          );
      final habitMaps = hasArtwork
          ? (v6Check.data()?['habits'] as List<dynamic>? ?? const [])
                .whereType<Map>()
                .toList()
          : <Map>[];
      final hasSlotMetadata =
          hasArtwork && habitMaps.any((h) => h['timeOfDay'] != null);
      final hasDurationMetadata =
          hasArtwork &&
          habitMaps.isNotEmpty &&
          habitMaps.every(
            (h) => ((h['timerDurationMinutes'] as num?)?.toInt() ?? 0) > 0,
          );

      if (hasArtwork && hasSlotMetadata && hasDurationMetadata) {
        AppLogger.i(
          'BlueprintRepository: Blueprints already seeded (v$_seedVersion).',
        );
        return;
      }

      // Backfilling existing docs: merge must not clobber live-doc adoption
      // counts or creation timestamps, so increment(0) is a no-op for
      // counters and createdAt is left untouched on existing docs.
      final backfilling = v6Check.exists;

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
          image: 'assets/images/blueprints/morning_1.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: [
            (
              title: 'Wake Up at 6 AM',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.vitality,
              defaultTime: '06:00',
              timerDurationMinutes: 1,
            ),
            (
              title: 'Drink 500ml Water',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.vitality,
              defaultTime: null,
              timerDurationMinutes: 2,
            ),
            (
              title: '10 Min Sunlight Exposure',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.vitality,
              defaultTime: null,
              timerDurationMinutes: 10,
            ),
          ],
          recommendedArchetypes: const ['athlete', 'stoic'],
        ),
        _createSeed(
          id: 'morning_2',
          category: 'Morning',
          title: 'Power Morning',
          description: 'An energizing morning routine to dominate your day.',
          image: 'assets/images/blueprints/morning_2.webp',
          difficulty: BlueprintDifficulty.intermediate,
          habits: [
            (
              title: 'Cold Shower',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.strength,
              defaultTime: null,
              timerDurationMinutes: 5,
            ),
            (
              title: 'Stretch Routine',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.vitality,
              defaultTime: null,
              timerDurationMinutes: 10,
            ),
            (
              title: 'High-Protein Breakfast',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.strength,
              defaultTime: null,
              timerDurationMinutes: 15,
            ),
          ],
          recommendedArchetypes: const ['athlete'],
        ),
        _createSeed(
          id: 'morning_3',
          category: 'Morning',
          title: 'Mindful Awakening',
          description: 'Ease into the day with calm and clarity.',
          image: 'assets/images/blueprints/morning_3.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: [
            (
              title: '5 Min Meditation',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.focus,
              defaultTime: null,
              timerDurationMinutes: 5,
            ),
            (
              title: 'Gratitude Journal',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.spirit,
              defaultTime: null,
              timerDurationMinutes: 5,
            ),
            (
              title: 'Herbal Tea',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.spirit,
              defaultTime: null,
              timerDurationMinutes: 5,
            ),
          ],
          recommendedArchetypes: const ['stoic'],
        ),
        _createSeed(
          id: 'morning_4',
          category: 'Morning',
          title: 'Early Bird Stack',
          description: 'Rise before the world and claim your quiet hours.',
          image: 'assets/images/blueprints/morning_4.webp',
          difficulty: BlueprintDifficulty.advanced,
          habits: [
            (
              title: 'Wake at 5 AM',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.vitality,
              defaultTime: '05:00',
              timerDurationMinutes: 1,
            ),
            (
              title: 'Deep Work Block',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.focus,
              defaultTime: '05:30',
              timerDurationMinutes: 90,
            ),
            (
              title: 'No Phone for 1 Hour',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.focus,
              defaultTime: null,
              timerDurationMinutes: 60,
            ),
          ],
          recommendedArchetypes: const ['scholar', 'zealot'],
        ),
        _createSeed(
          id: 'morning_5',
          category: 'Morning',
          title: 'Morning Mobility',
          description: 'Loosen up and prepare your body for the day ahead.',
          image: 'assets/images/blueprints/morning_5.webp',
          difficulty: BlueprintDifficulty.intermediate,
          habits: [
            (
              title: 'Dynamic Stretching',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.vitality,
              defaultTime: null,
              timerDurationMinutes: 10,
            ),
            (
              title: 'Foam Rolling',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.vitality,
              defaultTime: null,
              timerDurationMinutes: 10,
            ),
            (
              title: 'Posture Check',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.vitality,
              defaultTime: null,
              timerDurationMinutes: 2,
            ),
          ],
          recommendedArchetypes: const ['athlete'],
        ),

        // PRODUCTIVITY
        _createSeed(
          id: 'productivity_1',
          category: 'Productivity',
          title: 'Deep Work Protocol',
          description: 'Train your focus for uninterrupted deep work sessions.',
          image: 'assets/images/blueprints/productivity_1.webp',
          difficulty: BlueprintDifficulty.advanced,
          habits: [
            (
              title: '90 Min Deep Work',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.focus,
              defaultTime: '09:00',
              timerDurationMinutes: 90,
            ),
            (
              title: 'Phone on DND',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.focus,
              defaultTime: null,
              timerDurationMinutes: 2,
            ),
            (
              title: 'Task Batching',
              timeOfDay: 'Afternoon',
              attribute: HabitAttribute.focus,
              defaultTime: null,
              timerDurationMinutes: 10,
            ),
          ],
          recommendedArchetypes: const ['scholar', 'zealot'],
        ),
        _createSeed(
          id: 'productivity_2',
          category: 'Productivity',
          title: 'The Ivy Lee Method',
          description:
              'A century-old productivity system for daily prioritization.',
          image: 'assets/images/blueprints/productivity_2.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: [
            (
              title: 'Write Top 6 Tasks',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.focus,
              defaultTime: '21:00',
              timerDurationMinutes: 5,
            ),
            (
              title: 'Prioritize by Importance',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.intellect,
              defaultTime: null,
              timerDurationMinutes: 5,
            ),
            (
              title: 'Complete One at a Time',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.focus,
              defaultTime: null,
              timerDurationMinutes: 25,
            ),
          ],
          recommendedArchetypes: const ['scholar', 'zealot'],
        ),
        _createSeed(
          id: 'productivity_3',
          category: 'Productivity',
          title: 'Time Block Master',
          description: 'Schedule every hour of your day with purpose.',
          image: 'assets/images/blueprints/productivity_3.webp',
          difficulty: BlueprintDifficulty.intermediate,
          habits: [
            (
              title: 'Plan Tomorrow Tonight',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.intellect,
              defaultTime: '21:30',
              timerDurationMinutes: 10,
            ),
            (
              title: 'Time Block Calendar',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.intellect,
              defaultTime: '08:00',
              timerDurationMinutes: 10,
            ),
            (
              title: 'Review & Reflect',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.focus,
              defaultTime: null,
              timerDurationMinutes: 10,
            ),
          ],
          recommendedArchetypes: const ['scholar', 'zealot'],
        ),
        _createSeed(
          id: 'productivity_4',
          category: 'Productivity',
          title: 'Digital Declutter',
          description: 'Clear digital noise and reclaim your attention.',
          image: 'assets/images/blueprints/productivity_4.webp',
          difficulty: BlueprintDifficulty.intermediate,
          habits: [
            (
              title: 'Unsubscribe from Junk',
              timeOfDay: 'Afternoon',
              attribute: HabitAttribute.focus,
              defaultTime: null,
              timerDurationMinutes: 10,
            ),
            (
              title: 'Organize Files',
              timeOfDay: 'Afternoon',
              attribute: HabitAttribute.intellect,
              defaultTime: null,
              timerDurationMinutes: 30,
            ),
            (
              title: 'App Purge',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.focus,
              defaultTime: null,
              timerDurationMinutes: 15,
            ),
          ],
          recommendedArchetypes: const ['stoic', 'scholar'],
        ),
        _createSeed(
          id: 'productivity_5',
          category: 'Productivity',
          title: 'Pomodoro Flow',
          description: 'Harness the Pomodoro technique for sustained output.',
          image: 'assets/images/blueprints/productivity_5.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: [
            (
              title: '25 Min Focus Sprint',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.focus,
              defaultTime: null,
              timerDurationMinutes: 25,
            ),
            (
              title: '5 Min Break',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.vitality,
              defaultTime: null,
              timerDurationMinutes: 5,
            ),
            (
              title: 'Track Pomodoros',
              timeOfDay: 'Afternoon',
              attribute: HabitAttribute.focus,
              defaultTime: null,
              timerDurationMinutes: 2,
            ),
          ],
          recommendedArchetypes: const ['scholar', 'athlete'],
        ),

        // FITNESS
        _createSeed(
          id: 'fitness_1',
          category: 'Fitness',
          title: 'Bodyweight Foundation',
          description: 'Build strength with just your body weight.',
          image: 'assets/images/blueprints/fitness_1.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: [
            (
              title: 'Push-Ups',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.strength,
              defaultTime: null,
              timerDurationMinutes: 5,
            ),
            (
              title: 'Bodyweight Squats',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.strength,
              defaultTime: null,
              timerDurationMinutes: 5,
            ),
            (
              title: 'Plank Hold',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.strength,
              defaultTime: null,
              timerDurationMinutes: 1,
            ),
          ],
          recommendedArchetypes: const ['athlete'],
        ),
        _createSeed(
          id: 'fitness_2',
          category: 'Fitness',
          title: 'Cardio Builder',
          description: 'Improve cardiovascular endurance step by step.',
          image: 'assets/images/blueprints/fitness_2.webp',
          difficulty: BlueprintDifficulty.intermediate,
          habits: [
            (
              title: '20 Min Run',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.vitality,
              defaultTime: null,
              timerDurationMinutes: 20,
            ),
            (
              title: 'Jump Rope',
              timeOfDay: 'Afternoon',
              attribute: HabitAttribute.vitality,
              defaultTime: null,
              timerDurationMinutes: 10,
            ),
            (
              title: 'Cool Down Stretch',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.vitality,
              defaultTime: null,
              timerDurationMinutes: 5,
            ),
          ],
          recommendedArchetypes: const ['athlete'],
        ),
        _createSeed(
          id: 'fitness_3',
          category: 'Fitness',
          title: 'Flexibility & Mobility',
          description: 'Increase range of motion and prevent injury.',
          image: 'assets/images/blueprints/fitness_3.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: [
            (
              title: 'Hamstring Stretch',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.vitality,
              defaultTime: null,
              timerDurationMinutes: 5,
            ),
            (
              title: 'Hip Openers',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.vitality,
              defaultTime: null,
              timerDurationMinutes: 5,
            ),
            (
              title: 'Spine Twists',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.vitality,
              defaultTime: null,
              timerDurationMinutes: 5,
            ),
          ],
          recommendedArchetypes: const ['athlete', 'stoic'],
        ),
        _createSeed(
          id: 'fitness_4',
          category: 'Fitness',
          title: 'Iron Will',
          description: 'A progressive strength training blueprint.',
          image: 'assets/images/blueprints/fitness_4.webp',
          difficulty: BlueprintDifficulty.advanced,
          habits: [
            (
              title: 'Deadlifts',
              timeOfDay: 'Afternoon',
              attribute: HabitAttribute.strength,
              defaultTime: null,
              timerDurationMinutes: 30,
            ),
            (
              title: 'Overhead Press',
              timeOfDay: 'Afternoon',
              attribute: HabitAttribute.strength,
              defaultTime: null,
              timerDurationMinutes: 20,
            ),
            (
              title: 'Pull-Ups',
              timeOfDay: 'Afternoon',
              attribute: HabitAttribute.strength,
              defaultTime: null,
              timerDurationMinutes: 15,
            ),
          ],
          recommendedArchetypes: const ['athlete', 'zealot'],
        ),
        _createSeed(
          id: 'fitness_5',
          category: 'Fitness',
          title: 'Active Recovery',
          description: 'Rest days that keep you moving and healing.',
          image: 'assets/images/blueprints/fitness_5.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: [
            (
              title: 'Brisk Walk',
              timeOfDay: 'Afternoon',
              attribute: HabitAttribute.vitality,
              defaultTime: null,
              timerDurationMinutes: 20,
            ),
            (
              title: 'Light Yoga',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.spirit,
              defaultTime: null,
              timerDurationMinutes: 20,
            ),
            (
              title: 'Hydration Focus',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.vitality,
              defaultTime: null,
              timerDurationMinutes: 2,
            ),
          ],
          recommendedArchetypes: const ['athlete', 'stoic'],
        ),

        // MINDFULNESS
        _createSeed(
          id: 'mindfulness_1',
          category: 'Mindfulness',
          title: 'Daily Meditation',
          description: 'Build a consistent meditation practice from scratch.',
          image: 'assets/images/blueprints/mindfulness_1.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: [
            (
              title: '5 Min Breath Focus',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.focus,
              defaultTime: null,
              timerDurationMinutes: 5,
            ),
            (
              title: 'Body Scan',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.spirit,
              defaultTime: null,
              timerDurationMinutes: 10,
            ),
            (
              title: 'Loving Kindness',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.spirit,
              defaultTime: null,
              timerDurationMinutes: 5,
            ),
          ],
          recommendedArchetypes: const ['stoic'],
        ),
        _createSeed(
          id: 'mindfulness_2',
          category: 'Mindfulness',
          title: 'Digital Sabbath',
          description: 'Weekly disconnection to recharge your mind.',
          image: 'assets/images/blueprints/mindfulness_2.webp',
          difficulty: BlueprintDifficulty.advanced,
          habits: [
            (
              title: 'No Screens for 4 Hours',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.focus,
              defaultTime: null,
              timerDurationMinutes: 240,
            ),
            (
              title: 'Nature Walk',
              timeOfDay: 'Afternoon',
              attribute: HabitAttribute.spirit,
              defaultTime: null,
              timerDurationMinutes: 30,
            ),
            (
              title: 'Analog Activity',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.creativity,
              defaultTime: null,
              timerDurationMinutes: 30,
            ),
          ],
          recommendedArchetypes: const ['stoic', 'scholar'],
        ),
        _createSeed(
          id: 'mindfulness_3',
          category: 'Mindfulness',
          title: 'Gratitude Practice',
          description: 'Rewire your brain for appreciation and abundance.',
          image: 'assets/images/blueprints/mindfulness_3.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: [
            (
              title: 'Write 3 Gratitudes',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.spirit,
              defaultTime: null,
              timerDurationMinutes: 5,
            ),
            (
              title: 'Thank Someone',
              timeOfDay: 'Afternoon',
              attribute: HabitAttribute.spirit,
              defaultTime: null,
              timerDurationMinutes: 5,
            ),
            (
              title: 'Savor a Moment',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.spirit,
              defaultTime: null,
              timerDurationMinutes: 3,
            ),
          ],
          recommendedArchetypes: const ['stoic', 'zealot'],
        ),
        _createSeed(
          id: 'mindfulness_4',
          category: 'Mindfulness',
          title: 'Stress Shield',
          description: 'Daily practices to build resilience against stress.',
          image: 'assets/images/blueprints/mindfulness_4.webp',
          difficulty: BlueprintDifficulty.intermediate,
          habits: [
            (
              title: 'Box Breathing',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.focus,
              defaultTime: null,
              timerDurationMinutes: 5,
            ),
            (
              title: 'Progressive Relaxation',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.spirit,
              defaultTime: null,
              timerDurationMinutes: 10,
            ),
            (
              title: 'Journaling',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.intellect,
              defaultTime: null,
              timerDurationMinutes: 15,
            ),
          ],
          recommendedArchetypes: const ['stoic'],
        ),
        _createSeed(
          id: 'mindfulness_5',
          category: 'Mindfulness',
          title: 'Evening Wind Down',
          description:
              'A calming ritual to signal your body it is time to rest.',
          image: 'assets/images/blueprints/mindfulness_5.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: [
            (
              title: 'No Screens 30 Min Before Bed',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.focus,
              defaultTime: null,
              timerDurationMinutes: 30,
            ),
            (
              title: 'Tidy Your Space',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.focus,
              defaultTime: null,
              timerDurationMinutes: 10,
            ),
            (
              title: 'Read Fiction',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.intellect,
              defaultTime: null,
              timerDurationMinutes: 20,
            ),
          ],
          recommendedArchetypes: const ['stoic', 'scholar'],
        ),

        // LEARNING
        _createSeed(
          id: 'learning_1',
          category: 'Learning',
          title: 'Daily Reader',
          description: 'Read consistently and compound knowledge.',
          image: 'assets/images/blueprints/learning_1.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: [
            (
              title: 'Read 20 Pages',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.intellect,
              defaultTime: null,
              timerDurationMinutes: 30,
            ),
            (
              title: 'Take Notes',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.intellect,
              defaultTime: null,
              timerDurationMinutes: 10,
            ),
            (
              title: 'Summarize Key Idea',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.intellect,
              defaultTime: null,
              timerDurationMinutes: 10,
            ),
          ],
          recommendedArchetypes: const ['scholar'],
        ),
        _createSeed(
          id: 'learning_2',
          category: 'Learning',
          title: 'Skill Sprint',
          description: 'Learn a new skill with focused daily practice.',
          image: 'assets/images/blueprints/learning_2.webp',
          difficulty: BlueprintDifficulty.intermediate,
          habits: [
            (
              title: '30 Min Deliberate Practice',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.focus,
              defaultTime: null,
              timerDurationMinutes: 30,
            ),
            (
              title: 'Track Progress',
              timeOfDay: 'Afternoon',
              attribute: HabitAttribute.focus,
              defaultTime: null,
              timerDurationMinutes: 5,
            ),
            (
              title: 'Review Mistakes',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.intellect,
              defaultTime: null,
              timerDurationMinutes: 10,
            ),
          ],
          recommendedArchetypes: const ['scholar', 'creator'],
        ),
        _createSeed(
          id: 'learning_3',
          category: 'Learning',
          title: 'Curious Mind',
          description: 'Feed your curiosity across diverse topics.',
          image: 'assets/images/blueprints/learning_3.webp',
          difficulty: BlueprintDifficulty.beginner,
          habits: [
            (
              title: 'Watch a Documentary',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.intellect,
              defaultTime: null,
              timerDurationMinutes: 45,
            ),
            (
              title: 'Read One Article',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.intellect,
              defaultTime: null,
              timerDurationMinutes: 15,
            ),
            (
              title: 'Discuss What You Learned',
              timeOfDay: 'Afternoon',
              attribute: HabitAttribute.creativity,
              defaultTime: null,
              timerDurationMinutes: 10,
            ),
          ],
          recommendedArchetypes: const ['scholar', 'creator'],
        ),
        _createSeed(
          id: 'learning_4',
          category: 'Learning',
          title: 'Memory Master',
          description: 'Strengthen recall with spaced repetition.',
          image: 'assets/images/blueprints/learning_4.webp',
          difficulty: BlueprintDifficulty.intermediate,
          habits: [
            (
              title: 'Review Flashcards',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.focus,
              defaultTime: null,
              timerDurationMinutes: 10,
            ),
            (
              title: 'Teach Someone',
              timeOfDay: 'Afternoon',
              attribute: HabitAttribute.intellect,
              defaultTime: null,
              timerDurationMinutes: 15,
            ),
            (
              title: 'Active Recall Session',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.focus,
              defaultTime: null,
              timerDurationMinutes: 20,
            ),
          ],
          recommendedArchetypes: const ['scholar'],
        ),
        _createSeed(
          id: 'learning_5',
          category: 'Learning',
          title: 'Course Completer',
          description:
              'Finish online courses with structure and accountability.',
          image: 'assets/images/blueprints/learning_5.webp',
          difficulty: BlueprintDifficulty.advanced,
          habits: [
            (
              title: 'Watch One Lesson',
              timeOfDay: 'Morning',
              attribute: HabitAttribute.intellect,
              defaultTime: null,
              timerDurationMinutes: 30,
            ),
            (
              title: 'Do the Assignment',
              timeOfDay: 'Afternoon',
              attribute: HabitAttribute.creativity,
              defaultTime: null,
              timerDurationMinutes: 45,
            ),
            (
              title: 'Write Reflection',
              timeOfDay: 'Evening',
              attribute: HabitAttribute.intellect,
              defaultTime: null,
              timerDurationMinutes: 15,
            ),
          ],
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
      AppLogger.i('BlueprintRepository: Seeding complete (v$_seedVersion).');
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
    required List<_SeedHabit> habits,
    required List<String> recommendedArchetypes,
  }) {
    return Blueprint(
      id: id,
      creatorUserId: 'system',
      creatorName: 'Emerge Official',
      creatorArchetype: 'Emerge',
      title: title,
      description: description,
      habits: habits
          .map(
            (h) => BlueprintHabit(
              title: h.title,
              timeOfDay: h.timeOfDay,
              attribute: h.attribute,
              defaultTime: _parseSeedTime(h.defaultTime),
              timerDurationMinutes: h.timerDurationMinutes,
            ),
          )
          .toList(),
      createdAt: DateTime.now(),
      imageUrl: image,
      category: category,
      difficulty: difficulty,
      recommendedArchetypes: recommendedArchetypes,
    );
  }

  static TimeOfDay? _parseSeedTime(String? timeStr) {
    if (timeStr == null) return null;
    final parts = timeStr.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}

final blueprintRepositoryProvider = Provider<BlueprintRepository>((ref) {
  return BlueprintRepository(FirebaseFirestore.instance);
});

final blueprintsStreamProvider = StreamProvider.autoDispose
    .family<List<Blueprint>, String?>((ref, category) {
      final repo = ref.watch(blueprintRepositoryProvider);
      return repo.getBlueprints(category: category);
    });

final allBlueprintsStreamProvider = StreamProvider.autoDispose<List<Blueprint>>(
  (ref) {
    final repo = ref.watch(blueprintRepositoryProvider);
    return repo.getBlueprints();
  },
);

/// Single-doc fetch for deep-link navigation (notifications, shared URLs).
/// Returns null when the doc doesn't exist.
final blueprintByIdProvider = FutureProvider.autoDispose
    .family<Blueprint?, String>((ref, id) {
      final repo = ref.watch(blueprintRepositoryProvider);
      return repo.getBlueprintById(id);
    });
