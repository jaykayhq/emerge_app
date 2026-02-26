import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/data/services/referral_service.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:emerge_app/features/social/presentation/providers/friend_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';

/// Friends Screen - Exact Stitch Design Match
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsListProvider);

    return Scaffold(
      backgroundColor: EmergeColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.cosmicGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'FRIENDS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showInviteSheet(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: EmergeColors.teal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: EmergeColors.glassWhite,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: EmergeColors.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: AppTheme.textSecondaryDark,
                          size: 20,
                        ),
                        const Gap(10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Find a cosmic ally...',
                              hintStyle: TextStyle(
                                color: AppTheme.textSecondaryDark,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: Gap(24)),

              // Online Orbits Section
              SliverToBoxAdapter(child: _OnlineOrbitsSection()),

              const SliverToBoxAdapter(child: Gap(24)),

              // Cosmic Invites Section
              SliverToBoxAdapter(child: _CosmicInvitesSection()),

              const SliverToBoxAdapter(child: Gap(24)),

              // Your Constellation Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Constellation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Sort by Streak',
                        style: TextStyle(
                          fontSize: 12,
                          color: EmergeColors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: Gap(16)),

              // Friends List
              friendsAsync.when(
                data: (friends) => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _ConstellationFriendCard(friend: friends[index]),
                    childCount: friends.length,
                  ),
                ),
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: CircularProgressIndicator(color: EmergeColors.teal),
                  ),
                ),
                error: (_, __) => const SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      'Failed to load friends',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: Gap(24)),

              // Aligned Orbits Section
              SliverToBoxAdapter(child: _AlignedOrbitsSection()),

              const SliverToBoxAdapter(child: Gap(100)),
            ],
          ),
        ),
      ),
    );
  }

  void _showInviteSheet(BuildContext context) {
    final authState = ref.read(authStateChangesProvider);
    final user = authState.value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to invite friends')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: EmergeColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: EmergeColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              const Text(
                'Invite Friends',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Gap(8),
              Text(
                'Earn 500 XP for each friend who joins!',
                style: TextStyle(fontSize: 14, color: EmergeColors.teal),
              ),
              const Gap(24),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: FutureBuilder<ReferralStats>(
                    future: ReferralService().getReferralStats(user.id),
                    builder: (context, snapshot) {
                      final referralCode =
                          snapshot.data?.referralCode ?? 'Loading...';
                      final totalReferrals = snapshot.data?.totalReferrals ?? 0;
                      final pendingReferrals =
                          snapshot.data?.pendingReferrals ?? 0;
                      final xpEarned = snapshot.data?.xpEarned ?? 0;

                      return Column(
                        children: [
                          // Referral Code Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: EmergeColors.glassWhite,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: EmergeColors.glassBorder,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Your Referral Code',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                const Gap(8),
                                GestureDetector(
                                  onTap: () async {
                                    // Copy referral code to clipboard
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    await Clipboard.setData(
                                      ClipboardData(text: referralCode),
                                    );
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Referral code copied: $referralCode',
                                        ),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: EmergeColors.teal.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: EmergeColors.teal,
                                      ),
                                    ),
                                    child: Text(
                                      referralCode,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: EmergeColors.teal,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                const Gap(8),
                                Text(
                                  'Tap to copy',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(16),

                          // Stats Row
                          Row(
                            children: [
                              Expanded(
                                child: _ReferralStatCard(
                                  icon: Icons.people,
                                  label: 'Successful',
                                  value: '$totalReferrals',
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: _ReferralStatCard(
                                  icon: Icons.pending,
                                  label: 'Pending',
                                  value: '$pendingReferrals',
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: _ReferralStatCard(
                                  icon: Icons.bolt,
                                  label: 'XP Earned',
                                  value: '$xpEarned',
                                ),
                              ),
                            ],
                          ),
                          const Gap(24),

                          // Share Button
                          GestureDetector(
                            onTap: () {
                              final link =
                                  'https://emerge.app/referral?code=$referralCode';
                              SharePlus.instance.share(
                                ShareParams(
                                  text:
                                      'Join me on Emerge! Let\'s build better habits together. '
                                      'Use my code: $referralCode 🚀\n\n$link',
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    EmergeColors.teal,
                                    EmergeColors.coral,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.share, color: Colors.white),
                                  Gap(12),
                                  Text(
                                    'Share Referral Link',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Gap(24),

                          // Reward Preview
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: EmergeColors.glassWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: EmergeColors.glassBorder,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.card_giftcard,
                                      color: Colors.amber.shade700,
                                    ),
                                    const Gap(8),
                                    const Text(
                                      'Reward Milestones',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(12),
                                _MilestoneRow(
                                  count: 3,
                                  reward: '1,500 XP',
                                  achieved: totalReferrals >= 3,
                                ),
                                const Gap(8),
                                _MilestoneRow(
                                  count: 5,
                                  reward: 'Unlock Tribe Creation',
                                  achieved: totalReferrals >= 5,
                                ),
                                const Gap(8),
                                _MilestoneRow(
                                  count: 10,
                                  reward: 'Exclusive Badge',
                                  achieved: totalReferrals >= 10,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ REFERRAL WIDGETS ============

class _ReferralStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReferralStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EmergeColors.glassWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EmergeColors.glassBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: EmergeColors.teal, size: 20),
          const Gap(4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.white54)),
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final int count;
  final String reward;
  final bool achieved;

  const _MilestoneRow({
    required this.count,
    required this.reward,
    required this.achieved,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: achieved ? EmergeColors.teal : EmergeColors.glassWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: achieved ? EmergeColors.teal : EmergeColors.glassBorder,
            ),
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: achieved ? Colors.white : Colors.white54,
              ),
            ),
          ),
        ),
        const Gap(12),
        Expanded(
          child: Text(
            reward,
            style: TextStyle(
              fontSize: 13,
              color: achieved ? Colors.white : Colors.white54,
            ),
          ),
        ),
        if (achieved)
          Icon(Icons.check_circle, color: EmergeColors.teal, size: 20)
        else
          Icon(Icons.lock, color: Colors.white24, size: 20),
      ],
    );
  }
}

// ============ ONLINE ORBITS ============

class _OnlineOrbitsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final onlineUsers = [
      {'name': 'Kora', 'initial': 'K'},
      {'name': 'Jax', 'initial': 'J'},
      {'name': 'Elara', 'initial': 'E'},
      {'name': 'Vex', 'initial': 'V'},
      {'name': 'Luna', 'initial': 'L'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ONLINE ORBITS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryDark,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const Gap(12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: onlineUsers.length,
            itemBuilder: (context, index) {
              final user = onlineUsers[index];
              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Column(
                  children: [
                    // Avatar with online indicator
                    Stack(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                EmergeColors.violet.withValues(alpha: 0.6),
                                EmergeColors.teal.withValues(alpha: 0.4),
                              ],
                            ),
                            border: Border.all(
                              color: EmergeColors.glassBorder,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              user['initial']!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        // Online dot
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: EmergeColors.background,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(6),
                    Text(
                      user['name']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 60).ms);
            },
          ),
        ),
      ],
    );
  }
}

// ============ COSMIC INVITES ============

class _CosmicInvitesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final invites = [
      {'name': 'Nebula_Nine', 'archetype': 'The Meditator', 'level': 6},
      {'name': 'Orion_Pax', 'archetype': 'The Runner', 'level': 8},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Cosmic Invites',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Gap(8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: EmergeColors.violet.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  invites.length.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Gap(12),
        ...invites.map(
          (invite) => _InviteCard(
            name: invite['name'] as String,
            archetype: invite['archetype'] as String,
            level: invite['level'] as int,
          ),
        ),
      ],
    );
  }
}

