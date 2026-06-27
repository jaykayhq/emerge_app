import 'package:emerge_app/features/auth/presentation/screens/creator_login_screen.dart';
import 'package:emerge_app/features/auth/presentation/screens/creator_signup_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/creator_onboarding/creator_onboarding_archetype_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/creator_onboarding/creator_onboarding_profile_screen.dart';
import 'package:emerge_app/features/onboarding/presentation/screens/creator_onboarding/creator_onboarding_reveal_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_dashboard_scaffold.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_overview_tab.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_blueprints_tab.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/blueprint_builder_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_tribe_management_tab.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> get creatorRoutes => [
      // Creator auth routes
      GoRoute(
        path: '/creator/login',
        builder: (context, state) => const CreatorLoginScreen(),
      ),
      GoRoute(
        path: '/creator/signup',
        builder: (context, state) => const CreatorSignUpScreen(),
      ),
      // Creator onboarding routes
      GoRoute(
        path: '/onboarding/creator/archetype',
        builder: (context, state) => const CreatorOnboardingArchetypeScreen(),
      ),
      GoRoute(
        path: '/onboarding/creator/profile',
        builder: (context, state) => const CreatorOnboardingProfileScreen(),
      ),
      GoRoute(
        path: '/onboarding/creator/reveal',
        builder: (context, state) => const CreatorOnboardingRevealScreen(),
      ),
      // Creator dashboard shell with 3 tabs
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
                    builder: (context, state) =>
                        const BlueprintBuilderScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/creator/dashboard/tribe',
                builder: (context, state) =>
                    const CreatorTribeManagementTab(),
              ),
            ],
          ),
        ],
      ),
    ];
