import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/core/utils/app_logger.dart';

class BlueprintRepository {
  final FirebaseFirestore _firestore;

  BlueprintRepository(this._firestore);

  Stream<List<CreatorBlueprint>> getBlueprints() {
    return _firestore
        .collection('creator_blueprints')
        .orderBy('adoptionCount', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CreatorBlueprint.fromMap(d.data()))
            .toList());
  }

  Future<void> adoptBlueprint(String blueprintId) async {
    final docRef = _firestore.collection('creator_blueprints').doc(blueprintId);
    await docRef.update({
      'adoptionCount': FieldValue.increment(1),
    });
  }

  Future<void> seedBlueprintsIfEmpty() async {
    try {
      final now = DateTime.now();
      final blueprints = [
        CreatorBlueprint(
          id: 'blueprint_atomic_habits',
          creatorUserId: 'system',
          creatorName: 'James Clear',
          creatorArchetype: 'Scholar',
          blueprintName: 'The Atomic Habits Starter Kit',
          description: 'Build the systems that fuel creative output and make good habits inevitable.',
          habitTitles: ['Habit Stacking', 'Environment Design', '2-Minute Rule'],
          adoptionCount: 0,
          category: 'Productivity',
          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD_357wWxUMnRri8nImd1s-eIliBpp3eF_CaZECldc5HtSN5UM48aZ2YkyT6TW65D-c82YI066ifv7q9xHkZXLj4kImgFqZ1FtG3sLiJSLzYZsJ_-HouaUF5sqwuyYaC91L4LCd5wAu0N5zN9cXK55ra_l4jARjWNVwzljZ260VNZc9nxLDyfu2y5-w3nmVEDQpjkWjRMZKkC2TIcrtndLsYH2yu7J6107haz1nZTdZhuC6xvepDx5YaVzvg5d7AYIojci-TJqup-M',
          createdAt: now,
        ),
        CreatorBlueprint(
          id: 'blueprint_optimal_morning',
          creatorUserId: 'system',
          creatorName: 'Dr. Andrew Huberman',
          creatorArchetype: 'Athlete',
          blueprintName: 'The Optimal Morning Routine',
          description: 'Leverage neuroscience to maximize your focus and energy every single day.',
          habitTitles: ['Morning Sunlight', 'Cold Exposure', 'Delay Caffeine'],
          adoptionCount: 0,
          category: 'Morning',
          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAfCNp1icRBAU8hg03pn5bQWXoBFEuaIz-ZFfUPXOh56xerlnlYitA0if4Yc5mPo2938KAYn8mxC25rkiXWhXcYFz9SfaZXyRbkgQzUjyo5Lbu0wgeu2-f88hbgcI2LmQwu7y8HtduqEUdr1X4wZjJLQ4nTwXeshkcfus-M2KwANVbUrrVVdmH0O96ujwECYbjBx9-QgoR4v3d59g8vui_2fJyHpXZs4iPsgZaO0Ql6gjPS-wyfvwQ_v_T_7Cmulv-_P9IlhJ9Tqp4',
          createdAt: now,
          isPremium: true,
        ),
        CreatorBlueprint(
          id: 'blueprint_100m_productivity',
          creatorUserId: 'system',
          creatorName: 'Alex Hormozi',
          creatorArchetype: 'Creator',
          blueprintName: '\$100M Offer Productivity Stack',
          description: 'The daily non-negotiables required to build a high-leverage business.',
          habitTitles: ['Revenue-Generating Activity', 'Lead Generation', 'Daily Reflection'],
          adoptionCount: 0,
          category: 'Business',
          imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCpEenasQ2PiqC-P3Gs1VE6p_G5LmQroYE6D9kN-T-Qylz96aFWrFzZ_bIZ2PrFy13J56PkwnkoSo8oz8eS_NVcesKqRSKMCFnLK1kgxSCaKfW3-25G5nbgYlXTeDDsHNhDsZ18pyYAwsk1r4K_BKKy_CO3fOseW0zgKn5XsawJlgcahei0SNdIAVYW8jLmmPZGLQpXP1whzb-H_a3hr31ax_rDUa5S6R3VNTzwHCqCDtFrJ0wtCyUxZPMA3UUxTbkvE8E8NpsnoQo',
          createdAt: now,
          isPremium: true,
        ),
        CreatorBlueprint(
          id: 'bp_psych_1',
          creatorUserId: 'system',
          creatorName: 'Behavioral Scientist',
          creatorArchetype: 'Scholar',
          blueprintName: 'The Behavior Design',
          description: 'Apply the B=MAT model to decode your habits. Optimize your triggers and ability to make desired behaviors inevitable.',
          habitTitles: ['Trigger Mapping', 'Friction Reduction', 'Small Success Celebration', 'Zeigarnik Task Start'],
          adoptionCount: 0,
          category: 'Psychology',
          imageUrl: 'https://images.unsplash.com/photo-1452802447250-470a88ac82bc?w=400',
          createdAt: now,
        ),
        CreatorBlueprint(
          id: 'bp_proc_1',
          creatorUserId: 'system',
          creatorName: 'Resistance Breaker',
          creatorArchetype: 'Stoic',
          blueprintName: 'Anti-Procrastination Loop',
          description: 'Shatter procrastination loops using the 5-Minute Rule and emotional labeling.',
          habitTitles: ['5-Minute Task Start', 'Emotional Labeling', 'Launch Countdown', 'Focus Burst'],
          adoptionCount: 0,
          category: 'Mindset',
          imageUrl: 'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?w=400',
          createdAt: now,
        ),
      ];

      final batch = _firestore.batch();
      for (final bp in blueprints) {
        final docRef = _firestore.collection('creator_blueprints').doc(bp.id);
        batch.set(docRef, bp.toMap(), SetOptions(merge: true));
      }
      await batch.commit();
      AppLogger.i('BlueprintRepository: Seeding/Sync complete.');
    } catch (e) {
      AppLogger.e('BlueprintRepository: Failed to seed blueprints', e);
    }
  }
}

final blueprintRepositoryProvider = Provider<BlueprintRepository>((ref) {
  return BlueprintRepository(FirebaseFirestore.instance);
});
