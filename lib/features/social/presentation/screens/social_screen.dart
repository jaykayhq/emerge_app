import 'dart:ui';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/core/presentation/widgets/world_background.dart';
import 'package:emerge_app/core/presentation/widgets/archetype_sliver_app_bar.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_tab_content.dart';
import 'package:emerge_app/features/social/presentation/screens/challenges_screen.dart';
import 'package:emerge_app/features/social/presentation/screens/create_solo_challenge_dialog.dart';
import 'package:emerge_app/features/social/presentation/screens/social_discover_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Consolidated Social Screen for the 3-tab layout
/// Hosts Archetype Tribe info, Challenges, and Discovery
class SocialScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const SocialScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _currentIndex,
    );
    _tabController.addListener(() {
      if (_tabController.index != _currentIndex) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void didUpdateWidget(SocialScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex &&
        widget.initialIndex != _currentIndex) {
      _tabController.animateTo(widget.initialIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildCurrentTabContent() {
    switch (_currentIndex) {
      case 0:
        return const TribeTabContent(); // TRIBE
      case 1:
        return const ChallengesScreen(showAppBar: false); // CHALLENGES
      case 2:
        return const SocialDiscoverTab(); // DISCOVER
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WorldBackground(
      useSafeArea: false,
      themeOverride: AppWorldTheme.nebula,
      floatingActionButton: _currentIndex == 1 // CHALLENGES tab gets the create challenge FAB
          ? FloatingActionButton(
              heroTag: 'create_challenge_fab',
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierColor: Colors.black.withValues(alpha:0.6),
                  builder: (context) => const CreateSoloChallengeDialog(),
                );
              },
              backgroundColor: EmergeColors.teal,
              foregroundColor: Colors.black,
              child: const Icon(Icons.add_rounded, size: 32),
            )
          : null,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            ArchetypeSliverAppBar(
              title: 'TRIBES',
              actions: [
                IconButton(
                  icon: const Icon(Icons.handshake_outlined, color: Colors.white),
                  onPressed: () => context.push('/tribes/contracts'),
                  tooltip: 'Habit Contracts',
                ),
                IconButton(
                  icon: const Icon(Icons.person_add_outlined, color: Colors.white),
                  onPressed: () => context.push('/tribes/accountability'),
                  tooltip: 'Accountability Partners',
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline, color: Colors.white),
                  onPressed: () => context.push('/profile'),
                  tooltip: 'Future Self Studio',
                ),
              ],
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: EmergeColors.teal,
                  labelColor: EmergeColors.teal,
                  unselectedLabelColor: Colors.white60,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'TRIBE'),
                    Tab(text: 'CHALLENGES'),
                    Tab(text: 'DISCOVER'),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              child: _buildCurrentTabContent(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha:0.4),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha:0.08),
                width: 1,
              ),
            ),
          ),
          child: _tabBar,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
