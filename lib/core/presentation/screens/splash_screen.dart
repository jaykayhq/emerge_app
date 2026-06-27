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

/// Pure routing decision for the splash screen.
///
/// Extracted from the widget so it can be unit-tested without Firebase.
/// Mirrors the logic in [decideRedirect] but is splash-specific.
///
/// The [hasCreatorProfile] flag is the fallback when [role] is
/// [UserRole.unknown] — it lets the splash screen detect creators even
/// when the `currentUserRoleProvider` fails to resolve (e.g. no emulator).
String determineSplashRoute({
  required bool isLoggedIn,
  required bool isFirstLaunch,
  UserRole role = UserRole.unknown,
  required bool hasCreatorProfile,
  required CreatorOnboardingState? creatorOnboarding,
  required int? userOnboardingProgress,
  required DateTime? userOnboardingCompletedAt,
}) {
  if (!isLoggedIn) {
    return isFirstLaunch ? '/welcome' : '/login';
  }

  // Fallback: if the role provider didn't resolve to creator but a
  // creator_profile document exists, treat as creator anyway.
  // This handles dev environments where the setUserRole Cloud Function
  // is not available and the custom claim never propagates.
  final effectiveRole = hasCreatorProfile ? UserRole.creator : role;

  if (effectiveRole == UserRole.creator) {
    final progress = creatorOnboarding?.progress ?? 0;
    final isComplete = creatorOnboarding?.isComplete ?? false;
    if (isComplete) return '/creator/dashboard';
    switch (progress) {
      case 0:
        return '/onboarding/creator/archetype';
      case 1:
        return '/onboarding/creator/profile';
      default:
        return '/onboarding/creator/reveal';
    }
  }

  // Normal user or truly unknown role without creator profile.
  final progress = userOnboardingProgress;
  final isComplete = userOnboardingCompletedAt != null ||
      (progress != null && progress >= 3);
  if (isComplete) return '/';
  switch (progress ?? 0) {
    case 0:
    case 1:
      return '/onboarding/identity-studio';
    case 2:
      return '/onboarding/first-habit';
    default:
      return '/onboarding/world-reveal';
  }
}

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

    // Resolve the user role. Then do a direct Firestore check for a
    // creator_profile document as a fallback, regardless of role value.
    // This handles the dev-environment case where the setUserRole Cloud
    // Function is not running and the custom claim never propagates.
    final role = await ref.read(currentUserRoleProvider.future);
    if (!mounted) return;
    AppLogger.d('Splash: resolved role=$role');

    // Defensive: check creator_profiles directly for any non-creator result.
    // This catches creators whose role claim / mirror hasn't propagated yet.
    bool hasCreatorProfile = false;
    if (role != UserRole.creator) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '(null)';
      AppLogger.d('Splash: checking creator_profiles for uid=$uid');
      try {
        if (uid.isNotEmpty && uid != '(null)') {
          final creatorDoc = await FirebaseFirestore.instance
              .collection('creator_profiles')
              .doc(uid)
              .get();
          hasCreatorProfile = creatorDoc.exists;
          AppLogger.d(
            'Splash: creator_profiles/${uid}=${hasCreatorProfile ? "EXISTS" : "MISSING"}',
          );
        }
      } catch (e) {
        AppLogger.w('Splash: Firestore creator_profiles check failed: $e');
      }
    }

    if (!mounted) return;

    // Fetch creator onboarding state (needed for both known and
    // fallback-detected creators).
    final creatorOnboarding =
        await ref.read(currentCreatorOnboardingProvider.future);
    if (!mounted) return;

    // For normal users, seed Drift from Firestore.
    // Also grab onboardingProgress for the decision.
    final userId = ref.read(authStateChangesProvider).value?.id ?? '';
    bool seededFromFirestore = false;
    if (userId.isNotEmpty && role != UserRole.creator && !hasCreatorProfile) {
      AppLogger.d('Splash: Logged in, seeding Drift from Firestore...');
      try {
        final firestoreDoc = await FirebaseFirestore.instance
            .collection('user_stats')
            .doc(userId)
            .get();

        if (firestoreDoc.exists) {
          final data = firestoreDoc.data()!;
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
          seededFromFirestore = true;
          AppLogger.d('Splash: Drift seeded from Firestore (user_stats).');
        } else {
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

            final repo = ref.read(userStatsRepositoryProvider);
            await repo.seedFromFirestoreData(userId, {
              'displayName': data['displayName'],
              'photoUrl': data['photoUrl'],
              'archetype': data['archetype'],
              'onboardingProgress': progress,
              'onboardingCompletedAt': completedAt,
              'hasEmerged': data['hasEmerged'] as bool? ?? false,
            });
            seededFromFirestore = true;
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
        AppLogger.w('Splash: Could not seed Drift from Firestore: $e');
      }
    }

    if (!mounted) return;

    // Read user onboarding progress for the decision.
    int? userOnboardingProgress;
    DateTime? userOnboardingCompletedAt;
    if (role != UserRole.creator && !hasCreatorProfile) {
      if (seededFromFirestore) {
        final userStatsAsync = await ref.read(userStatsStreamProvider.future);
        if (!mounted) return;
        userOnboardingProgress = userStatsAsync.onboardingProgress;
        userOnboardingCompletedAt = userStatsAsync.onboardingCompletedAt;
      } else {
        userOnboardingProgress = 0;
        userOnboardingCompletedAt = null;
      }
    }

    if (!mounted) return;

    final nextRoute = determineSplashRoute(
      isLoggedIn: true,
      isFirstLaunch: ref.read(onboardingControllerProvider),
      role: role ?? UserRole.unknown,
      hasCreatorProfile: hasCreatorProfile,
      creatorOnboarding: creatorOnboarding,
      userOnboardingProgress: userOnboardingProgress,
      userOnboardingCompletedAt: userOnboardingCompletedAt,
    );

    AppLogger.d('Splash: Navigating to $nextRoute');
    if (mounted) {
      context.go(nextRoute);
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
