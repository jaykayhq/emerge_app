import 'package:emerge_app/core/presentation/screens/splash_screen.dart';
import 'package:emerge_app/core/presentation/widgets/scaffold_with_nav_bar.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/screens/login_screen.dart';
import 'package:emerge_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/gamification/presentation/screens/creator_blueprints_screen.dart';
import 'package:emerge_app/features/gamification/presentation/screens/growing_world_screen.dart';
import 'package:emerge_app/features/ai/presentation/screens/goldilocks_screen.dart';
import 'package:emerge_app/features/gamification/presentation/screens/leveling_screen.dart';
import 'package:emerge_app/features/gamification/presentation/screens/avatar_customization_screen.dart';
import 'package:emerge_app/features/gamification/presentation/screens/user_profile_screen.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/level_up_listener.dart';
import 'package:emerge_app/features/habits/presentation/screens/advanced_create_habit_screen.dart';
import 'package:emerge_app/features/habits/presentation/screens/habit_builder_screen.dart';
import 'package:emerge_app/features/habits/presentation/screens/environment_priming_screen.dart';
import 'package:emerge_app/features/home/presentation/screens/gatekeeper_screen.dart';
import 'package:emerge_app/features/home/presentation/screens/home_screen.dart';
import 'package:emerge_app/features/home/presentation/screens/two_minute_timer_screen.dart';
import 'package:emerge_app/features/gamification/presentation/screens/weekly_recap_screen.dart';
import 'package:emerge_app/features/gamification/presentation/screens/daily_report_screen.dart';
import 'package:emerge_app/features/gamification/presentation/screens/building_placement_screen.dart';
import 'package:emerge_app/features/gamification/presentation/screens/land_expansion_screen.dart';
import 'package:emerge_app/features/insights/presentation/screens/recap_screen.dart';
import 'package:emerge_app/features/ai/presentation/screens/ai_reflections_screen.dart';
import 'package:emerge_app/features/monetization/presentation/screens/paywall_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/habit_anchors_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/habit_stacking_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/identity_attributes_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/integrate_why_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/onboarding_archetype_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:emerge_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:emerge_app/features/settings/presentation/screens/notification_settings_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/accountability_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/community_challenges_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/tribes_screen.dart';
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

          if (onboardingProgress < 5) {
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
          if (onboardingProgress < 5) {
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
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
        routes: [
          GoRoute(
            path: 'archetype',
            builder: (context, state) => const OnboardingArchetypeScreen(),
          ),
          GoRoute(
            path: 'attributes',
            builder: (context, state) => const IdentityAttributesScreen(),
          ),
          GoRoute(
            path: 'why',
            builder: (context, state) => const IntegrateWhyScreen(),
          ),
          GoRoute(
            path: 'anchors',
            builder: (context, state) => const HabitAnchorsScreen(),
          ),
          GoRoute(
            path: 'stacking',
            builder: (context, state) => const HabitStackingScreen(),
          ),
        ],
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
          // Branch 1: Habits (Home)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'create-habit',
                    parentNavigatorKey: _rootNavigatorKey, // Hide bottom nav
                    builder: (context, state) =>
                        const AdvancedCreateHabitScreen(),
                  ),
                  GoRoute(
                    path: 'two-minute-timer',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const TwoMinuteTimerScreen(),
                  ),
                  GoRoute(
                    path: 'gatekeeper',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const GatekeeperScreen(),
                  ),
                  GoRoute(
                    path: 'paywall',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const PaywallScreen(),
                  ),
                  GoRoute(
                    path: 'habit-builder',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const HabitBuilderScreen(),
                  ),
                  GoRoute(
                    path: 'blueprints',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        const CreatorBlueprintsScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Branch 2: World (Gamification)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/world',
                builder: (context, state) => const GrowingWorldScreen(),
                routes: [
                  GoRoute(
                    path: 'recap',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const WeeklyRecapScreen(),
                  ),
                  GoRoute(
                    path: 'daily-report',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const DailyReportScreen(),
                  ),
                  GoRoute(
                    path: 'build',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        const BuildingPlacementScreen(),
                  ),
                  GoRoute(
                    path: 'expand',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const LandExpansionScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Branch 3: Tribes & Social
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tribes',
                builder: (context, state) => const TribesScreen(),
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
          // Branch 4: Profile & Insights
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const UserProfileScreen(),
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
                  GoRoute(
                    path: 'avatar',
                    builder: (context, state) =>
                        const AvatarCustomizationScreen(),
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
String _getOnboardingRouteForProgress(int progress) {
  switch (progress) {
    case 0:
      return '/onboarding/archetype';
    case 1:
      return '/onboarding/attributes';
    case 2:
      return '/onboarding/why';
    case 3:
      return '/onboarding/anchors';
    case 4:
      return '/onboarding/stacking';
    default:
      return '/'; // All onboarding complete, go to dashboard
  }
}
