import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/social/domain/entities/leaderboard_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LeaderboardEntry', () {
    test('should create instance with all required fields', () {
      // Arrange & Act
      const entry = LeaderboardEntry(
        userId: 'user1',
        userName: 'Test User',
        xp: 1500,
        level: 5,
        archetype: UserArchetype.athlete,
        rank: 1,
        lastUpdated: null,
      );

      // Assert
      expect(entry.userId, 'user1');
      expect(entry.userName, 'Test User');
      expect(entry.xp, 1500);
      expect(entry.level, 5);
      expect(entry.archetype, UserArchetype.athlete);
      expect(entry.rank, 1);
      expect(entry.lastUpdated, isNull);
    });

    test('should create instance with optional lastUpdated', () {
      // Arrange
      final now = DateTime.now();

      // Act
      final entry = LeaderboardEntry(
        userId: 'user1',
        userName: 'Test User',
        xp: 1500,
        level: 5,
        archetype: UserArchetype.athlete,
        rank: 1,
        lastUpdated: now,
      );

      // Assert
      expect(entry.lastUpdated, now);
    });

    test('should serialize to map correctly', () {
      // Arrange
      final now = DateTime(2026, 3, 9, 12, 0);
      final entry = LeaderboardEntry(
        userId: 'user1',
        userName: 'Test User',
        xp: 1500,
        level: 5,
        archetype: UserArchetype.athlete,
        rank: 1,
        lastUpdated: now,
      );

      // Act
      final map = entry.toMap();

      // Assert
      expect(map['userId'], 'user1');
      expect(map['userName'], 'Test User');
      expect(map['xp'], 1500);
      expect(map['level'], 5);
      expect(map['archetype'], 'athlete');
      expect(map['rank'], 1);
      expect(map['lastUpdated'], now.toIso8601String());
    });

    test('should deserialize from map correctly', () {
      // Arrange
      final now = DateTime(2026, 3, 9, 12, 0);
      final map = {
        'userId': 'user1',
        'userName': 'Test User',
        'xp': 1500,
        'level': 5,
        'archetype': 'athlete',
        'rank': 1,
        'lastUpdated': now.toIso8601String(),
      };

      // Act
      final entry = LeaderboardEntry.fromMap(map);

      // Assert
      expect(entry.userId, 'user1');
      expect(entry.userName, 'Test User');
      expect(entry.xp, 1500);
      expect(entry.level, 5);
      expect(entry.archetype, UserArchetype.athlete);
      expect(entry.rank, 1);
      expect(entry.lastUpdated, now);
    });

    test('should handle null lastUpdated in fromMap', () {
      // Arrange
      final map = {
        'userId': 'user1',
        'userName': 'Test User',
        'xp': 1500,
        'level': 5,
        'archetype': 'athlete',
        'rank': 1,
        'lastUpdated': null,
      };

      // Act
      final entry = LeaderboardEntry.fromMap(map);

      // Assert
      expect(entry.lastUpdated, isNull);
    });

    test('should handle missing lastUpdated in fromMap', () {
      // Arrange
      final map = {
        'userId': 'user1',
        'userName': 'Test User',
        'xp': 1500,
        'level': 5,
        'archetype': 'athlete',
        'rank': 1,
      };

      // Act
      final entry = LeaderboardEntry.fromMap(map);

      // Assert
      expect(entry.lastUpdated, isNull);
    });

    test('should handle invalid archetype with default', () {
      // Arrange
      final map = {
        'userId': 'user1',
        'userName': 'Test User',
        'xp': 1500,
        'level': 5,
        'archetype': 'invalid_archetype',
        'rank': 1,
      };

      // Act
      final entry = LeaderboardEntry.fromMap(map);

      // Assert
      expect(entry.archetype, UserArchetype.none);
    });

    test('should roundtrip serialization correctly', () {
      // Arrange
      final now = DateTime(2026, 3, 9, 12, 0);
      final original = LeaderboardEntry(
        userId: 'user1',
        userName: 'Test User',
        xp: 1500,
        level: 5,
        archetype: UserArchetype.scholar,
        rank: 1,
        lastUpdated: now,
      );

      // Act
      final map = original.toMap();
      final restored = LeaderboardEntry.fromMap(map);

      // Assert
      expect(restored.userId, original.userId);
      expect(restored.userName, original.userName);
      expect(restored.xp, original.xp);
      expect(restored.level, original.level);
      expect(restored.archetype, original.archetype);
      expect(restored.rank, original.rank);
      expect(restored.lastUpdated, original.lastUpdated);
    });
  });
}
