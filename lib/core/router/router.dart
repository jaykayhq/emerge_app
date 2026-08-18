import 'package:emerge_app/core/presentation/screens/splash_screen.dart';
import 'package:emerge_app/core/presentation/screens/world_splash_screen.dart';
import 'package:emerge_app/core/presentation/widgets/scaffold_with_nav_bar.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/providers/role_provider.dart';
import 'package:emerge_app/features/auth/presentation/screens/login_screen.dart';
import 'package:emerge_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:emerge_app/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:emerge_app/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/world_map/presentation/screens/world_map_screen.dart';
import 'package:emerge_app/features/timeline/presentation/screens/timeline_screen.dart';
import 'package:emerge_app/features/gamification/presentation/screens/leveling_screen.dart';
import 'package:emerge_app/features/profile/presentation/screens/future_self_studio_screen.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/level_up_listener.dart';
import 'package:emerge_app/features/habits/presentation/screens/habit_create_screen.dart';
import 'package:emerge_app/features/habits/presentation/screens/habit_activity_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/leaderboard_screen.dart';
import 'package:emerge_app/features/gamification/presentation/screens/level_up_reward_screen.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/presentation/screens/attribute_detail_screen.dart';

import 'package:emerge_app/features/gamification/presentation/screens/weekly_recap_screen.dart';
import 'package:emerge_app/features/gamification/presentation/screens/recap_hub_screen.dart';

import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/first_habits_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/identity_studio_screen.dart';

import 'package:emerge_app/features/onboarding/presentation/screens/club_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/interests_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/world_reveal_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/endowment_interstitial_screen.dart';
import 'package:emerge_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:emerge_app/features/settings/presentation/screens/notification_settings_screen.dart';
import 'package:emerge_app/features/monetization/presentation/screens/order_confirmed_screen.dart';
import 'package:emerge_app/features/monetization/presentation/screens/paywall_screen.dart';
import 'package:emerge_app/features/monetization/presentation/screens/manage_premium_screen.dart';

