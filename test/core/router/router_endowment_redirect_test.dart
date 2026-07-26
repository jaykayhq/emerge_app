// Unit tests for the endowment-interstitial gating in the redirect logic.
//
// New users (onboarding progress 0) who have NOT yet seen the one-time
// endowment interstitial are routed to it; once seen, they proceed to
// archetype selection. Existing branches are covered in
// router_redirect_test.dart.

import 'package:emerge_app/core/router/router.dart';
import 'package:emerge_app/features/auth/presentation/providers/role_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decideRedirect — endowment interstitial gating', () {
    RedirectContext ctxWith({required bool hasSeenEndowment, int? progress}) {
      return RedirectContext(
        isLoggedIn: true,
        role: UserRole.user,
        isFirstLaunch: false,
        userOnboardingProgress: progress,
        userOnboardingCompletedAt: null,
        creatorOnboarding: null,
        hasSeenEndowment: hasSeenEndowment,
      );
    }

    test('progress=0, endowment NOT seen -> /onboarding/endowment', () {
      expect(
        decideRedirect(
          currentPath: '/world-map',
          ctx: ctxWith(hasSeenEndowment: false, progress: 0),
        ),
        '/onboarding/endowment',
      );
    });

    test('progress=null, endowment NOT seen -> /onboarding/endowment', () {
      expect(
        decideRedirect(
          currentPath: '/world-map',
          ctx: ctxWith(hasSeenEndowment: false, progress: null),
        ),
        '/onboarding/endowment',
      );
    });

    test('progress=0, endowment seen -> /onboarding/identity-studio', () {
      expect(
        decideRedirect(
          currentPath: '/world-map',
          ctx: ctxWith(hasSeenEndowment: true, progress: 0),
        ),
        '/onboarding/identity-studio',
      );
    });

    test('endowment screen itself is allowed through (no redirect loop)', () {
      expect(
        decideRedirect(
          currentPath: '/onboarding/endowment',
          ctx: ctxWith(hasSeenEndowment: false, progress: 0),
        ),
        isNull,
      );
    });
  });
}
