import 'package:emerge_app/features/gamification/domain/entities/reward_catalog.dart';
import 'package:emerge_app/features/gamification/domain/entities/reward_item.dart';
import 'package:emerge_app/features/gamification/domain/entities/user_stats.dart';
import 'package:emerge_app/features/gamification/domain/services/reward_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RewardService service;

  setUp(() {
    service = RewardService();
  });

  group('RewardCatalog', () {
    test('has at least 20 rewards', () {
      expect(RewardCatalog.all.length, greaterThanOrEqualTo(20));
    });

    test('getById returns correct reward', () {
      final reward = RewardCatalog.getById('title_initiate');
      expect(reward, isNotNull);
      expect(reward!.name, 'The Initiate');
      expect(reward.type, RewardType.title);
    });

    test('getById returns null for unknown ID', () {
      expect(RewardCatalog.getById('nonexistent'), isNull);
    });

    test('byType filters correctly', () {
      final titles = RewardCatalog.byType(RewardType.title);
      expect(titles, isNotEmpty);
      expect(titles.every((r) => r.type == RewardType.title), isTrue);
    });

    test('purchasable returns only IAP items', () {
      final shop = RewardCatalog.purchasable;
      expect(shop, isNotEmpty);
      expect(shop.every((r) => r.iapProductId != null), isTrue);
    });
  });

  group('RewardService - Eligibility', () {
    test('new user only gets default nameplate', () {
      final stats = UserStats(userId: 'test', currentXp: 0, currentStreak: 0);
      final eligible = service.getEligibleRewards(stats);
      expect(eligible.length, 1);
      expect(eligible.first.id, 'nameplate_default');
    });

    test('user with XP > 0 unlocks initiate title + first step emblem', () {
      final stats = UserStats(userId: 'test', currentXp: 10);
      final eligible = service.getEligibleRewards(stats);
      final ids = eligible.map((r) => r.id).toList();
      expect(ids, contains('title_initiate'));
      expect(ids, contains('emblem_first_step'));
      expect(ids, contains('nameplate_default'));
    });

    test('user with 7-day streak unlocks unyielding + ember', () {
      final stats = UserStats(
        userId: 'test',
        currentXp: 200,
        currentLevel: 3,
        currentStreak: 7,
      );
      final eligible = service.getEligibleRewards(stats);
      final ids = eligible.map((r) => r.id).toList();
      expect(ids, contains('title_unyielding'));
      expect(ids, contains('nameplate_ember'));
      expect(ids, contains('emblem_streak_7'));
    });

    test('IAP rewards are excluded from eligibility', () {
      final stats = UserStats(
        userId: 'test',
        currentXp: 99999,
        currentLevel: 10,
        currentStreak: 200,
      );
      final eligible = service.getEligibleRewards(stats);
      expect(eligible.any((r) => r.source == RewardSource.purchase), isFalse);
    });

    test('already unlocked rewards are excluded', () {
      final stats = UserStats(
        userId: 'test',
        currentXp: 10,
        unlockedRewardIds: ['title_initiate'],
      );
      final eligible = service.getEligibleRewards(stats);
      expect(eligible.any((r) => r.id == 'title_initiate'), isFalse);
    });
  });

  group('RewardService - Unlock', () {
    test('unlockReward adds ID to unlockedRewardIds', () {
      final stats = UserStats(userId: 'test', currentXp: 10);
      final updated = service.unlockReward(stats, 'title_initiate');
      expect(updated, isNotNull);
      expect(updated!.unlockedRewardIds, contains('title_initiate'));
    });

    test('unlockReward returns null for already unlocked', () {
      final stats = UserStats(
        userId: 'test',
        currentXp: 10,
        unlockedRewardIds: ['title_initiate'],
      );
      final updated = service.unlockReward(stats, 'title_initiate');
      expect(updated, isNull);
    });

    test('unlockReward returns null for ineligible reward', () {
      final stats = UserStats(userId: 'test', currentXp: 0, currentStreak: 0);
      final updated = service.unlockReward(stats, 'title_unyielding');
      expect(updated, isNull);
    });
  });

  group('RewardService - Equip', () {
    test('equipTitle sets equippedTitleId', () {
      final stats = UserStats(
        userId: 'test',
        unlockedRewardIds: ['title_initiate'],
      );
      final updated = service.equipTitle(stats, 'title_initiate');
      expect(updated, isNotNull);
      expect(updated!.equippedTitleId, 'title_initiate');
    });

    test('equipTitle returns null for non-unlocked title', () {
      final stats = UserStats(userId: 'test');
      final updated = service.equipTitle(stats, 'title_initiate');
      expect(updated, isNull);
    });

    test('equipNameplate sets equippedNameplateId', () {
      final stats = UserStats(
        userId: 'test',
        unlockedRewardIds: ['nameplate_ember'],
      );
      final updated = service.equipNameplate(stats, 'nameplate_ember');
      expect(updated, isNotNull);
      expect(updated!.equippedNameplateId, 'nameplate_ember');
    });

    test('equipEmblem adds to equippedEmblemIds', () {
      final stats = UserStats(
        userId: 'test',
        unlockedRewardIds: ['emblem_first_step'],
      );
      final updated = service.equipEmblem(stats, 'emblem_first_step');
      expect(updated, isNotNull);
      expect(updated!.equippedEmblemIds, contains('emblem_first_step'));
    });

    test('equipEmblem toggles off if already equipped', () {
      final stats = UserStats(
        userId: 'test',
        unlockedRewardIds: ['emblem_first_step'],
        equippedEmblemIds: ['emblem_first_step'],
      );
      final updated = service.equipEmblem(stats, 'emblem_first_step');
      expect(updated, isNotNull);
      expect(updated!.equippedEmblemIds, isEmpty);
    });

    test('equipEmblem caps at 3', () {
      final stats = UserStats(
        userId: 'test',
        unlockedRewardIds: [
          'emblem_first_step',
          'emblem_streak_7',
          'emblem_streak_30',
          'emblem_contract_keeper',
        ],
        equippedEmblemIds: [
          'emblem_first_step',
          'emblem_streak_7',
          'emblem_streak_30',
        ],
      );
      final updated = service.equipEmblem(stats, 'emblem_contract_keeper');
      expect(updated, isNotNull);
      expect(updated!.equippedEmblemIds.length, 3);
      // First one removed, new one added
      expect(updated.equippedEmblemIds, contains('emblem_contract_keeper'));
      expect(updated.equippedEmblemIds.contains('emblem_first_step'), isFalse);
    });
  });

  group('RewardService - Display', () {
    test('getEquippedTitleDisplay returns display value', () {
      final stats = UserStats(
        userId: 'test',
        equippedTitleId: 'title_unyielding',
      );
      final display = service.getEquippedTitleDisplay(stats);
      expect(display, ', The Unyielding');
    });

    test('getEquippedTitleDisplay returns empty for no title', () {
      final stats = UserStats(userId: 'test');
      expect(service.getEquippedTitleDisplay(stats), '');
    });

    test('getEquippedNameplateKey returns key', () {
      final stats = UserStats(
        userId: 'test',
        equippedNameplateId: 'nameplate_ember',
      );
      expect(service.getEquippedNameplateKey(stats), 'ember');
    });

    test('getEquippedNameplateKey returns default for none', () {
      final stats = UserStats(userId: 'test');
      expect(service.getEquippedNameplateKey(stats), 'default');
    });
  });

  group('RewardItem serialization', () {
    test('toMap / fromMap roundtrip', () {
      const original = RewardItem(
        id: 'test_reward',
        name: 'Test',
        type: RewardType.title,
        rarity: RewardRarity.epic,
        source: RewardSource.milestone,
        displayValue: ', The Test',
        description: 'A test reward',
        levelRequirement: 5,
        archetypeId: 'warrior',
        xpCost: 100,
      );
      final map = original.toMap();
      final restored = RewardItem.fromMap(map);
      expect(restored, equals(original));
    });
  });
}
