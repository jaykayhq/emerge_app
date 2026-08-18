import 'package:emerge_app/core/router/router.dart';
import 'package:emerge_app/features/auth/presentation/providers/role_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    'decideRedirect — simplified onboarding redirect (no endowment gate)',
    () {
      RedirectContext ctxWith({required int? progress}) {
        return RedirectContext(
          isLoggedIn: true,
          role: UserRole.user,
          isFirstLaunch: false,
          userOnboardingProgress: progress,
          userOnboardingCompletedAt: null,
          creatorOnboarding: null,
        );
      }

      test('progress=0 -> /onboarding/identity-studio', () {
        expect(
          decideRedirect(currentPath: '/world-map', ctx: ctxWith(progress: 0)),
          '/onboarding/identity-studio',
        );
      });

      test('progress=null -> /onboarding/identity-studio', () {
        expect(
          decideRedirect(
            currentPath: '/world-map',
            ctx: ctxWith(progress: null),
          ),
          '/onboarding/identity-studio',
        );
      });

      test('progress=1 -> /onboarding/interests', () {
        expect(
          decideRedirect(currentPath: '/world-map', ctx: ctxWith(progress: 1)),
          '/onboarding/interests',
        );
      });

      test('onboarding screen path returns null (no redirect loop)', () {
        expect(
          decideRedirect(
            currentPath: '/onboarding/identity-studio',
            ctx: ctxWith(progress: 0),
          ),
          isNull,
        );
      });
    },
  );
}
