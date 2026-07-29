import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/domain/services/tribe_membership_service.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/onboarding/presentation/widgets/club_box_card.dart';
import 'package:emerge_app/features/onboarding/presentation/widgets/club_emblem_images.dart';
import 'package:emerge_app/features/onboarding/presentation/widgets/club_preview_sheet.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

class TribeEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const TribeEmptyState({super.key, required this.message, this.icon = Icons.info_outline});

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

class TribeFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;

  const TribeFilterChip({
    super.key,
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

class TribeDiscoveryScreen extends ConsumerStatefulWidget {
  const TribeDiscoveryScreen({super.key});

  @override
  ConsumerState<TribeDiscoveryScreen> createState() => _TribeDiscoveryScreenState();
}

class _TribeDiscoveryScreenState extends ConsumerState<TribeDiscoveryScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

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
          TribeFilterChip(
            label: 'All',
            selected: _selectedFilter == 'All',
            onSelected: () => setState(() => _selectedFilter = 'All'),
            icon: Icons.explore,
          ),
          const SizedBox(width: 8),
          TribeFilterChip(
            label: 'Archetype',
            selected: _selectedFilter == 'By Archetype',
            onSelected: () => setState(() => _selectedFilter = 'By Archetype'),
            icon: Icons.auto_awesome,
          ),
          const SizedBox(width: 8),
          TribeFilterChip(
            label: 'Creator',
            selected: _selectedFilter == 'Creator',
            onSelected: () => setState(() => _selectedFilter = 'Creator'),
            icon: Icons.person,
          ),
        ],
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
    if (!mounted) return;
    if (await clubJoinBlockedByFreeTier(ref, context, userId)) return;
    if (!mounted) return;
    try {
      final service = ref.read(tribeMembershipServiceProvider);
      final result = await service.joinTribe(
        userId: userId,
        tribeId: club.id,
        type: club.archetypeId != null ? 'archetype' : 'creator',
      );
      result.fold(
        (failure) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to join: ${failure.message}')),
          );
        },
        (_) {
          ref.invalidate(discoveryClubsProvider);
        },
      );
    } catch (e, s) {
      AppLogger.e('TribeDiscoveryScreen: joinClub failed', e, s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubsAsync = ref.watch(discoveryClubsProvider);

    return clubsAsync.when(
      data: (clubs) {
        final filtered = _filterClubs(clubs);
        final columns = MediaQuery.of(context).size.width > 600 ? 4 : 3;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildFilterChips()),
            if (filtered.isEmpty)
              SliverFillRemaining(
                child: TribeEmptyState(
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
      error: (err, _) => TribeEmptyState(
        message: 'Could not load clubs',
        icon: Icons.groups,
      ),
    );
  }
}
