import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:emerge_app/features/companion/domain/enums/companion_enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/presentation/widgets/feature_coach_mark.dart';
import 'package:emerge_app/core/utils/app_logger.dart';

import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/leaderboard_provider.dart';
import 'package:emerge_app/features/social/domain/entities/leaderboard_entry.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/onboarding/presentation/widgets/club_box_card.dart';
import 'package:emerge_app/features/onboarding/presentation/widgets/club_emblem_images.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/monetization/presentation/widgets/premium_limit_dialog.dart';
import 'package:emerge_app/features/onboarding/presentation/widgets/club_preview_sheet.dart';
import '../widgets/tribe_header_widgets.dart';
import '../widgets/tribe_quests_section.dart';
import '../widgets/tribe_activity_feed.dart';
import '../widgets/tribe_accountability_section.dart';

/// Merged pool of clubs shown in the discovery grid (Plan 5, Task 7):
/// every tribe in the `tribes` collection — official archetype clubs plus
/// creator / brand / public clubs. Mapped from Firestore docs to [Tribe].
/// Cards derive their ARCHETYPE/CREATOR tag from [Tribe.archetypeId].
final discoveryClubsProvider = StreamProvider<List<Tribe>>((ref) {
  return FirebaseFirestore.instance
      .collection('tribes')
      .snapshots()
      .map((snap) => snap.docs.map((d) => Tribe.fromMap(d.data())).toList());
});

/// Whether the signed-in user belongs to any club.
///
/// Derived from [tribeRepositoryProvider.getUserTribes]: a user "has a club"
/// when they appear in the `members` array of at least one tribe. Returns
/// false while signed out or while the membership lookup is in flight.
final hasClubProvider = FutureProvider<bool>((ref) async {
  final authUser = await ref.watch(authStateChangesProvider.future);
  if (authUser.isEmpty) return false;
  try {
    final repo = ref.watch(tribeRepositoryProvider);
    final tribes = await repo.getUserTribes(authUser.id);
    return tribes.isNotEmpty;
  } catch (e, s) {
    // Treat a failed lookup as "no club" rather than blocking the UI.
    AppLogger.e('hasClubProvider: getUserTribes failed', e, s);
    return false;
  }
});

