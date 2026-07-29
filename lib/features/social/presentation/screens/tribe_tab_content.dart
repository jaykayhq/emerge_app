import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/presentation/widgets/feature_coach_mark.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:emerge_app/features/companion/domain/enums/companion_enums.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_discovery_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_sanctum_tab.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_quests_tab.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_members_tab.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_bonds_tab.dart';

class TribeTabContent extends ConsumerStatefulWidget {
  const TribeTabContent({super.key});

  @override
  ConsumerState<TribeTabContent> createState() => _TribeTabContentState();
}

class _TribeTabContentState extends ConsumerState<TribeTabContent> {
  bool _showFirstVisitGuide = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final repo = ref.read(companionRepositoryProvider);
      if (!repo.hasVisited('/tribes')) {
        repo.markVisited('/tribes');
        ref
            .read(companionEngineProvider.notifier)
            .triggerEvent(
              eventType: CompanionEventType.firstFeatureVisit,
              userContext: {'route': '/tribes'},
            );
        setState(() => _showFirstVisitGuide = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasClubAsync = ref.watch(hasClubProvider);
    final profileAsync = ref.watch(userStatsStreamProvider);
    final profile = profileAsync.asData?.value;
    final theme = profile != null
        ? ArchetypeTheme.forArchetype(profile.archetype)
        : null;

    return Stack(
      children: [
        hasClubAsync.when(
          data: (hasClub) {
            if (!hasClub) return const TribeDiscoveryScreen();
            return DefaultTabController(
              length: 4,
              child: Scaffold(
                body: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) =>
                                    const TribeDiscoveryScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.explore, size: 18),
                          label: const Text('SEE ALL TRIBES'),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: TabBar(
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicator: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    (theme?.primaryColor ?? Colors.cyan)
                                        .withValues(alpha: 0.25),
                                    (theme?.accentColor ?? Colors.teal)
                                        .withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: (theme?.primaryColor ?? Colors.cyan)
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.white54,
                              labelStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              tabs: const [
                                Tab(text: 'SANCTUM'),
                                Tab(text: 'QUESTS'),
                                Tab(text: 'MEMBERS'),
                                Tab(text: 'BONDS'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: const [
                          TribeSanctumTab(),
                          TribeQuestsTab(),
                          TribeMembersTab(),
                          TribeBondsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const EmergeLoadingSkeleton(itemCount: 5),
          error: (_, _) => const TribeSanctumTab(),
        ),
        if (_showFirstVisitGuide)
          FeatureCoachMark(
            title: "Tribe Sanctum",
            primaryColor: EmergeColors.green,
            items: const [
              CoachItemData(
                icon: Icons.shield_outlined,
                title: "Tribe Momentum Score",
                body: "Check your team's current weekly momentum, active members, and territory tier.",
              ),
              CoachItemData(
                icon: Icons.people_outline,
                title: "Tribe Accountability",
                body: "Track who completed which habits today and maintain your collective streak.",
              ),
            ],
            onDismiss: () => setState(() => _showFirstVisitGuide = false),
          ),
      ],
    );
  }
}
