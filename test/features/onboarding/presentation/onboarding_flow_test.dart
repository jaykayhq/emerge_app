import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/identity_studio_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/first_habit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockAuthUser extends Mock implements AuthUser {}

class MockUserProfile extends Mock implements UserProfile {}

void main() {
  group('Onboarding Flow Widget Tests', () {
    testWidgets('Walkthrough Identity Studio (Archetype -> Motive)', (
      tester,
    ) async {
      final mockAuthUser = const AuthUser(
        id: 'test-user',
        email: 'test@emerge.com',
        displayName: 'Test User',
      );

      final mockProfile = UserProfile(
        uid: 'test-user',
        archetype: UserArchetype.none,
        onboardingProgress: 0,
        avatarStats: const UserAvatarStats(level: 1),
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const IdentityStudioScreen(),
          ),
          GoRoute(
            path: '/onboarding/first-habit',
            builder: (context, state) =>
                const Scaffold(body: Text('Habit Screen Placeholder')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthUser),
            ),
            userStatsStreamProvider.overrideWith(
              (ref) => Stream.value(mockProfile),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // --- STEP 1: Archetype Selection ---
      expect(find.text('STEP 1 OF 3'), findsOneWidget);

      // Swipe more aggressively to ensure Scholar is visible
      // Use the inner PageView (at index 1) which is the archetype carousel
      await tester.drag(find.byType(PageView).at(1), const Offset(-600, 0));
      await tester.pumpAndSettle();

      // Tap SCHOLAR (using textContaining to be safe about case/whitespace)
      final scholarFinder = find.textContaining('SCHOLAR');
      expect(scholarFinder, findsWidgets);
      await tester.tap(scholarFinder.first);
      await tester.pumpAndSettle();

      // Tap "THIS IS ME" to go to Motive
      final thisIsMeBtn = find.text('THIS IS ME');
      expect(thisIsMeBtn, findsOneWidget);
      await tester.tap(thisIsMeBtn);
      await tester.pumpAndSettle();

      // --- STEP 2: Motive Selection ---
      expect(find.text('STEP 2 OF 3'), findsOneWidget);
      expect(find.text('What drives you?'), findsOneWidget);

      // Pick a suggestion (Scholar motives start with "I want to")
      final motiveSuggestion = find.textContaining('I want to').first;
      expect(motiveSuggestion, findsOneWidget);
      await tester.tap(motiveSuggestion);
      await tester.pumpAndSettle();

      // Wait a bit for the button fade-in animation
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      // Verify CONTINUE button is enabled
      final continueBtnMotive = find.text('CONTINUE');
      expect(continueBtnMotive, findsOneWidget);
      await tester.tap(continueBtnMotive);
      await tester.pumpAndSettle();

      // Verify we navigated to the next step (Placeholder should be visible)
      expect(find.text('Habit Screen Placeholder'), findsOneWidget);
    });

    testWidgets('FirstHabitScreen shows correct step and suggestions', (
      tester,
    ) async {
      final mockAuthUser = const AuthUser(
        id: 'test-user',
        email: 'test@emerge.com',
      );
      final mockProfile = UserProfile(
        uid: 'test-user',
        archetype: UserArchetype.scholar,
        onboardingProgress: 1,
        avatarStats: const UserAvatarStats(level: 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(mockAuthUser),
            ),
            userStatsStreamProvider.overrideWith(
              (ref) => Stream.value(mockProfile),
            ),
          ],
          child: const MaterialApp(home: FirstHabitScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // --- STEP 3: Habit Selection ---
      expect(find.text('STEP 3 OF 3'), findsOneWidget);
      expect(find.text('Your First Identity Vote'), findsOneWidget);
      // Fix: text is "becoming The Scholar"
      expect(
        find.textContaining(RegExp('becoming', caseSensitive: false)),
        findsWidgets,
      );
      expect(
        find.textContaining(RegExp('Scholar', caseSensitive: false)),
        findsWidgets,
      );
    });

    testWidgets(
      'Explorer archetype shows neutral message in FirstHabitScreen',
      (tester) async {
        final mockAuthUser = const AuthUser(
          id: 'test-user',
          email: 'test@emerge.com',
        );
        final mockProfile = UserProfile(
          uid: 'test-user',
          archetype: UserArchetype.none,
          onboardingProgress: 1,
          avatarStats: const UserAvatarStats(level: 1),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateChangesProvider.overrideWith(
                (ref) => Stream.value(mockAuthUser),
              ),
              userStatsStreamProvider.overrideWith(
                (ref) => Stream.value(mockProfile),
              ),
            ],
            child: const MaterialApp(home: FirstHabitScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.textContaining('No specific suggestions'), findsOneWidget);
      },
    );
  });
}