/// Whether a free-tier user is blocked from joining another club.
///
/// Returns true (and shows the premium limit dialog) when a non-premium user
/// is already a member of at least one club. Premium status is resolved via
/// [isPremiumProvider.future] so the real entitlement is awaited rather than a
/// stale synchronous snapshot. Fails CLOSED: if the membership lookup errors,
/// the join is blocked and the user is told to retry (mirrors the fail-closed
/// habit gate and prevents free users from silently exceeding the cap).
Future<bool> clubJoinBlockedByFreeTier(
  WidgetRef ref,
  BuildContext context,
  String userId,
) async {
  bool isPremium = false;
  try {
    isPremium = await ref.read(isPremiumProvider.future);
  } catch (e, s) {
    AppLogger.e('clubJoinBlockedByFreeTier: isPremium resolve failed', e, s);
  }
  if (isPremium) return false;
  try {
    final tribes = await ref.read(tribeRepositoryProvider).getUserTribes(userId);
    if (!context.mounted) return true;
    if (tribes.isNotEmpty) {
      showPremiumLimitDialog(context, limitType: PremiumLimitType.club);
      return true;
    }
    return false;
  } catch (e, s) {
    // Fail closed: block the join and surface a retry message.
    AppLogger.e('clubJoinBlockedByFreeTier: getUserTribes failed', e, s);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't verify your membership — please try again."),
        ),
      );
    }
    return true;
  }
}

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

  bool _showFirstVisitGuide = false;

  // Discovery view local state (kept in-sync with the file's StatefulWidget idiom).
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All' | 'By Archetype' | 'Creator'

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

    return Stack(
      children: [
        hasClubAsync.when(
          data: (hasClub) {
            if (!hasClub) return _buildDiscoveryView(context);
            return _buildClubTabs(context);
          },
          loading: () => const EmergeLoadingSkeleton(itemCount: 5),
          error: (_, _) => _buildClubTabs(context),
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

  // ============ DISCOVERY VIEW (no club) ============

  Widget _buildDiscoveryView(BuildContext context) {
    final clubsAsync = ref.watch(discoveryClubsProvider);

    return clubsAsync.when(
      data: (clubs) {
        final filtered = _filterClubs(clubs);
        final columns =
            MediaQuery.of(context).size.width > 600 ? 4 : 3;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildFilterChips()),
            if (filtered.isEmpty)
              SliverFillRemaining(
                child: _EmptyState(
                  message: _searchQuery.isEmpty
                      ? 'No clubs to discover yet.'
                      : 'No clubs match "$_searchQuery".',
                  icon: Icons.search_off,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final club = filtered[index];
                      return ClubBoxCard(
                        title: club.name,
                        imageUrl: clubEmblemImageUrl(
                          existingImageUrl: club.imageUrl,
                          archetypeId: club.archetypeId,
                          clubId: club.id,
                        ),
                        memberCount: club.memberCount,
                        activityStatus:
                            club.memberCount >= 10 ? '🔥 Active' : '🌙 Quiet',
                        typeTag: _typeTagFor(club),
                        onTap: () => _showPreviewSheet(context, club),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const EmergeLoadingSkeleton(itemCount: 6),
      error: (err, _) => _EmptyState(
        message: 'Could not load clubs',
        icon: Icons.groups,
      ),
    );
  }

  List<Tribe> _filterClubs(List<Tribe> clubs) {
    final query = _searchQuery.trim().toLowerCase();
    return clubs.where((club) {
      final matchesQuery = query.isEmpty ||
          club.name.toLowerCase().contains(query) ||
          club.description.toLowerCase().contains(query);
      if (!matchesQuery) return false;

      switch (_selectedFilter) {
        case 'By Archetype':
          return club.archetypeId != null && club.archetypeId!.isNotEmpty;
        case 'Creator':
          // Creator clubs are brand / user-owned (non-archetype) tribes.
          return club.archetypeId == null || club.archetypeId!.isEmpty;
        case 'All':
        default:
          return true;
      }
    }).toList();
  }

  String _typeTagFor(Tribe club) {
    return (club.archetypeId != null && club.archetypeId!.isNotEmpty)
        ? 'ARCHETYPE'
        : 'CREATOR';
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: '🔍 Search clubs...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: _selectedFilter == 'All',
            onSelected: () => setState(() => _selectedFilter = 'All'),
            icon: Icons.explore,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Archetype',
            selected: _selectedFilter == 'By Archetype',
            onSelected: () => setState(() => _selectedFilter = 'By Archetype'),
            icon: Icons.auto_awesome,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Creator',
            selected: _selectedFilter == 'Creator',
            onSelected: () => setState(() => _selectedFilter = 'Creator'),
            icon: Icons.person,
          ),
        ],
      ),
    );
  }

  void _showPreviewSheet(BuildContext context, Tribe club) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => ClubPreviewSheet(
        title: club.name,
        description: club.description,
        benefits: _benefitsFor(club),
        onJoin: () => _joinClub(club),
      ),
    );
  }

  List<String> _benefitsFor(Tribe club) {
    return [
      'Join ${club.memberCount} members on the same path',
      'Club challenges and shared XP (Lv ${club.level})',
      if (club.tags.isNotEmpty)
        'Focused on ${club.tags.take(3).join(', ')}'
      else
        'A tribe to anchor your habits',
    ];
  }

  Future<void> _joinClub(Tribe club) async {
    final authUser =
        ref.read(authStateChangesProvider).value;
    final userId = authUser?.id;
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to join a club')),
      );
      return;
    }
    // Free-tier gate: block joining a second club (free tier = 1) unless
    // premium. Resolves the real entitlement rather than a stale snapshot.
    if (!mounted) return;
    if (await clubJoinBlockedByFreeTier(ref, context, userId)) return;
    if (!mounted) return;
    try {
      await ref.read(tribeRepositoryProvider).joinClub(userId, club.id);
      // Membership changed → re-evaluate hasClub so the view switches to the
      // 4-tab layout, and refresh the discovery pool.
      ref.invalidate(hasClubProvider);
      ref.invalidate(discoveryClubsProvider);
    } catch (e, s) {
      AppLogger.e('TribeTabContent: joinClub failed', e, s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join: $e')),
      );
    }
  }

  // ============ CLUB TABS (has club) ============

  Widget _buildClubTabs(BuildContext context) {
    final profileAsync = ref.watch(userStatsStreamProvider);
    final clubsAsync = ref.watch(allArchetypeClubsProvider);

    return clubsAsync.when(
      data: (clubs) {
        return profileAsync.when(
          data: (profile) {
            final theme = ArchetypeTheme.forArchetype(profile.archetype);

            // Find the club that matches the user's archetype
            // First try exact archetype match, then fall back to multi-archetype clubs
            final matchingIndex = clubs.isNotEmpty
                ? clubs.indexWhere(
                    (club) => club.archetypeId == profile.archetype.name,
                  )
                : -1;
            final userClub = matchingIndex != -1
                ? clubs[matchingIndex]
                : clubs
                      .where(
                        (club) =>
                            club.archetypeId == null ||
                            club.archetypeId!.isEmpty,
                      )
                      .firstOrNull;

            if (userClub == null) {
              return const _EmptyState(
                message: 'No clubs available for your archetype yet.',
                icon: Icons.groups,
              );
            }

            return DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  // "SEE ALL TRIBES" — open the discovery view for users with a club.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _showDiscoveryView(context),
                        icon: const Icon(Icons.explore, size: 18),
                        label: const Text('SEE ALL TRIBES'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ),

                  // Secondary glassmorphic pill tab bar
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
                                  theme.primaryColor.withValues(alpha: 0.25),
                                  theme.accentColor.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: theme.primaryColor.withValues(alpha: 0.3),
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

                  // Tab contents
                  Expanded(
                    child: TabBarView(
                      children: [
                        // SANCTUM Tab
                        _buildSanctumTab(context, userClub, theme, profile),

                        // QUESTS Tab
                        _buildQuestsTab(),

                        // MEMBERS Tab
                        _buildMembersTab(userClub, profile),

                        // BONDS Tab
                        _buildBondsTab(),
                      ],
                    ),
                  ),
                ],
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

  /// Opens the discovery view as a full-screen modal for users who already
  /// have a club (the "SEE ALL TRIBES" button).
  void _showDiscoveryView(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const _DiscoveryScreen(),
      ),
    );
  }

  Widget _buildSanctumTab(BuildContext context, Tribe userClub, ArchetypeTheme theme, UserProfile profile) {
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
            ArchetypeClubEmblem(
              key: _emblemKey,
              theme: theme,
            ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
            const Gap(16),
            Text(
              userClub.name.toUpperCase(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
            RealTimeMemberCount(
              tribeId: userClub.id,
            ).animate().fadeIn(delay: 200.ms),
            const Gap(32),
            RealTimeTribeProgressMetrics(
              isGlobal: _showGlobalActivity,
              tribeId: userClub.id,
              theme: theme,
            ).animate().fadeIn(delay: 350.ms),
            const Gap(32),
            Row(
              key: _feedKey,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _showGlobalActivity ? 'Global Activity' : 'Recent Activity',
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
                        onTap: () => setState(() => _showGlobalActivity = false),
                      ),
                      _ToggleItem(
                        label: 'Global',
                        isSelected: _showGlobalActivity,
                        onTap: () => setState(() => _showGlobalActivity = true),
                      ),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 500.ms),
            const Gap(16),
            TribeActivitySection(
              clubId: _showGlobalActivity ? null : userClub.id,
              isGlobal: _showGlobalActivity,
            ).animate().fadeIn(delay: 550.ms),
            const Gap(32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Gap(16),
          const TribeQuestsSection(),
          const Gap(32),
        ],
      ),
    );
  }

  Widget _buildMembersTab(Tribe userClub, UserProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Gap(16),
          ContributorsSection(
            clubId: userClub.id,
          ).animate().fadeIn(delay: 300.ms),
          const Gap(32),
          _TribeLeaderboardSection(
            clubId: userClub.id,
            archetypeName: profile.archetype.name,
            isGlobal: _showGlobalActivity,
          ).animate().fadeIn(delay: 370.ms),
          const Gap(32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/tribes/all'),
              icon: const Icon(Icons.explore_outlined, size: 20),
              label: const Text('SEE ALL TRIBES'),
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
          const Gap(32),
        ],
      ),
    );
  }

  Widget _buildBondsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Gap(16),
          TribeAccountabilitySection(
            key: _bondsKey,
          ).animate().fadeIn(delay: 400.ms),
          const Gap(32),
        ],
      ),
    );
  }
}

