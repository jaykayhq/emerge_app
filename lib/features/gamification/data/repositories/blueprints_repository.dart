import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/gamification/domain/models/blueprint.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlueprintsRepository {
  final FirebaseFirestore _firestore;

  BlueprintsRepository(this._firestore);

  final List<Blueprint> _fallbackBlueprints = [
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
          ? ['All', 'Morning', 'Focus', 'Health', 'Fitness', 'Mindset']
          : categories;
    } catch (e) {
      return ['All', 'Morning', 'Focus', 'Health', 'Fitness', 'Mindset'];
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
