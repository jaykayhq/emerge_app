import 'package:emerge_app/core/presentation/widgets/growth_background.dart';

import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/core/presentation/widgets/animated_flame_logo.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/presentation/providers/role_provider.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    // CRITICAL: Check the user's role BEFORE deciding where to go. A
    // creator has no user_stats doc (only creator_profiles), so the
    // onboardingProgress-based logic below would route them to
    // /onboarding/identity-studio (normal-user flow) — the bug we are
    // fixing. By branching on role here, creators go to their own flow.
    final role = await ref.read(currentUserRoleProvider.future);
    if (!mounted) return;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final emailVerified = firebaseUser?.emailVerified ?? false;

    AppLogger.d('Splash: role=$role, emailVerified=$emailVerified');

    if (role == UserRole.creator) {
      // Creator flow. Email verification comes first.
      if (!emailVerified) {
        AppLogger.d(
          'Splash: Creator with unverified email -> /creator/verify-email',
        );
        context.go('/creator/verify-email');
        return;
      }
      // Email is verified. Drive the creator onboarding flow.
      final creatorOnboarding =
          await ref.read(currentCreatorOnboardingProvider.future);
      if (!mounted) return;
      final progress = creatorOnboarding?.progress ?? 0;
      final isComplete = creatorOnboarding?.isComplete ?? false;
      if (isComplete) {
        AppLogger.d('Splash: Creator onboarding complete -> /creator/dashboard');
        context.go('/creator/dashboard');
        return;
      }
      final next = switch (progress) {
        0 => '/onboarding/creator/archetype',
        1 => '/onboarding/creator/profile',
        _ => '/onboarding/creator/reveal',
      };
      AppLogger.d('Splash: Creator onboarding progress=$progress -> $next');
      context.go(next);
      return;
    }

    // For role=user or role=unknown, fall through to the existing
    // user_stats-based logic (legacy users may not have a role claim
    // yet, and that path is correct for them).

    // Logged in — seed Drift from Firestore BEFORE reading onboardingProgress.
    // On a fresh install or reinstall the local Drift DB is empty, so
    // watchUserStats returns onboardingProgress=0 for every returning user
    // and sends them back through onboarding endlessly.
    AppLogger.d('Splash: Logged in, seeding Drift from Firestore...');
    final userId = ref.read(authStateChangesProvider).value?.id ?? '';
    if (userId.isNotEmpty) {
      try {
        final firestoreDoc = await FirebaseFirestore.instance
            .collection('user_stats')
            .doc(userId)
            .get();

        if (firestoreDoc.exists) {
          final data = firestoreDoc.data()!;
          // Coerce Firestore types that Drift expects as primitives
          final normalised = <String, dynamic>{
            'displayName': data['displayName'],
            'photoUrl': data['photoUrl'],
            'totalXp': (data['totalXp'] as num?)?.toInt() ?? 0,
            'level': (data['level'] as num?)?.toInt() ?? 1,
            'streak': (data['streak'] as num?)?.toInt() ?? 0,
            'strengthXp': (data['strengthXp'] as num?)?.toInt() ?? 0,
            'intellectXp': (data['intellectXp'] as num?)?.toInt() ?? 0,
            'vitalityXp': (data['vitalityXp'] as num?)?.toInt() ?? 0,
            'creativityXp': (data['creativityXp'] as num?)?.toInt() ?? 0,
            'focusXp': (data['focusXp'] as num?)?.toInt() ?? 0,
            'spiritXp': (data['spiritXp'] as num?)?.toInt() ?? 0,
            'challengeXp': (data['challengeXp'] as num?)?.toInt() ?? 0,
            'worldHealthScore':
                (data['worldHealthScore'] as num?)?.toDouble() ?? 1.0,
            'archetype': data['archetype'],
            'characterClass': data['characterClass'],
            'motive': data['motive'],
            'why': data['why'],
            'anchorsJson': data['anchorsJson'],
            'habitStacksJson': data['habitStacksJson'],
            'skippedOnboardingStepsJson': data['skippedOnboardingStepsJson'],
            'settingsJson': data['settingsJson'],
            'avatarJson': data['avatarJson'],
            'worldStateJson': data['worldStateJson'],
            'onboardingProgress':
                (data['onboardingProgress'] as num?)?.toInt() ?? 0,
            'onboardingCompletedAt': data['onboardingCompletedAt'] is Timestamp
                ? (data['onboardingCompletedAt'] as Timestamp)
                    .toDate()
                    .toIso8601String()
                : data['onboardingCompletedAt'] as String?,
            'onboardingStartedAt': data['onboardingStartedAt'] is Timestamp
                ? (data['onboardingStartedAt'] as Timestamp)
                    .toDate()
                    .toIso8601String()
                : data['onboardingStartedAt'] as String?,
            'hasEmerged': data['hasEmerged'] as bool? ?? false,
            'momentumScore':
                (data['momentumScore'] as num?)?.toDouble() ?? 0.5,
            'lastCelebratedLevel':
                (data['lastCelebratedLevel'] as num?)?.toInt() ?? 0,
          };

          final repo = ref.read(userStatsRepositoryProvider);
          await repo.seedFromFirestoreData(userId, normalised);
          AppLogger.d('Splash: Drift seeded from Firestore (user_stats).');
        } else {
          // user_stats doc not found — try users collection as fallback.
          // This covers new users whose data hasn't been flushed from the
          // sync-engine queue to user_stats yet, but IS in users already.
          AppLogger.d(
            'Splash: user_stats doc missing, checking users collection...',
          );
          final usersDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

          if (usersDoc.exists) {
            final data = usersDoc.data()!;
            final progress =
                (data['onboardingProgress'] as num?)?.toInt() ?? 0;
            final completedAt = data['onboardingCompletedAt'] is Timestamp
                ? (data['onboardingCompletedAt'] as Timestamp)
                    .toDate()
                    .toIso8601String()
                : data['onboardingCompletedAt'] as String?;

            // Seed Drift with just the onboarding fields from users doc
            final repo = ref.read(userStatsRepositoryProvider);
            await repo.seedFromFirestoreData(userId, {
              'displayName': data['displayName'],
              'photoUrl': data['photoUrl'],
              'archetype': data['archetype'],
              'onboardingProgress': progress,
              'onboardingCompletedAt': completedAt,
              'hasEmerged': data['hasEmerged'] as bool? ?? false,
            });
            AppLogger.d(
              'Splash: Drift seeded from users collection (progress=$progress).',
            );
          } else {
            AppLogger.d(
              'Splash: No user doc found at all — brand new user, starting onboarding.',
            );
          }
        }
      } catch (e) {
        // Non-fatal: if offline or doc missing, fall through and use Drift as-is
        AppLogger.w('Splash: Could not seed Drift from Firestore: $e');
      }
    }

    if (!mounted) return;

    AppLogger.d('Splash: Logged in, loading user stats...');
    final userStatsAsync = await ref.read(userStatsStreamProvider.future);

    if (!mounted) return;

    final onboardingProgress = userStatsAsync.onboardingProgress;

    AppLogger.d(
      'Splash: Navigation ready, onboardingProgress=$onboardingProgress',
    );

    final nextRoute = onboardingProgress >= 3
        ? '/'
        : _getOnboardingRouteForProgress(onboardingProgress);

    AppLogger.d('Splash: Navigating to $nextRoute');
    if (mounted) {
      context.go(nextRoute);
    }
  }

  /// Helper function to get the onboarding route for a given progress level.
  /// Matches the router's [_getOnboardingRouteForProgress] exactly:
  /// 0,1 = identity-studio, 2 = first-habit, 3 = world-reveal, 4+ = home
  String _getOnboardingRouteForProgress(int progress) {
    switch (progress) {
      case 0:
      case 1:
        return '/onboarding/identity-studio';
      case 2:
        return '/onboarding/first-habit';
      default:
        return '/onboarding/world-reveal';
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
