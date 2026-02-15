import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/challenge_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class CommunityChallengesScreen extends ConsumerStatefulWidget {
  const CommunityChallengesScreen({super.key});
  // ... (rest of class)

  // ... (skip to _ChallengeCard)

  @override
  ConsumerState<CommunityChallengesScreen> createState() =>
      _CommunityChallengesScreenState();
}

class _CommunityChallengesScreenState
    extends ConsumerState<CommunityChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Fitness',
    'Mindfulness',
    'Learning',
    'Nutrition',
    'Productivity',
    'Creative',
    'Faith',
  ];

  static const Map<String, IconData> _categoryIcons = {
    'All': Icons.star,
    'Fitness': Icons.fitness_center,
    'Mindfulness': Icons.self_improvement,
    'Learning': Icons.menu_book,
    'Nutrition': Icons.restaurant,
    'Productivity': Icons.bolt,
    'Creative': Icons.palette,
    'Faith': Icons.favorite,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userStatsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Community Challenges'),
        backgroundColor: Colors.transparent,
        actions: [
          // User Level Badge
          userProfileAsync.when(
            data: (profile) {
              final level = profile.avatarStats.level;
              final totalXp = profile.avatarStats.totalXp;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      EmergeColors.teal.withValues(alpha: 0.2),
                      EmergeColors.coral.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: EmergeColors.teal.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars, size: 16, color: EmergeColors.teal),
                    const SizedBox(width: 6),
                    Text(
                      'Lvl $level',
                      style: TextStyle(
                        color: EmergeColors.teal,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '• $totalXp XP',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.handshake_outlined),
            onPressed: () => context.push('/tribes/accountability'),
            tooltip: 'Accountability Partners',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Featured'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Horizontal Category Filter Chips
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const Gap(8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return FilterChip(
                  selected: isSelected,
                  showCheckmark: false,
                  avatar: Icon(
                    _categoryIcons[category],
                    size: 18,
                    color: isSelected ? Colors.white : AppTheme.primary,
                  ),
                  label: Text(category),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  backgroundColor: AppTheme.surfaceDark,
                  selectedColor: AppTheme.primary,
                  side: BorderSide(
                    color: isSelected ? AppTheme.primary : Colors.white24,
                  ),
                  onSelected: (_) {
                    setState(() => _selectedCategory = category);
                  },
                );
              },
            ),
          ),
          // Challenge List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ChallengeList(
                  status: ChallengeStatus.featured,
                  categoryFilter: _selectedCategory,
                ),
                _ChallengeList(
                  status: ChallengeStatus.active,
                  categoryFilter: _selectedCategory,
                ),
                _ChallengeList(
                  status: ChallengeStatus.completed,
                  categoryFilter: _selectedCategory,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeList extends ConsumerWidget {
  final ChallengeStatus status;
  final String categoryFilter;

  const _ChallengeList({required this.status, this.categoryFilter = 'All'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(filteredChallengesProvider(status));

    return challengesAsync.when(
      data: (challenges) {
        // Apply category filter
        final filteredChallenges = categoryFilter == 'All'
            ? challenges
            : challenges.where((c) => c.category.name.toLowerCase() == categoryFilter.toLowerCase()).toList();

        if (filteredChallenges.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 64,
                  color: Colors.white24,
                ),
                const Gap(16),
                Text(
                  categoryFilter == 'All'
                      ? 'No ${status.name} challenges found'
                      : 'No $categoryFilter challenges found',
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filteredChallenges.length,
          separatorBuilder: (context, index) => const Gap(16),
          itemBuilder: (context, index) {
            final challenge = filteredChallenges[index];
            return _ChallengeCard(challenge: challenge)
                .animate()
                .fadeIn(delay: (100 * index).ms)
                .slideY(begin: 0.1, end: 0);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class _ChallengeCard extends ConsumerWidget {
  final Challenge challenge;

  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChallengeDetailScreen(challenge: challenge),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Header
            SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    challenge.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      child: Icon(Icons.image, color: AppTheme.primary),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: challenge.sponsorLogoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                challenge.sponsorLogoUrl!,
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.local_fire_department,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.local_fire_department,
                              color: Colors.orange,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'Reward: ${challenge.reward}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const Gap(12),
                  // Progress UI only for Active/Completed
                  if (challenge.status != ChallengeStatus.featured) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: challenge.totalDays > 0
                            ? challenge.currentDay / challenge.totalDays
                            : 0,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'Day ${challenge.currentDay} of ${challenge.totalDays}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const Gap(16),
                  ],
                  const Divider(color: Colors.white10),
                  const Gap(8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.groups,
                            size: 16,
                            color: Colors.white54,
                          ),
                          const Gap(4),
                          Text(
                            '${challenge.participants} Adventurers',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      if (challenge.status == ChallengeStatus.featured)
                        Row(
                          children: [
                            const Icon(
                              Icons.timer,
                              size: 16,
                              color: Colors.white54,
                            ),
                            const Gap(4),
                            Text(
                              '${challenge.totalDays} Days',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            const Icon(
                              Icons.timer,
                              size: 16,
                              color: Colors.white54,
                            ),
                            const Gap(4),
                            Text(
                              'Ends in ${challenge.daysLeft} days',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const Gap(16),
                  // Action Buttons based on status
                  if (challenge.status == ChallengeStatus.featured)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final userAsync = ref.read(
                              authStateChangesProvider,
                            );
                            final user = userAsync.value;

                            if (user != null) {
                              final repo = ref.read(
                                challengeRepositoryProvider,
                              );
                              // Log Activity for XP
                              final userStatsRepo = ref.read(
                                userStatsRepositoryProvider,
                              );

                              // 1. Join Challenge
                              await repo.joinChallenge(user.id, challenge.id);

                              await userStatsRepo.logActivity(
                                userId: user.id,
                                type: 'joined_challenge',
                                sourceId: challenge.id,
                                date: DateTime.now(),
                              );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Joined challenge! Check Active tab.',
                                    ),
                                  ),
                                );
                              }
                              // Invalidate providers to refresh
                              ref.invalidate(userChallengesProvider);
                              ref.invalidate(filteredChallengesProvider);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please sign in to join challenges.',
                                    ),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to join: $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.backgroundDark,
                        ),
                        child: const Text('Join Challenge'),
                      ),
                    )
                  else if (challenge.status == ChallengeStatus.completed)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Affiliate Link Logic
                          if (challenge.affiliateUrl != null) {
                            // Launch URL
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Opening reward: ${challenge.affiliateUrl}',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Reward claimed!')),
                            );
                          }
                        },
                        icon: const Icon(Icons.redeem),
                        label: const Text('Claim Reward'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sharing Challenge...'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('Share Progress'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: BorderSide(color: AppTheme.primary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
