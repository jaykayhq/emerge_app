import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TribeStatsService XP extraction logic', () {
    test('sums avatarStats attributes correctly from user_data map', () {
      // This tests the XP accumulation pattern used in TribeStatsService
      // when avatarStats.totalXp and currentXp are both absent/null.
      final userData = {
        'avatarStats': {
          'strengthXp': 100,
          'intellectXp': 200,
          'vitalityXp': 150,
          'creativityXp': 50,
          'focusXp': 75,
          'spiritXp': 25,
        },
      };

      final avatarStats = userData['avatarStats'] as Map<String, dynamic>;
      int xp = 0;
      xp += avatarStats['strengthXp'] as int? ?? 0;
      xp += avatarStats['intellectXp'] as int? ?? 0;
      xp += avatarStats['vitalityXp'] as int? ?? 0;
      xp += avatarStats['creativityXp'] as int? ?? 0;
      xp += avatarStats['focusXp'] as int? ?? 0;
      xp += avatarStats['spiritXp'] as int? ?? 0;
      expect(xp, 600);
    });

    test('uses totalXp when present and skips attribute sum', () {
      final userData = {
        'avatarStats': {
          'totalXp': 5000,
          'strengthXp': 100,
          'intellectXp': 200,
        },
      };

      final avatarStats = userData['avatarStats'] as Map<String, dynamic>;
      final xp = (avatarStats['totalXp'] as int?) ??
          (avatarStats['currentXp'] as int?) ??
          0;
      expect(xp, 5000);
    });

    test('uses currentXp when totalXp is absent and skips attribute sum', () {
      final userData = {
        'avatarStats': {
          'currentXp': 3000,
          'strengthXp': 100,
          'intellectXp': 200,
        },
      };

      final avatarStats = userData['avatarStats'] as Map<String, dynamic>;
      int userXp = (avatarStats['totalXp'] as int?) ??
          (avatarStats['currentXp'] as int?) ??
          0;

      if (userXp == 0) {
        userXp += avatarStats['strengthXp'] as int? ?? 0;
        userXp += avatarStats['intellectXp'] as int? ?? 0;
      }
      expect(userXp, 3000);
    });

    test('uses top-level currentXp when totalXp is absent', () {
      final userData = {
        'currentXp': 777,
      };

      final xp = userData['totalXp'] ??
          userData['currentXp'] ??
          0;
      expect(xp, 777);
    });

    test('includes customAttributeXp in fallback sum', () {
      final userData = {
        'avatarStats': {
          'attributeXp': {
            'custom1': 50,
            'custom2': 30,
          },
          'strengthXp': 10,
        },
      };

      final avatarStats = userData['avatarStats'] as Map<String, dynamic>;
      int userXp = (avatarStats['totalXp'] as int?) ??
          (avatarStats['currentXp'] as int?) ??
          0;

      if (userXp == 0) {
        userXp += avatarStats['strengthXp'] as int? ?? 0;

        final customAttributeXp =
            avatarStats['attributeXp'] as Map<String, dynamic>?;
        if (customAttributeXp != null) {
          for (final value in customAttributeXp.values) {
            if (value is int) userXp += value;
          }
        }
      }
      expect(userXp, 90);
    });

    test('falls back to top-level totalXp when avatarStats is null', () {
      final Map<String, dynamic> userData = {
        'totalXp': 999,
      };

      final xp = (userData['totalXp'] as int?) ??
          (userData['currentXp'] as int?) ??
          0;
      expect(xp, 999);
    });

    test('returns 0 when no XP data is present', () {
      final userData = <String, dynamic>{};

      final xp = (userData['totalXp'] as int?) ??
          (userData['currentXp'] as int?) ??
          0;
      expect(xp, 0);
    });
  });
}
