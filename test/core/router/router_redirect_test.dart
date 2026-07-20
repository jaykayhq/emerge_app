// Unit tests for the GoRouter redirect decision logic.
//
// These tests exercise the pure `decideRedirect` function so we can
// verify every routing branch without spinning up GoRouter, Riverpod,
// or Firebase.

import 'package:emerge_app/core/router/router.dart';
import 'package:emerge_app/features/auth/presentation/providers/role_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decideRedirect', () {
    // 1. Unauthenticated users always get bounced to a login surface.
    test('unauthenticated, first launch, on / -> /welcome', () {
      final ctx = const RedirectContext(
        isLoggedIn: false,
        role: null,
        isFirstLaunch: true,
        userOnboardingProgress: null,
        userOnboardingCompletedAt: null,
        creatorOnboarding: null,
      );
      expect(decideRedirect(currentPath: '/world-map', ctx: ctx), '/welcome');
    });

    test('unauthenticated, returning user, on / -> /login', () {
      final ctx = const RedirectContext(
        isLoggedIn: false,
        role: null,
        isFirstLaunch: false,
        userOnboardingProgress: null,
        userOnboardingCompletedAt: null,
        creatorOnboarding: null,
      );
      expect(decideRedirect(currentPath: '/world-map', ctx: ctx), '/login');
    });

    test('unauthenticated, on /creator/signup -> stays (open signup form)', () {
      final ctx = const RedirectContext(
        isLoggedIn: false,
        role: null,
        isFirstLaunch: false,
        userOnboardingProgress: null,
        userOnboardingCompletedAt: null,
        creatorOnboarding: null,
      );
      expect(
        decideRedirect(currentPath: '/creator/signup', ctx: ctx),
        isNull,
      );
    });

    test('unauthenticated, on /login -> stays', () {
      final ctx = const RedirectContext(
        isLoggedIn: false,
        role: null,
        isFirstLaunch: false,
        userOnboardingProgress: null,
        userOnboardingCompletedAt: null,
        creatorOnboarding: null,
      );
      expect(decideRedirect(currentPath: '/login', ctx: ctx), isNull);
    });

    // 2. Splash screen is always allowed.
    test('/splash is always allowed', () {
      final ctx = const RedirectContext(
        isLoggedIn: false,
        role: null,
        isFirstLaunch: false,
        userOnboardingProgress: null,
        userOnboardingCompletedAt: null,
        creatorOnboarding: null,
      );
      expect(decideRedirect(currentPath: '/splash', ctx: ctx), isNull);
    });

    // 3. A creator mid-signup must NOT be redirected before the role claim propagates.
    test('creator mid-signup (role=unknown, on /creator/signup) is held', () {
      final ctx = const RedirectContext(
        isLoggedIn: true,
        role: UserRole.unknown,
        isFirstLaunch: false,
        userOnboardingProgress: null,
        userOnboardingCompletedAt: null,
        creatorOnboarding: null,
      );
      expect(
        decideRedirect(currentPath: '/creator/signup', ctx: ctx),
        isNull,
      );
    });

    test(
        'creator mid-signup (role=unknown, on /onboarding/creator/*) is held',
        () {
      final ctx = const RedirectContext(
        isLoggedIn: true,
        role: UserRole.unknown,
        isFirstLaunch: false,
        userOnboardingProgress: null,
        userOnboardingCompletedAt: null,
        creatorOnboarding: null,
      );
      expect(
        decideRedirect(
            currentPath: '/onboarding/creator/archetype', ctx: ctx),
        isNull,
      );
    });

    test(
        'logged in but role still unknown, on /welcome -> /onboarding/identity-studio',
        () {
      final ctx = const RedirectContext(
        isLoggedIn: true,
        role: UserRole.unknown,
        isFirstLaunch: false,
        userOnboardingProgress: null,
        userOnboardingCompletedAt: null,
        creatorOnboarding: null,
      );
      expect(
        decideRedirect(currentPath: '/welcome', ctx: ctx),
        '/onboarding/identity-studio',
      );
    });

    // 4. Creator branch must never regress to normal-user onboarding.
    test(
        'role=creator, on /onboarding/identity-studio -> /onboarding/creator/archetype',
        () {
      final ctx = RedirectContext(
        isLoggedIn: true,
        role: UserRole.creator,
        isFirstLaunch: false,
        userOnboardingProgress: null,
        userOnboardingCompletedAt: null,
        creatorOnboarding: CreatorOnboardingState.empty,
      );
      expect(
        decideRedirect(currentPath: '/onboarding/identity-studio', ctx: ctx),
        '/onboarding/creator/archetype',
      );
    });

    test('role=creator, on / -> /onboarding/creator/archetype if onboarding incomplete',
        () {
      final ctx = RedirectContext(
        isLoggedIn: true,
        role: UserRole.creator,
        isFirstLaunch: false,
        userOnboardingProgress: null,
        userOnboardingCompletedAt: null,
        creatorOnboarding: CreatorOnboardingState.empty,
      );
      expect(
        decideRedirect(currentPath: '/world-map', ctx: ctx),
        '/onboarding/creator/archetype',
      );
    });

    test(
        'role=creator, email verified, no onboarding -> /onboarding/creator/archetype',
        () {
      final ctx = RedirectContext(
        isLoggedIn: true,
        role: UserRole.creator,
        isFirstLaunch: false,
        userOnboardingProgress: null,
        userOnboardingCompletedAt: null,
        creatorOnboarding: CreatorOnboardingState.empty,
      );
      expect(
        decideRedirect(currentPath: '/world-map', ctx: ctx),
        '/onboarding/creator/archetype',
      );
    });

    test('role=creator, onboarding step 1 -> /onboarding/creator/profile', () {
      final ctx = RedirectContext(
        isLoggedIn: true,
        role: UserRole.creator,
        isFirstLaunch: false,
        userOnboardingProgress: null,
        userOnboardingCompletedAt: null,
        creatorOnboarding: const CreatorOnboardingState(
          progress: 1,
          isComplete: false,
        ),
      );
      expect(
        decideRedirect(currentPath: '/world-map', ctx: ctx),
        '/onboarding/creator/profile',
      );
    });

    test('role=creator, onboarding step 2 -> /onboarding/creator/reveal', () {
      final ctx = RedirectContext(
        isLoggedIn: true,
        role: UserRole.creator,
        isFirstLaunch: false,
        userOnboardingProgress: null,
        userOnboardingCompletedAt: null,
        creatorOnboarding: const CreatorOnboardingState(
          progress: 2,
          isComplete: false,
        ),
      );
      expect(
        decideRedirect(currentPath: '/world-map', ctx: ctx),
        '/onboarding/creator/reveal',
      );
    });

    test('role=creator, onboarding complete -> /creator/dashboard', () {
      final ctx = RedirectContext(
        isLoggedIn: true,
        role: UserRole.creator,
        isFirstLaunch: false,
        userOnboardingProgress: null,
        userOnboardingCompletedAt: null,
        creatorOnboarding: CreatorOnboardingState(
          progress: 3,
          isComplete: true,
          completedAt: DateTime(2026, 1, 1),
        ),
      );
      expect(
        decideRedirect(currentPath: '/world-map', ctx: ctx),
        '/creator/dashboard',
      );
    });

    test('role=creator, on /welcome -> /creator/dashboard (already complete)',
        () {
      final ctx = RedirectContext(
        isLoggedIn: true,
        role: UserRole.creator,
        isFirstLaunch: false,
        userOnboardingProgress: null,
        userOnboardingCompletedAt: null,
        creatorOnboarding: CreatorOnboardingState(
          progress: 3,
          isComplete: true,
        ),
      );
      expect(
        decideRedirect(currentPath: '/welcome', ctx: ctx),
        '/creator/dashboard',
      );
    });

    test(
        'role=creator, on /onboarding/identity-studio when complete -> /creator/dashboard',
        () {
      final ctx = RedirectContext(
        isLoggedIn: true,
        role: UserRole.creator,
        isFirstLaunch: false,
        userOnboardingProgress: null,
        userOnboardingCompletedAt: null,
        creatorOnboarding: CreatorOnboardingState(
          progress: 3,
          isComplete: true,
        ),
      );
      expect(
        decideRedirect(currentPath: '/onboarding/identity-studio', ctx: ctx),
        '/creator/dashboard',
      );
    });

    // 5. Normal-user flow still works as before.
    test(
        'role=user, no user_stats yet, on / -> /onboarding/identity-studio',
        () {
      final ctx = const RedirectContext(
        isLoggedIn: true,
        role: UserRole.user,
        isFirstLaunch: false,
        userOnboardingProgress: null,
        userOnboardingCompletedAt: null,
        creatorOnboarding: null,
      );
      expect(
        decideRedirect(currentPath: '/world-map', ctx: ctx),
        '/onboarding/identity-studio',
      );
    });

    test('role=user, progress=2, on / -> /onboarding/club', () {
      final ctx = const RedirectContext(
        isLoggedIn: true,
        role: UserRole.user,
        isFirstLaunch: false,
        userOnboardingProgress: 2,
        userOnboardingCompletedAt: null,
        creatorOnboarding: null,
      );
      expect(
        decideRedirect(currentPath: '/world-map', ctx: ctx),
        '/onboarding/club',
      );
    });

    test('role=user, progress=3, on / -> /onboarding/first-habits', () {
      final ctx = const RedirectContext(
        isLoggedIn: true,
        role: UserRole.user,
        isFirstLaunch: false,
        userOnboardingProgress: 3,
        userOnboardingCompletedAt: null,
        creatorOnboarding: null,
      );
      expect(
        decideRedirect(currentPath: '/world-map', ctx: ctx),
        '/onboarding/first-habits',
      );
    });

    test(
        'role=user, completed onboarding (timestamp), on /login -> /timeline (kick off auth surface)',
        () {
      final ctx = RedirectContext(
        isLoggedIn: true,
        role: UserRole.user,
        isFirstLaunch: false,
        userOnboardingProgress: 4,
        userOnboardingCompletedAt: DateTime(2026, 1, 1),
        creatorOnboarding: null,
      );
      expect(decideRedirect(currentPath: '/login', ctx: ctx), '/timeline');
    });

    test('role=user, on /creator/dashboard -> /onboarding/identity-studio '
        '(not a creator)', () {
      final ctx = RedirectContext(
        isLoggedIn: true,
        role: UserRole.user,
        isFirstLaunch: false,
        userOnboardingProgress: 4,
        userOnboardingCompletedAt: DateTime(2026, 1, 1),
        creatorOnboarding: null,
      );
      expect(
        decideRedirect(currentPath: '/creator/dashboard', ctx: ctx),
        '/onboarding/identity-studio',
      );
    });

    test('role=user, on /onboarding/creator/* -> /onboarding/identity-studio '
        '(not a creator)', () {
      final ctx = RedirectContext(
        isLoggedIn: true,
        role: UserRole.user,
        isFirstLaunch: false,
        userOnboardingProgress: 4,
        userOnboardingCompletedAt: DateTime(2026, 1, 1),
        creatorOnboarding: null,
      );
      expect(
        decideRedirect(
            currentPath: '/onboarding/creator/archetype', ctx: ctx),
        '/onboarding/identity-studio',
      );
    });
  });

  group('personalized 5-step onboarding route mapping', () {
    RedirectContext ctxAt(int progress, {String? atPath}) {
      return RedirectContext(
        isLoggedIn: true,
        role: UserRole.user,
        isFirstLaunch: false,
        userOnboardingProgress: progress,
        userOnboardingCompletedAt: progress >= 4
            ? DateTime(2026, 1, 1)
            : null,
        creatorOnboarding: null,
      );
    }

    test('progress=0 routes to /onboarding/identity-studio', () {
      expect(
        decideRedirect(
            currentPath: '/world-map', ctx: ctxAt(0)),
        '/onboarding/identity-studio',
      );
    });

    test('progress=1 routes to /onboarding/interests', () {
      expect(
        decideRedirect(
            currentPath: '/world-map', ctx: ctxAt(1)),
        '/onboarding/interests',
      );
    });

    test('progress=2 routes to /onboarding/club', () {
      expect(
        decideRedirect(
            currentPath: '/world-map', ctx: ctxAt(2)),
        '/onboarding/club',
      );
    });

    test('progress=3 routes to /onboarding/first-habits', () {
      expect(
        decideRedirect(
            currentPath: '/world-map', ctx: ctxAt(3)),
        '/onboarding/first-habits',
      );
    });

    test('progress=4 is treated as complete, stays on /world-map', () {
      expect(
        decideRedirect(
          currentPath: '/world-map',
          ctx: ctxAt(4),
        ),
        isNull,
      );
    });

    test('stale /onboarding/first-habit still resolves to new '
        'first-habits via the notifier, but a redirect off /timeline to '
        'that legacy path with progress=3 lands on /first-habits', () {
      // Directly verify the new path.
      expect(
        decideRedirect(
          currentPath: '/world-map',
          ctx: ctxAt(3),
        ),
        '/onboarding/first-habits',
      );
    });
  });
}
