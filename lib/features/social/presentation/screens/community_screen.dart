import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/social/presentation/screens/challenges_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/friends_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_tab_content.dart';
import 'package:emerge_app/features/social/presentation/screens/create_solo_challenge_dialog.dart';
import 'package:emerge_app/features/social/domain/services/online_presence_service.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/features/tutorial/presentation/providers/tutorial_provider.dart';
import 'package:emerge_app/features/tutorial/presentation/widgets/tutorial_overlay.dart';

/// Community Screen - Stitch Design "Identity Club Home"
/// Features: Club stats card, Weekly goal, Top contributors, Activity feed
class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  final GlobalKey _challengesTabKey = GlobalKey();
  final GlobalKey _tribeTabKey = GlobalKey();
  final GlobalKey _friendsTabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    // Start presence heartbeat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateChangesProvider).value;
      if (user != null && user.isNotEmpty) {
        ref.read(onlinePresenceServiceProvider).startHeartbeat(user.id);
      }
      _checkTutorial();
    });
  }

  void _checkTutorial() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final tutorialNotifier = ref.read(tutorialProvider.notifier);
      final tutorialState = ref.watch(tutorialProvider);
      tutorialNotifier.enableTutorialAutoShow();

      // Check if any of the social tutorials need to be shown
      if (tutorialNotifier.shouldShowTutorial()) {
        if (!tutorialState.isCompleted(TutorialStep.community) ||
            !tutorialState.isCompleted(TutorialStep.challenges) ||
            !tutorialState.isCompleted(TutorialStep.friends)) {
          _showSocialTutorial();
        }
      }
    });
  }

  void _showSocialTutorial() {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => TutorialOverlay(
        steps: [
          TutorialStepInfo(
            title: 'The Collective Forge',
            description:
                'Your Tribe is your core identity support system. Together, you manifest collective growth and compete for archetype dominance.',
            targetKey: _tribeTabKey,
          ),
          TutorialStepInfo(
            title: 'Heroic Feats',
            description:
                'Join community challenges to push your limits and earn massive XP. Shared growth is accelerated growth.',
            targetKey: _challengesTabKey,
          ),
          TutorialStepInfo(
            title: 'Bonding in the Cosmos',
            description:
                'Forge direct links with other explorers. Accountability vows ensure you never drift alone into the void.',
            targetKey: _friendsTabKey,
          ),
        ],
        onCompleted: () {
          final notifier = ref.read(tutorialProvider.notifier);
          notifier.completeStep(TutorialStep.community);
          notifier.completeStep(TutorialStep.challenges);
          notifier.completeStep(TutorialStep.friends);
          entry.remove();
        },
      ),
    );
    Overlay.of(context).insert(entry);
  }

  @override
  void dispose() {
    // Stop presence heartbeat when exiting social hub
    ref.read(onlinePresenceServiceProvider).stopHeartbeat();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmergeColors.background,
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierColor: Colors.black.withValues(alpha: 0.6),
                  builder: (context) => const CreateSoloChallengeDialog(),
                );
              },
              backgroundColor: EmergeColors.teal,
              foregroundColor: Colors.black,
              child: const Icon(Icons.add_rounded, size: 32),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.cosmicGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    if (_isSearching)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: EmergeColors.glassWhite,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: EmergeColors.glassBorder),
                          ),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search friends & clubs...',
                              hintStyle: TextStyle(
                                color: AppTheme.textSecondaryDark.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Text(
                          'TRIBES',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.textMainDark,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        _isSearching ? Icons.close : Icons.search,
                        color: EmergeColors.teal,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_isSearching) {
                            _isSearching = false;
                            _searchController.clear();
                          } else {
                            _isSearching = true;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: EmergeColors.glassWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EmergeColors.glassBorder),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: EmergeColors.teal,
                  unselectedLabelColor: AppTheme.textSecondaryDark,
                  indicatorColor: EmergeColors.teal,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(key: _challengesTabKey, text: 'Challenges'),
                    Tab(key: _tribeTabKey, text: 'Tribe'),
                    Tab(key: _friendsTabKey, text: 'Friends'),
                  ],
                ),
              ),

              const Gap(16),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    const ChallengesTabContent(),
                    const TribeTabContent(),
                    const FriendsTabContent(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // CLUBS TAB - Shows user's archetype club from seeded data
  // ==========================================================================
}
