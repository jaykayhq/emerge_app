import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/skeleton_shimmer.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/social/presentation/screens/blueprint_detail_screen.dart';
import 'package:emerge_app/features/tutorial/presentation/providers/tutorial_provider.dart';
import 'package:emerge_app/features/tutorial/presentation/widgets/tutorial_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

class SocialDiscoverTab extends ConsumerStatefulWidget {
  const SocialDiscoverTab({super.key});

  @override
  ConsumerState<SocialDiscoverTab> createState() => _SocialDiscoverTabState();
}

class _SocialDiscoverTabState extends ConsumerState<SocialDiscoverTab> {
  final GlobalKey _blueprintsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkTutorial();
  }

  void _checkTutorial() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      final tutorialNotifier = ref.read(tutorialProvider.notifier);
      final tutorialState = ref.read(tutorialProvider);

      tutorialNotifier.enableTutorialAutoShow();

      if (!tutorialState.isCompleted(TutorialStep.discover) &&
          tutorialNotifier.shouldShowTutorial()) {
        _showTutorial();
      }
    });
  }

  void _showTutorial() {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => TutorialOverlay(
        steps: [
          TutorialStepInfo(
            title: 'Creator Blueprints',
            description: 'Explore complete behavioral systems designed by top performers. Adopt them to fast-track your identity shift.',
            targetKey: _blueprintsKey,
          ),
          TutorialStepInfo(
            title: 'Choose Your Path',
            description: 'Browse through different categories of blueprints to find the one that resonates with your future self.',
            targetKey: _blueprintsKey,
          ),
        ],
        onCompleted: () {
          ref
              .read(tutorialProvider.notifier)
              .completeStep(TutorialStep.discover);
          entry.remove();
        },
      ),
    );
    Overlay.of(context).insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final blueprintsAsync = ref.watch(allBlueprintsStreamProvider);

    return blueprintsAsync.when(
      data: (blueprints) {
        // Group blueprints by category
        final grouped = <String, List<Blueprint>>{};
        for (final bp in blueprints) {
          final cat = bp.category;
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
              key: entry.key == 0 ? _blueprintsKey : null,
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
                child: SkeletonShimmer(width: 240, height: 200, borderRadius: 20),
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

  const _CategoryStrip({super.key, required this.title, required this.items});

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
