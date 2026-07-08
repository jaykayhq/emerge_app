import 'package:emerge_app/core/presentation/screens/splash_screen.dart';
import 'package:emerge_app/core/presentation/screens/world_splash_screen.dart';
import 'package:emerge_app/core/presentation/widgets/scaffold_with_nav_bar.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/providers/role_provider.dart';
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
import 'package:emerge_app/features/social/presentation/screens/social_contacts_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/all_tribes_screen.dart';
import 'package:emerge_app/features/monetization/presentation/screens/habit_contract_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/social_onboarding_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/creator_profile_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/blueprint_detail_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/creators_browse_screen.dart';
import 'package:emerge_app/features/social/presentation/providers/social_onboarding_provider.dart';
import 'package:emerge_app/core/router/creator_routes.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/features/pulse_feed/presentation/screens/pulse_feed_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

// Global navigator key - must be defined outside the provider to prevent duplication
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Snapshot of everything the redirect decision needs.
///
/// This is a pure data struct so the redirect logic can be unit-tested
/// without spinning up GoRouter, Riverpod, or Firebase. Production code
/// builds it from providers; tests construct it directly.
class RedirectContext {
  final bool isLoggedIn;
  final UserRole? role; // null = unknown / still resolving
  final bool isFirstLaunch;
  final int? userOnboardingProgress; // null = no user_stats doc yet
  final DateTime? userOnboardingCompletedAt;
  final CreatorOnboardingState? creatorOnboarding; // null = not a creator

  const RedirectContext({
    required this.isLoggedIn,
    required this.role,
    required this.isFirstLaunch,
    required this.userOnboardingProgress,
    required this.userOnboardingCompletedAt,
    required this.creatorOnboarding,
  });
}

/// Pure redirect decision. Returns:
///   - null  : stay on the current path
///   - path  : redirect to that path
///
/// The decision is driven by the `role` enum, which is the canonical
/// source of truth (Firebase Auth custom claim, with Firestore fallback
/// inside `currentUserRoleProvider`). This eliminates the
/// collection-existence race that previously sent creators into the
/// normal-user onboarding flow.
String? decideRedirect({
  required String currentPath,
  required RedirectContext ctx,
}) {
  // 1. Always allow splash.
  if (currentPath == '/splash') return null;

  // 2. Public auth paths available to anyone (logged in or not).
  const authPaths = {
    '/welcome',
    '/login',
    '/signup',
    '/creator/login',
    '/creator/signup',
  };

  final isOnAuthPath = authPaths.contains(currentPath);
  final isOnCreatorOnboardingPath =
      currentPath.startsWith('/onboarding/creator/');
  final isOnNormalOnboardingPath =
      currentPath.startsWith('/onboarding/') && !isOnCreatorOnboardingPath;
  final isOnCreatorPath = currentPath.startsWith('/creator');

  // 3. Unauthenticated: bounce into the right login surface.
  if (!ctx.isLoggedIn) {
    if (isOnAuthPath) return null;
    if (isOnCreatorPath || isOnCreatorOnboardingPath) return '/creator/login';
    return ctx.isFirstLaunch ? '/welcome' : '/login';
  }

  // 4. Authenticated but role still resolving — hold the current path
  //    so the router doesn't yank the user mid-signup. This is the
  //    fix for the race window between Firebase Auth user creation
  //    and the setUserRole Cloud Function returning.
  //
  //    We DO redirect away from clearly-stale paths (e.g. /welcome) to
  //    avoid leaving a logged-in user on the welcome screen forever.
  if (ctx.role == null || ctx.role == UserRole.unknown) {
    if (isOnAuthPath && currentPath != '/welcome') return null;
    if (isOnCreatorPath) return null;
    if (isOnCreatorOnboardingPath) return null;
    if (isOnNormalOnboardingPath) return null;
    if (currentPath == '/welcome') {
      // No role known yet — assume normal user and route to onboarding.
      // Will be re-evaluated as soon as the role provider settles.
      return '/onboarding/identity-studio';
    }
    return null;
  }

  // 5. Creator branch.
  if (ctx.role == UserRole.creator) {
    final onboarding = ctx.creatorOnboarding;
    if (onboarding == null || !onboarding.isComplete) {
      // Allow creator-onboarding screens through.
      if (isOnCreatorOnboardingPath) return null;
      // If the user somehow landed on a normal-user onboarding screen,
      // push them to the corresponding creator step.
      if (isOnNormalOnboardingPath) {
        final progress = onboarding?.progress ?? 0;
        switch (progress) {
          case 0:
            return '/onboarding/creator/archetype';
          case 1:
            return '/onboarding/creator/profile';
          case 2:
          default:
            return '/onboarding/creator/reveal';
        }
      }
      // Push the user to the next onboarding step.
      final progress = onboarding?.progress ?? 0;
      switch (progress) {
        case 0:
          return '/onboarding/creator/archetype';
        case 1:
          return '/onboarding/creator/profile';
        case 2:
          return '/onboarding/creator/reveal';
        default:
          return '/onboarding/creator/reveal';
      }
    }

    // Onboarding complete: keep creators on creator surfaces only.
    if (isOnCreatorOnboardingPath || isOnNormalOnboardingPath || isOnAuthPath) {
      return '/creator/dashboard';
    }
    if (!isOnCreatorPath) return '/creator/dashboard';
    return null;
  }

  // 6. Normal user branch.
  if (ctx.role == UserRole.user) {
    // Creators-only paths are forbidden here.
    if (isOnCreatorPath || isOnCreatorOnboardingPath) {
      return '/onboarding/identity-studio';
    }

    final progress = ctx.userOnboardingProgress;
    final isUserOnboardingComplete = ctx.userOnboardingCompletedAt != null ||
        (progress != null && progress >= 3);

    if (!isUserOnboardingComplete) {
      if (isOnNormalOnboardingPath) return null;
      if (isOnAuthPath) return null;
      // No stats doc yet OR progress < 3.
      final effectiveProgress = progress ?? 0;
      switch (effectiveProgress) {
        case 0:
        case 1:
          return '/onboarding/identity-studio';
        case 2:
          return '/onboarding/first-habit';
        default:
          return '/onboarding/world-reveal';
      }
    }

    // Onboarding complete.
    if (isOnAuthPath) return '/timeline';
    return null;
  }

  // Unreachable.
  return null;
}

