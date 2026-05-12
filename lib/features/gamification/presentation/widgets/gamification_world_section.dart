import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/world_view.dart';
import 'package:emerge_app/features/habits/presentation/widgets/momentum_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class GamificationWorldSection extends ConsumerWidget {
  const GamificationWorldSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatsAsync = ref.watch(userStatsStreamProvider);
    return userStatsAsync.when(
      data: (profile) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WorldView(
              worldState: profile.worldState,
              isCity:
                  profile.archetype == UserArchetype.creator ||
                  profile.archetype == UserArchetype.scholar, // Example logic
            ),
            const Gap(12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'World Momentum',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Gap(6),
                  MomentumBar(
                    momentumScore: profile.avatarStats.momentumScore,
                    streakState: profile.avatarStats.momentumState,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}