/// Full-screen discovery view shown via the "SEE ALL TRIBES" button for
/// users who already have a club. Reuses the same grid/search/filter logic
/// as the no-club discovery state.
class _DiscoveryScreen extends ConsumerStatefulWidget {
  const _DiscoveryScreen();

  @override
  ConsumerState<_DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<_DiscoveryScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final clubsAsync = ref.watch(discoveryClubsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'All Tribes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: clubsAsync.when(
        data: (clubs) {
          final filtered = _filterClubs(clubs);
          final columns =
              MediaQuery.of(context).size.width > 600 ? 4 : 3;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildFilterChips()),
              if (filtered.isEmpty)
                SliverFillRemaining(
                  child: _EmptyState(
                    message: _searchQuery.isEmpty
                        ? 'No clubs to discover yet.'
                        : 'No clubs match "$_searchQuery".',
                    icon: Icons.search_off,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final club = filtered[index];
                        return ClubBoxCard(
                          title: club.name,
                          imageUrl: clubEmblemImageUrl(
                            existingImageUrl: club.imageUrl,
                            archetypeId: club.archetypeId,
                            clubId: club.id,
                          ),
                          memberCount: club.memberCount,
                          activityStatus: club.memberCount >= 10
                              ? '🔥 Active'
                              : '🌙 Quiet',
                          typeTag: _typeTagFor(club),
                          onTap: () => _showPreviewSheet(context, club),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text(
            'Could not load clubs',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }

  List<Tribe> _filterClubs(List<Tribe> clubs) {
    final query = _searchQuery.trim().toLowerCase();
    return clubs.where((club) {
      final matchesQuery = query.isEmpty ||
          club.name.toLowerCase().contains(query) ||
          club.description.toLowerCase().contains(query);
      if (!matchesQuery) return false;

      switch (_selectedFilter) {
        case 'By Archetype':
          return club.archetypeId != null && club.archetypeId!.isNotEmpty;
        case 'Creator':
          return club.archetypeId == null || club.archetypeId!.isEmpty;
        case 'All':
        default:
          return true;
      }
    }).toList();
  }

  String _typeTagFor(Tribe club) {
    return (club.archetypeId != null && club.archetypeId!.isNotEmpty)
        ? 'ARCHETYPE'
        : 'CREATOR';
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: '🔍 Search clubs...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: _selectedFilter == 'All',
            onSelected: () => setState(() => _selectedFilter = 'All'),
            icon: Icons.explore,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Archetype',
            selected: _selectedFilter == 'By Archetype',
            onSelected: () => setState(() => _selectedFilter = 'By Archetype'),
            icon: Icons.auto_awesome,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Creator',
            selected: _selectedFilter == 'Creator',
            onSelected: () => setState(() => _selectedFilter = 'Creator'),
            icon: Icons.person,
          ),
        ],
      ),
    );
  }

