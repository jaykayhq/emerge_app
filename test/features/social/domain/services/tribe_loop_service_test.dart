import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/core/services/event_bus.dart';
import 'package:emerge_app/core/game_loop/game_loop_result.dart';
import 'package:emerge_app/features/social/domain/services/tribe_loop_service.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:emerge_app/features/social/domain/services/streak_watchdog.dart';

class MockSocialActivity extends Mock implements SocialActivityService {}
class MockStreakWatchdog extends Mock implements StreakWatchdog {}

void main() {
  late TribeLoopService service;
  late MockSocialActivity mockSocial;
  late MockStreakWatchdog mockWatchdog;

  setUp(() {
    mockSocial = MockSocialActivity();
    mockWatchdog = MockStreakWatchdog();

    when(() => mockSocial.logStreakMilestone(
      userId: any(named: 'userId'),
      userName: any(named: 'userName'),
      archetype: any(named: 'archetype'),
      streakDays: any(named: 'streakDays'),
    )).thenAnswer((_) async {});

    when(() => mockSocial.logLevelUp(
      userId: any(named: 'userId'),
      userName: any(named: 'userName'),
      archetype: any(named: 'archetype'),
      newLevel: any(named: 'newLevel'),
      totalXp: any(named: 'totalXp'),
    )).thenAnswer((_) async {});

    when(() => mockWatchdog.checkPartners(
      userId: any(named: 'userId'),
      tribeId: any(named: 'tribeId'),
    )).thenAnswer((_) async {});

    service = TribeLoopService(
      socialActivity: mockSocial,
      streakWatchdog: mockWatchdog,
      driftSyncer: null,
    );
  });

  tearDown(() {
    service.dispose();
  });

  HabitCompleted _event({
    int newStreak = 1,
    int newLevel = 5,
    int previousLevel = 5,
    String? tribeId = 't1',
  }) {
    return HabitCompleted(
      habitId: 'h1',
      userId: 'u1',
      date: DateTime.now(),
      gameLoopResult: GameLoopResult(
        newStreak: newStreak,
        longestStreak: newStreak,
        xpGained: 10,
        attribute: 'strength',
        newLevel: newLevel,
        newTotalXp: 500,
        newMomentumScore: 10,
        newConsecutiveMisses: 0,
        isRecovery: false,
        worldHealthDelta: 0.1,
        challengeUpdates: {},
      ),
      previousLevel: previousLevel,
      tribeId: tribeId,
      archetype: 'athlete',
      userName: 'User1',
    );
  }

  test('streak milestone 7 calls logStreakMilestone', () async {
    await service.onHabitCompleted(_event(newStreak: 7));
    verify(() => mockSocial.logStreakMilestone(
      userId: any(named: 'userId'),
      userName: any(named: 'userName'),
      archetype: any(named: 'archetype'),
      streakDays: 7,
    )).called(1);
  });

  test('streak 14 calls logStreakMilestone', () async {
    await service.onHabitCompleted(_event(newStreak: 14));
    verify(() => mockSocial.logStreakMilestone(
      userId: any(named: 'userId'),
      userName: any(named: 'userName'),
      archetype: any(named: 'archetype'),
      streakDays: 14,
    )).called(1);
  });

  test('non-milestone streak does not log', () async {
    await service.onHabitCompleted(_event(newStreak: 3));
    verifyNever(() => mockSocial.logStreakMilestone(
      userId: any(named: 'userId'),
      userName: any(named: 'userName'),
      archetype: any(named: 'archetype'),
      streakDays: any(named: 'streakDays'),
    ));
  });

  test('level up calls logLevelUp', () async {
    await service.onHabitCompleted(_event(newLevel: 6, previousLevel: 5));
    verify(() => mockSocial.logLevelUp(
      userId: any(named: 'userId'),
      userName: any(named: 'userName'),
      archetype: any(named: 'archetype'),
      newLevel: 6,
      totalXp: any(named: 'totalXp'),
    )).called(1);
  });

  test('no level change does not call logLevelUp', () async {
    await service.onHabitCompleted(_event(newLevel: 5, previousLevel: 5));
    verifyNever(() => mockSocial.logLevelUp(
      userId: any(named: 'userId'),
      userName: any(named: 'userName'),
      archetype: any(named: 'archetype'),
      newLevel: any(named: 'newLevel'),
      totalXp: any(named: 'totalXp'),
    ));
  });

  test('calls StreakWatchdog on habit completion', () async {
    await service.onHabitCompleted(_event());
    verify(() => mockWatchdog.checkPartners(userId: 'u1', tribeId: 't1')).called(1);
  });
}
