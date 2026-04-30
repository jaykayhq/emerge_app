import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/presentation/providers/blueprint_providers.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_bundle_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/blueprint_detail_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/challenge_detail_screen.dart';
import 'package:emerge_app/features/social/data/repositories/challenge_repository.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:emerge_app/features/social/data/repositories/blueprint_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

class SocialDiscoverTab extends ConsumerWidget {
  const SocialDiscoverTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blueprintsAsync = ref.watch(blueprintsStreamProvider);
    final featuredChallenges = ref.watch(featuredChallengesFromBundleProvider);

    // Trigger seeding if empty
    Future.microtask(() {
      if (blueprintsAsync.hasValue && blueprintsAsync.value!.isEmpty) {
        ref.read(blueprintRepositoryProvider).seedBlueprintsIfEmpty();
      }
      if (featuredChallenges.isEmpty) {
        final repo = ref.read(challengeRepositoryProvider);
        if (repo is FirestoreChallengeRepository) {
          repo.seedChallengesIfEmpty();
        }
      }
    });

    return blueprintsAsync.when(
      data: (blueprints) {
        // Group blueprints by category
        final grouped = <String, List<CreatorBlueprint>>{};
        for (final bp in blueprints) {
          final cat = bp.category ?? 'Uncategorized';
          grouped.putIfAbsent(cat, () => []).add(bp);
        }

        final categories = grouped.keys.toList()..sort();

        return ListView(
          padding: const EdgeInsets.only(top: 16, bottom: 40),
          children: [
            // Featured Challenges section
            if (featuredChallenges.isNotEmpty)
              _FeaturedChallengesStrip(challenges: featuredChallenges),

            // Blueprint categories
            if (categories.isEmpty && featuredChallenges.isEmpty)
              const _EmptyState()
            else
              ...categories.map((category) {
                final items = grouped[category]!;
                return _CategoryStrip(title: category, items: items);
              }),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: EmergeColors.teal),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Error: $err',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }
}

class _FeaturedChallengesStrip extends StatelessWidget {
  final List<Challenge> challenges;

  const _FeaturedChallengesStrip({required this.challenges});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FEATURED QUESTS',
                style: GoogleFonts.outfit(
                  color: EmergeColors.teal,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Icon(Icons.star_rounded, color: EmergeColors.teal, size: 18),
            ],
          ),
        ),
        const Gap(8),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              return _ChallengeStripCard(challenge: challenge);
            },
          ),
        ),
        const Gap(32),
      ],
    );
  }
}

class _ChallengeStripCard extends StatelessWidget {
  final Challenge challenge;

  const _ChallengeStripCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChallengeDetailScreen(challenge: challenge),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              challenge.imageUrl.isNotEmpty
                  ? (challenge.imageUrl.startsWith('assets/')
                      ? Image.asset(challenge.imageUrl, fit: BoxFit.cover)
                      : Image.network(challenge.imageUrl, fit: BoxFit.cover))
                  : Container(color: Colors.white10),
              
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha:0.9),
                    ],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Text(
                            '${challenge.xpReward} XP',
                            style: const TextStyle(
                              color: EmergeColors.yellow,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Gap(8),
                        const Icon(Icons.people, color: Colors.white70, size: 14),
                        const Gap(4),
                        Text(
                          '${challenge.participants}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                    const Gap(8),
                    Text(
                      challenge.title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      challenge.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final String title;
  final List<CreatorBlueprint> items;

  const _CategoryStrip({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _BlueprintStripCard(blueprint: items[index]);
            },
          ),
        ),
        const Gap(24),
      ],
    );
  }
}

class _BlueprintStripCard extends StatelessWidget {
  final CreatorBlueprint blueprint;

  const _BlueprintStripCard({required this.blueprint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlueprintDetailScreen(blueprint: blueprint),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image
                    blueprint.imageUrl != null
                        ? (blueprint.imageUrl!.startsWith('assets/')
                            ? Image.asset(blueprint.imageUrl!, fit: BoxFit.cover)
                            : Image.network(blueprint.imageUrl!, fit: BoxFit.cover))
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha:0.1),
                                  Colors.white.withValues(alpha:0.05),
                                ],
                              ),
                            ),
                            child: const Icon(Icons.auto_awesome, color: Colors.white10, size: 40),
                          ),
                    
                    // Shadow Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha:0.5),
                          ],
                        ),
                      ),
                    ),

                    // Badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                          blueprint.creatorArchetype.toUpperCase(),
                          style: const TextStyle(
                            color: EmergeColors.teal,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(12),
            Text(
              blueprint.blueprintName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(4),
            Text(
              'By ${blueprint.creatorName}',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_outlined,
            size: 64,
            color: Colors.white.withValues(alpha:0.1),
          ),
          const Gap(16),
          const Text(
            'NO CONTENT FOUND',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const Gap(8),
          const Text(
            'Check back later for curated behavioral paths.',
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