  void _showPreviewSheet(BuildContext context, Tribe club) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => ClubPreviewSheet(
        title: club.name,
        description: club.description,
        benefits: _benefitsFor(club),
        onJoin: () => _joinClub(club),
      ),
    );
  }

  List<String> _benefitsFor(Tribe club) {
    return [
      'Join ${club.memberCount} members on the same path',
      'Club challenges and shared XP (Lv ${club.level})',
      if (club.tags.isNotEmpty)
        'Focused on ${club.tags.take(3).join(', ')}'
      else
        'A tribe to anchor your habits',
    ];
  }

  Future<void> _joinClub(Tribe club) async {
    final authUser = ref.read(authStateChangesProvider).value;
    final userId = authUser?.id;
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to join a club')),
      );
      return;
    }
    // Free-tier gate: block joining a second club (free tier = 1) unless
    // premium. Resolves the real entitlement rather than a stale snapshot.
    if (!mounted) return;
    if (await clubJoinBlockedByFreeTier(ref, context, userId)) return;
    if (!mounted) return;
    try {
      await ref.read(tribeRepositoryProvider).joinClub(userId, club.id);
      ref.invalidate(discoveryClubsProvider);
    } catch (e, s) {
      AppLogger.e('_DiscoveryScreen: joinClub failed', e, s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join: $e')),
      );
    }
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final accent = selected ? Colors.cyanAccent : Colors.white54;
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.cyanAccent.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.cyanAccent.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: accent,
                letterSpacing: 0.3,
              ),
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