@riverpod
GoRouter router(Ref ref) {
  // Watch ONLY auth state. Rebuilding the GoRouter on any other data
  // change resets initialLocation to /splash, re-mounting the splash
  // screen and creating an infinite loop.
  final authState = ref.watch(authStateChangesProvider);

  // Single refresh notifier — fires only on auth login/logout and social onboarding state changes.
  final refreshNotifier = ValueNotifier<int>(0);
  ref.listen(authStateChangesProvider, (_, _) => refreshNotifier.value++);
  ref.listen(socialOnboardingCompletedProvider, (_, _) => refreshNotifier.value++);
  
  // Listen to redirect-dependencies so they are initialized *before* GoRouter 
  // is built, preventing ref.read inside redirect from triggering initialization
  // and throwing setState-during-build errors on web. 
  // When they change, we just ask GoRouter to re-evaluate redirect.
  ref.listen(currentUserRoleProvider, (_, _) => refreshNotifier.value++);
  ref.listen(currentCreatorOnboardingProvider, (_, _) => refreshNotifier.value++);
  ref.listen(userStatsStreamProvider, (_, _) => refreshNotifier.value++);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final path = state.uri.path;

      // Wait for auth to initialize before making any routing decision.
      if (authState.isLoading) return null;

      final isLoggedIn = authState.value?.isNotEmpty ?? false;
      final isFirstLaunch = ref.read(onboardingControllerProvider);

      // Read synchronously inside redirect — ref.read gives the latest
      // value at navigation time. Because we listened to them above, 
      // they are already initialized and won't throw on web.
      final roleAsync = ref.read(currentUserRoleProvider);
      final creatorOnboardingAsync = ref.read(currentCreatorOnboardingProvider);
      final userStatsAsync = ref.read(userStatsStreamProvider);

      final role = roleAsync is AsyncData ? roleAsync.value : null;
      final creatorOnboarding = creatorOnboardingAsync is AsyncData
          ? creatorOnboardingAsync.value
          : null;
      final userStats = userStatsAsync is AsyncData ? userStatsAsync.value : null;

      return decideRedirect(
        currentPath: path,
        ctx: RedirectContext(
          isLoggedIn: isLoggedIn,
          role: role,
          isFirstLaunch: isFirstLaunch,
          userOnboardingProgress: userStats?.onboardingProgress,
          userOnboardingCompletedAt: userStats?.onboardingCompletedAt,
          creatorOnboarding: creatorOnboarding,
        ),
      );
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
      // All creator routes (login, signup, onboarding, dashboard)
      ...creatorRoutes,
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      // Normal-user onboarding routes.
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
          // Branch 0: Timeline (Home) - Daily Command Center
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
          // Branch 1: World (Gamification)
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
          // Branch 2: Social (Pulse Feed)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/social',
                builder: (context, state) => const PulseFeedScreen(),
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
                    path: 'contacts',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        const SocialContactsScreen(),
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
          // Branch 3: Profile (Identity)
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
