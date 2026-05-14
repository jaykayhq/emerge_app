// Firestore Seed Data Script
// Run this script to populate your Firestore with initial data
// You can run this once from a test file or a dedicated initialization screen

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:emerge_app/features/social/data/seeds/official_clubs_seed.dart';

class FirestoreSeedData {
  final FirebaseFirestore _firestore;

  FirestoreSeedData(this._firestore);

  /// Seeds the 'tribes' collection with official archetype clubs
  /// Uses OfficialClubsSeed data which includes proper type and archetypeId fields
  Future<void> seedTribes() async {
    final clubsMap = OfficialClubsSeed.getOfficialClubsMap();

    final batch = _firestore.batch();
    for (final entry in clubsMap.entries) {
      final docRef = _firestore.collection('tribes').doc(entry.key);
      batch.set(docRef, entry.value);
    }
    await batch.commit();
    debugPrint('Seeded ${clubsMap.length} official clubs');
  }

  /// Seeds the 'challenges' collection matching the design mockups
  /// Includes brand-sponsored challenges with real-world rewards
  Future<void> seedChallenges() async {
    final challenges = [
      {
        'id': 'challenge_30_day_running_streak',
        'title': 'The 30-Day Running Streak',
        'description':
            'Build a consistent running habit with 1,500+ adventurers. Complete 30 days of running (verified via GPS/HealthKit) to unlock exclusive Nike rewards.',
        'imageUrl':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDOh_utD3m3xlwj_lio5W-29cxexZgkN2h28IwWvfeMCbW6mFb2mf4R2hxpgLTqZoyjc5GMat3j2885Y_ZNMHxjHP5Hz45ARtDAD14ZRPtB--_peel9PvIq9NIzXOrbCu4gZhcVHfPUY9oWKFi0xMk-yHoab6iZFuFu44jBOcp7V_17aH8Dt4g7ZoqIAk6nMY9ghnlJdUPFrttCNe6ZocpOvxgxtDCXy_6w062COFol-Ehw2GgYkzVp2cG9yRW9VOtrN8mscbeIY0o',
        'reward': '20% Off Running Shoes',
        'participants': 1500,
        'daysLeft': 8,
        'totalDays': 30,
        'currentDay': 22,
        'status': 'featured',
        'affiliateUrl': 'https://nike.com/emerge-challenge',
        'xpReward': 750,
        'isFeatured': true,
        'isTeamChallenge': false,
        'buddyValidationRequired': false,
        'sponsor': 'Nike',
        'category': 'Fitness',
        'sponsorLogoUrl':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBGz-EMqiVoM-llOkthR_q3OGdagHZi2OdSNTD9nGj67nOEa_S2eSsBU7C1TcsQeoD9IkHT9evvNhRMTMXDpwFKRHGtoR4XLiaQfMZJULxHUF5LyNtHfNw3HTdwjtL6tYAZf-TiJ1hsaqkwzFmaxhBMDXMFnWqpFH2Re9eV10msA5_d-Dg3PDE7jS4RfFW20lJCrtpOHN4_KnJ2kEoSZsysIGge9dcmbysEpr-09yc1mpj4mP3uEe0l3eCXJdv29CVi8ngACeB4Hus',
        'steps': [
          {
            'day': 1,
            'title': 'Day 1: First Steps',
            'description': 'Complete your first run of any distance',
            'isCompleted': true,
          },
          {
            'day': 10,
            'title': '10-Day Milestone',
            'description': 'You are building momentum!',
            'isCompleted': true,
          },
          {
            'day': 22,
            'title': 'Day 22 of 30',
            'description': 'Almost there! Keep the streak going.',
            'isCompleted': false,
          },
          {
            'day': 30,
            'title': 'Runner Identity Unlocked',
            'description': 'You ARE a runner now. Claim your rewards!',
            'isCompleted': false,
          },
        ],
      },
      {
        'id': 'challenge_morning_meditation_quest',
        'title': 'The Morning Meditation Quest',
        'description':
            'Partner with Headspace to build a meditation practice. 21 days of daily meditation unlocks premium content and digital rewards.',
        'imageUrl':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCodTUg4WyK3YvCqWVf4ApHDNFGSNFSqtJE_GxnttuProcXtP9wjNwWcMyJGUOIbB5HIh5CdNswcArwjXOUKsYtPrEyMeenKVR7cU56R7YEtIxrvSSjqQyGJeHW8-7r0ECmPbjEAn3344G2BB5Ti74Z6Uti3uPfy0sZaMd33pwrpVY9_pUsms407N66K9opRXoMHYC_yuvD31j0t1J2yuOTO1bCKmwgw7Roe9LnzveZVGHZtzb6gFSDlVtEnDOQsGgHsQkyeQFEpRg',
        'reward': '3-Months Premium Free',
        'participants': 2100,
        'daysLeft': 12,
        'totalDays': 21,
        'currentDay': 0,
        'status': 'featured',
        'affiliateUrl': 'https://headspace.com/emerge',
        'xpReward': 500,
        'isFeatured': true,
        'isTeamChallenge': false,
        'buddyValidationRequired': false,
        'sponsor': 'Headspace',
        'category': 'Mindfulness',
        'sponsorLogoUrl':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBxGhYEEYGCoR6_2Ds-9rr1kM2DcybR8QX7GEhP8EIoVJawEsofGR8oD0YZp6Nlbr1ITVS5bYdOW6WKQXdX09BwIuklcenJ6eKiD405U1BOeAOvKp9-xvxKHp9Bt5PSqZfceEfJ8PGpz-7l_mdtAHIxW9ctjZJmx_DcPi1SJlIVlA4pLCqDpq8JxJMmMkgBULAIDkSNe7C-wM93K81-PKEXkiPXeLy35Sv5Q_QxVQoOq-IoYGTRs453Wgs-BSYQfeMdUq3KOdJlAN8',
        'steps': [
          {
            'day': 1,
            'title': 'Day 1: Begin',
            'description': '5 minutes of guided breathing',
            'isCompleted': false,
          },
          {
            'day': 7,
            'title': 'Week 1 Complete',
            'description': 'Increase to 10 minutes',
            'isCompleted': false,
          },
          {
            'day': 14,
            'title': 'Halfway There',
            'description': 'Try unguided meditation',
            'isCompleted': false,
          },
          {
            'day': 21,
            'title': 'Mindful Master',
            'description': 'You have built a meditation practice!',
            'isCompleted': false,
          },
        ],
      },
      {
        'id': 'challenge_unbroken_reading_chain',
        'title': 'The Unbroken Reading Chain',
        'description':
            'Build a consistent reading habit with 800+ adventurers. Read every day to earn your bookstore reward.',
        'imageUrl':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAlYY5nIOTy52ymmpwrZBmawmFk9qQyO48K1Jf9NjS_2OAswlnFmRKDbc8tyINedp5K8UMtwNEdv0YmhvOez54Rp8B_zfIcRBFnu9pLscU6ax3o2M9Ny6ILlG_V3qu-VyOYlCdRhaF0fuLefQdl7PnSCSV_vaNKcrpA_ykmv1kPzJKYRSdnwMWpL3T8w0AaW-KGNejNGwSB9ruiJm3VytwssiajjMqtqgvHt4wKu-hEGMWEyp-M9hZw0bnPTxgOpJFIN-eWN5pjUsE',
        'reward': '\$10 Bookstore Credit',
        'participants': 876,
        'daysLeft': 21,
        'totalDays': 30,
        'currentDay': 0,
        'status': 'featured',
        'affiliateUrl': null,
        'xpReward': 600,
        'isFeatured': true,
        'isTeamChallenge': false,
        'buddyValidationRequired': false,
        'sponsor': null,
        'category': 'Learning',
        'sponsorLogoUrl':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBM0YxrRaJSwni_v7vAXWBO_9fPvrlzYU3h0dPNu0KGOzaA40_Tj4bokYp_NWiQsjAoQ7JeoUv5s5H9tnSH11o6tmZtx0BlwFxnvqBIw6K5fvzwU2NQq6gDutr62LecfvYjpc5VuYYb7J-SPeAfr0rgKGK9nfErW9Gmo4mCCj8O8tnmj4OYhHty4p2eno19HAMDILFXFtZTblwLzBIbG1uk2lZCCfpSuCFiLogRGf1ePnLXzHVAIR5UXJuNr1V6EHfK9EbPBUGG7WQ',
        'steps': [
          {
            'day': 1,
            'title': 'Day 1: Open the Book',
            'description': 'Read your first 10 pages',
            'isCompleted': false,
          },
          {
            'day': 10,
            'title': '100 Pages Read',
            'description': 'You are making progress!',
            'isCompleted': false,
          },
          {
            'day': 20,
            'title': '200 Pages Read',
            'description': 'The habit is sticking',
            'isCompleted': false,
          },
          {
            'day': 30,
            'title': 'Scholar Status',
            'description': '300 pages conquered!',
            'isCompleted': false,
          },
        ],
      },
      {
        'id': 'challenge_whole_foods_nutrition',
        'title': 'Whole Foods Plant-Based Week',
        'description':
            'Try plant-based eating for 7 days with Whole Foods. Log your meals and build healthy eating habits.',
        'imageUrl':
            'https://images.unsplash.com/photo-1490818387583-1baba5e638af?w=400',
        'reward': 'Vitality Boost Badge + \$15 Whole Foods Gift Card',
        'participants': 1567,
        'daysLeft': 7,
        'totalDays': 7,
        'currentDay': 0,
        'status': 'featured',
        'affiliateUrl': 'https://wholefoods.com/plant-based-challenge',
        'xpReward': 200,
        'isFeatured': true,
        'isTeamChallenge': false,
        'buddyValidationRequired': false,
        'sponsor': 'Whole Foods',
        'category': 'Nutrition',
        'steps': [
          {
            'day': 1,
            'title': 'Day 1: Go Green',
            'description': 'Your first plant-based day',
            'isCompleted': false,
          },
          {
            'day': 4,
            'title': 'Halfway!',
            'description': 'Feeling the difference?',
            'isCompleted': false,
          },
          {
            'day': 7,
            'title': 'Complete!',
            'description': 'You did it! Claim your rewards.',
            'isCompleted': false,
          },
        ],
      },
      {
        'id': 'challenge_deep_work_sprint',
        'title': '14-Day Deep Work Sprint',
        'description':
            'Master focused, distraction-free work. Complete 2-hour deep work blocks daily for 14 days.',
        'imageUrl':
            'https://images.unsplash.com/photo-1497032628192-86f99bcd76bc?w=400',
        'reward': 'Focus Master Badge + Creator Avatar Equipment + 500 XP',
        'participants': 2345,
        'daysLeft': 14,
        'totalDays': 14,
        'currentDay': 0,
        'status': 'featured',
        'affiliateUrl': null,
        'xpReward': 500,
        'isFeatured': true,
        'isTeamChallenge': false,
        'buddyValidationRequired': false,
        'sponsor': null,
        'category': 'Productivity',
        'steps': [
          {
            'day': 1,
            'title': 'Day 1: No Distractions',
            'description': 'Complete your first 2-hour block',
            'isCompleted': false,
          },
          {
            'day': 7,
            'title': 'Week 1 Done',
            'description': '14 hours of deep work!',
            'isCompleted': false,
          },
          {
            'day': 14,
            'title': 'Focus Master',
            'description': '28 hours of deep work achieved!',
            'isCompleted': false,
          },
        ],
      },
    ];

    final batch = _firestore.batch();
    for (final challenge in challenges) {
      final docRef = _firestore
          .collection('challenges')
          .doc(challenge['id'] as String);
      batch.set(docRef, challenge);
    }
    await batch.commit();
    debugPrint('Seeded ${challenges.length} challenges');
  }

