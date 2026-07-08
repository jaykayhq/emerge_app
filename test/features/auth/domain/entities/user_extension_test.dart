import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/domain/models/avatar.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserArchetype', () {
    test('displayName returns capitalized name', () {
      expect(UserArchetype.athlete.displayName, 'Athlete');
      expect(UserArchetype.creator.displayName, 'Creator');
      expect(UserArchetype.scholar.displayName, 'Scholar');
      expect(UserArchetype.stoic.displayName, 'Stoic');
      expect(UserArchetype.zealot.displayName, 'Zealot');
      expect(UserArchetype.none.displayName, 'None');
    });

    test('color returns correct color for each archetype', () {
      expect(UserArchetype.athlete.color, EmergeColors.coral);
      expect(UserArchetype.creator.color, EmergeColors.purple);
      expect(UserArchetype.scholar.color, EmergeColors.blue);
      expect(UserArchetype.stoic.color, EmergeColors.teal);
      expect(UserArchetype.zealot.color, EmergeColors.yellow);
      expect(UserArchetype.none.color, Colors.grey);
    });

    test('icon returns correct icon for each archetype', () {
      expect(UserArchetype.athlete.icon, Icons.fitness_center);
      expect(UserArchetype.creator.icon, Icons.palette);
      expect(UserArchetype.scholar.icon, Icons.menu_book);
      expect(UserArchetype.stoic.icon, Icons.self_improvement);
      expect(UserArchetype.zealot.icon, Icons.flash_on);
      expect(UserArchetype.none.icon, Icons.person_outline);
    });
  });

  group('UserAvatarStats', () {
    test('default constructor uses zeros for XPs, level=1, streak=0, momentumScore=0', () {
      const stats = UserAvatarStats();
      expect(stats.strengthXp, 0);
      expect(stats.intellectXp, 0);
      expect(stats.vitalityXp, 0);
      expect(stats.creativityXp, 0);
      expect(stats.focusXp, 0);
      expect(stats.spiritXp, 0);
      expect(stats.challengeXp, 0);
      expect(stats.level, 1);
      expect(stats.streak, 0);
      expect(stats.momentumScore, 0);
      expect(stats.lastCelebratedLevel, 0);
    });

    test('constructor with explicit values', () {
      const stats = UserAvatarStats(
        strengthXp: 10,
        intellectXp: 20,
        vitalityXp: 30,
        creativityXp: 40,
        focusXp: 50,
        spiritXp: 60,
        challengeXp: 70,
        level: 5,
        streak: 3,
        momentumScore: 75,
        lastCelebratedLevel: 3,
      );
      expect(stats.strengthXp, 10);
      expect(stats.intellectXp, 20);
      expect(stats.vitalityXp, 30);
      expect(stats.creativityXp, 40);
      expect(stats.focusXp, 50);
      expect(stats.spiritXp, 60);
      expect(stats.challengeXp, 70);
      expect(stats.level, 5);
      expect(stats.streak, 3);
      expect(stats.momentumScore, 75);
      expect(stats.lastCelebratedLevel, 3);
    });

    test('toMap/fromMap roundtrip', () {
      const stats = UserAvatarStats(
        strengthXp: 10,
        intellectXp: 20,
        vitalityXp: 30,
        creativityXp: 40,
        focusXp: 50,
        spiritXp: 60,
        challengeXp: 70,
        level: 5,
        streak: 3,
        momentumScore: 75,
        attributeXp: {'strength': 10, 'intellect': 20},
        lastCelebratedLevel: 3,
      );
      final map = stats.toMap();
      final restored = UserAvatarStats.fromMap(map);
      expect(restored.strengthXp, 10);
      expect(restored.intellectXp, 20);
      expect(restored.vitalityXp, 30);
      expect(restored.creativityXp, 40);
      expect(restored.focusXp, 50);
      expect(restored.spiritXp, 60);
      expect(restored.challengeXp, 70);
      expect(restored.level, 5);
      expect(restored.streak, 3);
      expect(restored.momentumScore, 75);
      expect(restored.attributeXp, {'strength': 10, 'intellect': 20});
      expect(restored.lastCelebratedLevel, 3);
    });

    test('fromMap with missing keys uses defaults', () {
      final stats = UserAvatarStats.fromMap({});
      expect(stats.strengthXp, 0);
      expect(stats.intellectXp, 0);
      expect(stats.vitalityXp, 0);
      expect(stats.creativityXp, 0);
      expect(stats.focusXp, 0);
      expect(stats.spiritXp, 0);
      expect(stats.challengeXp, 0);
      expect(stats.level, 1);
      expect(stats.streak, 0);
      expect(stats.momentumScore, 0);
      expect(stats.lastCelebratedLevel, 0);
    });

    test('totalXp getter sums all 6 XP fields', () {
      const stats = UserAvatarStats(
        strengthXp: 10,
        intellectXp: 20,
        vitalityXp: 30,
        creativityXp: 40,
        focusXp: 50,
        spiritXp: 60,
      );
      expect(stats.totalXp, 210);
    });

    test('totalXp does not include challengeXp', () {
      const stats = UserAvatarStats(
        strengthXp: 1,
        intellectXp: 2,
        vitalityXp: 3,
        creativityXp: 4,
        focusXp: 5,
        spiritXp: 6,
        challengeXp: 999,
      );
      expect(stats.totalXp, 21);
    });

    test('momentumState returns onFire when >= 90', () {
      const stats = UserAvatarStats(momentumScore: 90);
      expect(stats.momentumState, HabitStreakState.onFire);
    });

    test('momentumState returns strong when >= 70', () {
      const stats = UserAvatarStats(momentumScore: 70);
      expect(stats.momentumState, HabitStreakState.strong);
    });

    test('momentumState returns building when >= 50', () {
      const stats = UserAvatarStats(momentumScore: 50);
      expect(stats.momentumState, HabitStreakState.building);
    });

    test('momentumState returns atRisk when >= 30', () {
      const stats = UserAvatarStats(momentumScore: 30);
      expect(stats.momentumState, HabitStreakState.atRisk);
    });

    test('momentumState returns recovery when >= 10', () {
      const stats = UserAvatarStats(momentumScore: 10);
      expect(stats.momentumState, HabitStreakState.recovery);
    });

    test('momentumState returns reset when < 10', () {
      const stats = UserAvatarStats(momentumScore: 9);
      expect(stats.momentumState, HabitStreakState.reset);
    });

    test('copyWith overrides individual fields', () {
      const stats = UserAvatarStats(strengthXp: 10, intellectXp: 20);
      final copied = stats.copyWith(strengthXp: 99);
      expect(copied.strengthXp, 99);
      expect(copied.intellectXp, 20);
    });

    test('getAttributeXp returns correct value from attributeXp map', () {
      const stats = UserAvatarStats(attributeXp: {'strength': 15, 'intellect': 25});
      expect(stats.getAttributeXp('strength'), 15);
      expect(stats.getAttributeXp('intellect'), 25);
    });

    test('getAttributeXp returns 0 for unknown keys', () {
      const stats = UserAvatarStats(attributeXp: {'strength': 15});
      expect(stats.getAttributeXp('unknown'), 0);
    });

    test('getAttributeXp is case-insensitive', () {
      const stats = UserAvatarStats(attributeXp: {'strength': 15});
      expect(stats.getAttributeXp('STRENGTH'), 15);
    });

    test('addAttributeXp adds to both map and the corresponding field for strength', () {
      const stats = UserAvatarStats(strengthXp: 10, attributeXp: {'strength': 10});
      final updated = stats.addAttributeXp('strength', 5);
      expect(updated.strengthXp, 15);
      expect(updated.attributeXp['strength'], 15);
    });

    test('addAttributeXp adds to both map and the corresponding field for intellect', () {
      const stats = UserAvatarStats(intellectXp: 10, attributeXp: {'intellect': 10});
      final updated = stats.addAttributeXp('intellect', 5);
      expect(updated.intellectXp, 15);
      expect(updated.attributeXp['intellect'], 15);
    });

    test('addAttributeXp adds to both map and the corresponding field for vitality', () {
      const stats = UserAvatarStats(vitalityXp: 10, attributeXp: {'vitality': 10});
      final updated = stats.addAttributeXp('vitality', 5);
      expect(updated.vitalityXp, 15);
      expect(updated.attributeXp['vitality'], 15);
    });

    test('addAttributeXp adds to both map and the corresponding field for creativity', () {
      const stats = UserAvatarStats(creativityXp: 10, attributeXp: {'creativity': 10});
      final updated = stats.addAttributeXp('creativity', 5);
      expect(updated.creativityXp, 15);
      expect(updated.attributeXp['creativity'], 15);
    });

    test('addAttributeXp adds to both map and the corresponding field for focus', () {
      const stats = UserAvatarStats(focusXp: 10, attributeXp: {'focus': 10});
      final updated = stats.addAttributeXp('focus', 5);
      expect(updated.focusXp, 15);
      expect(updated.attributeXp['focus'], 15);
    });

    test('addAttributeXp adds to both map and the corresponding field for spirit', () {
      const stats = UserAvatarStats(spiritXp: 10, attributeXp: {'spirit': 10});
      final updated = stats.addAttributeXp('spirit', 5);
      expect(updated.spiritXp, 15);
      expect(updated.attributeXp['spirit'], 15);
    });

    test('addAttributeXp with unknown key only updates map', () {
      const stats = UserAvatarStats();
      final updated = stats.addAttributeXp('unknown', 5);
      expect(updated.strengthXp, 0);
      expect(updated.attributeXp['unknown'], 5);
    });
  });

  group('WorldSeason', () {
    test('has four seasons', () {
      expect(WorldSeason.values.length, 4);
      expect(WorldSeason.values, containsAll([WorldSeason.spring, WorldSeason.summer, WorldSeason.autumn, WorldSeason.winter]));
    });
  });

  group('WorldTheme', () {
    test('has four themes', () {
      expect(WorldTheme.values.length, 4);
      expect(WorldTheme.values, containsAll([WorldTheme.sanctuary, WorldTheme.island, WorldTheme.settlement, WorldTheme.floatingRealm]));
    });
  });

  group('UserWorldState', () {
    test('default constructor uses level=1, entropy=0.0', () {
      const state = UserWorldState();
      expect(state.cityLevel, 1);
      expect(state.forestLevel, 1);
      expect(state.entropy, 0.0);
      expect(state.worldAge, 0);
      expect(state.worldTheme, WorldTheme.sanctuary);
      expect(state.seasonalState, WorldSeason.spring);
    });

    test('worldHealth getter returns 1.0 - entropy', () {
      const state = UserWorldState(entropy: 0.3);
      expect(state.worldHealth, 0.7);
    });

    test('isDecaying returns true when entropy > 0.3', () {
      const state = UserWorldState(entropy: 0.31);
      expect(state.isDecaying, true);
    });

    test('isDecaying returns false when entropy <= 0.3', () {
      const state = UserWorldState(entropy: 0.3);
      expect(state.isDecaying, false);
    });

    test('isThriving returns true when entropy < 0.1', () {
      const state = UserWorldState(entropy: 0.09);
      expect(state.isThriving, true);
    });

    test('isThriving returns false when entropy >= 0.1', () {
      const state = UserWorldState(entropy: 0.1);
      expect(state.isThriving, false);
    });

    test('toMap/fromMap roundtrip', () {
      const state = UserWorldState(
        cityLevel: 3,
        forestLevel: 2,
        entropy: 0.15,
        worldAge: 30,
        worldTheme: WorldTheme.island,
        seasonalState: WorldSeason.summer,
        highestCompletedNodeLevel: 2,
        activeEntropyEffects: ['fog', 'weeds'],
      );
      final map = state.toMap();
      final restored = UserWorldState.fromMap(map);
      expect(restored.cityLevel, 3);
      expect(restored.forestLevel, 2);
      expect(restored.entropy, 0.15);
      expect(restored.worldAge, 30);
      expect(restored.worldTheme, WorldTheme.island);
      expect(restored.seasonalState, WorldSeason.summer);
      expect(restored.highestCompletedNodeLevel, 2);
      expect(restored.activeEntropyEffects, ['fog', 'weeds']);
    });

    test('fromMap with missing keys uses defaults', () {
      final state = UserWorldState.fromMap({});
      expect(state.cityLevel, 1);
      expect(state.forestLevel, 1);
      expect(state.entropy, 0.0);
      expect(state.worldAge, 0);
      expect(state.worldTheme, WorldTheme.sanctuary);
      expect(state.seasonalState, WorldSeason.spring);
    });

    test('copyWith overrides individual fields', () {
      const state = UserWorldState(cityLevel: 1, forestLevel: 1);
      final copied = state.copyWith(cityLevel: 5);
      expect(copied.cityLevel, 5);
      expect(copied.forestLevel, 1);
    });

    test('initial() factory creates 6 zones', () {
      final state = UserWorldState.initial();
      expect(state.zones.length, 6);
      expect(state.zones.containsKey('garden'), true);
      expect(state.zones.containsKey('library'), true);
      expect(state.zones.containsKey('forge'), true);
      expect(state.zones.containsKey('studio'), true);
      expect(state.zones.containsKey('shrine'), true);
      expect(state.zones.containsKey('temple'), true);
      expect(state.lastActiveDate, isNotNull);
    });

    test('toMap serializes lastActiveDate as ISO string', () {
      final now = DateTime(2026, 6, 16);
      final state = UserWorldState(lastActiveDate: now);
      final map = state.toMap();
      expect(map['lastActiveDate'], '2026-06-16T00:00:00.000');
    });
  });

  group('HabitStack', () {
    test('constructor with all fields', () {
      const stack = HabitStack(
        anchorId: 'anchor_1',
        habitId: 'habit_1',
        defaultTime: '08:00',
        timeOfDayPreference: 'morning',
      );
      expect(stack.anchorId, 'anchor_1');
      expect(stack.habitId, 'habit_1');
      expect(stack.defaultTime, '08:00');
      expect(stack.timeOfDayPreference, 'morning');
    });

    test('constructor with null defaultTime and timeOfDayPreference', () {
      const stack = HabitStack(
        anchorId: 'anchor_1',
        habitId: 'habit_1',
      );
      expect(stack.anchorId, 'anchor_1');
      expect(stack.habitId, 'habit_1');
      expect(stack.defaultTime, null);
      expect(stack.timeOfDayPreference, null);
    });

    test('toMap/fromMap roundtrip', () {
      const stack = HabitStack(
        anchorId: 'anchor_1',
        habitId: 'habit_1',
        defaultTime: '08:00',
        timeOfDayPreference: 'morning',
      );
      final map = stack.toMap();
      final restored = HabitStack.fromMap(map);
      expect(restored.anchorId, 'anchor_1');
      expect(restored.habitId, 'habit_1');
      expect(restored.defaultTime, '08:00');
      expect(restored.timeOfDayPreference, 'morning');
    });

    test('toMap/fromMap roundtrip with null optionals', () {
      const stack = HabitStack(
        anchorId: 'anchor_1',
        habitId: 'habit_1',
      );
      final map = stack.toMap();
      final restored = HabitStack.fromMap(map);
      expect(restored.anchorId, 'anchor_1');
      expect(restored.habitId, 'habit_1');
      expect(restored.defaultTime, null);
      expect(restored.timeOfDayPreference, null);
    });
  });

  group('UserSettings', () {
    test('default constructor uses correct defaults', () {
      const settings = UserSettings();
      expect(settings.notificationsEnabled, true);
      expect(settings.healthKitConnected, false);
      expect(settings.screenTimeConnected, false);
      expect(settings.soundsEnabled, true);
      expect(settings.hapticsEnabled, true);
      expect(settings.habitReminders, true);
      expect(settings.streakWarnings, true);
      expect(settings.aiInsights, true);
      expect(settings.communityUpdates, false);
      expect(settings.rewardsUpdates, true);
      expect(settings.archetypeNudges, true);
      expect(settings.doNotDisturb, false);
    });

    test('toMap/fromMap roundtrip', () {
      const settings = UserSettings(
        notificationsEnabled: false,
        healthKitConnected: true,
        screenTimeConnected: true,
        soundsEnabled: false,
        hapticsEnabled: false,
        habitReminders: false,
        streakWarnings: false,
        aiInsights: false,
        communityUpdates: true,
        rewardsUpdates: false,
        archetypeNudges: false,
        doNotDisturb: true,
      );
      final map = settings.toMap();
      final restored = UserSettings.fromMap(map);
      expect(restored.notificationsEnabled, false);
      expect(restored.healthKitConnected, true);
      expect(restored.screenTimeConnected, true);
      expect(restored.soundsEnabled, false);
      expect(restored.hapticsEnabled, false);
      expect(restored.habitReminders, false);
      expect(restored.streakWarnings, false);
      expect(restored.aiInsights, false);
      expect(restored.communityUpdates, true);
      expect(restored.rewardsUpdates, false);
      expect(restored.archetypeNudges, false);
      expect(restored.doNotDisturb, true);
    });

    test('fromMap with missing keys uses correct defaults', () {
      final settings = UserSettings.fromMap({});
      expect(settings.notificationsEnabled, true);
      expect(settings.healthKitConnected, false);
      expect(settings.screenTimeConnected, false);
      expect(settings.soundsEnabled, true);
      expect(settings.hapticsEnabled, true);
      expect(settings.habitReminders, true);
      expect(settings.streakWarnings, true);
      expect(settings.aiInsights, true);
      expect(settings.communityUpdates, false);
      expect(settings.rewardsUpdates, true);
      expect(settings.archetypeNudges, true);
      expect(settings.doNotDisturb, false);
    });

    test('copyWith overrides individual fields', () {
      const settings = UserSettings(notificationsEnabled: true);
      final copied = settings.copyWith(notificationsEnabled: false);
      expect(copied.notificationsEnabled, false);
      expect(copied.soundsEnabled, true);
    });
  });

  group('UserProfile', () {
    test('deep constructor with all fields set', () {
      final createdAt = DateTime(2026, 1, 1);
      final startedAt = DateTime(2026, 1, 2);
      final completedAt = DateTime(2026, 1, 3);
      final worldLastActive = DateTime(2026, 6, 15);
      final profile = UserProfile(
        uid: 'user_1',
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
        archetype: UserArchetype.athlete,
        identityVotes: {'Runner': 10, 'Reader': 5},
        avatarStats: const UserAvatarStats(
          strengthXp: 100,
          level: 10,
          momentumScore: 85,
        ),
        worldState: UserWorldState(
          cityLevel: 3,
          entropy: 0.1,
          lastActiveDate: worldLastActive,
          worldTheme: WorldTheme.floatingRealm,
          seasonalState: WorldSeason.autumn,
        ),
        reframeMode: true,
        motive: 'Become stronger',
        dominantMotive: 'mastery',
        why: 'To be my best',
        anchors: ['anchor_1'],
        habitStacks: [
          const HabitStack(anchorId: 'a1', habitId: 'h1'),
        ],
        onboardingProgress: 3,
        skippedOnboardingSteps: ['archetype'],
        onboardingStartedAt: startedAt,
        onboardingCompletedAt: completedAt,
        equipment: ['sword', 'shield'],
        characterClass: 'warrior',
        avatar: const Avatar(
          bodyType: AvatarBodyType.feminine,
          skinTone: AvatarSkinTone.olive,
        ),
        worldTheme: 'forest',
        settings: const UserSettings(
          notificationsEnabled: false,
          soundsEnabled: false,
        ),
        accountCreatedAt: createdAt,
        hasEmerged: true,
        momentumScore: 0.8,
        totalHabitsCompleted: 50,
        totalChallengesCompleted: 10,
        totalQuestsCompleted: 5,
      );

      expect(profile.uid, 'user_1');
      expect(profile.displayName, 'Test User');
      expect(profile.photoUrl, 'https://example.com/photo.jpg');
      expect(profile.archetype, UserArchetype.athlete);
      expect(profile.identityVotes, {'Runner': 10, 'Reader': 5});
      expect(profile.avatarStats.strengthXp, 100);
      expect(profile.avatarStats.level, 10);
      expect(profile.worldState.cityLevel, 3);
      expect(profile.worldState.worldTheme, WorldTheme.floatingRealm);
      expect(profile.reframeMode, true);
      expect(profile.motive, 'Become stronger');
      expect(profile.dominantMotive, 'mastery');
      expect(profile.why, 'To be my best');
      expect(profile.anchors, ['anchor_1']);
      expect(profile.habitStacks.length, 1);
      expect(profile.habitStacks[0].anchorId, 'a1');
      expect(profile.onboardingProgress, 3);
      expect(profile.skippedOnboardingSteps, ['archetype']);
      expect(profile.onboardingStartedAt, startedAt);
      expect(profile.onboardingCompletedAt, completedAt);
      expect(profile.equipment, ['sword', 'shield']);
      expect(profile.characterClass, 'warrior');
      expect(profile.avatar.bodyType, AvatarBodyType.feminine);
      expect(profile.worldTheme, 'forest');
      expect(profile.settings.notificationsEnabled, false);
      expect(profile.settings.soundsEnabled, false);
      expect(profile.accountCreatedAt, createdAt);
      expect(profile.hasEmerged, true);
      expect(profile.momentumScore, 0.8);
      expect(profile.totalHabitsCompleted, 50);
      expect(profile.totalChallengesCompleted, 10);
      expect(profile.totalQuestsCompleted, 5);
    });

    test('default constructor uses correct defaults', () {
      final profile = UserProfile(uid: 'user_1');
      expect(profile.uid, 'user_1');
      expect(profile.archetype, UserArchetype.none);
      expect(profile.hasEmerged, false);
      expect(profile.momentumScore, 0.5);
      expect(profile.avatarStats.level, 1);
      expect(profile.reframeMode, false);
      expect(profile.onboardingProgress, 0);
    });

    test('effectiveLevel returns XP level when lowest', () {
      final profile = UserProfile(
        uid: 'user_1',
        avatarStats: const UserAvatarStats(level: 3),
        worldState: const UserWorldState(highestCompletedNodeLevel: 5),
        hasEmerged: true,
      );
      expect(profile.effectiveLevel, 3);
    });

    test('effectiveLevel caps at 5 when hasEmerged is false', () {
      final profile = UserProfile(
        uid: 'user_1',
        avatarStats: const UserAvatarStats(level: 10),
        worldState: const UserWorldState(highestCompletedNodeLevel: 10),
        hasEmerged: false,
      );
      expect(profile.effectiveLevel, 5);
    });

    test('effectiveLevel respects node gate when it is lowest', () {
      final profile = UserProfile(
        uid: 'user_1',
        avatarStats: const UserAvatarStats(level: 10),
        worldState: const UserWorldState(highestCompletedNodeLevel: 2),
        hasEmerged: true,
      );
      expect(profile.effectiveLevel, 3);
    });

    test('toMap/fromMap roundtrip with non-null optionals', () {
      final profile = UserProfile(
        uid: 'user_1',
        displayName: 'Test',
        photoUrl: 'https://example.com/photo.jpg',
        archetype: UserArchetype.creator,
        identityVotes: {'Artist': 3},
        avatarStats: const UserAvatarStats(
          strengthXp: 50,
          intellectXp: 30,
          level: 4,
          momentumScore: 60,
        ),
        worldState: const UserWorldState(
          cityLevel: 2,
          entropy: 0.2,
          worldTheme: WorldTheme.settlement,
        ),
        reframeMode: true,
        motive: 'Create',
        anchors: ['a1'],
        habitStacks: [
          const HabitStack(anchorId: 'a1', habitId: 'h1'),
        ],
        onboardingProgress: 2,
        settings: const UserSettings(
          notificationsEnabled: false,
          soundsEnabled: false,
        ),
        avatar: const Avatar(
          bodyType: AvatarBodyType.feminine,
          skinTone: AvatarSkinTone.tan,
        ),
        hasEmerged: true,
        momentumScore: 0.7,
        totalHabitsCompleted: 25,
      );

      final map = profile.toMap();
      final restored = UserProfile.fromMap(map);
      expect(restored.uid, 'user_1');
      expect(restored.displayName, 'Test');
      expect(restored.photoUrl, 'https://example.com/photo.jpg');
      expect(restored.archetype, UserArchetype.creator);
      expect(restored.identityVotes, {'Artist': 3});
      expect(restored.avatarStats.strengthXp, 50);
      expect(restored.avatarStats.level, 4);
      expect(restored.avatarStats.momentumScore, 60);
      expect(restored.worldState.cityLevel, 2);
      expect(restored.worldState.entropy, 0.2);
      expect(restored.worldState.worldTheme, WorldTheme.settlement);
      expect(restored.reframeMode, true);
      expect(restored.motive, 'Create');
      expect(restored.anchors, ['a1']);
      expect(restored.habitStacks.length, 1);
      expect(restored.habitStacks[0].anchorId, 'a1');
      expect(restored.onboardingProgress, 2);
      expect(restored.settings.notificationsEnabled, false);
      expect(restored.settings.soundsEnabled, false);
      expect(restored.avatar.bodyType, AvatarBodyType.feminine);
      expect(restored.hasEmerged, true);
      expect(restored.momentumScore, 0.7);
      expect(restored.totalHabitsCompleted, 25);
    });

    test('fromMap with empty map uses defaults', () {
      final profile = UserProfile.fromMap({});
      expect(profile.uid, '');
      expect(profile.archetype, UserArchetype.none);
      expect(profile.hasEmerged, false);
      expect(profile.momentumScore, 0.5);
      expect(profile.avatarStats.level, 1);
    });

    test('fromMap handles datetime fields as String ISO format', () {
      final map = {
        'uid': 'user_1',
        'onboardingStartedAt': '2026-01-02T00:00:00.000',
        'onboardingCompletedAt': '2026-01-03T00:00:00.000',
        'accountCreatedAt': '2026-01-01T00:00:00.000',
      };
      final profile = UserProfile.fromMap(map);
      expect(profile.onboardingStartedAt, DateTime(2026, 1, 2));
      expect(profile.onboardingCompletedAt, DateTime(2026, 1, 3));
      expect(profile.accountCreatedAt, DateTime(2026, 1, 1));
    });

    test('toFirestore converts DateTime to Timestamp', () {
      final startedAt = DateTime(2026, 1, 2);
      final completedAt = DateTime(2026, 1, 3);
      final createdAt = DateTime(2026, 1, 1);
      final worldLastActive = DateTime(2026, 6, 15);
      final profile = UserProfile(
        uid: 'user_1',
        onboardingStartedAt: startedAt,
        onboardingCompletedAt: completedAt,
        accountCreatedAt: createdAt,
        worldState: UserWorldState(lastActiveDate: worldLastActive),
      );
      final firestoreMap = profile.toFirestore();

      expect(firestoreMap['onboardingStartedAt'], isA<Timestamp>());
      expect((firestoreMap['onboardingStartedAt'] as Timestamp).toDate(), startedAt);

      expect(firestoreMap['onboardingCompletedAt'], isA<Timestamp>());
      expect((firestoreMap['onboardingCompletedAt'] as Timestamp).toDate(), completedAt);

      expect(firestoreMap['accountCreatedAt'], isA<Timestamp>());
      expect((firestoreMap['accountCreatedAt'] as Timestamp).toDate(), createdAt);

      final worldMap = firestoreMap['worldState'] as Map<String, dynamic>;
      expect(worldMap['lastActiveDate'], isA<Timestamp>());
      expect((worldMap['lastActiveDate'] as Timestamp).toDate(), worldLastActive);
    });

    test('copyWith overrides individual fields', () {
      final profile = UserProfile(
        uid: 'user_1',
        displayName: 'Original',
        archetype: UserArchetype.none,
      );
      final copied = profile.copyWith(
        displayName: 'Changed',
        archetype: UserArchetype.stoic,
      );
      expect(copied.uid, 'user_1');
      expect(copied.displayName, 'Changed');
      expect(copied.archetype, UserArchetype.stoic);
    });
  });
}
