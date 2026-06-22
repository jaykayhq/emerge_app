import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';

class CreatorOverviewTab extends ConsumerWidget {
  const CreatorOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final profileAsync = ref.watch(userStatsStreamProvider);
    final blueprintsAsync = ref.watch(allBlueprintsStreamProvider);
    final creatorProfileAsync = ref.watch(creatorProfileProvider(uid));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Creator Hub'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: profileAsync.when(
        data: (userProfile) {
          final displayName = (userProfile.displayName?.isNotEmpty == true)
              ? userProfile.displayName!
              : 'Creator';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Welcome Banner ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.withValues(alpha: 0.15),
                      Colors.orange.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade700, Colors.orange.shade600],
                        ),
                      ),
                      child: const Center(
                        child: Text('🎨', style: TextStyle(fontSize: 26)),
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, $displayName!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const Gap(2),
                          creatorProfileAsync.when(
                            data: (cp) => Text(
                              cp?.isVerifiedCreator == true
                                  ? '✅ Verified Creator'
                                  : '⏳ Pending Verification',
                              style: TextStyle(
                                color: cp?.isVerifiedCreator == true
                                    ? Colors.greenAccent
                                    : Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (e, st) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(24),

              // ── Live Analytics Cards ──────────────────────────────
              Text(
                'YOUR ANALYTICS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Gap(12),

              blueprintsAsync.when(
                data: (allBlueprints) {
                  final myBlueprints = allBlueprints
                      .where((b) => b.creatorUserId == uid)
                      .toList();
                  final totalAdoptions = myBlueprints.fold(
                    0, (sum, b) => sum + b.adoptionCount);
                  final totalHabits = myBlueprints.fold(
                    0, (sum, b) => sum + b.habits.length);

                  return Column(
                    children: [
                      Row(
                        children: [
                          _AnalyticCard(
                            icon: Icons.widgets_rounded,
                            value: myBlueprints.length.toString(),
                            label: 'Blueprints',
                            color: EmergeColors.neonTeal,
                          ),
                          const Gap(12),
                          _AnalyticCard(
                            icon: Icons.download_done_rounded,
                            value: totalAdoptions.toString(),
                            label: 'Adoptions',
                            color: Colors.amber,
                          ),
                        ],
                      ),
                      const Gap(12),
                      Row(
                        children: [
                          _AnalyticCard(
                            icon: Icons.bolt_rounded,
                            value: totalHabits.toString(),
                            label: 'Total Habits',
                            color: Colors.blue,
                          ),
                          const Gap(12),
                          _AnalyticCard(
                            icon: Icons.trending_up_rounded,
                            value: totalAdoptions > 0
                                ? '+${((totalAdoptions / 7)).toStringAsFixed(1)}/wk'
                                : '—',
                            label: 'Growth Rate',
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const EmergeLoadingSkeleton(itemCount: 2),
                error: (e, st) =>
                    const Text('Analytics unavailable.',
                        style: TextStyle(color: Colors.white38)),
              ),

              const Gap(28),

              // ── Navigation Cards ──────────────────────────────────
              Text(
                'MANAGE',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Gap(12),

              _NavCard(
                icon: Icons.widgets_rounded,
                title: 'Blueprint Studio',
                subtitle: 'Create and manage your habit blueprints',
                color: EmergeColors.neonTeal,
                onTap: () => context.push('/creator/dashboard/blueprints'),
              ),
              const Gap(10),
              _NavCard(
                icon: Icons.groups_rounded,
                title: 'Tribe Management',
                subtitle: 'Announcements, members, challenges',
                color: Colors.blue,
                onTap: () => context.push('/creator/dashboard/tribe'),
              ),
              const Gap(10),

              // Analytics card — links to future analytics page
              _NavCard(
                icon: Icons.analytics_rounded,
                title: 'Full Analytics',
                subtitle: 'Adoption trends, engagement, member growth',
                color: Colors.amber,
                badge: 'SOON',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Full analytics dashboard coming in v1.5 🚀'),
                    behavior: SnackBarBehavior.floating,
                  ),
                ),
              ),

              const Gap(10),

              // Public profile link
              _NavCard(
                icon: Icons.open_in_new_rounded,
                title: 'View Public Profile',
                subtitle: 'See how your tribe sees you',
                color: Colors.white54,
                onTap: () => context.push('/creators/$uid'),
              ),
            ],
          );
        },
        loading: () => const EmergeLoadingSkeleton(itemCount: 6),
        error: (e, st) => const Center(
          child: Text('Could not load profile.',
              style: TextStyle(color: Colors.white54)),
        ),
      ),
    );
  }
}

// ── Analytic Card ────────────────────────────────────────────────────────────
class _AnalyticCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _AnalyticCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const Gap(12),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(2),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Navigation Card ──────────────────────────────────────────────────────────
class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const Gap(2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Gap(8),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
