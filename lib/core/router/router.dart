import 'package:emerge_app/core/presentation/screens/splash_screen.dart';
import 'package:emerge_app/core/presentation/screens/world_splash_screen.dart';
import 'package:emerge_app/core/presentation/widgets/scaffold_with_nav_bar.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/screens/login_screen.dart';
import 'package:emerge_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/world_map/presentation/screens/world_map_screen.dart';
import 'package:emerge_app/features/timeline/presentation/screens/timeline_screen.dart';
import 'package:emerge_app/features/ai/presentation/screens/goldilocks_screen.dart';
import 'package:emerge_app/features/gamification/presentation/screens/leveling_screen.dart';
import 'package:emerge_app/features/profile/presentation/screens/future_self_studio_screen.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/level_up_listener.dart';
import 'package:emerge_app/features/habits/presentation/screens/advanced_create_habit_screen.dart';
import 'package:emerge_app/features/habits/presentation/screens/environment_priming_screen.dart';
import 'package:emerge_app/features/gamification/presentation/screens/weekly_recap_screen.dart';
import 'package:emerge_app/features/insights/presentation/screens/recap_screen.dart';
import 'package:emerge_app/features/ai/presentation/screens/ai_reflections_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/first_habit_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/identity_studio_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/world_reveal_screen.dart';
import 'package:emerge_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:emerge_app/features/settings/presentation/screens/notification_settings_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/accountability_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/community_challenges_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/community_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

// Global navigator key - must be defined outside the provider to prevent duplication
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

