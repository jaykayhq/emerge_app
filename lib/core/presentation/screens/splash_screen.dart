import 'package:emerge_app/core/presentation/widgets/growth_background.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
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
    // Artificial delay for branding
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final authState = ref.read(authStateChangesProvider);
    final isFirstLaunch = ref.read(onboardingControllerProvider);

    // Check auth state
    authState.when(
      data: (user) {
        if (isFirstLaunch) {
          context.go('/onboarding');
        } else if (user.isNotEmpty) {
          context.go('/');
        } else {
          context.go('/login');
        }
      },
      loading: () {
        // Wait for auth to load if needed, but usually stream emits quickly
        // For simplicity, if loading takes too long, we might default to login
        // But here we'll just let the router redirect logic handle it eventually
        // or re-check.
        // Actually, the router redirect logic is better suited for this.
        // We just need to trigger a navigation to root and let router decide.
        context.go('/');
      },
      error: (_, __) => context.go('/login'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GrowthBackground(
      showPattern: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo / Icon
            Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.deepSunriseOrange.withValues(
                          alpha: 0.4,
                        ),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    size: 64,
                    color: Colors.white,
                  ),
                )
                .animate()
                .scale(duration: 1.seconds, curve: Curves.elasticOut)
                .then()
                .shimmer(duration: 2.seconds),

            const Gap(24),

            // App Name
            Text(
                  'EMERGE',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    letterSpacing: 4,
                    color: AppTheme.slateBlue,
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
                color: Colors.grey[600],
                letterSpacing: 1.2,
              ),
            ).animate().fadeIn(duration: 800.ms, delay: 1000.ms),
          ],
        ),
      ),
    );
  }
}
