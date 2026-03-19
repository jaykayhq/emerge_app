import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:emerge_app/features/social/data/seeds/official_clubs_seed.dart';

/// Run this function once to seed Firestore with official clubs
/// Can be called from a debug screen or initialization
Future<void> seedOfficialClubs({FirebaseFirestore? firestore}) async {
  final fs = firestore ?? FirebaseFirestore.instance;

  try {
    // Get official clubs from seed data
    final clubsMap = OfficialClubsSeed.getOfficialClubsMap();

    // Check if clubs already exist
    final existingSnapshot = await fs
        .collection('tribes')
        .where('type', isEqualTo: 'official')
        .limit(1)
        .get();

    if (existingSnapshot.docs.isNotEmpty) {
      debugPrint('🔄 Official clubs already exist. Skipping seed.');
      return;
    }

    // Seed the clubs
    final batch = fs.batch();
    for (final entry in clubsMap.entries) {
      final docRef = fs.collection('tribes').doc(entry.key);
      batch.set(docRef, entry.value);
    }
    await batch.commit();

    debugPrint('✅ Seeded ${clubsMap.length} official clubs!');
  } catch (e) {
    debugPrint('❌ Error seeding clubs: $e');
    rethrow;
  }
}

/// Also seed challenges if needed
Future<void> seedChallenges({FirebaseFirestore? firestore}) async {
  final fs = firestore ?? FirebaseFirestore.instance;

  try {
    final challenges = [
      {
        'id': 'challenge_30_day_running',
        'title': '30-Day Running Streak',
        'description':
            'Build a consistent running habit. Complete 30 days of running.',
        'imageUrl':
            'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800',
        'reward': 'Runner Badge + 750 XP',
        'participants': 0,
        'totalDays': 30,
        'currentDay': 0,
        'status': 'active',
        'xpReward': 750,
        'isFeatured': true,
        'isTeamChallenge': false,
        'category': 'Fitness',
        'archetypeId': 'athlete',
      },
      {
        'id': 'challenge_21_day_meditation',
        'title': '21-Day Meditation Quest',
        'description':
            'Build a meditation practice. 21 days of daily meditation.',
        'imageUrl':
            'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800',
        'reward': 'Mindful Master Badge + 500 XP',
        'participants': 0,
        'totalDays': 21,
        'currentDay': 0,
        'status': 'active',
        'xpReward': 500,
        'isFeatured': true,
        'isTeamChallenge': false,
        'category': 'Mindfulness',
        'archetypeId': 'stoic',
      },
      {
        'id': 'challenge_deep_work',
        'title': '14-Day Deep Work Sprint',
        'description':
            'Master focused, distraction-free work. 2-hour deep work blocks daily.',
        'imageUrl':
            'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800',
        'reward': 'Focus Master Badge + 500 XP',
        'participants': 0,
        'totalDays': 14,
        'currentDay': 0,
        'status': 'active',
        'xpReward': 500,
        'isFeatured': true,
        'isTeamChallenge': false,
        'category': 'Productivity',
        'archetypeId': 'scholar',
      },
      {
        'id': 'challenge_creative_30',
        'title': '30-Day Creative Challenge',
        'description':
            'Create something every day. Build your creative muscle.',
        'imageUrl':
            'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=800',
        'reward': 'Creator Badge + 600 XP',
        'participants': 0,
        'totalDays': 30,
        'currentDay': 0,
        'status': 'active',
        'xpReward': 600,
        'isFeatured': true,
        'isTeamChallenge': false,
        'category': 'Creativity',
        'archetypeId': 'creator',
      },
    ];

    // Check if challenges already exist
    final existingSnapshot = await fs.collection('challenges').limit(1).get();

    if (existingSnapshot.docs.isNotEmpty) {
      debugPrint('🔄 Challenges already exist. Skipping seed.');
      return;
    }

    final batch = fs.batch();
    for (final challenge in challenges) {
      final docRef = fs.collection('challenges').doc(challenge['id'] as String);
      batch.set(docRef, {
        ...challenge,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    debugPrint('✅ Seeded ${challenges.length} challenges!');
  } catch (e) {
    debugPrint('❌ Error seeding challenges: $e');
  }
}