import 'package:emerge_app/features/social/presentation/screens/tribe_lobby_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/challenges_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/challenge_detail_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/friends_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/social_activity_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/social_contacts_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/all_tribes_screen.dart';
import 'package:emerge_app/features/monetization/presentation/screens/habit_contract_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/creator_profile_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/blueprint_detail_screen.dart';
import 'package:emerge_app/core/router/creator_routes.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/features/rating/presentation/screens/feedback_screen.dart';
import 'package:emerge_app/features/rating/presentation/widgets/rating_prompt_host.dart';
import 'package:emerge_app/features/social/presentation/screens/social_hub_screen.dart';

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
  final bool? emailVerified; // null = unknown; false = unverified
  final DateTime? emailLockedAt; // null = within grace period

  const RedirectContext({
    required this.isLoggedIn,
    required this.role,
    required this.isFirstLaunch,
    required this.userOnboardingProgress,
    required this.userOnboardingCompletedAt,
    required this.creatorOnboarding,
    this.emailVerified,
    this.emailLockedAt,
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
  // Normalize: the redirect decision only ever inspects the bare path.
  // GoRouter passes state.uri.path (no query), but email links deep-link as
  // /verify-email?oobCode=... and /reset-password?oobCode=..., so strip any
  // query/fragment defensively before the allowlist lookup — otherwise the
  // oobCode-bearing path would miss the authPaths set and bounce signed-out
  // users away from the screen that must consume the code.
  currentPath = currentPath.split('?').first.split('#').first;

  // 1. Always allow splash.
  if (currentPath == '/splash') return null;

  // 2. Public auth paths available to anyone (logged in or not).
  const authPaths = {
    '/welcome',
    '/login',
    '/signup',
    '/verify-email',
    '/reset-password',
    '/creator/login',
    '/creator/signup',
    '/onboarding/endowment',
  };

  // Auth surfaces that must stay reachable while signed in: /verify-email and
  // /reset-password bubble up from deep links with a one-shot oobCode. If the
  // generic auth-path redirect handled them, a signed-in user would be bounced
  // to /timeline BEFORE the screen could consume the code — silently burning a
  // single-use action code with no retry affordance. Carve them out so the
  // screens render (confirmPasswordReset/applyActionCode are safe while signed
  // in); everything else in [authPaths] stays gated for authenticated users.
  const oobCodeSafePaths = {'/verify-email', '/reset-password'};

  final isOnAuthPath = authPaths.contains(currentPath);
  final isOnOobCodeSafePath = oobCodeSafePaths.contains(currentPath);
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
    // Email verification gate. During the 7-day grace period (emailLockedAt
    // not yet set) an unverified user may use the app freely — the top
    // banner nudges verification instead of blocking. Once emailLockedAt is
    // set (past grace), every surface except /verify-email itself is
    // blocked — locked users can only verify.
    final unverified = ctx.emailVerified == false;
    final locked = ctx.emailLockedAt != null;
    if (unverified) {
      if (currentPath == '/verify-email') return null;
      if (locked) return '/verify-email';
      return null;
    }

    // Creators-only paths are forbidden here.
    if (isOnCreatorPath || isOnCreatorOnboardingPath) {
      return '/onboarding/identity-studio';
    }

    final progress = ctx.userOnboardingProgress;
    final isUserOnboardingComplete = ctx.userOnboardingCompletedAt != null ||
        (progress != null && progress >= 4);

    if (!isUserOnboardingComplete) {
      if (isOnNormalOnboardingPath) return null;
      if (isOnAuthPath) return null;
      // No stats doc yet OR progress < 4. Send the user to the next
      // uncompleted step in the new 5-step flow:
      //   0 = archetype  → /onboarding/identity-studio
      //   1 = interests  → /onboarding/interests
      //   2 = club       → /onboarding/club
      //   3 = first 3   → /onboarding/first-habits
      //   4 = world reveal → /onboarding/world-reveal
      final effectiveProgress = progress ?? 0;
      switch (effectiveProgress) {
        case 0:
          return '/onboarding/identity-studio';
        case 1:
          return '/onboarding/interests';
        case 2:
          return '/onboarding/club';
        case 3:
          return '/onboarding/first-habits';
        default:
          return '/onboarding/world-reveal';
      }
    }

    // Onboarding complete. Signed-in users are generally bounced off auth
    // surfaces — except the oobCode-bearing ones, which must render so the
    // single-use action code is consumed (see the carve-out comment above).
    if (isOnOobCodeSafePath) return null;
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

  // Single refresh notifier — fires only on auth login/logout.
  final refreshNotifier = ValueNotifier<int>(0);
  ref.listen(authStateChangesProvider, (_, _) => refreshNotifier.value++);

  // Listen to redirect-dependencies so they are initialized *before* GoRouter
  // is built, preventing ref.read inside redirect from triggering initialization
  // and throwing setState-during-build errors on web.
  // When they change, we just ask GoRouter to re-evaluate redirect.
  ref.listen(currentUserRoleProvider, (_, _) => refreshNotifier.value++);
  ref.listen(currentCreatorOnboardingProvider, (_, _) => refreshNotifier.value++);
  ref.listen(userStatsStreamProvider, (_, _) => refreshNotifier.value++);
  ref.listen(onboardingControllerProvider, (_, _) => refreshNotifier.value++);
  ref.listen(currentEmailLockedAtProvider, (_, _) => refreshNotifier.value++);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final path = state.uri.path;

      // Wait for auth to initialize before making any routing decision.
      if (authState.isLoading) return null;

      final isLoggedIn = authState.value?.isNotEmpty ?? false;

      // Read synchronously inside redirect — ref.read gives the latest
      // value at navigation time. Because we listened to them above,
      // they are already initialized and won't throw on web.
      // We wrap reads in try/catch returning defaults as a final fallback for build-time safety.
      bool isFirstLaunch = true;
      try {
        isFirstLaunch = ref.read(onboardingControllerProvider);
      } catch (e) {
        debugPrint('[Router] Provider not ready during redirect, deferring: $e');
        // Return null to defer redirect safely (provider will trigger rebuild when ready)
      }

      final roleAsync = ref.read(currentUserRoleProvider);
      final creatorOnboardingAsync = ref.read(currentCreatorOnboardingProvider);
      final userStatsAsync = ref.read(userStatsStreamProvider);

      // Email lock read is guarded too: if the provider isn't ready during
      // build, treat the user as within the grace period rather than throwing.
      // Error ⇒ treat as within grace; a stale lock only relaxes an already-gated path.
      DateTime? emailLockedAt;
      try {
        final emailLockedAtAsync = ref.read(currentEmailLockedAtProvider);
        emailLockedAt = emailLockedAtAsync is AsyncData
            ? emailLockedAtAsync.value
            : null;
      } catch (e) {
        debugPrint(
            '[Router] emailLockedAt provider not ready during redirect, deferring: $e');
      }

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
          emailVerified: authState.value?.emailVerified,
          emailLockedAt: emailLockedAt,
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
        path: '/order-confirmed',
        builder: (context, state) => OrderConfirmedScreen(
          reference: state.uri.queryParameters['reference'],
        ),
      ),
      GoRoute(
        path: '/manage-premium',
        builder: (context, state) => const ManagePremiumScreen(),
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
      // Endowment interstitial — pre-auth "Future You" preview shown before
      // sign-up, on the welcome screen path.
      GoRoute(
        path: '/onboarding/endowment',
        builder: (context, state) => const EndowmentInterstitialScreen(),
      ),
      // Normal-user onboarding routes.
      GoRoute(
        path: '/onboarding/identity-studio',
        builder: (context, state) => const IdentityStudioScreen(),
      ),
      GoRoute(
        path: '/onboarding/interests',
        builder: (context, state) => const InterestsScreen(),
      ),
      GoRoute(
        path: '/onboarding/club',
        builder: (context, state) => const ClubScreen(),
      ),
      GoRoute(
        path: '/onboarding/first-habits',
        builder: (context, state) => const FirstHabitsScreen(),
      ),
      GoRoute(
        path: '/onboarding/world-reveal',
        builder: (context, state) => const WorldRevealScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
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
      GoRoute(
        path: '/challenges',
        builder: (context, state) => const ChallengesScreen(showAppBar: true),
      ),
      // Low-rating feedback form, pushed by the rating controller when the
      // user rates 1–3 stars. Query params carry the userId + low rating.
      GoRoute(
        path: '/feedback',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => FeedbackScreen(
          userId: state.uri.queryParameters['userId'] ?? '',
          rating: (int.tryParse(state.uri.queryParameters['rating'] ?? '') ?? 3)
              .clamp(1, 5)
              .toInt(),
        ),
      ),
      // ShellRoute for Bottom Navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return RatingPromptHost(
            child: LevelUpListener(
              child: ScaffoldWithNavBar(navigationShell: navigationShell),
            ),
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
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => CustomTransitionPage(
                      key: state.pageKey,
                      child: const HabitCreateScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) =>
                              SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 1),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeInOut,
                                  ),
                                ),
                                child: child,
                              ),
                    ),
                  ),
                  GoRoute(
                    path: 'habit/:habitId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => HabitActivityScreen(
                      habitId: state.pathParameters['habitId']!,
                    ),
                  ),
                  // detail/:habitId removed — HabitDetailScreen deleted
                ],
              ),
            ],
          ),
          // Branch 1: World (Gamification)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/world-map',
                builder: (context, state) {
                  final focusAttribute = state.extra as String?;
                  return WorldMapScreen(focusAttribute: focusAttribute);
                },
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
                    path: 'attribute/:attributeName',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final name = state.pathParameters['attributeName']!;
                      final attr = HabitAttribute.values.firstWhere(
                        (a) => a.name == name,
                        orElse: () => HabitAttribute.vitality,
                      );
                      return AttributeDetailScreen(attribute: attr);
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
                builder: (context, state) => const SocialHubScreen(),
                routes: [
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
                    path: 'tribe/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        TribeLobbyScreen(
                      tribeId: state.pathParameters['id'],
                    ),
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
                    path: 'leveling',
                    builder: (context, state) => const LevelingScreen(),
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