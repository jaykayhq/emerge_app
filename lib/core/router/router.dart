import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/core/presentation/screens/splash_screen.dart';
import 'package:emerge_app/core/presentation/screens/world_splash_screen.dart';
import 'package:emerge_app/core/presentation/widgets/scaffold_with_nav_bar.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/screens/login_screen.dart';
import 'package:emerge_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/gamification/presentation/screens/level_up_reward_screen.dart';
import 'package:emerge_app/features/world_map/presentation/screens/world_map_screen.dart';
import 'package:emerge_app/features/timeline/presentation/screens/timeline_screen.dart';
import 'package:emerge_app/features/ai/presentation/screens/goldilocks_screen.dart';
import 'package:emerge_app/features/gamification/presentation/screens/leveling_screen.dart';
import 'package:emerge_app/features/profile/presentation/screens/future_self_studio_screen.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/level_up_listener.dart';
import 'package:emerge_app/features/habits/presentation/screens/advanced_create_habit_screen.dart';
import 'package:emerge_app/features/habits/presentation/screens/habit_detail_screen.dart';
import 'package:emerge_app/features/habits/presentation/screens/environment_priming_screen.dart';
import 'package:emerge_app/features/gamification/presentation/screens/weekly_recap_screen.dart';
import 'package:emerge_app/features/insights/presentation/screens/recap_screen.dart';
import 'package:emerge_app/features/ai/presentation/screens/ai_reflections_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/first_habit_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/identity_studio_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/map_identity_attributes_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/world_reveal_screen.dart';
import 'package:emerge_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:emerge_app/features/settings/presentation/screens/notification_settings_screen.dart';
import 'package:emerge_app/features/monetization/presentation/screens/paywall_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/coming_soon_screen.dart';
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
      final path = state.uri.path;

      // Always allow splash screen to run its course
      if (path == '/splash') return null;

      final authState = ref.read(authStateChangesProvider);
      final isLoggedIn = authState.valueOrNull?.isNotEmpty ?? false;
      final isFirstLaunch = ref.read(onboardingControllerProvider);

      // Define path guards
      final isWelcome = path == '/welcome';
      final isLogin = path == '/login';
      final isSignup = path == '/signup';
      final isOnboardingPath = path.startsWith('/onboarding');
      final isAuthScreen = isWelcome || isLogin || isSignup;

      AppLogger.d(
        'Router Redirect: path=$path, isLoggedIn=$isLoggedIn, isFirstLaunch=$isFirstLaunch',
      );

      // NOT LOGGED IN: Only allow welcome/login/signup
      if (!isLoggedIn) {
        if (isAuthScreen) return null;
        // First time users go to welcome, returning users go to login
        return isFirstLaunch ? '/welcome' : '/login';
      }

      // LOGGED IN: Check onboarding progress
      final userStatsAsync = ref.read(userStatsStreamProvider);
      final userStats = userStatsAsync.valueOrNull;

      // If user stats are still loading, allow current path only if it's an onboarding path
      // This prevents landing on the dashboard briefly for new users
      if (userStats == null || userStatsAsync.isLoading) {
        if (isOnboardingPath) {
          return null;
        }

        // For returning users (not first launch on device), allow dashboard/tabs while loading
        // For new users, wait for user stats to determine actual onboarding status
        if (!isFirstLaunch) {
          if (path == '/' ||
              path == '/timeline' ||
              path == '/community' ||
              path == '/profile') {
            return null;
          }
        }
        // Don't redirect for new users - wait for user stats to load
        return null;
      }

      final onboardingProgress = userStats.onboardingProgress;
      final isOnboardingComplete = onboardingProgress >= 4;

      AppLogger.d(
        'Router: onboardingProgress=$onboardingProgress, isOnboardingComplete=$isOnboardingComplete, path=$path',
      );

      // If onboarding is incomplete, only allow onboarding paths
      if (!isOnboardingComplete) {
        if (isOnboardingPath) {
          // Allow ALL onboarding paths - don't redirect while in onboarding flow
          // This prevents the redirect loop
          return null;
        }
        // Redirect to the appropriate onboarding step
        return _getOnboardingRouteForProgress(onboardingProgress);
      }

      // Onboarding complete: Allow all paths, redirect auth screens to home
      if (isAuthScreen) return '/';

      // Allow all other paths for authenticated users with complete onboarding
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
      // Onboarding routes - removed the old OnboardingScreen
      GoRoute(
        path: '/onboarding/identity-studio',
        builder: (context, state) => const IdentityStudioScreen(),
      ),
      GoRoute(
        path: '/onboarding/map-attributes',
        builder: (context, state) => const MapIdentityAttributesScreen(),
      ),
      GoRoute(
        path: '/onboarding/first-habit',
        builder: (context, state) => const FirstHabitScreen(),
      ),
      GoRoute(
        path: '/onboarding/world-reveal',
        builder: (context, state) => const WorldRevealScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
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
                routes: [
                  GoRoute(
                    path: 'create-habit',
                    builder: (context, state) =>
                        const AdvancedCreateHabitScreen(),
                  ),
                  GoRoute(
                    path: 'detail/:habitId',
                    builder: (context, state) {
                      final habitId = state.pathParameters['habitId']!;
                      return HabitDetailScreen(habitId: habitId);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 3: Community (Coming Soon)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                builder: (context, state) => const ComingSoonScreen(),
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
                    path: 'level-up-reward/:level',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final level =
                          int.tryParse(state.pathParameters['level'] ?? '1') ??
                          1;
                      return LevelUpRewardScreen(celebratedLevel: level);
                    },
                  ),
                  GoRoute(
                    path: 'goldilocks',
                    builder: (context, state) => const GoldilocksScreen(),
                  ),
                  GoRoute(
                    path: 'paywall',
                    builder: (context, state) => const PaywallScreen(),
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
/// New flow: 0 = identity-studio, 1 = map-attributes, 2 = first-habit, 3 = world-reveal, 4+ = complete
String _getOnboardingRouteForProgress(int progress) {
  switch (progress) {
    case 0:
      return '/onboarding/identity-studio';
    case 1:
      return '/onboarding/map-attributes';
    case 2:
      return '/onboarding/first-habit';
    case 3:
      return '/onboarding/world-reveal';
    default:
      return '/'; // All onboarding complete, go to world
  }
}