class _InviteCard extends StatelessWidget {
  final String name;
  final String archetype;
  final int level;

  const _InviteCard({
    required this.name,
    required this.archetype,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EmergeColors.glassWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EmergeColors.glassBorder),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  EmergeColors.violet.withValues(alpha: 0.6),
                  EmergeColors.teal.withValues(alpha: 0.4),
                ],
              ),
            ),
            child: Center(
              child: Text(
                name[0],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const Gap(12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$archetype • Lvl $level',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),

          // Decline button
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: EmergeColors.coral.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 16, color: EmergeColors.coral),
            ),
          ),

          // Accept button
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: EmergeColors.teal),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Accept',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: EmergeColors.teal,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

// ============ CONSTELLATION FRIEND CARD ============

class _ConstellationFriendCard extends StatelessWidget {
  final Friend friend;

  const _ConstellationFriendCard({required this.friend});

  String _archetypeDisplay() {
    switch (friend.archetype) {
      case FriendArchetype.athlete:
        return 'The Runner';
      case FriendArchetype.creator:
        return 'The Creator';
      case FriendArchetype.scholar:
        return 'The Scholar';
      case FriendArchetype.stoic:
        return 'The Architect';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EmergeColors.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmergeColors.glassBorder),
      ),
      child: Column(
        children: [
          // Top row - avatar and info
          Row(
            children: [
              // Avatar with level badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          EmergeColors.violet.withValues(alpha: 0.6),
                          EmergeColors.teal.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        friend.name[0],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Level badge
                  Positioned(
                    left: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: EmergeColors.violet,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: EmergeColors.background,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        'LVL ${friend.level}',
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(14),

              // Name and info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.name.replaceAll(' ', '_'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      _archetypeDisplay(),
                      style: TextStyle(fontSize: 12, color: EmergeColors.teal),
                    ),
                    Text(
                      'Last seen ${friend.lastSeen}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),

              // Streak
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        '${friend.streak}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Gap(2),
                      const Text('🔥', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  Text(
                    'STREAK',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppTheme.textSecondaryDark,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Gap(14),

          // Action buttons row
          Row(
            children: [
              // Nudge button
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: EmergeColors.glassBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_active,
                          size: 14,
                          color: Colors.white,
                        ),
                        const Gap(6),
                        const Text(
                          'Nudge',
                          style: TextStyle(fontSize: 13, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Gap(10),

              // Challenge button
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: EmergeColors.teal),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.offline_bolt,
                          size: 14,
                          color: EmergeColors.teal,
                        ),
                        const Gap(6),
                        const Text(
                          'Challenge',
                          style: TextStyle(
                            fontSize: 13,
                            color: EmergeColors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Gap(10),

              // Link icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: EmergeColors.glassBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.link,
                  size: 18,
                  color: AppTheme.textSecondaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

// ============ ALIGNED ORBITS ============

class _AlignedOrbitsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final suggestions = [
      {'name': 'ZenMaster_X', 'reason': 'Does Meditation'},
      {'name': 'Velocity_V', 'reason': 'Does Running'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Aligned Orbits',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const Gap(12),
        ...suggestions.map(
          (s) => _SuggestionCard(name: s['name']!, reason: s['reason']!),
        ),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final String name;
  final String reason;

  const _SuggestionCard({required this.name, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EmergeColors.glassWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EmergeColors.glassBorder),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  EmergeColors.teal.withValues(alpha: 0.4),
                  EmergeColors.violet.withValues(alpha: 0.4),
                ],
              ),
            ),
            child: Center(
              child: Text(
                name[0],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const Gap(12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.bolt, size: 12, color: EmergeColors.teal),
                    const Gap(4),
                    Expanded(
                      child: Text(
                        reason,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Add button
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: EmergeColors.teal.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: EmergeColors.teal),
            ),
            child: const Icon(
              Icons.person_add,
              size: 18,
              color: EmergeColors.teal,
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

// ============ TAB CONTENT WRAPPER (for embedding in TabBarView) ============

class FriendsTabContent extends ConsumerStatefulWidget {
  const FriendsTabContent({super.key});

  @override
  ConsumerState<FriendsTabContent> createState() => _FriendsTabContentState();
}

class _FriendsTabContentState extends ConsumerState<FriendsTabContent> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsListProvider);

    return CustomScrollView(
      slivers: [
        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: EmergeColors.glassWhite,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: EmergeColors.glassBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: AppTheme.textSecondaryDark,
                    size: 20,
                  ),
                  const Gap(10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Find a cosmic ally...',
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondaryDark,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: Gap(24)),

        // Online Orbits Section
        SliverToBoxAdapter(child: _OnlineOrbitsSection()),

        const SliverToBoxAdapter(child: Gap(24)),

        // Cosmic Invites Section
        SliverToBoxAdapter(child: _CosmicInvitesSection()),

        const SliverToBoxAdapter(child: Gap(24)),

        // Your Constellation Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Constellation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Sort by Streak',
                  style: TextStyle(fontSize: 12, color: EmergeColors.teal),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: Gap(16)),

        // Friends List
        friendsAsync.when(
          data: (friends) => SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _ConstellationFriendCard(friend: friends[index]),
              childCount: friends.length,
            ),
          ),
          loading: () => const SliverToBoxAdapter(
            child: Center(
              child: CircularProgressIndicator(color: EmergeColors.teal),
            ),
          ),
          error: (_, __) => const SliverToBoxAdapter(
            child: Center(
              child: Text(
                'Failed to load friends',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: Gap(24)),

        // Aligned Orbits Section
        SliverToBoxAdapter(child: _AlignedOrbitsSection()),

        const SliverToBoxAdapter(child: Gap(80)),
      ],
    );
  }
}
