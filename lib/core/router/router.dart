import 'package:emerge_app/core/presentation/screens/splash_screen.dart';
import 'package:emerge_app/core/presentation/widgets/scaffold_with_nav_bar.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/screens/login_screen.dart';
import 'package:emerge_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/gamification/presentation/screens/creator_blueprints_screen.dart';
import 'package:emerge_app/features/gamification/presentation/screens/evolving_forest_screen.dart';
import 'package:emerge_app/features/ai/presentation/screens/goldilocks_screen.dart';
import 'package:emerge_app/features/gamification/presentation/screens/leveling_screen.dart';
import 'package:emerge_app/features/gamification/presentation/screens/avatar_customization_screen.dart';
import 'package:emerge_app/features/gamification/presentation/screens/user_profile_screen.dart';
import 'package:emerge_app/features/habits/presentation/screens/advanced_create_habit_screen.dart';
import 'package:emerge_app/features/habits/presentation/screens/habit_builder_screen.dart';
import 'package:emerge_app/features/habits/presentation/screens/environment_priming_screen.dart';
import 'package:emerge_app/features/home/presentation/screens/gatekeeper_screen.dart';
import 'package:emerge_app/features/home/presentation/screens/home_screen.dart';
import 'package:emerge_app/features/home/presentation/screens/two_minute_timer_screen.dart';
import 'package:emerge_app/features/gamification/presentation/screens/cinematic_recap_screen.dart';
import 'package:emerge_app/features/insights/presentation/screens/recap_screen.dart';
import 'package:emerge_app/features/ai/presentation/screens/ai_reflections_screen.dart';
import 'package:emerge_app/features/monetization/presentation/screens/paywall_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/habit_anchors_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/habit_stacking_screen.dart';
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

  // Define the navigator keys
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
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

      debugPrint(
        'Router Redirect: path=${state.uri.path}, isLoggedIn=$isLoggedIn, isFirstLaunch=$isFirstLaunch',
      );

      if (isSplash) return null; // Allow splash to run its course

      // 1. First Launch: Force Welcome Screen
      if (isFirstLaunch) {
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

      // 2. Not Logged In: Force Login (or Signup/Welcome if they are navigating there)
      if (!isLoggedIn) {
        if (isLoggingIn || isSigningUp || isWelcome) {
          return null;
        }
        debugPrint('Router: Redirecting to /login (Not Logged In)');
        return '/login';
      }

      // 3. Logged In: Check Profile
      if (isLoggedIn) {
        final userProfileAsync = ref.read(userStatsStreamProvider);

        // If profile is loading, wait
        if (userProfileAsync.isLoading) {
          debugPrint('Router: Profile loading, staying put');
          return null;
        }

        final userProfile = userProfileAsync.valueOrNull;

        debugPrint(
          'Router: userProfile=${userProfile != null}, onboardingProgress=${userProfile?.onboardingProgress}',
        );

        // Allow dashboard access for all authenticated users
        // Onboarding milestones will appear in the timeline
        // No forced redirect - users can access dashboard regardless of onboarding status

        // If user is authenticated but trying to access auth/welcome screens, go home
        if (isLoggingIn || isSigningUp || isWelcome) {
          debugPrint('Router: Redirecting to / (Home) from ${state.uri.path}');
          return '/';
        }
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
          // Removed: attributes route (streamlined flow)
          // Removed: why route (streamlined flow)
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
          return ScaffoldWithNavBar(navigationShell: navigationShell);
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
                    parentNavigatorKey: rootNavigatorKey, // Hide bottom nav
                    builder: (context, state) =>
                        const AdvancedCreateHabitScreen(),
                  ),
                  GoRoute(
                    path: 'two-minute-timer',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const TwoMinuteTimerScreen(),
                  ),
                  GoRoute(
                    path: 'gatekeeper',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const GatekeeperScreen(),
                  ),
                  GoRoute(
                    path: 'paywall',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const PaywallScreen(),
                  ),
                  GoRoute(
                    path: 'habit-builder',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const HabitBuilderScreen(),
                  ),
                  GoRoute(
                    path: 'blueprints',
                    parentNavigatorKey: rootNavigatorKey,
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
                builder: (context, state) => const EvolvingForestScreen(),
                routes: [
                  GoRoute(
                    path: 'recap',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const CinematicRecapScreen(),
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
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const SettingsScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) =>
                        const NotificationSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'priming',
                    parentNavigatorKey: rootNavigatorKey,
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
