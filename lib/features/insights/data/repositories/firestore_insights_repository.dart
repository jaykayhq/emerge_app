import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/insights/data/repositories/insights_repository.dart';
import 'package:emerge_app/features/insights/domain/entities/insights_entities.dart';

class FirestoreInsightsRepository implements InsightsRepository {
  final FirebaseFirestore _firestore;

  FirestoreInsightsRepository(this._firestore);

  @override
  Future<Recap> getLatestRecap(String userId) async {
    final snapshot = await _firestore
        .collection('user_stats')
        .doc(userId)
        .collection('recaps')
        .orderBy(
          'dateRange',
          descending: true,
        ) // Assuming dateRange string is sortable or we add a timestamp field
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      // Return a default empty recap or throw exception depending on logic
      // For now, return a placeholder to avoid UI crash if no recap exists
      return const Recap(
        id: 'empty',
        period: 'No Data',
        dateRange: '',
        habitsCompleted: 0,
        perfectDays: 0,
        xpGained: 0,
        focusTime: '0h',
        summary: 'No recap available yet.',
        consistencyChange: 0.0,
      );
    }

    final data = snapshot.docs.first.data();
    return Recap(
      id: snapshot.docs.first.id,
      period: data['period'] as String? ?? 'Weekly',
      dateRange: data['dateRange'] as String? ?? '',
      habitsCompleted: data['habitsCompleted'] as int? ?? 0,
      perfectDays: data['perfectDays'] as int? ?? 0,
      xpGained: data['xpGained'] as int? ?? 0,
      focusTime: data['focusTime'] as String? ?? '0h',
      summary: data['summary'] as String? ?? '',
      consistencyChange: (data['consistencyChange'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  Future<List<Reflection>> getReflections(String userId) async {
    final snapshot = await _firestore
        .collection('user_stats')
        .doc(userId)
        .collection('reflections')
        .orderBy('date', descending: true) // Assuming date is sortable
        .limit(10)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Reflection(
        id: doc.id,
        date: data['date'] as String? ?? '',
        title: data['title'] as String? ?? '',
        content: data['content'] as String? ?? '',
        type: data['type'] as String? ?? 'insight',
      );
    }).toList();
  }
}
