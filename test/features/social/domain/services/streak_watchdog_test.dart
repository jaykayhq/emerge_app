import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emerge_app/core/drift/app_database.dart';
import 'package:emerge_app/core/drift/daos/habit_completions_dao.dart';
import 'package:emerge_app/core/drift/daos/tribe_membership_dao.dart';
import 'package:emerge_app/core/domain/entities/app_notification.dart';
import 'package:emerge_app/features/social/domain/services/streak_watchdog.dart';
import 'package:emerge_app/features/social/domain/repositories/friend_repository.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:emerge_app/core/services/social_notification_service.dart';

class MockFriendRepo extends Mock implements FriendRepository {}
class MockHabitCompletionsDao extends Mock implements HabitCompletionsDao {}
class MockNotificationService extends Mock implements SocialNotificationService {}
class MockTribeMembershipDao extends Mock implements TribeMembershipDao {}

final _fakeFirestore = FakeFirebaseFirestore();

void main() {
  late StreakWatchdog watchdog;
  late MockFriendRepo mockFriendRepo;
  late MockHabitCompletionsDao mockDao;
  late MockNotificationService mockNotification;
  late MockTribeMembershipDao mockTribeMembership;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
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
    SharedPreferences.setMockInitialValues({});
    mockFriendRepo = MockFriendRepo();
    mockDao = MockHabitCompletionsDao();
    mockNotification = MockNotificationService();
    mockTribeMembership = MockTribeMembershipDao();
    watchdog = StreakWatchdog(
      friendRepo: mockFriendRepo,
      habitCompletionsDao: mockDao,
      notificationService: mockNotification,
      tribeMembershipDao: mockTribeMembership,
    );
  });

  group('checkPartners', () {
    test('notifies when partner missed 2+ days', () async {
      when(() => mockTribeMembership.getMembership('partner1', 't1'))
          .thenAnswer((_) async => UserTribeTableData(
                userId: 'partner1',
                tribeId: 't1',
                membershipType: 'archetype',
                joinedAt: DateTime.now().toIso8601String(),
                isActive: true,
              ));
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
                challengeXp: 0,
              ));
      when(() => mockNotification.sendNotification(any(), any()))
          .thenAnswer((_) async => _fakeFirestore.collection('_').doc());

      await watchdog.checkPartners(userId: 'user1', tribeId: 't1');

      verify(() => mockNotification.sendNotification(any(), any())).called(1);
    });

    test('does not notify when partner completed today', () async {
      when(() => mockTribeMembership.getMembership('partner1', 't1'))
          .thenAnswer((_) async => UserTribeTableData(
                userId: 'partner1',
                tribeId: 't1',
                membershipType: 'archetype',
                joinedAt: DateTime.now().toIso8601String(),
                isActive: true,
              ));
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
                challengeXp: 0,
              ));

      await watchdog.checkPartners(userId: 'user1', tribeId: 't1');

      verifyNever(() => mockNotification.sendNotification(any(), any()));
    });

    test('rate-limiter suppresses duplicate within 24h', () async {
      when(() => mockTribeMembership.getMembership('partner1', 't1'))
          .thenAnswer((_) async => UserTribeTableData(
                userId: 'partner1',
                tribeId: 't1',
                membershipType: 'archetype',
                joinedAt: DateTime.now().toIso8601String(),
                isActive: true,
              ));
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
                challengeXp: 0,
              ));
      when(() => mockNotification.sendNotification(any(), any()))
          .thenAnswer((_) async => _fakeFirestore.collection('_').doc());

      await watchdog.checkPartners(userId: 'user1', tribeId: 't1');
      await watchdog.checkPartners(userId: 'user1', tribeId: 't1');

      verify(() => mockNotification.sendNotification(any(), any())).called(1);
    });

    test('skips partner with no completions', () async {
      when(() => mockTribeMembership.getMembership('partner1', 't1'))
          .thenAnswer((_) async => UserTribeTableData(
                userId: 'partner1',
                tribeId: 't1',
                membershipType: 'archetype',
                joinedAt: DateTime.now().toIso8601String(),
                isActive: true,
              ));
      when(() => mockFriendRepo.getFriends('user1'))
          .thenAnswer((_) async => [
            Friend(id: 'partner1', name: 'Partner1', archetype: FriendArchetype.athlete),
          ]);
      when(() => mockDao.getLastCompletion('partner1'))
          .thenAnswer((_) async => null);

      await watchdog.checkPartners(userId: 'user1', tribeId: 't1');

      verifyNever(() => mockNotification.sendNotification(any(), any()));
    });

    test('skips partner not in the same tribe', () async {
      when(() => mockTribeMembership.getMembership('partner1', 't1'))
          .thenAnswer((_) async => null);
      when(() => mockFriendRepo.getFriends('user1'))
          .thenAnswer((_) async => [
            Friend(id: 'partner1', name: 'Partner1', archetype: FriendArchetype.athlete),
          ]);

      await watchdog.checkPartners(userId: 'user1', tribeId: 't1');

      verifyNever(() => mockDao.getLastCompletion(any()));
      verifyNever(() => mockNotification.sendNotification(any(), any()));
    });
  });
}
