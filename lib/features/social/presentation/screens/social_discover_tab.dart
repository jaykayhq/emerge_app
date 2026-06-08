import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/skeleton_shimmer.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/social/presentation/screens/blueprint_detail_screen.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:emerge_app/features/companion/domain/enums/companion_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

class SocialDiscoverTab extends ConsumerStatefulWidget {
  const SocialDiscoverTab({super.key});

  @override
  ConsumerState<SocialDiscoverTab> createState() => _SocialDiscoverTabState();
}

/// Blueprint categories that should be displayed. Old archetype categories
/// (Athlete, Creator, Scholar, Stoic, Zealot) are excluded even if they
/// still exist in Firestore from previous seed data.
const _displayedBlueprintCategories = {
  'Morning',
  'Productivity',
  'Fitness',
  'Mindfulness',
  'Learning',
};

class _SocialDiscoverTabState extends ConsumerState<SocialDiscoverTab> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final repo = ref.read(companionRepositoryProvider);
      if (!repo.hasVisited('/discover')) {
        repo.markVisited('/discover');
        ref.read(companionEngineProvider.notifier).triggerEvent(
          eventType: CompanionEventType.firstFeatureVisit,
          userContext: {'route': '/discover'},
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final blueprintsAsync = ref.watch(allBlueprintsStreamProvider);

    return blueprintsAsync.when(
      data: (blueprints) {
        // Group blueprints by category (filter out old archetype categories)
        final grouped = <String, List<Blueprint>>{};
        for (final bp in blueprints) {
          final cat = bp.category;
          if (!_displayedBlueprintCategories.contains(cat)) continue;
          grouped.putIfAbsent(cat, () => []).add(bp);
        }

        final categories = grouped.keys.toList()..sort();

        if (categories.isEmpty) {
          return const _EmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allBlueprintsStreamProvider);
          },
          color: EmergeColors.teal,
          child: ListView(
            padding: const EdgeInsets.only(top: 16, bottom: 40),
            children: categories.asMap().entries.map((entry) {
              final category = entry.value;
              final items = grouped[category]!;
              return _CategoryStrip(
                title: category,
                items: items,
              );
            }).toList(),
          ),
        );
      },
      loading: () => _buildShimmerLoading(),
      error: (err, stack) => Center(
        child: AppErrorWidget(
          message: 'Could not load blueprints',
          onRetry: () => ref.refresh(allBlueprintsStreamProvider),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 24),
      itemCount: 3,
      itemBuilder: (context, index) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SkeletonShimmer(width: 150, height: 24),
          ),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 3,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SkeletonShimmer(
                  width: 240,
                  height: 200,
                  borderRadius: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final String title;
  final List<Blueprint> items;

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
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white24,
                size: 14,
              ),
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
  final Blueprint blueprint;

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
                        ? (blueprint.imageUrl!.startsWith('images/')
                              ? Image.asset(
                                  blueprint.imageUrl!,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  blueprint.imageUrl!,
                                  fit: BoxFit.cover,
                                ))
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.1),
                                  Colors.white.withValues(alpha: 0.05),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white10,
                              size: 40,
                            ),
                          ),

                    // Shadow Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(12),
            Text(
              blueprint.title,
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
            color: Colors.white.withValues(alpha: 0.1),
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