// ============ LEADERBOARD SECTION ============

class _TribeLeaderboardSection extends ConsumerWidget {
  final String clubId;
  final String archetypeName;
  final bool isGlobal;

  const _TribeLeaderboardSection({
    required this.clubId,
    required this.archetypeName,
    this.isGlobal = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isGlobal) {
      return _WorldLeaderboardSection();
    }

    final leaderboardAsync = ref.watch(clubLeaderboardProvider(clubId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.leaderboard,
                  size: 18,
                  color: EmergeColors.yellow,
                ),
                const Gap(8),
                Text(
                  '${archetypeName.toUpperCase()} TRIBE',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => context.push('/tribes/leaderboard?tab=tribe'),
              child: const Text(
                'View All >',
                style: TextStyle(fontSize: 12, color: EmergeColors.teal),
              ),
            ),
          ],
        ),
        const Gap(16),
        leaderboardAsync.when(
          data: (entries) {
            if (entries.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: EmergeColors.glassWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EmergeColors.glassBorder),
                ),
                child: const Center(
                  child: Text(
                    'No rankings yet. Complete habits to earn XP!',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
              );
            }
            final top = entries.length > 5 ? entries.sublist(0, 5) : entries;
            return Column(
              children: top
                  .asMap()
                  .entries
                  .map(
                    (e) => _LeaderboardRow(entry: e.value, rank: e.key + 1)
                        .animate(delay: (e.key * 50).ms)
                        .fadeIn()
                        .slideX(begin: 0.03),
                  )
                  .toList(),
            );
          },
          loading: () => const EmergeLoadingSkeleton(itemCount: 3),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _WorldLeaderboardSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worldAsync = ref.watch(worldLeaderboardProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.public, size: 18, color: EmergeColors.teal),
                Gap(8),
                Text(
                  'WORLD RANKINGS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => context.push('/tribes/leaderboard?tab=world'),
              child: const Text(
                'View All >',
                style: TextStyle(fontSize: 12, color: EmergeColors.teal),
              ),
            ),
          ],
        ),
        const Gap(16),
        worldAsync.when(
          data: (entries) {
            if (entries.isEmpty) return const SizedBox.shrink();
            final top = entries.length > 5 ? entries.sublist(0, 5) : entries;
            return Column(
              children: top
                  .asMap()
                  .entries
                  .map(
                    (e) =>
                        _WorldRankingRow(club: e.value.tribe, rank: e.key + 1)
                            .animate(delay: (e.key * 50).ms)
                            .fadeIn()
                            .slideX(begin: 0.03),
                  )
                  .toList(),
            );
          },
          loading: () => const EmergeLoadingSkeleton(itemCount: 3),
          error: (err, st) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _WorldRankingRow extends StatelessWidget {
  final Tribe club;
  final int rank;

  const _WorldRankingRow({required this.club, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: EmergeColors.glassWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EmergeColors.glassBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: TextStyle(
                color: rank <= 3 ? EmergeColors.yellow : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const Gap(8),
          CircleAvatar(
            radius: 16,
            backgroundColor: EmergeColors.violet.withValues(alpha: 0.2),
            child: Icon(Icons.shield, size: 16, color: EmergeColors.violet),
          ),
          const Gap(12),
          Expanded(
            child: Text(
              club.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${club.totalXp} XP',
                style: const TextStyle(
                  color: EmergeColors.yellow,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                '${club.memberCount} members',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;

  const _LeaderboardRow({required this.entry, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: EmergeColors.glassWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EmergeColors.glassBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: TextStyle(
                color: rank <= 3 ? EmergeColors.yellow : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const Gap(8),
          CircleAvatar(
            radius: 16,
            backgroundColor: EmergeColors.teal.withValues(alpha: 0.2),
            child: Text(
              entry.userName.isNotEmpty ? entry.userName[0].toUpperCase() : '?',
              style: TextStyle(
                color: EmergeColors.teal,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Text(
              entry.userName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.xp} XP',
                style: const TextStyle(
                  color: EmergeColors.yellow,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                'Level ${entry.level}',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
