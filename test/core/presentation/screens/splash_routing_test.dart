// Unit tests for the splash screen route decision logic.
//
// These test the pure `determineSplashRoute` function which decides
// where to send the user after the splash animation completes.

import 'package:emerge_app/core/presentation/screens/splash_screen.dart';
import 'package:emerge_app/features/auth/presentation/providers/role_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('determineSplashRoute', () {
    // 1. Not logged in.
    test('not logged in, first launch -> /welcome', () {
      expect(
        determineSplashRoute(
          isLoggedIn: false,
          isFirstLaunch: true,
          role: UserRole.unknown,
          hasCreatorProfile: false,
          creatorOnboarding: null,
          userOnboardingProgress: null,
          userOnboardingCompletedAt: null,
        ),
        '/welcome',
      );
    });

    test('not logged in, returning user -> /login', () {
      expect(
        determineSplashRoute(
          isLoggedIn: false,
          isFirstLaunch: false,
          role: UserRole.unknown,
          hasCreatorProfile: false,
          creatorOnboarding: null,
          userOnboardingProgress: null,
          userOnboardingCompletedAt: null,
        ),
        '/login',
      );
    });

    // 2. Creator with known role.
    test('role=creator, onboarding complete -> /creator/dashboard', () {
      expect(
        determineSplashRoute(
          isLoggedIn: true,
          isFirstLaunch: false,
          role: UserRole.creator,
          hasCreatorProfile: true,
          creatorOnboarding: const CreatorOnboardingState(
            progress: 3,
            isComplete: true,
            completedAt: null,
          ),
          userOnboardingProgress: null,
          userOnboardingCompletedAt: null,
        ),
        '/creator/dashboard',
      );
    });

    test('role=creator, progress=0 -> /onboarding/creator/archetype', () {
      expect(
        determineSplashRoute(
          isLoggedIn: true,
          isFirstLaunch: false,
          role: UserRole.creator,
          hasCreatorProfile: true,
          creatorOnboarding: CreatorOnboardingState.empty,
          userOnboardingProgress: null,
          userOnboardingCompletedAt: null,
        ),
        '/onboarding/creator/archetype',
      );
    });

    test('role=creator, progress=1 -> /onboarding/creator/profile', () {
      expect(
        determineSplashRoute(
          isLoggedIn: true,
          isFirstLaunch: false,
          role: UserRole.creator,
          hasCreatorProfile: true,
          creatorOnboarding: const CreatorOnboardingState(
            progress: 1,
            isComplete: false,
          ),
          userOnboardingProgress: null,
          userOnboardingCompletedAt: null,
        ),
        '/onboarding/creator/profile',
      );
    });

    test('role=creator, progress=2 -> /onboarding/creator/reveal', () {
      expect(
        determineSplashRoute(
          isLoggedIn: true,
          isFirstLaunch: false,
          role: UserRole.creator,
          hasCreatorProfile: true,
          creatorOnboarding: const CreatorOnboardingState(
            progress: 2,
            isComplete: false,
          ),
          userOnboardingProgress: null,
          userOnboardingCompletedAt: null,
        ),
        '/onboarding/creator/reveal',
      );
    });

    // 3. Unknown role but creator profile exists (the bug fix).
    test('role=unknown, hasCreatorProfile=true -> creator onboarding', () {
      expect(
        determineSplashRoute(
          isLoggedIn: true,
          isFirstLaunch: false,
          role: UserRole.unknown,
          hasCreatorProfile: true,
          creatorOnboarding: CreatorOnboardingState.empty,
          userOnboardingProgress: null,
          userOnboardingCompletedAt: null,
        ),
        '/onboarding/creator/archetype',
      );
    });

    test('role=unknown, hasCreatorProfile=true, complete -> /creator/dashboard',
        () {
      expect(
        determineSplashRoute(
          isLoggedIn: true,
          isFirstLaunch: false,
          role: UserRole.unknown,
          hasCreatorProfile: true,
          creatorOnboarding: const CreatorOnboardingState(
            progress: 3,
            isComplete: true,
          ),
          userOnboardingProgress: null,
          userOnboardingCompletedAt: null,
        ),
        '/creator/dashboard',
      );
    });

    // 4. Unknown role, no creator profile (true unknown) -> normal user flow.
    test('role=unknown, no creator profile, progress=0 -> identity-studio', () {
      expect(
        determineSplashRoute(
          isLoggedIn: true,
          isFirstLaunch: false,
          role: UserRole.unknown,
          hasCreatorProfile: false,
          creatorOnboarding: null,
          userOnboardingProgress: 0,
          userOnboardingCompletedAt: null,
        ),
        '/onboarding/identity-studio',
      );
    });

    test('role=unknown, no creator profile, progress=3 -> home', () {
      expect(
        determineSplashRoute(
          isLoggedIn: true,
          isFirstLaunch: false,
          role: UserRole.unknown,
          hasCreatorProfile: false,
          creatorOnboarding: null,
          userOnboardingProgress: 3,
          userOnboardingCompletedAt: null,
        ),
        '/',
      );
    });

    // 4b. Role=user but creator_profile exists (post-provider-fix scenario).
    test(
        'role=user, hasCreatorProfile=true, progress=0 -> creator archetype',
        () {
      expect(
        determineSplashRoute(
          isLoggedIn: true,
          isFirstLaunch: false,
          role: UserRole.user,
          hasCreatorProfile: true,
          creatorOnboarding: CreatorOnboardingState.empty,
          userOnboardingProgress: null,
          userOnboardingCompletedAt: null,
        ),
        '/onboarding/creator/archetype',
      );
    });

    test('role=user, hasCreatorProfile=true, complete -> /creator/dashboard',
        () {
      expect(
        determineSplashRoute(
          isLoggedIn: true,
          isFirstLaunch: false,
          role: UserRole.user,
          hasCreatorProfile: true,
          creatorOnboarding: const CreatorOnboardingState(
            progress: 3,
            isComplete: true,
          ),
          userOnboardingProgress: null,
          userOnboardingCompletedAt: null,
        ),
        '/creator/dashboard',
      );
    });

    // 5. Normal user (role=user).
    test('role=user, progress=0 -> /onboarding/identity-studio', () {
      expect(
        determineSplashRoute(
          isLoggedIn: true,
          isFirstLaunch: false,
          role: UserRole.user,
          hasCreatorProfile: false,
          creatorOnboarding: null,
          userOnboardingProgress: 0,
          userOnboardingCompletedAt: null,
        ),
        '/onboarding/identity-studio',
      );
    });

    test('role=user, progress=2 -> /onboarding/first-habit', () {
      expect(
        determineSplashRoute(
          isLoggedIn: true,
          isFirstLaunch: false,
          role: UserRole.user,
          hasCreatorProfile: false,
          creatorOnboarding: null,
          userOnboardingProgress: 2,
          userOnboardingCompletedAt: null,
        ),
        '/onboarding/first-habit',
      );
    });

    test('role=user, progress=3 -> / (home)', () {
      expect(
        determineSplashRoute(
          isLoggedIn: true,
          isFirstLaunch: false,
          role: UserRole.user,
          hasCreatorProfile: false,
          creatorOnboarding: null,
          userOnboardingProgress: 3,
          userOnboardingCompletedAt: null,
        ),
        '/',
      );
    });

    test('role=user, completedAt set -> / (home)', () {
      expect(
        determineSplashRoute(
          isLoggedIn: true,
          isFirstLaunch: false,
          role: UserRole.user,
          hasCreatorProfile: false,
          creatorOnboarding: null,
          userOnboardingProgress: 4,
          userOnboardingCompletedAt: DateTime(2026, 1, 1),
        ),
        '/',
      );
    });
  });
}
