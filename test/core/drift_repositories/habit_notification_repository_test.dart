import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/core/services/notification_service.dart';
import 'package:emerge_app/core/sync/sync_engine_barrel.dart';
import 'package:emerge_app/features/habits/data/repositories/habit_notification_repository.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/entities/habit_notification_schedule.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ignore_for_file: subtype_of_sealed_class

// Mock classes
class MockNotificationService extends Mock implements NotificationService {}

class MockFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockSyncEngine extends Mock implements EnhancedSyncEngine {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class FakeHabit extends Fake implements Habit {}

void main() {
  late HabitNotificationRepository repository;
  late MockNotificationService mockNotificationService;
  late MockFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late MockSyncEngine mockSyncEngine;
  late MockUser mockUser;

  const testUserId = 'test_user_123';

  Habit createTestHabit({
    String id = 'habit_001',
    String title = 'Morning Workout',
    HabitFrequency frequency = HabitFrequency.daily,
    List<int> specificDays = const [],
    HabitAttribute attribute = HabitAttribute.vitality,
  }) {
    return Habit(
      id: id,
      userId: testUserId,
      title: title,
      frequency: frequency,
      specificDays: specificDays,
      attribute: attribute,
      createdAt: DateTime.now(),
    );
  }

  setUpAll(() {
    registerFallbackValue(UserArchetype.athlete);
    registerFallbackValue(HabitFrequency.daily);
    registerFallbackValue(FakeHabit());
  });

  setUp(() {
    mockNotificationService = MockNotificationService();
    mockFirestore = MockFirestore();
    mockAuth = MockFirebaseAuth();
    mockSyncEngine = MockSyncEngine();
    mockUser = MockUser();

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn(testUserId);

    when(
      () => mockFirestore.collection(any()),
    ).thenReturn(MockCollectionReference());

    when(
      () => mockSyncEngine.enqueueSet(
        collectionPath: any(named: 'collectionPath'),
        documentId: any(named: 'documentId'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockSyncEngine.enqueueUpdate(
        collectionPath: any(named: 'collectionPath'),
        documentId: any(named: 'documentId'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockSyncEngine.enqueueMutation(
        collectionPath: any(named: 'collectionPath'),
        documentId: any(named: 'documentId'),
        operation: any(named: 'operation'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async {});

    repository = HabitNotificationRepository(
      notificationService: mockNotificationService,
      firestore: mockFirestore,
      auth: mockAuth,
      syncEngine: mockSyncEngine,
    );
  });

  group('HabitNotificationRepository', () {
    group('scheduleHabitNotifications', () {
      test('calls enqueueSet with correct collection path', () async {
        final mockDocRef = MockDocumentReference();
        final mockCollection = MockCollectionReference();
        final habit = createTestHabit();

        when(
          () => mockFirestore.collection('users'),
        ).thenReturn(mockCollection);
        when(() => mockCollection.doc(testUserId)).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async {
          final snapshot = MockDocumentSnapshot();
          when(() => snapshot.exists).thenReturn(false);
          return snapshot;
        });

        when(
          () => mockNotificationService.notifyHabitCreated(
            any(),
            any(),
            archetypeNudges: any(named: 'archetypeNudges'),
          ),
        ).thenAnswer((_) async {});

        when(
          () => mockNotificationService.scheduleHabitReminder(
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            attribute: any(named: 'attribute'),
            archetypeNudges: any(named: 'archetypeNudges'),
          ),
        ).thenAnswer((_) async {});

        await repository.scheduleHabitNotifications(
          habit,
          UserArchetype.athlete,
        );

        verify(
          () => mockSyncEngine.enqueueSet(
            collectionPath: 'users/$testUserId/notificationSchedules',
            documentId: habit.id,
            data: any(named: 'data'),
          ),
        ).called(1);
      });
    });

    group('updateHabitNotifications', () {
      test('calls enqueueUpdate with correct collection path', () async {
        final mockDocRef = MockDocumentReference();
        final mockCollection = MockCollectionReference();
        final habit = createTestHabit();

        when(
          () => mockFirestore.collection('users'),
        ).thenReturn(mockCollection);
        when(() => mockCollection.doc(testUserId)).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async {
          final snapshot = MockDocumentSnapshot();
          when(() => snapshot.exists).thenReturn(false);
          return snapshot;
        });

        when(
          () => mockNotificationService.updateHabitNotification(
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            attribute: any(named: 'attribute'),
            archetypeNudges: any(named: 'archetypeNudges'),
          ),
        ).thenAnswer((_) async {});

        await repository.updateHabitNotifications(
          habit,
          UserArchetype.scholar,
        );

        verify(
          () => mockSyncEngine.enqueueUpdate(
            collectionPath: 'users/$testUserId/notificationSchedules',
            documentId: habit.id,
            data: any(named: 'data'),
          ),
        ).called(1);
      });
    });

    group('cancelHabitNotifications', () {
      test('calls enqueueMutation with delete operation', () async {
        final habitId = 'habit_to_cancel';

        when(
          () => mockNotificationService.cancelHabitNotifications(any()),
        ).thenAnswer((_) async {});

        await repository.cancelHabitNotifications(habitId);

        verify(
          () => mockSyncEngine.enqueueMutation(
            collectionPath: 'users/$testUserId/notificationSchedules',
            documentId: habitId,
            operation: 'delete',
          ),
        ).called(1);
      });

      test('returns early when user is null', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        await repository.cancelHabitNotifications('habit_001');

        verifyNever(
          () => mockSyncEngine.enqueueMutation(
            collectionPath: any(named: 'collectionPath'),
            documentId: any(named: 'documentId'),
            operation: any(named: 'operation'),
          ),
        );
      });
    });

    group('getNotificationSchedules', () {
      test('returns stream of schedules from firestore', () async {
        final mockCollection = MockCollectionReference();
        final mockDocRef = MockDocumentReference();
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockQueryDocSnapshot = MockQueryDocumentSnapshot();

        final scheduleData = {
          'habitId': 'habit_001',
          'userId': testUserId,
          'archetype': 'athlete',
          'reminderTime': '08:00',
          'frequency': 'daily',
          'specificDays': <int>[],
          'welcomeNotified': true,
          'enabled': true,
          'streakWarningCount': 0,
          'createdAt': DateTime.now().toIso8601String(),
        };

        when(
          () => mockFirestore.collection('users'),
        ).thenReturn(mockCollection);
        when(() => mockCollection.doc(testUserId)).thenReturn(mockDocRef);
        when(
          () => mockDocRef.collection('notificationSchedules'),
        ).thenReturn(mockCollection);
        when(() => mockCollection.snapshots()).thenAnswer((_) {
          return Stream.value(mockQuerySnapshot);
        });
        when(() => mockQuerySnapshot.docs).thenReturn([mockQueryDocSnapshot]);
        when(() => mockQueryDocSnapshot.data()).thenReturn(scheduleData);

        await expectLater(
          repository.getNotificationSchedules(),
          emits(
            predicate<List<HabitNotificationSchedule>>(
              (schedules) =>
                  schedules.length == 1 &&
                  schedules.first.habitId == 'habit_001',
            ),
          ),
        );
      });

      test('returns empty stream when user is null', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        await expectLater(
          repository.getNotificationSchedules(),
          emits(equals([])),
        );
      });
    });

    group('scheduleStreakWarning', () {
      test('calls notification service with correct parameters', () async {
        when(
          () => mockNotificationService.scheduleStreakWarning(
            any(),
            any(),
            any(),
            any(),
            any(),
          ),
        ).thenAnswer((_) async {});

        await repository.scheduleStreakWarning(
          'habit_001',
          'Morning Workout',
          UserArchetype.stoic,
          '07:00',
          5,
        );

        verify(
          () => mockNotificationService.scheduleStreakWarning(
            'habit_001',
            'Morning Workout',
            UserArchetype.stoic,
            '07:00',
            5,
          ),
        ).called(1);
      });
    });

    group('notifyLevelUp', () {
      test('calls notification service with correct parameters', () async {
        when(
          () => mockNotificationService.notifyLevelUp(
            any(),
            any(),
            any(),
          ),
        ).thenAnswer((_) async {});

        await repository.notifyLevelUp(5, UserArchetype.creator);

        verify(
          () => mockNotificationService.notifyLevelUp(
            testUserId,
            5,
            UserArchetype.creator,
          ),
        ).called(1);
      });

      test('returns early when user is null', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        await repository.notifyLevelUp(5, UserArchetype.creator);

        verifyNever(
          () => mockNotificationService.notifyLevelUp(
            any(),
            any(),
            any(),
          ),
        );
      });
    });

    group('notifyAchievement', () {
      test('calls notification service with correct parameters', () async {
        when(
          () => mockNotificationService.notifyAchievement(
            any(),
            any(),
            any(),
          ),
        ).thenAnswer((_) async {});

        await repository.notifyAchievement(
          'first_habit',
          UserArchetype.athlete,
        );

        verify(
          () => mockNotificationService.notifyAchievement(
            testUserId,
            'first_habit',
            UserArchetype.athlete,
          ),
        ).called(1);
      });

      test('returns early when user is null', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        await repository.notifyAchievement(
          'first_habit',
          UserArchetype.athlete,
        );

        verifyNever(
          () => mockNotificationService.notifyAchievement(
            any(),
            any(),
            any(),
          ),
        );
      });
    });
  });
}
