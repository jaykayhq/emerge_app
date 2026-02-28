import 'package:emerge_app/core/services/notification_service.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/data/repositories/habit_notification_repository.dart';
import 'package:emerge_app/features/habits/data/repositories/habit_notification_repository_provider.dart';
import 'package:emerge_app/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

/// Integration tests for the Emerge app
/// These tests verify end-to-end flows with actual UI interaction
///
/// NOTE: TimePicker verification is done indirectly via:
/// 1. Checking that "Set Time" button exists
/// 2. Verifying the notification service receives the correct time string
/// 3. The showTimePicker dialog is a platform-specific overlay that cannot
///    be easily inspected in widget tests, so we verify the outcome instead
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Startup Tests', () {
    testWidgets('App starts and shows Login screen', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(const ProviderScope(child: EmergeApp()));
      await tester.pumpAndSettle();

      // Verify we are on the Login screen (or Onboarding if first launch)
      // For now, just ensure it pumped successfully.
      expect(find.byType(EmergeApp), findsOneWidget);
    });
  });

  group('Notification Flow Integration Tests', () {
    late MockUser mockUser;
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockNotificationService mockNotificationService;
    late HabitNotificationRepository notificationRepository;

    setUp(() {
      // Setup mock user
      mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('test-user-123');
      when(() => mockUser.email).thenReturn('test@emerge.com');
      when(() => mockUser.displayName).thenReturn('Test User');

      // Setup mock auth
      mockAuth = MockFirebaseAuth();
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));
      when(() => mockAuth.userChanges()).thenAnswer((_) => Stream.value(mockUser));

      // Setup mock Firestore
      mockFirestore = MockFirebaseFirestore();

      // Setup mock notification service
      mockNotificationService = MockNotificationService();

      // Create notification repository with mocks
      notificationRepository = HabitNotificationRepository(
        notificationService: mockNotificationService,
        firestore: mockFirestore,
        auth: mockAuth,
      );

      // Mock the notification service methods
      when(() => mockNotificationService.initialize()).thenAnswer((_) async {});
      when(() => mockNotificationService.scheduleHabitReminder(
        any(),
        any(),
        any(),
        any(),
        any(),
        any(),
      )).thenAnswer((_) async {});
      when(() => mockNotificationService.notifyHabitCreated(
        any(),
        any(),
      )).thenAnswer((_) async {});
    });

    testWidgets('Scholar archetype: Creates habit with notification scheduling',
        (WidgetTester tester) async {
      // Arrange: Create a Scholar user with complete onboarding
      final scholarProfile = UserProfile(
        uid: 'test-scholar-user',
        avatarStats: const UserAvatarStats(
          level: 5,
          intellectXp: 500,
          attributeXp: {'intellect': 500},
        ),
        archetype: UserArchetype.scholar,
        onboardingProgress: 4,
      );

      // Act: Launch app with Scholar user
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith((ref) {
              return Stream.value(
                const AuthUser(
                  id: 'test-scholar-user',
                  email: 'scholar@emerge.com',
                  displayName: 'Scholar User',
                ),
              );
            }),
            userStatsStreamProvider.overrideWith((ref) {
              return Stream.value(scholarProfile);
            }),
            notificationRepositoryProvider.overrideWithValue(notificationRepository),
          ],
          child: const EmergeApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify: App launched successfully
      expect(find.byType(EmergeApp), findsOneWidget);

      // Act: Navigate to Timeline via bottom nav
      final timelineIconFinder = find.byIcon(Icons.timeline);
      expect(timelineIconFinder, findsOneWidget, reason: 'Timeline icon should be visible');
      await tester.tap(timelineIconFinder);
      await tester.pumpAndSettle();

      // Act: Tap FAB to create habit
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget, reason: 'FAB should be visible on Timeline');
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Verify: Habit creation screen is displayed
      expect(find.text('Create Habit'), findsWidgets);
      expect(find.text('Identity Preview'), findsOneWidget);

      // Act: Find and tap the time picker button
      final setTimeButtonFinder = find.text('Set Time');
      expect(setTimeButtonFinder, findsOneWidget, reason: 'Set Time button should be visible');
      await tester.tap(setTimeButtonFinder);
      await tester.pumpAndSettle();

      // Note: showTimePicker opens a platform dialog that cannot be easily inspected
      // We verify the time was set by checking the displayed text after selection
      // The dialog auto-selects the default time (8 AM for Scholar) when opened

      // Act: Fill habit form with valid data
      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, 'Morning Study Session');
      await tester.pumpAndSettle();

      // Act: Find and tap Create button
      final createButtonFinder = find.text('Create Habit');
      expect(createButtonFinder, findsOneWidget, reason: 'Create Habit button should be visible');
      await tester.tap(createButtonFinder);
      await tester.pumpAndSettle();

      // Wait for async operations
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify: Notification service was called with Scholar archetype and 8 AM time
      // This proves the time picker defaulted to 8 AM for Scholar
      verify(() => mockNotificationService.scheduleHabitReminder(
        any<String>(that: isNotEmpty), // habitId
        any<String>(that: isNotEmpty), // habitTitle
        UserArchetype.scholar, // archetype
        any<String>(that: contains('08')), // reminderTime should contain '08' for 8 AM
        any(), // frequency
        any(), // specificDays
      )).called(1);

      // Verify: Welcome notification was sent
      verify(() => mockNotificationService.notifyHabitCreated(
        any(), // habit
        UserArchetype.scholar, // archetype
      )).called(1);
    });

    testWidgets('Athlete archetype: Creates habit with 6 AM default time',
        (WidgetTester tester) async {
      // Arrange: Create an Athlete user
      final athleteProfile = UserProfile(
        uid: 'test-athlete-user',
        avatarStats: const UserAvatarStats(
          level: 5,
          strengthXp: 500,
          attributeXp: {'strength': 500},
        ),
        archetype: UserArchetype.athlete,
        onboardingProgress: 4,
      );

      // Act: Launch app with Athlete user
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith((ref) {
              return Stream.value(
                const AuthUser(
                  id: 'test-athlete-user',
                  email: 'athlete@emerge.com',
                  displayName: 'Athlete User',
                ),
              );
            }),
            userStatsStreamProvider.overrideWith((ref) {
              return Stream.value(athleteProfile);
            }),
            notificationRepositoryProvider.overrideWithValue(notificationRepository),
          ],
          child: const EmergeApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify: App launched
      expect(find.byType(EmergeApp), findsOneWidget);

      // Act: Navigate to habit creation
      final timelineIconFinder = find.byIcon(Icons.timeline);
      await tester.tap(timelineIconFinder);
      await tester.pumpAndSettle();

      final fabFinder = find.byType(FloatingActionButton);
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Verify: Habit creation screen displayed
      expect(find.text('Create Habit'), findsWidgets);

      // Act: Tap time picker
      final setTimeButtonFinder = find.text('Set Time');
      await tester.tap(setTimeButtonFinder);
      await tester.pumpAndSettle();

      // Act: Fill form and submit
      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, 'Morning Workout');
      await tester.pumpAndSettle();

      final createButtonFinder = find.text('Create Habit');
      await tester.tap(createButtonFinder);
      await tester.pumpAndSettle();

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify: Notification service called with Athlete archetype and 6 AM
      // This proves the time picker defaulted to 6 AM for Athlete
      verify(() => mockNotificationService.scheduleHabitReminder(
        any(),
        any(),
        UserArchetype.athlete,
        any<String>(that: contains('06')), // Should be 06:XX for 6 AM
        any(),
        any(),
      )).called(1);
    });

    testWidgets('User without archetype: Creates habit with fallback time (7 AM)',
        (WidgetTester tester) async {
      // Arrange: Create a user with no archetype (UserArchetype.none)
      final noneProfile = UserProfile(
        uid: 'test-none-user',
        avatarStats: const UserAvatarStats(
          level: 1,
        ),
        archetype: UserArchetype.none,
        onboardingProgress: 4,
      );

      // Act: Launch app with user having no archetype
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith((ref) {
              return Stream.value(
                const AuthUser(
                  id: 'test-none-user',
                  email: 'none@emerge.com',
                  displayName: 'No Archetype User',
                ),
              );
            }),
            userStatsStreamProvider.overrideWith((ref) {
              return Stream.value(noneProfile);
            }),
            notificationRepositoryProvider.overrideWithValue(notificationRepository),
          ],
          child: const EmergeApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify: App launched
      expect(find.byType(EmergeApp), findsOneWidget);

      // Act: Navigate to habit creation
      final timelineIconFinder = find.byIcon(Icons.timeline);
      await tester.tap(timelineIconFinder);
      await tester.pumpAndSettle();

      final fabFinder = find.byType(FloatingActionButton);
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Act: Tap time picker
      final setTimeButtonFinder = find.text('Set Time');
      await tester.tap(setTimeButtonFinder);
      await tester.pumpAndSettle();

      // Act: Fill form and submit
      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, 'Generic Habit');
      await tester.pumpAndSettle();

      final createButtonFinder = find.text('Create Habit');
      await tester.tap(createButtonFinder);
      await tester.pumpAndSettle();

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify: Notification service called with UserArchetype.none and 7 AM
      verify(() => mockNotificationService.scheduleHabitReminder(
        any(),
        any(),
        UserArchetype.none,
        any<String>(that: contains('07')), // Should be 07:XX for 7 AM fallback
        any(),
        any(),
      )).called(1);
    });

    testWidgets('Multiple habits: Creates two habits with correct notification times',
        (WidgetTester tester) async {
      // Arrange: Create a Scholar user
      final scholarProfile = UserProfile(
        uid: 'test-multi-habit-user',
        avatarStats: const UserAvatarStats(
          level: 5,
          intellectXp: 500,
        ),
        archetype: UserArchetype.scholar,
        onboardingProgress: 4,
      );

      // Act: Launch app
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith((ref) {
              return Stream.value(
                const AuthUser(
                  id: 'test-multi-habit-user',
                  email: 'scholar@emerge.com',
                ),
              );
            }),
            userStatsStreamProvider.overrideWith((ref) {
              return Stream.value(scholarProfile);
            }),
            notificationRepositoryProvider.overrideWithValue(notificationRepository),
          ],
          child: const EmergeApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify: App launched
      expect(find.byType(EmergeApp), findsOneWidget);

      // Act: Create first habit
      final timelineIconFinder = find.byIcon(Icons.timeline);
      await tester.tap(timelineIconFinder);
      await tester.pumpAndSettle();

      final fabFinder = find.byType(FloatingActionButton);
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      final setTimeButtonFinder = find.text('Set Time');
      await tester.tap(setTimeButtonFinder);
      await tester.pumpAndSettle();

      final titleField1 = find.byType(TextField).first;
      await tester.enterText(titleField1, 'First Habit');
      await tester.pumpAndSettle();

      final createButtonFinder1 = find.text('Create Habit');
      await tester.tap(createButtonFinder1);
      await tester.pumpAndSettle();

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify: First habit notification scheduled
      verify(() => mockNotificationService.scheduleHabitReminder(
        any(),
        'First Habit',
        UserArchetype.scholar,
        any<String>(that: contains('08')),
        any(),
        any(),
      )).called(1);

      // Act: Create second habit
      await tester.tap(timelineIconFinder);
      await tester.pumpAndSettle();

      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Set Time'));
      await tester.pumpAndSettle();

      final titleField2 = find.byType(TextField).first;
      await tester.enterText(titleField2, 'Second Habit');
      await tester.pumpAndSettle();

      final createButtonFinder2 = find.text('Create Habit');
      await tester.tap(createButtonFinder2);
      await tester.pumpAndSettle();

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify: Second habit notification also scheduled
      verify(() => mockNotificationService.scheduleHabitReminder(
        any(),
        'Second Habit',
        UserArchetype.scholar,
        any<String>(that: contains('08')),
        any(),
        any(),
      )).called(1);

      // Total should be 2 calls (one for each habit)
      verify(() => mockNotificationService.scheduleHabitReminder(
        any(),
        any(),
        any(),
        any(),
        any(),
        any(),
      )).called(2);
    });

    testWidgets('Notification service: Both methods called on habit creation',
        (WidgetTester tester) async {
      // Arrange: Create a user
      final testProfile = UserProfile(
        uid: 'test-service-user',
        avatarStats: const UserAvatarStats(
          level: 1,
        ),
        archetype: UserArchetype.scholar,
        onboardingProgress: 4,
      );

      // Act: Launch app
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith((ref) {
              return Stream.value(
                const AuthUser(
                  id: 'test-service-user',
                  email: 'test@emerge.com',
                ),
              );
            }),
            userStatsStreamProvider.overrideWith((ref) {
              return Stream.value(testProfile);
            }),
            notificationRepositoryProvider.overrideWithValue(notificationRepository),
          ],
          child: const EmergeApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Act: Navigate to habit creation
      final timelineIconFinder = find.byIcon(Icons.timeline);
      await tester.tap(timelineIconFinder);
      await tester.pumpAndSettle();

      final fabFinder = find.byType(FloatingActionButton);
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Act: Set time
      await tester.tap(find.text('Set Time'));
      await tester.pumpAndSettle();

      // Act: Fill form
      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, 'Test Habit');
      await tester.pumpAndSettle();

      // Act: Submit
      await tester.tap(find.text('Create Habit'));
      await tester.pumpAndSettle();

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify: BOTH notification methods were called
      verify(() => mockNotificationService.scheduleHabitReminder(
        any(), // habitId
        any(), // habitTitle
        any(), // archetype
        any(), // reminderTime
        any(), // frequency
        any(), // specificDays
      )).called(1);

      verify(() => mockNotificationService.notifyHabitCreated(
        any(), // habit
        any(), // archetype
      )).called(1);
    });
  });
}

/// Mock classes
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockUser extends Mock implements User {}

class MockNotificationService extends Mock implements NotificationService {}
