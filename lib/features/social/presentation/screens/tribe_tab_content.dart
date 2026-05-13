import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/features/tutorial/presentation/providers/tutorial_provider.dart';
import 'package:emerge_app/features/tutorial/presentation/widgets/tutorial_overlay.dart';
import 'package:go_router/go_router.dart';

import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';

import '../widgets/tribe_header_widgets.dart';
import '../widgets/tribe_quests_section.dart';
import '../widgets/tribe_activity_feed.dart';
import '../widgets/tribe_accountability_section.dart';

/// Tribe Tab Content - Shared between CommunityScreen (tab) and TribesScreen (standalone)
class TribeTabContent extends ConsumerStatefulWidget {
  const TribeTabContent({super.key});

  @override
  ConsumerState<TribeTabContent> createState() => _TribeTabContentState();
}

class _TribeTabContentState extends ConsumerState<TribeTabContent> {
  bool _showGlobalActivity = false;
  final GlobalKey _emblemKey = GlobalKey();
  final GlobalKey _bondsKey = GlobalKey();
  final GlobalKey _feedKey = GlobalKey();

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

      if (!tutorialState.isCompleted(TutorialStep.tribes) &&
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
            title: 'Your Archetype Tribe',
            description:
                'You\'ve been grouped with others who share your primary archetype. Together, you build collective momentum.',
            targetKey: _emblemKey,
          ),
          TutorialStepInfo(
            title: 'Collective Momentum',
            description:
                'Toggle between your Tribe\'s focused activity and Global progress. Seeing the world grow together fuels your identity.',
            targetKey: _feedKey,
          ),
          TutorialStepInfo(
            title: 'Social Witnessing',
            description:
                'See how your tribe members are progressing. Witnessing others\' wins strengthens your own commitment.',
            targetKey: _feedKey,
            alignment: Alignment.topCenter,
          ),
          TutorialStepInfo(
            title: 'Accountability Bonds',
            description:
                'Form deep contracts with partners. High-stakes accountability is the ultimate "skin in the game".',
            targetKey: _bondsKey,
          ),
        ],
        onCompleted: () {
          ref.read(tutorialProvider.notifier).completeStep(TutorialStep.tribes);
          entry.remove();
        },
      ),
    );
    Overlay.of(context).insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userStatsStreamProvider);
    final clubsAsync = ref.watch(allArchetypeClubsProvider);

    return clubsAsync.when(
      data: (clubs) {
        return profileAsync.when(
          data: (profile) {
            final theme = ArchetypeTheme.forArchetype(profile.archetype);

            // Find the club that matches the user's archetype
            final matchingIndex = clubs.isNotEmpty
                ? clubs.indexWhere(
                    (club) => club.archetypeId == profile.archetype.name,
                  )
                : -1;
            final userClub = matchingIndex != -1 ? clubs[matchingIndex] : null;

            if (userClub == null) {
              return const _EmptyState(
                message: 'No clubs available for your archetype yet.',
                icon: Icons.groups,
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(allArchetypeClubsProvider);
                ref.invalidate(userStatsStreamProvider);
              },
              color: EmergeColors.teal,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const Gap(16),

                    // ===== CLUB EMBLEM (Archetype-colored) =====
                    ArchetypeClubEmblem(
                      key: _emblemKey,
                      theme: theme,
                    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),

                    const Gap(16),

                    // ===== CLUB NAME & SUBTITLE =====
                    Text(
                      userClub.name.toUpperCase(),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                    ).animate().fadeIn(delay: 100.ms),
                    const Gap(4),
                    Text(
                      userClub.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ).animate().fadeIn(delay: 150.ms),

                    const Gap(16),

                    // ===== MEMBER COUNT (Real-time from members array) =====
                    RealTimeMemberCount(
                      tribeId: userClub.id,
                    ).animate().fadeIn(delay: 200.ms),

                    const Gap(32),

                    // ===== TOP CONTRIBUTORS =====
                    ContributorsSection(
                      clubId: userClub.id,
                    ).animate().fadeIn(delay: 300.ms),

                    const Gap(32),

                    // ===== PROGRESS METRICS (Real-time stats) =====
                    RealTimeTribeProgressMetrics(
                      isGlobal: _showGlobalActivity,
                      tribeId: userClub.id,
                      theme: theme,
                    ).animate().fadeIn(delay: 350.ms),

                    const Gap(32),

                    TribeAccountabilitySection(
                      key: _bondsKey,
                    ).animate().fadeIn(delay: 400.ms),

                    const Gap(32),

                    // ===== ACTIVE QUESTS =====
                    const TribeQuestsSection().animate().fadeIn(delay: 450.ms),

                    const Gap(32),

                    // ===== ACTIVITY FEED HEADER CON toggle =====
                    Row(
                      key: _feedKey,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _showGlobalActivity
                              ? 'Global Activity'
                              : 'Recent Activity',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: EmergeColors.glassWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: EmergeColors.glassBorder),
                          ),
                          child: Row(
                            children: [
                              _ToggleItem(
                                label: 'Tribe',
                                isSelected: !_showGlobalActivity,
                                onTap: () =>
                                    setState(() => _showGlobalActivity = false),
                              ),
                              _ToggleItem(
                                label: 'Global',
                                isSelected: _showGlobalActivity,
                                onTap: () =>
                                    setState(() => _showGlobalActivity = true),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 500.ms),

                    const Gap(16),

                    // ===== ACTIVITY FEED =====
                    TribeActivitySection(
                      clubId: _showGlobalActivity ? null : userClub.id,
                      isGlobal: _showGlobalActivity,
                    ).animate().fadeIn(delay: 550.ms),

                    const Gap(32),

                    // ===== SEE ALL TRIBES =====
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/tribes/all'),
                        icon: const Icon(Icons.explore_outlined, size: 20),
                        label: const Text('SEE ALL'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms),

                    const Gap(48),
                  ],
                ),
              ),
            );
          },
          loading: () => const EmergeLoadingSkeleton(itemCount: 1),
          error: (error, stack) => AppErrorWidget(
            message: 'Could not load your profile',
            onRetry: () => ref.invalidate(userStatsStreamProvider),
          ),
        );
      },
      loading: () => const EmergeLoadingSkeleton(itemCount: 5),
      error: (error, _) => AppErrorWidget(
        message: 'Could not load tribes',
        onRetry: () => ref.invalidate(allArchetypeClubsProvider),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyState({required this.message, this.icon = Icons.info_outline});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.white38),
            const Gap(16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? EmergeColors.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }
}
