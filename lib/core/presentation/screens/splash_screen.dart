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
    // UNCONDITIONAL 3 second splash screen for branding
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Check auth state after splash completes
    final authState = ref.read(authStateChangesProvider);

    bool isLoggedIn = false;
    authState.when(
      data: (user) {
        isLoggedIn = user.id.isNotEmpty;
      },
      loading: () {
        // Auth still loading, wait briefly and check again
        isLoggedIn = false;
      },
      error: (_, _) {
        isLoggedIn = false;
      },
    );

    // If auth is still loading, wait briefly and check again
    if (!isLoggedIn) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      final state = ref.read(authStateChangesProvider);
      isLoggedIn = state.value?.id.isNotEmpty ?? false;
    }

    if (!mounted) return;

    if (!isLoggedIn) {
      // Not logged in - check if first launch
      final isFirstLaunch = ref.read(onboardingControllerProvider);
      AppLogger.d('Splash: Not logged in, isFirstLaunch=$isFirstLaunch');
      if (!mounted) return;
      if (isFirstLaunch) {
        context.go('/welcome');
      } else {
        context.go('/login');
      }
      return;
    }

    // Logged in - load user stats and navigate
    AppLogger.d('Splash: Logged in, loading user stats...');
    final userStatsAsync = await ref.read(userStatsStreamProvider.future);

    if (!mounted) return;

    final onboardingProgress = userStatsAsync.onboardingProgress;

    AppLogger.d(
      'Splash: Navigation ready, onboardingProgress=$onboardingProgress',
    );

    final nextRoute = onboardingProgress >= 4
        ? '/'
        : _getOnboardingRouteForProgress(onboardingProgress);

    AppLogger.d('Splash: Navigating to $nextRoute');
    if (mounted) {
      context.go(nextRoute);
    }
  }

  /// Helper function to get the onboarding route for a given progress level
  /// Flow: 0 = identity-studio, 1 = first-habit, 2 = world-reveal, 3+ = complete
  String _getOnboardingRouteForProgress(int progress) {
    switch (progress) {
      case 0:
        return '/onboarding/identity-studio';
      case 1:
        return '/onboarding/first-habit';
      case 2:
        return '/onboarding/world-reveal';
      default:
        return '/';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GrowthBackground(
      overrideGradient: const [
        Color(0xFF0A0A1A), // Cosmic Void Dark
        Color(0xFF1A0A2A), // Cosmic Void Center
      ],
      showPattern: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo / Icon
            const AnimatedFlameLogo(size: 140),

            const Gap(40),

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
