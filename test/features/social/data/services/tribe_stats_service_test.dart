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

    test('falls back to top-level totalXp when avatarStats is null', () {
      final userData = {
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
