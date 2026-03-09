import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/data/services/referral_service.dart';
import 'package:emerge_app/features/social/domain/entities/social_entities.dart';
import 'package:emerge_app/features/social/presentation/providers/friend_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/friend_stream_provider.dart'
    as stream;
import 'package:emerge_app/features/monetization/presentation/providers/contract_provider.dart';
import 'package:emerge_app/features/monetization/domain/entities/habit_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';

/// Friends Screen - Accountability Partners
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
    final friendsAsync = ref.watch(partnersListProvider);

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
                        'PARTNERS',
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
                              hintText: 'Find a partner...',
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

              // Active Partners Section
              SliverToBoxAdapter(child: _ActivePartnersSection()),

              const SliverToBoxAdapter(child: Gap(24)),

              // Partner Requests Section
              SliverToBoxAdapter(child: _PartnerRequestsSection()),

              const SliverToBoxAdapter(child: Gap(24)),

              // Active Contracts Section
              SliverToBoxAdapter(child: _ActiveContractsSection()),

              const SliverToBoxAdapter(child: Gap(24)),

              // Your Accountability Circle Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Accountability Circle',
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

              // Partners List
              friendsAsync.when(
                data: (friends) => friends.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: EmergeColors.glassWhite,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: EmergeColors.glassBorder,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 48,
                                  color: AppTheme.textSecondaryDark.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                const Gap(16),
                                Text(
                                  'No accountability partners yet',
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryDark,
                                    fontSize: 14,
                                  ),
                                ),
                                const Gap(4),
                                Text(
                                  'Invite someone to hold you accountable!',
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryDark
                                        .withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _PartnerCard(friend: friends[index]),
                          childCount: friends.length,
                        ),
                      ),
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: CircularProgressIndicator(color: EmergeColors.teal),
                  ),
                ),
                error: (_, _) => const SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      'Failed to load partners',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),

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
        const SnackBar(content: Text('Please sign in to invite partners')),
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
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: EmergeColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Invite Partners',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Gap(8),
              Text(
                'Earn 500 XP for each partner who joins!',
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
                          // Reward Milestones
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
                                  reward: 'Exclusive Title',
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
          const Gap(6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Gap(2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryDark),
          ),
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
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: achieved ? EmergeColors.teal : EmergeColors.glassWhite,
            border: Border.all(
              color: achieved ? EmergeColors.teal : EmergeColors.glassBorder,
            ),
          ),
          child: achieved
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
        const Gap(12),
        Expanded(
          child: Text(
            '$count Referrals — $reward',
            style: TextStyle(
              fontSize: 13,
              color: achieved ? Colors.white : AppTheme.textSecondaryDark,
              fontWeight: achieved ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

// ============ ACTIVE PARTNERS (Firestore) ============

class _ActivePartnersSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineAsync = ref.watch(stream.onlinePartnersStreamProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Partners',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: EmergeColors.teal.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: onlineAsync.when(
                  data: (partners) => Text(
                    '${partners.where((f) => f.isOnline).length} Online',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: EmergeColors.teal,
                    ),
                  ),
                  loading: () => const Text(
                    '...',
                    style: TextStyle(fontSize: 11, color: EmergeColors.teal),
                  ),
                  error: (_, _) => const Text(
                    '0 Online',
                    style: TextStyle(fontSize: 11, color: EmergeColors.teal),
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          onlineAsync.when(
            data: (partners) {
              if (partners.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: EmergeColors.glassWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: EmergeColors.glassBorder),
                  ),
                  child: const Center(
                    child: Text(
                      'No partners yet — invite someone!',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                );
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: partners.map((partner) {
                    return Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: partner.isOnline
                                        ? [
                                            EmergeColors.teal,
                                            EmergeColors.violet,
                                          ]
                                        : [
                                            EmergeColors.glassBorder,
                                            EmergeColors.glassBorder,
                                          ],
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: EmergeColors.background,
                                  ),
                                  child: Center(
                                    child: Text(
                                      partner.name.isNotEmpty
                                          ? partner.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (partner.isOnline)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: EmergeColors.teal,
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
                            partner.name.split(' ').first,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const SizedBox(
              height: 70,
              child: Center(
                child: CircularProgressIndicator(
                  color: EmergeColors.teal,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ============ PARTNER REQUESTS (Firestore) ============

class _PartnerRequestsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(stream.pendingPartnerRequestsStreamProvider);

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Partner Requests',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Gap(8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: EmergeColors.coral,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${requests.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(12),
              ...requests.map((req) => _PartnerRequestCard(request: req)),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _PartnerRequestCard extends ConsumerWidget {
  final PartnerRequest request;
  const _PartnerRequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EmergeColors.glassWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EmergeColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [EmergeColors.violet, EmergeColors.teal],
              ),
            ),
            child: Center(
              child: Text(
                request.senderName.isNotEmpty
                    ? request.senderName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.senderName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Gap(2),
                Text(
                  'Level ${request.senderLevel} • ${request.senderArchetype}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              try {
                await ref
                    .read(friendRepositoryProvider)
                    .acceptPartnerRequest(request.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Partner request accepted!'),
                    backgroundColor: EmergeColors.teal,
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to accept request: $e'),
                    backgroundColor: EmergeColors.coral,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: EmergeColors.teal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Accept',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const Gap(8),
          GestureDetector(
            onTap: () async {
              try {
                await ref
                    .read(friendRepositoryProvider)
                    .rejectPartnerRequest(request.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Partner request declined'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to decline request: $e'),
                    backgroundColor: EmergeColors.coral,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: EmergeColors.glassBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Decline',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ ACTIVE CONTRACTS (Social Contracts) ============

class _ActiveContractsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsAsync = ref.watch(activeOnlyContractsProvider);

    return contractsAsync.when(
      data: (contracts) {
        if (contracts.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.handshake,
                    size: 18,
                    color: EmergeColors.yellow,
                  ),
                  const Gap(8),
                  const Text(
                    'Active Contracts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: EmergeColors.yellow.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${contracts.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: EmergeColors.yellow,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(12),
              ...contracts.map((contract) => _ContractCard(contract: contract)),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _ContractCard extends StatelessWidget {
  final HabitContract contract;
  const _ContractCard({required this.contract});

  @override
  Widget build(BuildContext context) {
    final progress = contract.totalDays > 0
        ? (contract.totalDays - contract.missedDays) / contract.totalDays
        : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EmergeColors.glassWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EmergeColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: EmergeColors.yellow.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description,
                  size: 18,
                  color: EmergeColors.yellow,
                ),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contract.habitName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'with ${contract.partnerName ?? contract.partnerEmail}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${contract.penaltyAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: contract.missedDays > 0
                          ? EmergeColors.coral
                          : EmergeColors.teal,
                    ),
                  ),
                  Text(
                    'at stake',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Gap(10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: EmergeColors.glassWhite,
              valueColor: AlwaysStoppedAnimation<Color>(
                contract.missedDays > 2
                    ? EmergeColors.coral
                    : EmergeColors.teal,
              ),
              minHeight: 6,
            ),
          ),
          const Gap(6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${contract.totalDays - contract.missedDays}/${contract.totalDays} days complete',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondaryDark,
                ),
              ),
              if (contract.missedDays > 0)
                Text(
                  '${contract.missedDays} missed',
                  style: const TextStyle(
                    fontSize: 11,
                    color: EmergeColors.coral,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

// ============ PARTNER CARD ============

class _PartnerCard extends StatelessWidget {
  final Friend friend;

  const _PartnerCard({required this.friend});

  String _archetypeDisplay() {
    switch (friend.archetype) {
      case FriendArchetype.athlete:
        return 'The Athlete';
      case FriendArchetype.creator:
        return 'The Creator';
      case FriendArchetype.scholar:
        return 'The Scholar';
      case FriendArchetype.stoic:
        return 'The Stoic';
      case FriendArchetype.zealot:
        return 'The Zealot';
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
                        friend.name.isNotEmpty ? friend.name[0] : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            friend.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (friend.equippedTitle != null) ...[
                          const Gap(4),
                          Text(
                            friend.equippedTitle!,
                            style: TextStyle(
                              fontSize: 11,
                              color: EmergeColors.yellow,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Gap(2),
                    Text(
                      _archetypeDisplay(),
                      style: TextStyle(fontSize: 12, color: EmergeColors.teal),
                    ),
                    Text(
                      friend.isOnline
                          ? 'Online now'
                          : 'Last seen ${friend.lastSeen}',
                      style: TextStyle(
                        fontSize: 11,
                        color: friend.isOnline
                            ? EmergeColors.teal
                            : AppTheme.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
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
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: EmergeColors.glassBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_active,
                          size: 14,
                          color: Colors.white,
                        ),
                        Gap(6),
                        Text(
                          'Nudge',
                          style: TextStyle(fontSize: 13, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Gap(10),
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: EmergeColors.teal),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.handshake,
                          size: 14,
                          color: EmergeColors.teal,
                        ),
                        Gap(6),
                        Text(
                          'Contract',
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: EmergeColors.glassBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.more_vert,
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
    final friendsAsync = ref.watch(partnersListProvider);

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
                        hintText: 'Find a partner...',
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

        // Active Partners Section
        SliverToBoxAdapter(child: _ActivePartnersSection()),

        const SliverToBoxAdapter(child: Gap(24)),

        // Partner Requests Section
        SliverToBoxAdapter(child: _PartnerRequestsSection()),

        const SliverToBoxAdapter(child: Gap(24)),

        // Your Accountability Circle Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Accountability Circle',
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

        // Partners List
        friendsAsync.when(
          data: (friends) => friends.isEmpty
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'No accountability partners yet',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _PartnerCard(friend: friends[index]),
                    childCount: friends.length,
                  ),
                ),
          loading: () => const SliverToBoxAdapter(
            child: Center(
              child: CircularProgressIndicator(color: EmergeColors.teal),
            ),
          ),
          error: (_, _) => const SliverToBoxAdapter(
            child: Center(
              child: Text(
                'Failed to load partners',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: Gap(80)),
      ],
    );
  }
}