@riverpod
GoRouter router(Ref ref) {
  // Create a ValueNotifier to trigger router refreshes
  final refreshNotifier = ValueNotifier<int>(0);

  // Listen to all dependencies that should trigger a redirect
  ref.listen(authStateChangesProvider, (_, __) => refreshNotifier.value++);
  ref.listen(onboardingControllerProvider, (_, __) => refreshNotifier.value++);
  ref.listen(userStatsStreamProvider, (_, __) => refreshNotifier.value++);

  // Dispose the notifier when the provider is disposed
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      // Use ref.read to get the current state without registering a dependency for the provider itself
      final authState = ref.read(authStateChangesProvider);
      final isFirstLaunch = ref.read(onboardingControllerProvider);

      final isLoggedIn = authState.valueOrNull?.isNotEmpty ?? false;
      final isLoggingIn = state.uri.path == '/login';
      final isSigningUp = state.uri.path == '/signup';
      final isWelcome = state.uri.path == '/welcome';
      final isSplash = state.uri.path == '/splash';
      final isOnboardingPath = state.uri.path.startsWith('/onboarding');

      debugPrint(
        'Router Redirect: path=${state.uri.path}, isLoggedIn=$isLoggedIn, isFirstLaunch=$isFirstLaunch',
      );

      if (isSplash) return null; // Allow splash to run its course

      // 1. Handle onboarding paths - always allow if user is logged in
      if (isOnboardingPath) {
        if (isLoggedIn) {
          debugPrint('Router: Allowing onboarding path for logged in user');
          return null;
        }
        // If not logged in, redirect to welcome/login
        if (!isLoggedIn) {
          debugPrint('Router: Redirecting to /welcome (need to login first)');
          return '/welcome';
        }
      }

      // 2. First Launch (not logged in): Force Welcome Screen
      if (isFirstLaunch && !isLoggedIn) {
        // Allow access to welcome, login, and signup pages
        if (isWelcome || isLoggingIn || isSigningUp) {
          debugPrint(
            'Router: Allowing access to ${state.uri.path} during first launch',
          );
          return null;
        }
        debugPrint('Router: Redirecting to /welcome (First Launch)');
        return '/welcome';
      }

      // 3. Not Logged In: Force Login
      if (!isLoggedIn) {
        if (isLoggingIn || isSigningUp || isWelcome) {
          return null;
        }
        debugPrint('Router: Redirecting to /login (Not Logged In)');
        return '/login';
      }

      // 4. Logged In: Check if onboarding is complete
      if (isLoggedIn) {
        // If user is authenticated but trying to access auth/welcome screens, check onboarding
        if (isLoggingIn || isSigningUp || isWelcome) {
          // Redirect to onboarding if not complete, otherwise home
          final userProfileAsync = ref.read(userStatsStreamProvider);
          final userProfile = userProfileAsync.valueOrNull;
          final onboardingProgress = userProfile?.onboardingProgress ?? 0;

          if (onboardingProgress < 3) {
            final nextStep = _getOnboardingRouteForProgress(onboardingProgress);
            debugPrint(
              'Router: Redirecting to $nextStep (Incomplete onboarding)',
            );
            return nextStep;
          }

          debugPrint('Router: Redirecting to / (Home) from ${state.uri.path}');
          return '/';
        }

        // If trying to access home/dashboard but onboarding is incomplete, redirect to onboarding
        if (state.uri.path == '/' || state.uri.path.isEmpty) {
          // Check local onboarding state first (more reliable than Firestore)
          final isOnboardingComplete = !isFirstLaunch;

          debugPrint('Router: isOnboardingComplete=$isOnboardingComplete');

          // If local state says onboarding is complete, allow access
          if (isOnboardingComplete) {
            debugPrint(
              'Router: Onboarding complete (local state), allowing access',
            );
            return null;
          }

          // Otherwise check Firestore profile as fallback
          final userProfileAsync = ref.read(userStatsStreamProvider);

          // If profile is still loading, allow access (we'll redirect later when loaded)
          if (userProfileAsync.isLoading) {
            debugPrint('Router: Profile loading, allowing temporary access');
            return null;
          }

          final userProfile = userProfileAsync.valueOrNull;
          final onboardingProgress = userProfile?.onboardingProgress ?? 0;

          debugPrint('Router: onboardingProgress=$onboardingProgress');

          // If onboarding is not complete (progress < 5), redirect to the next step
          if (onboardingProgress < 3) {
            final nextStep = _getOnboardingRouteForProgress(onboardingProgress);
            debugPrint(
              'Router: Redirecting to $nextStep (Incomplete onboarding)',
            );
            return nextStep;
          }
        }

        // Allow all other paths for authenticated users who completed onboarding
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/world-splash',
        builder: (context, state) => const WorldSplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
        routes: [
          // New simplified onboarding flow (3 steps)
          GoRoute(
            path: 'identity-studio',
            builder: (context, state) => const IdentityStudioScreen(),
          ),
          GoRoute(
            path: 'first-habit',
            builder: (context, state) => const FirstHabitScreen(),
          ),
          GoRoute(
            path: 'world-reveal',
            builder: (context, state) => const WorldRevealScreen(),
          ),
        ],
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      // Add root-level create-habit route for FAB access
      GoRoute(
        path: '/create-habit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdvancedCreateHabitScreen(),
      ),
      // ShellRoute for Bottom Navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return LevelUpListener(
            child: ScaffoldWithNavBar(navigationShell: navigationShell),
          );
        },
        branches: [
          // Branch 1: World (Gamification) - NEW HOME
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const WorldMapScreen(),
                routes: [
                  GoRoute(
                    path: 'recap',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const WeeklyRecapScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Branch 2: Timeline (NEW)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/timeline',
                builder: (context, state) => const TimelineScreen(),
              ),
            ],
          ),
          // Branch 3: Community
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                builder: (context, state) => const CommunityScreen(),
                routes: [
                  GoRoute(
                    path: 'challenges',
                    builder: (context, state) =>
                        const CommunityChallengesScreen(),
                  ),
                  GoRoute(
                    path: 'accountability',
                    builder: (context, state) => const AccountabilityScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Branch 4: Profile & Insights (Future Self Studio)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const FutureSelfStudioScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const SettingsScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        const NotificationSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'priming',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        const EnvironmentPrimingScreen(),
                  ),
                  GoRoute(
                    path: 'recap',
                    builder: (context, state) => const RecapScreen(),
                  ),
                  GoRoute(
                    path: 'reflections',
                    builder: (context, state) => const AiReflectionsScreen(),
                  ),
                  GoRoute(
                    path: 'leveling',
                    builder: (context, state) => const LevelingScreen(),
                  ),
                  GoRoute(
                    path: 'goldilocks',
                    builder: (context, state) => const GoldilocksScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Helper function to get the onboarding route for a given progress level
/// New flow: 0 = identity-studio, 1 = first-habit, 2 = world-reveal, 3+ = complete
String _getOnboardingRouteForProgress(int progress) {
  switch (progress) {
    case 0:
      return '/onboarding/identity-studio';
    case 1:
      return '/onboarding/first-habit';
    case 2:
      return '/onboarding/world-reveal';
    default:
      return '/'; // All onboarding complete, go to world
  }
}
