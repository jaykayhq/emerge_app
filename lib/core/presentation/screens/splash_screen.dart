import 'package:emerge_app/core/presentation/widgets/growth_background.dart';

import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/core/presentation/widgets/animated_flame_logo.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait minimum branding time
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final authState = ref.read(authStateChangesProvider);

    // Check auth state
    authState.when(
      data: (user) async {
        final isLoggedIn = user.isNotEmpty;

        if (!isLoggedIn) {
          // Not logged in - check if first launch for welcome or go to login
          final isFirstLaunch = ref.read(onboardingControllerProvider);
          AppLogger.d('Splash: Not logged in, isFirstLaunch=$isFirstLaunch');
          if (isFirstLaunch) {
            context.go('/welcome');
          } else {
            context.go('/login');
          }
          return;
        }

        // Logged in - WAIT for user stats to load before deciding
        AppLogger.d('Splash: Logged in, waiting for user stats...');
        final userStatsAsync = await ref.read(userStatsStreamProvider.future);

        if (!mounted) return;

        final onboardingProgress = userStatsAsync.onboardingProgress;

        AppLogger.d(
          'Splash: User stats loaded, onboardingProgress=$onboardingProgress',
        );

        if (onboardingProgress >= 4) {
          // Onboarding complete - go directly to dashboard
          AppLogger.d('Splash: Onboarding complete, going to dashboard');
          context.go('/');
        } else {
          // Onboarding incomplete - resume from appropriate step
          final nextRoute = _getOnboardingRouteForProgress(onboardingProgress);
          AppLogger.d('Splash: Redirecting to $nextRoute');
          context.go(nextRoute);
        }
      },
      loading: () {
        // If auth is still loading, let the router redirect logic handle it
        AppLogger.d('Splash: Auth loading, letting router decide');
        context.go('/');
      },
      error: (_, __) {
        AppLogger.d('Splash: Auth error, going to login');
        context.go('/login');
      },
    );
  }

  /// Helper function to get the onboarding route for a given progress level
  /// Flow: 0 = identity-studio, 1 = map-attributes, 2 = first-habit, 3 = world-reveal, 4+ = complete
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
        return '/';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GrowthBackground(
      overrideGradient: const [
        Color(0xFF2A1B4E), // Deep Violet to match icon background
        Color(0xFF20153B),
      ],
      showPattern: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo / Icon
            const AnimatedFlameLogo(size: 140),

            const Gap(24),

            // App Name
            Text(
                  'EMERGE',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    letterSpacing: 4,
                    color: Colors.white, // White text for dark background
                    fontWeight: FontWeight.bold,
                  ),
                )
                .animate()
                .fadeIn(duration: 800.ms, delay: 500.ms)
                .moveY(begin: 20, end: 0),

            const Gap(8),

            // Tagline
            Text(
              'Build Your Future Self',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white70, // White text
                letterSpacing: 1.2,
              ),
            ).animate().fadeIn(duration: 800.ms, delay: 1000.ms),
          ],
        ),
      ),
    );
  }
}
