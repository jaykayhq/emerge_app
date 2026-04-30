import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/domain/models/app_world_theme.dart';
import 'package:emerge_app/core/presentation/widgets/world_background.dart';
import 'package:emerge_app/core/presentation/widgets/archetype_sliver_app_bar.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_tab_content.dart';
import 'package:emerge_app/features/social/presentation/screens/tribe_feed_tab.dart';
import 'package:emerge_app/features/social/presentation/screens/create_solo_challenge_dialog.dart';
import 'package:emerge_app/features/social/presentation/screens/social_discover_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Consolidated Social Screen for the 3-tab layout
/// Hosts Archetype Tribe info, Challenges, and Discovery
class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentIndex) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildCurrentTabContent() {
    switch (_currentIndex) {
      case 0:
        return const TribeFeedTab(); // FEED
      case 1:
        return const TribeTabContent(); // MY TRIBE
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
      floatingActionButton: _currentIndex == 1 // MY TRIBE tab gets the create challenge FAB
          ? FloatingActionButton(
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
                    Tab(text: 'FEED'),
                    Tab(text: 'MY TRIBE'),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha:0.4), // Reduced opacity for glassy look
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha:0.05),
            width: 1,
          ),
        ),
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
