import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/social/domain/models/challenge.dart';
import 'package:emerge_app/features/social/presentation/providers/challenge_provider.dart';
import 'package:emerge_app/features/social/presentation/screens/challenge_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class CommunityChallengesScreen extends ConsumerStatefulWidget {
  const CommunityChallengesScreen({super.key});

  @override
  ConsumerState<CommunityChallengesScreen> createState() =>
      _CommunityChallengesScreenState();
}

class _CommunityChallengesScreenState
    extends ConsumerState<CommunityChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Community Challenges'),
        backgroundColor: Colors.transparent,
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _ChallengeList(status: ChallengeStatus.featured),
          _ChallengeList(status: ChallengeStatus.active),
          _ChallengeList(status: ChallengeStatus.completed),
        ],
      ),
    );
  }
}

class _ChallengeList extends ConsumerWidget {
  final ChallengeStatus status;

  const _ChallengeList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(filteredChallengesProvider(status));

    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.white24),
            const Gap(16),
            Text(
              'No challenges found',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      separatorBuilder: (context, index) => const Gap(16),
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return _ChallengeCard(challenge: challenge)
            .animate()
            .fadeIn(delay: (100 * index).ms)
            .slideY(begin: 0.1, end: 0);
      },
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;

  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
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
                      child: Icon(
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
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const Gap(12),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: challenge.currentDay / challenge.totalDays,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                      minHeight: 6,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Day ${challenge.currentDay} of ${challenge.totalDays}',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const Gap(16),
                  const Divider(color: Colors.white10),
                  const Gap(8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.groups, size: 16, color: Colors.white54),
                          const Gap(4),
                          Text(
                            '${challenge.participants} Adventurers',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.timer, size: 16, color: Colors.white54),
                          const Gap(4),
                          Text(
                            'Ends in ${challenge.daysLeft} days',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Gap(16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Share logic placeholder
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sharing Challenge...')),
                        );
                      },
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Share Challenge'),
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
