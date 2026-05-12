// ignore_for_file: avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to reset all tribe stats in Firestore to zero.
/// This clears out the old "placeholder" data.
///
/// Usage:
///   flutter run lib/scripts/reset_tribe_stats.dart
Future<void> main() async {
  print('🚀 Starting tribe stats reset script...');

  final firestore = FirebaseFirestore.instance;
  final tribesSnapshot = await firestore.collection('tribes').get();

  print('🔍 Found ${tribesSnapshot.docs.length} tribes to reset');

  final batch = firestore.batch();
  int count = 0;

  for (final doc in tribesSnapshot.docs) {
    batch.update(doc.reference, {
      'totalXp': 0,
      'memberCount': 0,
      'totalHabitsCompleted': 0,
      'totalChallengesCompleted': 0,
    });
    count++;
  }

  if (count > 0) {
    await batch.commit();
    print('✅ Reset $count tribes to zero stats.');
  } else {
    print('ℹ️ No tribes found to reset.');
  }

  print('');
  print('💡 Stats will now recalculate in real-time as users join/interact.');
}
