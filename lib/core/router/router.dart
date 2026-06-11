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
import 'package:emerge_app/features/habits/presentation/screens/advanced_create_habit_dialog.dart';
import 'package:emerge_app/features/habits/presentation/screens/habit_detail_screen.dart';
import 'package:emerge_app/features/world_map/presentation/screens/level_immersive_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/leaderboard_screen.dart';
import 'package:emerge_app/features/gamification/presentation/screens/level_up_reward_screen.dart';
import 'package:emerge_app/features/world_map/domain/models/archetype_maps_catalog.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';

import 'package:emerge_app/features/gamification/presentation/screens/weekly_recap_screen.dart';
import 'package:emerge_app/features/gamification/presentation/screens/recap_hub_screen.dart';

import 'package:emerge_app/features/ai/presentation/screens/ai_reflections_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/first_habit_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/identity_studio_screen.dart';

import 'package:emerge_app/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/world_reveal_screen.dart';
import 'package:emerge_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:emerge_app/features/settings/presentation/screens/notification_settings_screen.dart';
import 'package:emerge_app/features/monetization/presentation/screens/paywall_screen.dart';

import 'package:emerge_app/features/social/presentation/screens/social_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/social_discover_tab.dart';
import 'package:emerge_app/features/social/presentation/screens/challenges_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/challenge_detail_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/friends_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/all_tribes_screen.dart';
import 'package:emerge_app/features/monetization/presentation/screens/habit_contract_screen.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

// Global navigator key - must be defined outside the provider to prevent duplication
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

@riverpod
GoRouter router(Ref ref) {
  // Watch auth state to rebuild router only on login/logout
  final authState = ref.watch(authStateChangesProvider);

  // Create a refresh notifier for onboarding completion only
  final refreshNotifier = ValueNotifier<int>(0);
  ref.listen(onboardingControllerProvider, (_, _) => refreshNotifier.value++);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final path = state.uri.path;

      // 1. Always allow splash screen
      if (path == '/splash') return null;

      // 2. Wait for auth state to initialize
      if (authState.isLoading) return null;

      final isLoggedIn = authState.value?.isNotEmpty ?? false;
      final isFirstLaunch = ref.read(onboardingControllerProvider);

      // Define path guards
      final isWelcome = path == '/welcome';
      final isLogin = path == '/login';
      final isSignup = path == '/signup';
      final isAuthScreen = isWelcome || isLogin || isSignup;
      final isOnboardingPath = path.startsWith('/onboarding');

      // 3. Handle Unauthenticated Users
      if (!isLoggedIn) {
        if (isAuthScreen) return null;
        return isFirstLaunch ? '/welcome' : '/login';
      }

      // 4. Handle Authenticated Users

      // Use ref.read for stats to avoid redundant rebuilds
      final statsAsync = ref.read(userStatsStreamProvider);

      // If stats are loading or in error state, allow current path to continue
      if (statsAsync.isLoading || statsAsync.hasError) return null;

      final userStats = statsAsync.value;
      if (userStats == null) return null;

      final onboardingProgress = userStats.onboardingProgress;
      // Onboarding is complete if progress >= 3 OR we have a completion timestamp
      // Threshold is 3 because the final step (World Reveal) marks the start of the app
      final isOnboardingComplete =
          onboardingProgress >= 3 || userStats.onboardingCompletedAt != null;

      // If onboarding is incomplete, restrict to onboarding flow
      if (!isOnboardingComplete) {
        if (isOnboardingPath) return null;
        return _getOnboardingRouteForProgress(onboardingProgress);
      }

      // Onboarding is complete:
      // Redirect auth screens to home, otherwise allow all paths (unblocks bottom nav)
      if (isAuthScreen) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
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
      GoRoute(
        path: '/challenges',
        builder: (context, state) => const ChallengesScreen(showAppBar: true),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const FutureSelfStudioScreen(),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) =>
                const NotificationSettingsScreen(),
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
            path: 'level-up-reward/:level',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final levelStr = state.pathParameters['level'];
              final level = int.tryParse(levelStr ?? '1') ?? 1;
              return LevelUpRewardScreen(celebratedLevel: level);
            },
          ),
        ],
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
                    path: 'recap-hub',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const RecapHubScreen(),
                  ),
                  GoRoute(
                    path: 'recap',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.uri.queryParameters['id'];
                      final startStr = state.uri.queryParameters['start'];
                      final endStr = state.uri.queryParameters['end'];

                      DateTime? start;
                      DateTime? end;

                      if (startStr != null) start = DateTime.tryParse(startStr);
                      if (endStr != null) end = DateTime.tryParse(endStr);

                      return WeeklyRecapScreen(
                        recapId: id,
                        startDate: start,
                        endDate: end,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'node/:nodeId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['nodeId']!;
                      final archetype =
                          ref.read(userStatsStreamProvider).value?.archetype ??
                          UserArchetype.scholar;
                      final config = ArchetypeMapsCatalog.getMapForArchetype(
                        archetype,
                      );
                      final node = config.nodes.firstWhere(
                        (n) => n.id == id,
                        orElse: () => config.nodes.first,
                      );
                      return LevelImmersiveScreen(node: node, config: config);
                    },
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
                        const AdvancedCreateHabitDialog(),
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
          // Branch 3: Discover (NEW ROOT TAB)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                builder: (context, state) => const SocialDiscoverTab(showAsRoot: true),
              ),
            ],
          ),
          // Branch 4: Social (Tribe & Challenges)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tribes',
                builder: (context, state) =>
                    const SocialScreen(initialIndex: 0),
                routes: [
                  GoRoute(
                    path: 'challenges',
                    builder: (context, state) =>
                        const SocialScreen(initialIndex: 1),
                  ),
                  GoRoute(
                    path: 'challenge/:challengeId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['challengeId']!;
                      return ChallengeDetailScreen(challengeId: id);
                    },
                  ),
                  GoRoute(
                    path: 'accountability',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const FriendsScreen(),
                  ),
                  GoRoute(
                    path: 'contracts',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const HabitContractScreen(),
                  ),
                  GoRoute(
                    path: 'leaderboard',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final tabStr = state.uri.queryParameters['tab'];
                      final tabIndex = int.tryParse(tabStr ?? '0') ?? 0;
                      return LeaderboardScreen(initialTabIndex: tabIndex);
                    },
                  ),
                  GoRoute(
                    path: 'all',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AllTribesScreen(),
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
/// Flow: 0-1 = identity-studio, 2 = first-habit, 3 = world-reveal, 4+ = complete
String _getOnboardingRouteForProgress(int progress) {
  switch (progress) {
    case 0:
    case 1:
      return '/onboarding/identity-studio';
    case 2:
      return '/onboarding/first-habit';
    case 3:
      return '/onboarding/world-reveal';
    default:
      return '/'; // Should reach this case only briefly before isOnboardingComplete takes over
  }
}
