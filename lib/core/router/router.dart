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

import 'package:emerge_app/features/social/presentation/screens/challenges_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/challenge_detail_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/friends_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/social_activity_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/all_tribes_screen.dart';
import 'package:emerge_app/features/monetization/presentation/screens/habit_contract_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/social_onboarding_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_lobby_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/creator_profile_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/blueprint_detail_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/creators_browse_screen.dart';
import 'package:emerge_app/features/social/presentation/providers/social_onboarding_provider.dart';
import 'package:emerge_app/features/auth/presentation/screens/creator_login_screen.dart';
import 'package:emerge_app/features/auth/presentation/screens/creator_signup_screen.dart';
import 'package:emerge_app/features/auth/presentation/screens/creator_verify_email_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_dashboard_scaffold.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_overview_tab.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_blueprints_tab.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/blueprint_builder_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_tribe_management_tab.dart';

import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  ref.listen(socialOnboardingCompletedProvider, (_, _) => refreshNotifier.value++);

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
      final isCreatorLogin = path == '/creator/login';
      final isCreatorSignup = path == '/creator/signup';
      final isCreatorAuthScreen = isCreatorLogin || isCreatorSignup;
      final isAuthScreen = isWelcome || isLogin || isSignup || isCreatorAuthScreen;
      final isOnboardingPath = path.startsWith('/onboarding');
      final isCreatorPath = path.startsWith('/creator');

      // 5. Handle Unauthenticated Users
      if (!isLoggedIn) {
        if (isAuthScreen) return null;
        if (isCreatorPath) return '/creator/login';
        return isFirstLaunch ? '/welcome' : '/login';
      }

      // 6. Handle Authenticated Users
      final user = authState.value;
      if (user == null || user.isEmpty) return null;

      // Use ref.read (NOT ref.watch) for role providers.
      // ref.watch inside redirect causes routerProvider to rebuild every time
      // those async futures settle → new GoRouter with initialLocation='/splash' → infinite loop.
      final isCreatorAsync = ref.read(isCreatorProvider(user.id));
      final isNormalUserAsync = ref.read(isNormalUserProvider(user.id));

      // While roles are still being determined, hold current path.
      if (isCreatorAsync.isLoading || isNormalUserAsync.isLoading) return null;

      final isCreator = isCreatorAsync.value ?? false;
      final isNormal = isNormalUserAsync.value ?? false;

      // 6a. Creator Role Handling
      if (isCreator) {
        final firebaseUser = ref.read(firebaseAuthProvider).currentUser;
        final isEmailVerified = firebaseUser?.emailVerified ?? false;

        if (!isEmailVerified) {
          if (path != '/creator/verify-email') {
            return '/creator/verify-email';
          }
          return null;
        }

        if (path == '/creator/verify-email' || !isCreatorPath || isCreatorLogin || isCreatorSignup) {
          return '/creator/dashboard';
        }
        return null;
      }

      // 6b. Normal User Role Handling
      if (isNormal) {
        if (isCreatorPath) {
          return '/';
        }
      }

      // 7. Normal User Onboarding Handling
      // Use ref.read for stats to avoid redundant rebuilds.
      final statsAsync = ref.read(userStatsStreamProvider);

      // If stats are loading or in error state, allow current path to continue.
      if (statsAsync.isLoading || statsAsync.hasError) return null;

      final userStats = statsAsync.value;

      // New user: no stats doc yet → treat as onboarding not complete.
      // Allow onboarding paths through; send everything else to identity-studio.
      if (userStats == null) {
        if (isOnboardingPath) return null;
        if (isAuthScreen) return null;
        return '/onboarding/identity-studio';
      }

      final onboardingProgress = userStats.onboardingProgress;
      // Onboarding is complete if progress >= 3 OR we have a completion timestamp.
      final isOnboardingComplete =
          onboardingProgress >= 3 || userStats.onboardingCompletedAt != null;

      // If onboarding is incomplete, restrict to onboarding flow
      if (!isOnboardingComplete) {
        if (isOnboardingPath) return null;
        if (isCreatorPath) return null;
        return _getOnboardingRouteForProgress(onboardingProgress);
      }

      // Onboarding is complete:
      // Redirect auth screens to home, otherwise allow all paths (unblocks bottom nav)
      if (isAuthScreen) {
        return '/';
      }

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
        path: '/creator/login',
        builder: (context, state) => const CreatorLoginScreen(),
      ),
      GoRoute(
        path: '/creator/signup',
        builder: (context, state) => const CreatorSignUpScreen(),
      ),
      GoRoute(
        path: '/creator/verify-email',
        builder: (context, state) => const CreatorVerifyEmailScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            CreatorDashboardScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/creator/dashboard',
                builder: (context, state) => const CreatorOverviewTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/creator/dashboard/blueprints',
                builder: (context, state) => const CreatorBlueprintsTab(),
                routes: [
                  GoRoute(
                    path: 'blueprint-builder',
                    builder: (context, state) => const BlueprintBuilderScreen(),
                  ),
                ]
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/creator/dashboard/tribe',
                builder: (context, state) => const CreatorTribeManagementTab(),
              ),
            ],
          ),
        ],
      ),
      // ISSUE-13: Top-level /creators/:id alias for deep linking, share links, notifications
      GoRoute(
        path: '/creators/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => CreatorProfileScreen(
          creatorId: state.pathParameters['id']!,
        ),
      ),
      // /blueprint/:id — deep-link entry point for any blueprint by id
      // (push sites may also pass the resolved Blueprint via `extra` to skip the fetch).
      GoRoute(
        path: '/blueprint/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra;
          if (extra is Blueprint) return BlueprintDetailScreen(blueprint: extra);
          return _BlueprintByIdLoader(blueprintId: id);
        },
      ),
      // /creators — browse all verified creators
      GoRoute(
        path: '/creators',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreatorsBrowseScreen(),
      ),
      GoRoute(
        path: '/challenges',
        builder: (context, state) => const ChallengesScreen(showAppBar: true),
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
          // Branch 3: Social (Tribe Lobby)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/social',
                builder: (context, state) => const TribeLobbyScreen(),
                redirect: (context, state) {
                  final asyncComplete = ref.read(socialOnboardingCompletedProvider);
                  if (asyncComplete.isLoading) return null; // Don't redirect while checking
                  
                  final isComplete = asyncComplete.value ?? false;
                  if (!isComplete && !state.uri.path.startsWith('/social/onboarding')) {
                    return '/social/onboarding';
                  }
                  return null;
                },
                routes: [
                  GoRoute(
                    path: 'onboarding',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const SocialOnboardingScreen(),
                  ),

                  GoRoute(
                    path: 'challenges',
                    builder: (context, state) =>
                        const ChallengesScreen(showAppBar: true),
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
                    path: 'activity',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final tribeId =
                          state.uri.queryParameters['tribeId'] ?? '';
                      return SocialActivityScreen(tribeId: tribeId);
                    },
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
                  GoRoute(
                    path: 'creator/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => CreatorProfileScreen(
                      creatorId: state.pathParameters['id']!,
                    ),
                  ),
                  // /social/discover — re-uses CreatorsBrowseScreen (avoids duplicate)
                  GoRoute(
                    path: 'discover',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const CreatorsBrowseScreen(),
                  ),
                  // /social/blueprint/:id — branch-local alias of /blueprint/:id
                  GoRoute(
                    path: 'blueprint/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      final extra = state.extra;
                      if (extra is Blueprint) {
                        return BlueprintDetailScreen(blueprint: extra);
                      }
                      return _BlueprintByIdLoader(blueprintId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 4: Profile (Identity)
          StatefulShellBranch(
            routes: [
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

/// Resolves a blueprint by id when the caller doesn't pass one via `extra`.
/// Uses [blueprintByIdProvider] (single-doc fetch, not a full collection
/// stream) so deep-link navigation is cheap even when the `blueprints`
/// collection is large. On miss or error, shows [AppErrorWidget] with a
/// retry that invalidates the provider.
class _BlueprintByIdLoader extends ConsumerWidget {
  final String blueprintId;
  const _BlueprintByIdLoader({required this.blueprintId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blueprintAsync = ref.watch(blueprintByIdProvider(blueprintId));

    return blueprintAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.transparent,
        body: AppErrorWidget(
          message: 'Failed to load blueprint: $e',
          onRetry: () => ref.invalidate(blueprintByIdProvider(blueprintId)),
        ),
      ),
      data: (blueprint) {
        if (blueprint == null) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: AppErrorWidget(
              message: 'Blueprint not found',
              onRetry: () =>
                  ref.invalidate(blueprintByIdProvider(blueprintId)),
            ),
          );
        }
        return BlueprintDetailScreen(blueprint: blueprint);
      },
    );
  }
}
