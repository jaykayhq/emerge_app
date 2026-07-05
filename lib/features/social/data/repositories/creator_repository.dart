// lib/features/social/data/repositories/creator_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';

final creatorRepositoryProvider = Provider<CreatorRepository>((ref) {
  return CreatorRepository();
});

class CreatorRepository {
  final FirebaseFirestore _firestore;

  CreatorRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<CreatorProfile?> getCreatorProfile(String userId) async {
    final doc = await _firestore
        .collection('creator_profiles')
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return CreatorProfile.fromMap({...data, 'userId': doc.id});
  }

  Stream<CreatorProfile?> watchCreatorProfile(String userId) {
    return _firestore
        .collection('creator_profiles')
        .doc(userId)
        .snapshots()
        .map(
          (doc) => doc.exists
              ? CreatorProfile.fromMap({...doc.data()!, 'userId': doc.id})
              : null,
        );
  }

  /// Streams verified creator profiles, ordered by [blueprintCount] desc,
  /// limited to [limit] entries. Used by the lobby's creator strip and the
  /// browse-all-creators screen.
  Stream<List<CreatorProfile>> watchVerifiedCreators({int limit = 12}) {
    return _firestore
        .collection('creator_profiles')
        .where('isVerifiedCreator', isEqualTo: true)
        .orderBy('blueprintCount', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map(
                    (d) => CreatorProfile.fromMap({
                      ...d.data(),
                      'userId': d.id,
                    }),
                  )
                  .toList(),
        );
  }

  Future<void> updateCreatorProfile(CreatorProfile profile) async {
    await _firestore
        .collection('creator_profiles')
        .doc(profile.userId)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  /// Seeds the `creator_profiles` collection with 6 verified creators
  /// if it is currently empty. Each creator maps to a stable userId so
  /// [seedCreatorBlueprintsIfEmpty] can reference them.
  Future<void> seedCreatorsIfEmpty() async {
    try {
      final existing = await _firestore
          .collection('creator_profiles')
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        AppLogger.i('CreatorRepository: creators already seeded.');
        return;
      }

      final List<Map<String, dynamic>> seedData = [
        {
          'userId': 'creator_aria_chen',
          'displayName': 'Aria Chen',
          'bio':
              'Scholar by trade and lifelong learner by choice. Aria has spent '
              'the last decade mapping the intersection of deep work and '
              'daily ritual, and now she shares the protocols that kept her '
              'sane through three graduate programs.',
          'avatarUrl': null,
          'heroImageUrl': null,
          'specialityTags': ['Deep Work', 'Reading', 'Note Systems'],
          'isVerifiedCreator': true,
          'archetype': UserArchetype.scholar.name,
        },
        {
          'userId': 'creator_marcus_okafor',
          'displayName': 'Marcus Okafor',
          'bio':
              'Marcus trains professional athletes and weekend warriors with '
              'the same playbook: short, repeatable blocks that respect your '
              'nervous system. His protocols come from a decade of coaching '
              'and a stubborn refusal to skip warm-ups.',
          'avatarUrl': null,
          'heroImageUrl': null,
          'specialityTags': ['Strength', 'Mobility', 'Recovery'],
          'isVerifiedCreator': true,
          'archetype': UserArchetype.athlete.name,
        },
        {
          'userId': 'creator_sora_tanaka',
          'displayName': 'Sora Tanaka',
          'bio':
              'Sora is a designer-turned-author who rebuilt her creative '
              'practice from scratch after burning out. She now teaches the '
              'micro-rituals and constraints that keep her studio output '
              'consistent without surrendering the joy of making.',
          'avatarUrl': null,
          'heroImageUrl': null,
          'specialityTags': ['Creative', 'Studio', 'Constraints'],
          'isVerifiedCreator': true,
          'archetype': UserArchetype.creator.name,
        },
        {
          'userId': 'creator_julian_cross',
          'displayName': 'Julian Cross',
          'bio':
              'Julian teaches modern Stoic practice to founders and parents. '
              'His work blends Marcus Aurelius journaling with the realities '
              'of crowded inboxes, and he ships a short weekly reflection '
              'prompt to anyone who asks.',
          'avatarUrl': null,
          'heroImageUrl': null,
          'specialityTags': ['Mindfulness', 'Journaling', 'Equanimity'],
          'isVerifiedCreator': true,
          'archetype': UserArchetype.stoic.name,
        },
        {
          'userId': 'creator_naia_singh',
          'displayName': 'Naia Singh',
          'bio':
              'Naia blends devotional practice with high-output work. She '
              'writes about sacred routine, fasting blocks, and the kind of '
              'fierce consistency that turns belief into embodied habit.',
          'avatarUrl': null,
          'heroImageUrl': null,
          'specialityTags': ['Devotion', 'Discipline', 'Service'],
          'isVerifiedCreator': true,
          'archetype': UserArchetype.zealot.name,
        },
        {
          'userId': 'creator_elias_vance',
          'displayName': 'Elias Vance',
          'bio':
              'Elias is a working illustrator who believes daily sketching '
              'is the gateway drug to a real art practice. His blueprints are '
              'short, opinionated, and built for people who think they "are '
              'not creative."',
          'avatarUrl': null,
          'heroImageUrl': null,
          'specialityTags': ['Sketching', 'Visual', 'Practice'],
          'isVerifiedCreator': true,
          'archetype': UserArchetype.creator.name,
        },
      ];

      final batch = _firestore.batch();
      for (final data in seedData) {
        final id = data['userId'] as String;
        final creator = CreatorProfile(
          userId: id,
          displayName: data['displayName'] as String?,
          bio: data['bio'] as String,
          avatarUrl: data['avatarUrl'] as String?,
          heroImageUrl: data['heroImageUrl'] as String?,
          specialityTags: List<String>.from(data['specialityTags'] as List),
          isVerifiedCreator: data['isVerifiedCreator'] as bool,
          blueprintCount: 0,
        );
        final docRef = _firestore.collection('creator_profiles').doc(id);
        batch.set(docRef, creator.toMap());
      }
      await batch.commit();
      AppLogger.i(
        'CreatorRepository: seeded ${seedData.length} verified creators.',
      );
    } catch (e, st) {
      AppLogger.e('CreatorRepository: seeding creators failed', e, st);
    }
  }
}
