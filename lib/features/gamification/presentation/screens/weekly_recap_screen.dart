import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/gamification/domain/services/weekly_recap_service.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/spotify_wrapped_recap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class WeeklyRecapScreen extends ConsumerStatefulWidget {
  const WeeklyRecapScreen({super.key});

  @override
  ConsumerState<WeeklyRecapScreen> createState() => _WeeklyRecapScreenState();
}

class _WeeklyRecapScreenState extends ConsumerState<WeeklyRecapScreen> {
  @override
  Widget build(BuildContext context) {
    final recapService = ref.read(weeklyRecapServiceProvider);

    final user = ref.watch(authStateChangesProvider).value;

    // If no user logic handled by auth wrapper or router usually, but safety check:
    if (user == null) {
      return const Scaffold(
        backgroundColor: EmergeColors.background,
        body: Center(
          child: CircularProgressIndicator(color: EmergeColors.teal),
        ),
      );
    }

    return Scaffold(
      backgroundColor: EmergeColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: HexMeshBackground()),
          FutureBuilder(
            future: recapService.generateRecapIfNeeded(user.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: EmergeColors.teal),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                // Show locked state for new users (< 7 days)
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 64,
                        color: EmergeColors.teal.withValues(alpha: 0.5),
                      ),
                      const Gap(24),
                      Text(
                        'Weekly Recap Unlocks After 7 Days',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Gap(12),
                      Text(
                        'Complete habits for a full week to see your stats',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Gap(32),
                      ElevatedButton(
                        onPressed: () => context.pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.surfaceDark,
                          foregroundColor: AppTheme.textMainDark,
                        ),
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                );
              }

              final recap = snapshot.data!;

              // Use the new Spotify Wrapped-style widget
              return SpotifyWrappedRecap(
                recap: recap,
                onClose: () => context.pop(),
              );
            },
          ),
        ],
      ),
    );
  }
}
