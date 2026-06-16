import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/presentation/widgets/world_background.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';

class TribeLobbyScreen extends ConsumerWidget {
  const TribeLobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userStatsStreamProvider);
    final clubsAsync = ref.watch(allArchetypeClubsProvider);

    return WorldBackground(
      child: SafeArea(
        child: clubsAsync.when(
          data: (clubs) {
            return profileAsync.when(
              data: (profile) {
                final matchingIndex = clubs.isNotEmpty
                    ? clubs.indexWhere(
                        (club) => club.archetypeId == profile.archetype.name,
                      )
                    : -1;
                final userClub = matchingIndex != -1
                    ? clubs[matchingIndex]
                    : clubs.isNotEmpty ? clubs.first : null;

                if (userClub == null) {
                  return const Center(
                    child: Text(
                      'No tribes available yet.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                final completionRatio = profile.momentumScore;

                return Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            children: [
                              Text(
                                userClub.name.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${userClub.memberCount} members \u00b7 Your streak: \u{1F525}${profile.avatarStats.streak}d',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                '\u{1F5E1}\uFE0F Collective Quest: ${(completionRatio * 100).toInt()}%',
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: completionRatio.clamp(0.0, 1.0),
                                backgroundColor: Colors.white24,
                                color: EmergeColors.green,
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.flash_on),
                                label: const Text("ENTER TRIBE"),
                                onPressed: () {
                                  context.push('/social/space');
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Could not load profile.',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (err, _) => Center(
            child: Text(
              'Could not load tribes.',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}