  /// Seeds the 'creator_blueprints' collection matching the design mockups
  /// Based on the creator_blueprints_4 design reference
  Future<void> seedBlueprints() async {
    final now = DateTime.now();
    final blueprints = [
      {
        'id': 'blueprint_atomic_habits',
        'creatorUserId': 'system',
        'creatorName': 'James Clear',
        'creatorArchetype': 'Scholar',
        'blueprintName': 'The Atomic Habits Starter Kit',
        'description':
            'Build the systems that fuel creative output and make good habits inevitable.',
        'category': 'Productivity',
        'adoptionCount': 12405,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuD_357wWxUMnRri8nImd1s-eIliBpp3eF_CaZECldc5HtSN5UM48aZ2YkyT6TW65D-c82YI066ifv7q9xHkZXLj4kImgFqZ1FtG3sLiJSLzYZsJ_-HouaUF5sqwuyYaC91L4LCd5wAu0N5zN9cXK55ra_l4jARjWNVwzljZ260VNZc9nxLDyfu2y5-w3nmVEDQpjkWjRMZKkC2TIcrtndLsYH2yu7J6107haz1nZTdZhuC6xvepDx5YaVzvg5d7AYIojci-TJqup-M',
        'habitTitles': [
          'Habit Stacking',
          'Environment Design',
          '2-Minute Rule',
        ],
      },
      {
        'id': 'blueprint_optimal_morning',
        'creatorUserId': 'system',
        'creatorName': 'Dr. Andrew Huberman',
        'creatorArchetype': 'Athlete',
        'blueprintName': 'The Optimal Morning Routine',
        'description':
            'Leverage neuroscience to maximize your focus and energy every single day.',
        'category': 'Morning',
        'adoptionCount': 9872,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAfCNp1icRBAU8hg03pn5bQWXoBFEuaIz-ZFfUPXOh56xerlnlYitA0if4Yc5mPo2938KAYn8mxC25rkiXWhXcYFz9SfaZXyRbkgQzUjyo5Lbu0wgeu2-f88hbgcI2LmQwu7y8HtduqEUdr1X4wZjJLQ4nTwXeshkcfus-M2KwANVbUrrVVdmH0O96ujwECYbjBx9-QgoR4v3d59g8vui_2fJyHpXZs4iPsgZaO0Ql6gjPS-wyfvwQ_v_T_7Cmulv-_P9IlhJ9Tqp4',
        'habitTitles': ['Morning Sunlight', 'Cold Exposure', 'Delay Caffeine'],
        'isPremium': true,
      },
      {
        'id': 'blueprint_100m_productivity',
        'creatorUserId': 'system',
        'creatorName': 'Alex Hormozi',
        'creatorArchetype': 'Creator',
        'blueprintName': '\$100M Offer Productivity Stack',
        'description':
            'The daily non-negotiables required to build a high-leverage business.',
        'category': 'Business',
        'adoptionCount': 15102,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCpEenasQ2PiqC-P3Gs1VE6p_G5LmQroYE6D9kN-T-Qylz96aFWrFzZ_bIZ2PrFy13J56PkwnkoSo8oz8eS_NVcesKqRSKMCFnLK1kgxSCaKfW3-25G5nbgYlXTeDDsHNhDsZ18pyYAwsk1r4K_BKKy_CO3fOseW0zgKn5XsawJlgcahei0SNdIAVYW8jLmmPZGLQpXP1whzb-H_a3hr31ax_rDUa5S6R3VNTzwHCqCDtFrJ0wtCyUxZPMA3UUxTbkvE8E8NpsnoQo',
        'habitTitles': [
          'Revenue-Generating Activity',
          'Lead Generation',
          'Daily Reflection',
        ],
        'isPremium': true,
      },
      {
        'id': 'blueprint_athlete',
        'creatorUserId': 'system',
        'creatorName': 'Emerge Team',
        'creatorArchetype': 'Athlete',
        'blueprintName': 'Fitness Foundation',
        'description':
            'Build a solid base of physical health and become the Athlete.',
        'category': 'Fitness',
        'adoptionCount': 5420,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=400',
        'habitTitles': ['30 Min Walk', 'Drink 2L Water', 'Stretch'],
      },
      {
        'id': 'blueprint_scholar',
        'creatorUserId': 'system',
        'creatorName': 'Emerge Team',
        'creatorArchetype': 'Scholar',
        'blueprintName': 'The Scholar Path',
        'description':
            'Focus on learning, reading, and cognitive expansion. Become a lifelong learner.',
        'category': 'Learning',
        'adoptionCount': 3210,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=400',
        'habitTitles': ['Read 20 Pages', 'Study Session', 'Review Notes'],
      },
      {
        'id': 'blueprint_creator',
        'creatorUserId': 'system',
        'creatorName': 'Emerge Team',
        'creatorArchetype': 'Creator',
        'blueprintName': 'The Creator Blueprint',
        'description':
            'Focus on output, deep work, and creative expression. Create something every day.',
        'category': 'Creativity',
        'adoptionCount': 4150,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1452802447250-470a88ac82bc?w=400',
        'habitTitles': [
          'Create First (1h)',
          'Document Progress',
          'Share Work Weekly',
        ],
      },
      {
        'id': 'blueprint_dopamine_detox',
        'creatorUserId': 'system',
        'creatorName': 'Emerge Team',
        'creatorArchetype': 'Stoic',
        'blueprintName': 'Dopamine Detox',
        'description':
            "Reset your brain's reward system and reclaim your focus.",
        'category': 'Mindset',
        'adoptionCount': 8900,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?w=400',
        'habitTitles': [
          'No Screens (1h)',
          'Nature Walk (30m)',
          'Reading (30m)',
        ],
      },
      {
        'id': 'blueprint_sleep_hygiene',
        'creatorUserId': 'system',
        'creatorName': 'Emerge Team',
        'creatorArchetype': 'Athlete',
        'blueprintName': 'Sleep Hygiene 101',
        'description':
            'Optimize your sleep for better recovery and energy. The evening wind-down ritual.',
        'category': 'Health',
        'adoptionCount': 6300,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=400',
        'habitTitles': [
          'No Screens 1hr Before Bed',
          'Read Fiction',
          'Dark Room Setup',
        ],
      },
      // --- ATHLETE BLUEPRINTS ---
      {
        'id': 'blueprint_longevity_stack',
        'creatorUserId': 'system',
        'creatorName': 'Peter Attia',
        'creatorArchetype': 'Athlete',
        'blueprintName': 'The Longevity Protocol',
        'description':
            'Master the four pillars of physical longevity: Strength, Zone 2, Stability, and VO2 Max.',
        'category': 'Health',
        'adoptionCount': 4500,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400',
        'habitTitles': [
          '45m Zone 2 Cardio',
          'Heavy Compound Lift',
          '1g Protein per lb',
        ],
        'isPremium': true,
      },
      {
        'id': 'blueprint_hyrox_prep',
        'creatorUserId': 'system',
        'creatorName': 'Emerge Team',
        'creatorArchetype': 'Athlete',
        'blueprintName': 'Hyrox Foundation',
        'description':
            'The ultimate hybrid athlete training plan for performance and endurance.',
        'category': 'Fitness',
        'adoptionCount': 2100,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=400',
        'habitTitles': ['1km Interval Run', 'Sled Push/Pull', 'Wall Ball Reps'],
      },
      {
        'id': 'blueprint_mobility_master',
        'creatorUserId': 'system',
        'creatorName': 'Emerge Team',
        'creatorArchetype': 'Athlete',
        'blueprintName': 'Functional Mobility',
        'description':
            'Unlock your joints and prevent injury with a daily functional movement ritual.',
        'category': 'Vitality',
        'adoptionCount': 3400,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400',
        'habitTitles': [
          'Hip Opening Routine',
          'Spine Mobility',
          'Deep Squat Hold',
        ],
      },
      // --- SCHOLAR BLUEPRINTS ---
      {
        'id': 'blueprint_polyglot_path',
        'creatorUserId': 'system',
        'creatorName': 'Tim Ferriss',
        'creatorArchetype': 'Scholar',
        'blueprintName': 'The Polyglot Path',
        'description':
            'Rapid language acquisition systems used by the world\'s top linguists.',
        'category': 'Learning',
        'adoptionCount': 5600,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=400',
        'habitTitles': [
          'Anki Flashcards',
          'Language Immersion',
          'Speaking Practice',
        ],
        'isPremium': true,
      },
      {
        'id': 'blueprint_deep_learning',
        'creatorUserId': 'system',
        'creatorName': 'Emerge Team',
        'creatorArchetype': 'Scholar',
        'blueprintName': 'The Deep Learning Ritual',
        'description':
            'Master complex subjects through focused active recall and Feynman techniques.',
        'category': 'Intellect',
        'adoptionCount': 4200,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=400',
        'habitTitles': [
          '90m Focus Block',
          'Active Recall Test',
          'Explain to a Child',
        ],
      },
      {
        'id': 'blueprint_philosophy_daily',
        'creatorUserId': 'system',
        'creatorName': 'Ryan Holiday',
        'creatorArchetype': 'Scholar',
        'blueprintName': 'Stoic Reflections',
        'description':
            'Daily wisdom from the classics to build a resilient and clear mind.',
        'category': 'Mindset',
        'adoptionCount': 7800,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1507413245164-6160d8298b31?w=400',
        'habitTitles': [
          'Morning Meditation',
          'Reading Classics',
          'Evening Review',
        ],
      },
      // --- CREATOR BLUEPRINTS ---
      {
        'id': 'blueprint_content_machine',
        'creatorUserId': 'system',
        'creatorName': 'MrBeast',
        'creatorArchetype': 'Creator',
        'blueprintName': 'The Content Engine',
        'description':
            'High-leverage systems for consistent creative output and audience growth.',
        'category': 'Business',
        'adoptionCount': 12000,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1492724441997-5dc865305da7?w=400',
        'habitTitles': ['Hook Writing', 'Deep Editing', 'Community Engagement'],
        'isPremium': true,
      },
      {
        'id': 'blueprint_indie_hacker',
        'creatorUserId': 'system',
        'creatorName': 'Pieter Levels',
        'creatorArchetype': 'Creator',
        'blueprintName': 'Solopreneur Sprint',
        'description':
            'Ship faster and build in public with this high-velocity founder stack.',
        'category': 'Productivity',
        'adoptionCount': 6700,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=400',
        'habitTitles': ['Shipping Code', 'Marketing Activity', 'User Outreach'],
        'isPremium': true,
      },
      {
        'id': 'blueprint_artist_way',
        'creatorUserId': 'system',
        'creatorName': 'Julia Cameron',
        'creatorArchetype': 'Creator',
        'blueprintName': 'The Artist\'s Way',
        'description':
            'Reconnect with your creative spirit and unlock your inner genius.',
        'category': 'Creativity',
        'adoptionCount': 8900,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1452802447250-470a88ac82bc?w=400',
        'habitTitles': [
          'Morning Pages',
          'Daily Sketch',
          'Artist Date (Weekly)',
        ],
      },
      // --- STOIC BLUEPRINTS ---
      {
        'id': 'blueprint_resilient_mind',
        'creatorUserId': 'system',
        'creatorName': 'David Goggins',
        'creatorArchetype': 'Stoic',
        'blueprintName': 'Mental Toughness',
        'description':
            'Callous your mind and become unfazed by life\'s challenges.',
        'category': 'Mindset',
        'adoptionCount': 15600,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?w=400',
        'habitTitles': [
          'Cold Shower',
          'Voluntary Discomfort',
          'Negative Visualization',
        ],
        'isPremium': true,
      },
      {
        'id': 'blueprint_digital_minimalism',
        'creatorUserId': 'system',
        'creatorName': 'Cal Newport',
        'creatorArchetype': 'Stoic',
        'blueprintName': 'Digital Minimalism',
        'description':
            'Reclaim your attention in a world designed to steal it.',
        'category': 'Focus',
        'adoptionCount': 9200,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1512428559087-560fa5ceab42?w=400',
        'habitTitles': [
          'Strict App Limits',
          'Phone-Free Meals',
          'Offline Hobby',
        ],
      },
      {
        'id': 'blueprint_essentialist',
        'creatorUserId': 'system',
        'creatorName': 'Greg McKeown',
        'creatorArchetype': 'Stoic',
        'blueprintName': 'The Essentialist',
        'description':
            'The disciplined pursuit of less. Do only what truly matters.',
        'category': 'Productivity',
        'adoptionCount': 4500,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1484480974693-6ca0a78fb36b?w=400',
        'habitTitles': [
          'Priority Mapping',
          'Saying No (Daily)',
          'Deep Work Sprint',
        ],
      },
      // --- ZEALOT BLUEPRINTS ---
      {
        'id': 'blueprint_spiritual_warrior',
        'creatorUserId': 'system',
        'creatorName': 'Emerge Team',
        'creatorArchetype': 'Zealot',
        'blueprintName': 'The Spiritual Warrior',
        'description':
            'Build a life centered on devotion, prayer, and sacred commitment.',
        'category': 'Spirit',
        'adoptionCount': 3400,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1507413245164-6160d8298b31?w=400',
        'habitTitles': [
          'Morning Prayer',
          'Sacred Text Reading',
          'Daily Fasting',
        ],
      },
      {
        'id': 'blueprint_zen_master',
        'creatorUserId': 'system',
        'creatorName': 'Thich Nhat Hanh',
        'creatorArchetype': 'Zealot',
        'blueprintName': 'Zen Mindfulness',
        'description':
            'Walk the path of peace with mindful presence in every moment.',
        'category': 'Vitality',
        'adoptionCount': 7800,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1528715471579-d1bcf0ba5e83?w=400',
        'habitTitles': [
          'Zazen Meditation',
          'Mindful Eating',
          'Walking Meditation',
        ],
        'isPremium': true,
      },
      {
        'id': 'blueprint_karma_yoga',
        'creatorUserId': 'system',
        'creatorName': 'Emerge Team',
        'creatorArchetype': 'Zealot',
        'blueprintName': 'Path of Service',
        'description':
            'Find yourself by losing yourself in the service of others.',
        'category': 'Spirit',
        'adoptionCount': 2900,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1469571486292-0ba58a3f068b?w=400',
        'habitTitles': ['Kindness Act', 'Volunteer Hour', 'Mentor Session'],
      },
      {
        'id': 'blueprint_monk_mode',
        'creatorUserId': 'system',
        'creatorName': 'Emerge Team',
        'creatorArchetype': 'Zealot',
        'blueprintName': 'Monk Mode Ritual',
        'description':
            'Intense focus and sacred isolation to achieve breakthrough results.',
        'category': 'Focus',
        'adoptionCount': 11000,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1518241353330-0f7941c2d9b5?w=400',
        'habitTitles': [
          'Silence Practice',
          'No Consumption',
          'Deep Reflection',
        ],
      },
      {
        'id': 'blueprint_vibration_boost',
        'creatorUserId': 'system',
        'creatorName': 'Emerge Team',
        'creatorArchetype': 'Zealot',
        'blueprintName': 'Energy Alignment',
        'description': 'Raise your vibration through breathwork and intention.',
        'category': 'Vitality',
        'adoptionCount': 5200,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=400',
        'habitTitles': ['Breathwork', 'Morning Affirmations', 'Sun Gazing'],
      },
      {
        'id': 'blueprint_stoic_calm',
        'creatorUserId': 'system',
        'creatorName': 'Marcus Aurelius',
        'creatorArchetype': 'Stoic',
        'blueprintName': 'The Calm Ruler',
        'description':
            'Maintain inner peace while leading at the highest levels.',
        'category': 'Mindset',
        'adoptionCount': 9800,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1507413245164-6160d8298b31?w=400',
        'habitTitles': ['Morning Journal', 'Duty Checklist', 'Gratitude Walk'],
        'isPremium': true,
      },
      {
        'id': 'blueprint_historical_lens',
        'creatorUserId': 'system',
        'creatorName': 'Dan Carlin',
        'creatorArchetype': 'Scholar',
        'blueprintName': 'Hardcore History Buff',
        'description':
            'Understand the present by deeply immersing yourself in the past.',
        'category': 'Learning',
        'adoptionCount': 3400,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1461360370896-922624d12aa1?w=400',
        'habitTitles': [
          'Documentary Study',
          'Archive Research',
          'Period Reading',
        ],
      },
      {
        'id': 'blueprint_data_scientist',
        'creatorUserId': 'system',
        'creatorName': 'Emerge Team',
        'creatorArchetype': 'Scholar',
        'blueprintName': 'Data Intuition',
        'description':
            'Build the technical skills and intuition required for data mastery.',
        'category': 'Intellect',
        'adoptionCount': 2100,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1551288049-bbbda5366991?w=400',
        'habitTitles': ['Coding Practice', 'Math Theory', 'Project Building'],
      },
      {
        'id': 'blueprint_podcaster_flow',
        'creatorUserId': 'system',
        'creatorName': 'Joe Rogan',
        'creatorArchetype': 'Creator',
        'blueprintName': 'Podcaster System',
        'description':
            'The daily habits of the world\'s most successful audio creators.',
        'category': 'Business',
        'adoptionCount': 6500,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1478737270239-2f02b77fc618?w=400',
        'habitTitles': [
          'Topic Research',
          'Recording Session',
          'Guest Outreach',
        ],
        'isPremium': true,
      },
      {
        'id': 'blueprint_writer_ritual',
        'creatorUserId': 'system',
        'creatorName': 'Stephen King',
        'creatorArchetype': 'Creator',
        'blueprintName': 'The Novelist Path',
        'description': 'Simple but effective habits to finish your first book.',
        'category': 'Creativity',
        'adoptionCount': 8900,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1455390582262-044cdead277a?w=400',
        'habitTitles': [
          '2000 Word Goal',
          'Daily Character Log',
          'No-Edit Draft Block',
        ],
        'isPremium': true,
      },
      {
        'id': 'blueprint_athlete_recovery',
        'creatorUserId': 'system',
        'creatorName': 'Emerge Team',
        'creatorArchetype': 'Athlete',
        'blueprintName': 'Pro Recovery Stack',
        'description':
            'Elite level recovery habits to maximize your performance and longevity.',
        'category': 'Vitality',
        'adoptionCount': 4300,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=400',
        'habitTitles': [
          'Cold/Heat Therapy',
          'Deep Sleep Reset',
          'Anti-Inflammatory Meal',
        ],
      },
      {
        'id': 'blueprint_essential_minimalist',
        'creatorUserId': 'system',
        'creatorName': 'The Minimalists',
        'creatorArchetype': 'Stoic',
        'blueprintName': 'Minimalist Mindset',
        'description':
            'Simplify your surroundings to clarify your internal state.',
        'category': 'Mindset',
        'adoptionCount': 7600,
        'createdAt': now.toIso8601String(),
        'imageUrl':
            'https://images.unsplash.com/photo-1512428559087-560fa5ceab42?w=400',
        'habitTitles': [
          'Daily Declutter',
          'Intentional Purchase',
          'Evening Calm',
        ],
      },
    ];

    final batch = _firestore.batch();
    for (final blueprint in blueprints) {
      final docRef = _firestore
          .collection('creator_blueprints')
          .doc(blueprint['id'] as String);
      batch.set(docRef, blueprint);
    }
    await batch.commit();
    debugPrint('Seeded ${blueprints.length} creator blueprints');
  }

  /// Runs all seed operations
  Future<void> seedAll() async {
    await seedTribes();
    await seedChallenges();
    await seedBlueprints();
    debugPrint('All seed data created successfully!');
  }
}
