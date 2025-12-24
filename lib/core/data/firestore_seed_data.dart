// Firestore Seed Data Script
// Run this script to populate your Firestore with initial data
// You can run this once from a test file or a dedicated initialization screen

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreSeedData {
  final FirebaseFirestore _firestore;

  FirestoreSeedData(this._firestore);

  /// Seeds the 'tribes' collection with data matching the design mockups
  Future<void> seedTribes() async {
    final tribes = [
      {
        'id': 'tribe_meditation_guild',
        'name': 'Meditation Guild',
        'description':
            'A sanctuary for mindfulness practitioners. Build your daily meditation habit with 2,500+ like-minded souls seeking inner peace.',
        'imageUrl':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCQPv10oFu2sDwJG5HnbqYGpxbA0wnzkC6vDlQDKULU6jqd1GFbAvaHlVR8HP5FFbKR_csCaRnpfWctY_KWyR2M1ncSIaVW8yWh3FvINl5K1powi1_HlOHAdAb70KYF1Zh17eHisSvHT7K9zpZ0cKwQM8R59grDPZrlwAwNoWvxJHM6s6Hh9KaFhsxOLvyRPLwbBAQmGzjp2zSF306Ho62WsKQR1Hk5Ym5Xjqyx8XMPXH__xq3jmOHuKvKiBVEfaZO5_BgmfJhgQuo',
        'memberCount': 2511,
        'ownerId': 'admin',
        'tags': ['Meditation', 'Mindfulness', 'Mental Health'],
        'levelRequirement': 1,
        'rank': 1,
        'totalXp': 15420,
        'members': [],
      },
      {
        'id': 'tribe_5am_writers',
        'name': '5 AM Writers',
        'description':
            'Early risers who write before the world wakes. Join us to build a consistent writing practice and become the Writer you aspire to be.',
        'imageUrl':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuClgA57GDCz5sdk2ZI7AfSAhkSv7hUoB_Wp-Tpa7zqU-A4H5UePzeWr9LE-xfPLVIA2BRUV6pfaZqqoRd29PuxlnRtuIfQPcO3YOCNI9LyL8GGugh3z_M99nsW62fAhd23x9IwcXZMazbVh3E2rVfFtwriLMAPGcAunjMZlwhRb7kiLAcDNR6P8IfadiZf0IwqQ_V-wbAHN3UhB3hHkmExRjo7uAWRE69oQhKcn3ez2YCynQ7Q7rhEsAIVE0sU7-YYjf1srOVEo-pk',
        'memberCount': 1204,
        'ownerId': 'admin',
        'tags': ['Writing', 'Creativity', 'Morning Routine'],
        'levelRequirement': 1,
        'rank': 2,
        'totalXp': 12890,
        'members': [],
      },
      {
        'id': 'tribe_fitness_guilds',
        'name': 'Fitness Guilds',
        'description':
            'Building physical vitality, endurance, and strength together. Every workout is a vote for your identity as an Athlete.',
        'imageUrl':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAcblAAnG3M4wmuLF9ZQ8PcI3vpkkp-Tsb9lPuwS3R9yyoz9p-9RzXs7SEnt-xumWZXp5M6ezwTrS7kdGjT_J5wxc5FJSVdFWFo8C_X_BEw89X-ADBiEMfX5WwTw3BgEvC5lPrczPdMpAiA5khGBQKAw-Wjspg94vy1I0Vomf6HklnNjg7NdPFWfylP5gxFDLqP-mV8MM8ch2D_j95CEZ03Cb48pHa87E9BV68ZUDoQQRHgsDfefC_MYIFgE28uPzaRJFxSreS0tZk',
        'memberCount': 1980,
        'ownerId': 'admin',
        'tags': ['Fitness', 'Strength', 'Vitality'],
        'levelRequirement': 1,
        'rank': 3,
        'totalXp': 11550,
        'members': [],
      },
      {
        'id': 'tribe_plant_based_parents',
        'name': 'Plant-Based Parents',
        'description':
            'Parents building healthy eating habits for themselves and their families. Share recipes, tips, and support on the plant-based journey.',
        'imageUrl':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCL4J9tsC-b5pwJGqxpGob7_-OkXHHv9dtL8P0XxMsL7FdqL9VnQzh8sU5wduI8XNiXnbz1PCsCCBXJzRqSyZPKm4cG4YXA24-a3ipyODG4a31uLncKAJkuVo3f70_-r3k4uYdgeSduK7Q5olfcgWpyA7gwbOFkyzDFtw1vKhBTu2wp-FiouVWnFKbOnTe2iE5K0xKdu-9SLaGNAYnn19aFnbJAxDMiGa_7sbQWynEOkHn3FS0h0ttwuAeV_uKEN3S5FbtrqIrbnh8',
        'memberCount': 856,
        'ownerId': 'admin',
        'tags': ['Nutrition', 'Family', 'Health'],
        'levelRequirement': 1,
        'rank': 4,
        'totalXp': 8500,
        'members': [],
      },
    ];

    final batch = _firestore.batch();
    for (final tribe in tribes) {
      final docRef = _firestore.collection('tribes').doc(tribe['id'] as String);
      batch.set(docRef, tribe);
    }
    await batch.commit();
    debugPrint('Seeded ${tribes.length} tribes');
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

  /// Seeds the 'blueprints' collection matching the design mockups
  /// Based on the creator_blueprints_4 design reference
  Future<void> seedBlueprints() async {
    final blueprints = [
      {
        'id': 'blueprint_atomic_habits',
        'title': 'The Atomic Habits Starter Kit',
        'description':
            'Build the systems that fuel creative output and make good habits inevitable.',
        'category': 'Productivity',
        'difficulty': 'Epic',
        'tier': 'Epic',
        'adoptedCount': 12405,
        'imageUrl':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuD_357wWxUMnRri8nImd1s-eIliBpp3eF_CaZECldc5HtSN5UM48aZ2YkyT6TW65D-c82YI066ifv7q9xHkZXLj4kImgFqZ1FtG3sLiJSLzYZsJ_-HouaUF5sqwuyYaC91L4LCd5wAu0N5zN9cXK55ra_l4jARjWNVwzljZ260VNZc9nxLDyfu2y5-w3nmVEDQpjkWjRMZKkC2TIcrtndLsYH2yu7J6107haz1nZTdZhuC6xvepDx5YaVzvg5d7AYIojci-TJqup-M',
        'creatorName': 'James Clear',
        'creatorTitle': 'Author',
        'creatorAvatarUrl':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBXRYtZjkkPb9bF9Csl9a-cmuKHoMRruFkungWlnmFAbTtNmpEKnbP6HXvCr3GRQ_B-yXxbNpFnQYjJ85OOZXjPuA4Cxl_3rIqQnTNq7Gau3bJGpZWCOa_jtbsJAgc600WGDQCBGlFN5ZktVhkotTHgX_C-fLIffExwXHqAycFG_UU4mByAFE9dGPtWZbnpENx2xdhWda5aq83RXgoPPRiGTQh029amLQ7Ek9oHlAvVx4R7XMdyhHZZzDwhRSQWAfNTOaeytffaz2k',
        'habits': [
          {
            'title': 'Habit Stacking',
            'frequency': 'Daily',
            'timeOfDay': 'Morning',
            'duration': '30 min',
          },
          {
            'title': 'Environment Design',
            'frequency': 'Weekly',
            'timeOfDay': 'Anytime',
            'duration': '15 min',
          },
          {
            'title': '2-Minute Rule',
            'frequency': 'Daily',
            'timeOfDay': 'Anytime',
            'duration': '2 min',
          },
        ],
      },
      {
        'id': 'blueprint_optimal_morning',
        'title': 'The Optimal Morning Routine',
        'description':
            'Leverage neuroscience to maximize your focus and energy every single day.',
        'category': 'Morning',
        'difficulty': 'Rare',
        'tier': 'Rare',
        'adoptedCount': 9872,
        'imageUrl':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAfCNp1icRBAU8hg03pn5bQWXoBFEuaIz-ZFfUPXOh56xerlnlYitA0if4Yc5mPo2938KAYn8mxC25rkiXWhXcYFz9SfaZXyRbkgQzUjyo5Lbu0wgeu2-f88hbgcI2LmQwu7y8HtduqEUdr1X4wZjJLQ4nTwXeshkcfus-M2KwANVbUrrVVdmH0O96ujwECYbjBx9-QgoR4v3d59g8vui_2fJyHpXZs4iPsgZaO0Ql6gjPS-wyfvwQ_v_T_7Cmulv-_P9IlhJ9Tqp4',
        'creatorName': 'Dr. Andrew Huberman',
        'creatorTitle': 'Neuroscientist',
        'creatorAvatarUrl':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuC94qmsOI1YKYB2g74vJVwr0Vh9VlkCBAUs23iuXf_ZMyP-oPHFK1hWtdc0RgqN1NFKABBayKG08sropAPD53qYavwdP_wnkjtB0Ct2vCXWR31s1wUuVjAWvhtYLIVova6ENGSfP-PS72sJpHdZRlFF7K-zKCvsI8BEZwt0Rk57dHd4kfshachLHvCdyquthAiRmELPLzUYafrZFDW2BOdFBoAGdCUOLQADPktapw9LdoUxBADgHu4O4-rNOnttz7ahhxruOhpenqo',
        'habits': [
          {
            'title': 'Morning Sunlight',
            'frequency': 'Daily',
            'timeOfDay': 'Morning',
            'duration': '10 min',
          },
          {
            'title': 'Cold Exposure',
            'frequency': 'Daily',
            'timeOfDay': 'Morning',
            'duration': '3 min',
          },
          {
            'title': 'Delay Caffeine',
            'frequency': 'Daily',
            'timeOfDay': 'Morning',
            'duration': '90 min',
          },
        ],
      },
      {
        'id': 'blueprint_100m_productivity',
        'title': '\$100M Offer Productivity Stack',
        'description':
            'The daily non-negotiables required to build a high-leverage business.',
        'category': 'Business',
        'difficulty': 'Legendary',
        'tier': 'Legendary',
        'adoptedCount': 15102,
        'imageUrl':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCpEenasQ2PiqC-P3Gs1VE6p_G5LmQroYE6D9kN-T-Qylz96aFWrFzZ_bIZ2PrFy13J56PkwnkoSo8oz8eS_NVcesKqRSKMCFnLK1kgxSCaKfW3-25G5nbgYlXTeDDsHNhDsZ18pyYAwsk1r4K_BKKy_CO3fOseW0zgKn5XsawJlgcahei0SNdIAVYW8jLmmPZGLQpXP1whzb-H_a3hr31ax_rDUa5S6R3VNTzwHCqCDtFrJ0wtCyUxZPMA3UUxTbkvE8E8NpsnoQo',
        'creatorName': 'Alex Hormozi',
        'creatorTitle': 'Entrepreneur',
        'creatorAvatarUrl':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDocGa4Ya0LttpQGZI5hn_lrbKVzmKI5IOzqSZjYXp_EwoI6uJf5rDg-mFj8L9tu2PilvgcvdxNSGgBiXznNDNCQrv40xZj00WWAwc_BnZMkeWKH7CFmpiRpBXWTf4FKv-eGKlLDocgcDq-5RvvCEh55XsRnfqVymPOaSD6U9vAgY-OwHDFKQql8Exa0RL4dqKxFKp4XXFG_hCIdbxSnIncUAuAcK5vcCOo8pH3FMjoJuhYd2dk4ZjoocWv87Av-S_umaLn1mCUlqI',
        'habits': [
          {
            'title': 'Revenue-Generating Activity',
            'frequency': 'Daily',
            'timeOfDay': 'Morning',
            'duration': '4 hours',
          },
          {
            'title': 'Lead Generation',
            'frequency': 'Daily',
            'timeOfDay': 'Afternoon',
            'duration': '2 hours',
          },
          {
            'title': 'Daily Reflection',
            'frequency': 'Daily',
            'timeOfDay': 'Evening',
            'duration': '15 min',
          },
        ],
      },
      {
        'id': 'blueprint_athlete',
        'title': 'Fitness Foundation',
        'description':
            'Build a solid base of physical health and become the Athlete.',
        'category': 'Fitness',
        'difficulty': 'beginner',
        'imageUrl':
            'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=400',
        'creatorName': 'Emerge Team',
        'habits': [
          {
            'title': '30 Min Walk',
            'frequency': 'Daily',
            'timeOfDay': 'Anytime',
            'duration': '30 min',
          },
          {
            'title': 'Drink 2L Water',
            'frequency': 'Daily',
            'timeOfDay': 'Anytime',
            'duration': '',
          },
          {
            'title': 'Stretch',
            'frequency': 'Daily',
            'timeOfDay': 'Morning',
            'duration': '10 min',
          },
        ],
      },
      {
        'id': 'blueprint_scholar',
        'title': 'The Scholar Path',
        'description':
            'Focus on learning, reading, and cognitive expansion. Become a lifelong learner.',
        'category': 'Learning',
        'difficulty': 'beginner',
        'imageUrl':
            'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=400',
        'creatorName': 'Emerge Team',
        'habits': [
          {
            'title': 'Read 20 Pages',
            'frequency': 'Daily',
            'timeOfDay': 'Evening',
            'duration': '30 min',
          },
          {
            'title': 'Study Session',
            'frequency': 'Weekdays',
            'timeOfDay': 'Morning',
            'duration': '45 min',
          },
          {
            'title': 'Review Notes',
            'frequency': 'Daily',
            'timeOfDay': 'Evening',
            'duration': '15 min',
          },
        ],
      },
      {
        'id': 'blueprint_creator',
        'title': 'The Creator Blueprint',
        'description':
            'Focus on output, deep work, and creative expression. Create something every day.',
        'category': 'Creativity',
        'difficulty': 'intermediate',
        'imageUrl':
            'https://images.unsplash.com/photo-1452802447250-470a88ac82bc?w=400',
        'creatorName': 'Emerge Team',
        'habits': [
          {
            'title': 'Create First (1h)',
            'frequency': 'Daily',
            'timeOfDay': 'Morning',
            'duration': '60 min',
          },
          {
            'title': 'Document Progress',
            'frequency': 'Daily',
            'timeOfDay': 'Evening',
            'duration': '10 min',
          },
          {
            'title': 'Share Work Weekly',
            'frequency': 'Weekly',
            'timeOfDay': 'Anytime',
            'duration': '15 min',
          },
        ],
      },
      {
        'id': 'blueprint_dopamine_detox',
        'title': 'Dopamine Detox',
        'description':
            "Reset your brain's reward system and reclaim your focus.",
        'category': 'Mindset',
        'difficulty': 'intermediate',
        'imageUrl':
            'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?w=400',
        'creatorName': 'Emerge Team',
        'habits': [
          {
            'title': 'No Screens (1h)',
            'frequency': 'Daily',
            'timeOfDay': 'Morning',
            'duration': '60 min',
          },
          {
            'title': 'Nature Walk (30m)',
            'frequency': 'Daily',
            'timeOfDay': 'Afternoon',
            'duration': '30 min',
          },
          {
            'title': 'Reading (30m)',
            'frequency': 'Daily',
            'timeOfDay': 'Evening',
            'duration': '30 min',
          },
        ],
      },
      {
        'id': 'blueprint_sleep_hygiene',
        'title': 'Sleep Hygiene 101',
        'description':
            'Optimize your sleep for better recovery and energy. The evening wind-down ritual.',
        'category': 'Health',
        'difficulty': 'beginner',
        'imageUrl':
            'https://images.unsplash.com/photo-1511296933631-18b5f0008d7b?w=400',
        'creatorName': 'Emerge Team',
        'habits': [
          {
            'title': 'No Screens 1hr Before Bed',
            'frequency': 'Daily',
            'timeOfDay': 'Evening',
            'duration': '',
          },
          {
            'title': 'Read Fiction',
            'frequency': 'Daily',
            'timeOfDay': 'Evening',
            'duration': '20 min',
          },
          {
            'title': 'Dark Room Setup',
            'frequency': 'Daily',
            'timeOfDay': 'Evening',
            'duration': '',
          },
        ],
      },
    ];

    final batch = _firestore.batch();
    for (final blueprint in blueprints) {
      final docRef = _firestore
          .collection('blueprints')
          .doc(blueprint['id'] as String);
      batch.set(docRef, blueprint);
    }
    await batch.commit();
    debugPrint('Seeded ${blueprints.length} blueprints');
  }

  /// Runs all seed operations
  Future<void> seedAll() async {
    await seedTribes();
    await seedChallenges();
    await seedBlueprints();
    debugPrint('All seed data created successfully!');
  }
}
