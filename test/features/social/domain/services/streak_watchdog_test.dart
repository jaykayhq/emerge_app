import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/drift/daos/habit_completions_dao.dart';
import 'package:emerge_app/core/domain/entities/app_notification.dart';
import 'package:emerge_app/features/social/domain/services/streak_watchdog.dart';
import 'package:emerge_app/features/social/domain/repositories/friend_repository.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:emerge_app/core/services/social_notification_service.dart';

class MockFriendRepo extends Mock implements FriendRepository {}
class MockHabitCompletionsDao extends Mock implements HabitCompletionsDao {}
class MockNotificationService extends Mock implements SocialNotificationService {}

class FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  late StreakWatchdog watchdog;
  late MockFriendRepo mockFriendRepo;
  late MockHabitCompletionsDao mockDao;
  late MockNotificationService mockNotification;

  setUpAll(() {
    registerFallbackValue(
      AppNotification(
        id: '',
        type: AppNotificationType.tribeActivity,
        title: '',
        body: '',
        createdAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockFriendRepo = MockFriendRepo();
    mockDao = MockHabitCompletionsDao();
    mockNotification = MockNotificationService();
    watchdog = StreakWatchdog(
      friendRepo: mockFriendRepo,
      habitCompletionsDao: mockDao,
      notificationService: mockNotification,
    );
  });

  group('checkPartners', () {
    test('notifies when partner missed 2+ days', () async {
      when(() => mockFriendRepo.getFriends('user1'))
          .thenAnswer((_) async => [
            Friend(id: 'partner1', name: 'Partner1', archetype: FriendArchetype.athlete),
          ]);
      when(() => mockDao.getLastCompletion('partner1'))
          .thenAnswer((_) async => HabitCompletionsTableData(
                id: 'c1',
                habitId: 'h1',
                userId: 'partner1',
                completedAt: DateTime.now()
                    .subtract(const Duration(days: 3))
                    .toIso8601String(),
                xpGained: 0,
                streakDay: 0,
                wasRecovery: 0,
              ));
      when(() => mockNotification.sendNotification(any(), any()))
          .thenAnswer((_) async => FakeDocumentReference());

      await watchdog.checkPartners(userId: 'user1', tribeId: 't1');

      verify(() => mockNotification.sendNotification(any(), any())).called(1);
    });

    test('does not notify when partner completed today', () async {
      when(() => mockFriendRepo.getFriends('user1'))
          .thenAnswer((_) async => [
            Friend(id: 'partner1', name: 'Partner1', archetype: FriendArchetype.athlete),
          ]);
      when(() => mockDao.getLastCompletion('partner1'))
          .thenAnswer((_) async => HabitCompletionsTableData(
                id: 'c1',
                habitId: 'h1',
                userId: 'partner1',
                completedAt: DateTime.now().toIso8601String(),
                xpGained: 0,
                streakDay: 0,
                wasRecovery: 0,
              ));

      await watchdog.checkPartners(userId: 'user1', tribeId: 't1');

      verifyNever(() => mockNotification.sendNotification(any(), any()));
    });

    test('rate-limiter suppresses duplicate within 24h', () async {
      when(() => mockFriendRepo.getFriends('user1'))
          .thenAnswer((_) async => [
            Friend(id: 'partner1', name: 'Partner1', archetype: FriendArchetype.athlete),
          ]);
      when(() => mockDao.getLastCompletion('partner1'))
          .thenAnswer((_) async => HabitCompletionsTableData(
                id: 'c1',
                habitId: 'h1',
                userId: 'partner1',
                completedAt: DateTime.now()
                    .subtract(const Duration(days: 3))
                    .toIso8601String(),
                xpGained: 0,
                streakDay: 0,
                wasRecovery: 0,
              ));
      when(() => mockNotification.sendNotification(any(), any()))
          .thenAnswer((_) async => FakeDocumentReference());

      await watchdog.checkPartners(userId: 'user1', tribeId: 't1');
      await watchdog.checkPartners(userId: 'user1', tribeId: 't1');

      verify(() => mockNotification.sendNotification(any(), any())).called(1);
    });

    test('skips partner with no completions', () async {
      when(() => mockFriendRepo.getFriends('user1'))
          .thenAnswer((_) async => [
            Friend(id: 'partner1', name: 'Partner1', archetype: FriendArchetype.athlete),
          ]);
      when(() => mockDao.getLastCompletion('partner1'))
          .thenAnswer((_) async => null);

      await watchdog.checkPartners(userId: 'user1', tribeId: 't1');

      verifyNever(() => mockNotification.sendNotification(any(), any()));
    });
  });
}
