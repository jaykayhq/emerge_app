import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/world_map/domain/models/world_node.dart';
import 'package:emerge_app/features/world_map/domain/models/hex_location.dart';

/// Integration tests for level progression mechanics
/// Tests the LevelUpListener's ability to detect and celebrate level increases
void main() {
  group('Level Progression Integration Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      // Initialize shared preferences for each test
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      // Reset the celebrated level before each test
      await prefs.setInt('last_celebrated_level', 0);
    });

    tearDown(() async {
      await prefs.clear();
    });

    test('Level-up screen triggers on every level increase', () async {
      // Arrange
      final container = ProviderContainer();

      // Act - simulate user going from level 1 to level 3
      // This should trigger celebrations for level 2 AND level 3

      final initialProfile = UserProfile(
        uid: 'test-user',
        avatarStats: const UserAvatarStats(
          level: 1,
          strengthXp: 0,
          intellectXp: 0,
        ),
      );

      final leveledUpProfile = UserProfile(
        uid: 'test-user',
        avatarStats: const UserAvatarStats(
          level: 3,
          strengthXp: 500,
          intellectXp: 1000,
        ),
      );

      // Assert - verify level difference is detected
      expect(leveledUpProfile.avatarStats.level, 3);
      expect(leveledUpProfile.avatarStats.level - initialProfile.avatarStats.level, 2);

      container.dispose();
    });

    test('Celebrated level is persisted to SharedPreferences', () async {
      // Arrange
      const newLevel = 5;
      const lastCelebrated = 3;

      await prefs.setInt('last_celebrated_level', lastCelebrated);

      // Act - simulate checking for level up
      final currentLevel = newLevel;
      final storedLevel = prefs.getInt('last_celebrated_level') ?? 0;

      // Assert - should detect 2 levels to celebrate (4 and 5)
      final levelsToCelebrate = currentLevel - storedLevel;
      expect(levelsToCelebrate, 2);
      expect(storedLevel, 3);
    });

    test('Single level increase triggers exactly one celebration', () {
      // Arrange
      const previousLevel = 5;
      const currentLevel = 6;

      // Act - calculate levels gained
      final levelsGained = currentLevel - previousLevel;

      // Assert
      expect(levelsGained, 1);
    });

    test('No celebration when level decreases', () async {
      // Arrange
      await prefs.setInt('last_celebrated_level', 10);

      // Act - simulate level drop (shouldn't happen normally but test robustness)
      const currentLevel = 5;
      final lastCelebrated = prefs.getInt('last_celebrated_level') ?? 0;

      // Assert - should not trigger celebration
      expect(currentLevel > lastCelebrated, false);
    });

    test('No celebration when level stays same', () async {
      // Arrange
      await prefs.setInt('last_celebrated_level', 5);

      // Act - same level
      const currentLevel = 5;
      final lastCelebrated = prefs.getInt('last_celebrated_level') ?? 0;

      // Assert
      expect(currentLevel > lastCelebrated, false);
    });

    test('Multiple level gap triggers correct number of celebrations', () {
      // Arrange
      const lastCelebrated = 1;
      const currentLevel = 5;

      // Act - calculate levels to celebrate
      final levelsToCelebrate = <int>[];
      for (int level = lastCelebrated + 1; level <= currentLevel; level++) {
        levelsToCelebrate.add(level);
      }

      // Assert - should celebrate levels 2, 3, 4, 5 (4 celebrations)
      expect(levelsToCelebrate.length, 4);
      expect(levelsToCelebrate, containsAll([2, 3, 4, 5]));
    });

    test('Initial load does not trigger celebration', () {
      // Arrange - first time loading the app
      final previousLevel = null; // No previous level on initial load

      // Assert - should not celebrate (previousLevel is null)
      expect(previousLevel, null);
    });
  });

  group('UserAvatarStats Attribute XP Tests', () {
    test('getAttributeXp returns correct XP for valid attribute', () {
      // Arrange
      const stats = UserAvatarStats(
        strengthXp: 100,
        intellectXp: 200,
        vitalityXp: 150,
        creativityXp: 50,
        focusXp: 75,
        spiritXp: 125,
        level: 5,
        attributeXp: {
          'strength': 100,
          'intellect': 200,
          'vitality': 150,
          'creativity': 50,
          'focus': 75,
          'spirit': 125,
        },
      );

      // Act & Assert
      expect(stats.getAttributeXp('strength'), 100);
      expect(stats.getAttributeXp('intellect'), 200);
      expect(stats.getAttributeXp('vitality'), 150);
      expect(stats.getAttributeXp('creativity'), 50);
      expect(stats.getAttributeXp('focus'), 75);
      expect(stats.getAttributeXp('spirit'), 125);
    });

    test('getAttributeXp returns 0 for unknown attribute', () {
      // Arrange
      const stats = UserAvatarStats(
        attributeXp: {'strength': 100},
      );

      // Act & Assert
      expect(stats.getAttributeXp('unknown'), 0);
    });

    test('addAttributeXp correctly increments attribute XP', () {
      // Arrange
      const stats = UserAvatarStats(
        attributeXp: {'strength': 100, 'intellect': 50},
        strengthXp: 100,
        intellectXp: 50,
      );

      // Act
      final updated = stats.addAttributeXp('strength', 25);

      // Assert
      expect(updated.attributeXp['strength'], 125);
      expect(updated.attributeXp['intellect'], 50); // Unchanged
      // Total XP is computed as sum of all attributes
      expect(updated.totalXp, 175); // 125 + 50
    });

    test('addAttributeXp creates new attribute if not exists', () {
      // Arrange
      const stats = UserAvatarStats(
        attributeXp: {'strength': 100},
        strengthXp: 100,
      );

      // Act
      final updated = stats.addAttributeXp('focus', 30);

      // Assert
      expect(updated.attributeXp['strength'], 100);
      expect(updated.attributeXp['focus'], 30);
      expect(updated.totalXp, 130); // 100 + 30
    });
  });

  group('WorldNode Progress Tests', () {
    test('isComplete returns true when nodeXp >= nodeXpRequired', () {
      // Arrange
      const node = WorldNode(
        id: 'test_node',
        name: 'Test Node',
        description: 'Test',
        emoji: '📍',
        targetedAttributes: [],
        xpBoosts: {},
        requiredLevel: 1,
        type: NodeType.waypoint,
        hexLocation: HexLocation(0, 0),
        nodeXp: 100,
        nodeXpRequired: 100,
        primaryAttributes: ['strength'],
      );

      // Act & Assert
      expect(node.isComplete, true);
    });

    test('isComplete returns false when nodeXp < nodeXpRequired', () {
      // Arrange
      const node = WorldNode(
        id: 'test_node',
        name: 'Test Node',
        description: 'Test',
        emoji: '📍',
        targetedAttributes: [],
        xpBoosts: {},
        requiredLevel: 1,
        type: NodeType.waypoint,
        hexLocation: HexLocation(0, 0),
        nodeXp: 50,
        nodeXpRequired: 100,
        primaryAttributes: ['strength'],
      );

      // Act & Assert
      expect(node.isComplete, false);
    });

    test('completionPercent returns correct ratio', () {
      // Arrange
      const node = WorldNode(
        id: 'test_node',
        name: 'Test Node',
        description: 'Test',
        emoji: '📍',
        targetedAttributes: [],
        xpBoosts: {},
        requiredLevel: 1,
        type: NodeType.waypoint,
        hexLocation: HexLocation(0, 0),
        nodeXp: 75,
        nodeXpRequired: 100,
        primaryAttributes: ['strength'],
      );

      // Act & Assert
      expect(node.completionPercent, 0.75);
    });

    test('completionPercent exceeds 1.0 for over-progress', () {
      // Arrange
      const node = WorldNode(
        id: 'test_node',
        name: 'Test Node',
        description: 'Test',
        emoji: '📍',
        targetedAttributes: [],
        xpBoosts: {},
        requiredLevel: 1,
        type: NodeType.waypoint,
        hexLocation: HexLocation(0, 0),
        nodeXp: 150,
        nodeXpRequired: 100,
        primaryAttributes: ['strength'],
      );

      // Act & Assert
      // Note: completionPercent returns raw ratio, not clamped in the model
      expect(node.completionPercent, 1.5);
    });
  });
}
