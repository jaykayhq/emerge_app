import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/social/data/repositories/creator_repository.dart';
import 'package:emerge_app/features/social/data/seeds/official_clubs_seed.dart';

/// Retry-safe seeding of official clubs.
Future<void> seedOfficialClubs({FirebaseFirestore? firestore}) async {
  final fs = firestore ?? FirebaseFirestore.instance;
  try {
    final existing = await fs.collection('tribes').limit(1).get();
    if (existing.docs.isNotEmpty) return;
    final clubsMap = OfficialClubsSeed.getOfficialClubsMap();
    final batch = fs.batch();
    for (final entry in clubsMap.entries) {
      final docRef = fs.collection('tribes').doc(entry.key);
      batch.set(docRef, {
        ...entry.value,
        'id': entry.key,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  } catch (e) {
    debugPrint('❌ Error seeding clubs: $e');
  }
}

Future<void> seedChallenges({FirebaseFirestore? firestore}) async {
  final fs = firestore ?? FirebaseFirestore.instance;
  try {
    final existingSnapshot = await fs.collection('challenges').limit(1).get();
    if (existingSnapshot.docs.isNotEmpty) return;
    final challenges = [
      {
        'id': 'challenge_30_day_running',
        'title': '30-Day Running Streak',
        'description': 'Build a consistent running habit.',
        'imageUrl':
            'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800',
        'reward': 'Runner Badge + 750 XP',
        'participants': 0,
        'totalDays': 30,
        'currentDay': 0,
        'status': 'active',
        'xpReward': 750,
        'isFeatured': true,
        'category': 'Fitness',
        'archetypeId': 'athlete',
      },
      {
        'id': 'challenge_21_day_meditation',
        'title': '21-Day Meditation Quest',
        'description': 'Build a meditation practice.',
        'imageUrl':
            'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800',
        'reward': 'Mindful Master Badge + 500 XP',
        'participants': 0,
        'totalDays': 21,
        'currentDay': 0,
        'status': 'active',
        'xpReward': 500,
        'isFeatured': true,
        'category': 'Mindfulness',
        'archetypeId': 'stoic',
      },
      {
        'id': 'challenge_deep_work',
        'title': '14-Day Deep Work Sprint',
        'description': 'Master focused, distraction-free work.',
        'imageUrl':
            'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800',
        'reward': 'Focus Master Badge + 500 XP',
        'participants': 0,
        'totalDays': 14,
        'currentDay': 0,
        'status': 'active',
        'xpReward': 500,
        'isFeatured': true,
        'category': 'Productivity',
        'archetypeId': 'scholar',
      },
      {
        'id': 'challenge_creative_30',
        'title': '30-Day Creative Challenge',
        'description': 'Create something every day.',
        'imageUrl':
            'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=800',
        'reward': 'Creator Badge + 600 XP',
        'participants': 0,
        'totalDays': 30,
        'currentDay': 0,
        'status': 'active',
        'xpReward': 600,
        'isFeatured': true,
        'category': 'Creativity',
        'archetypeId': 'creator',
      },
    ];
    final batch = fs.batch();
    for (final challenge in challenges) {
      final docRef = fs.collection('challenges').doc(challenge['id'] as String);
      batch.set(docRef, {
        ...challenge,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  } catch (e) {
    debugPrint('❌ Error seeding challenges: $e');
  }
}

Future<void> seedBlueprints({FirebaseFirestore? firestore}) async {
  try {
    final repo = BlueprintRepository(firestore ?? FirebaseFirestore.instance);
    await repo.seedBlueprintsIfEmpty();
  } catch (e) {
    debugPrint('❌ Error seeding blueprints: $e');
  }
}

Future<void> seedCreators({FirebaseFirestore? firestore}) async {
  try {
    final repo = CreatorRepository(firestore: firestore);
    await repo.seedCreatorsIfEmpty();
  } catch (e) {
    debugPrint('❌ Error seeding creators: $e');
  }
}

Future<void> seedCreatorBlueprints({FirebaseFirestore? firestore}) async {
  try {
    final repo = BlueprintRepository(firestore ?? FirebaseFirestore.instance);
    await repo.seedCreatorBlueprintsIfEmpty();
  } catch (e) {
    debugPrint('❌ Error seeding creator blueprints: $e');
  }
}
