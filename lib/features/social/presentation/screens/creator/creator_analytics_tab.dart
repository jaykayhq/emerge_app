// lib/features/social/presentation/screens/creator/creator_analytics_tab.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_analytics_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/creator_tribe_share_card.dart';
import 'package:emerge_app/features/social/domain/models/creator_analytics.dart';

class CreatorAnalyticsTab extends ConsumerWidget {
  const CreatorAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final profileAsync = ref.watch(creatorProfileProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: profileAsync.when(
        data: (profile) {
          final tribeId = profile?.tribeId;
          if (tribeId == null) return const _NoTribeState();
          final analyticsAsync =
              ref.watch(creatorAnalyticsProvider(uid: uid, tribeId: tribeId));
          return analyticsAsync.when(
            data: (analytics) => _AnalyticsView(analytics: analytics),
            loading: () => const EmergeLoadingSkeleton(itemCount: 6),
            error: (e, st) => AppErrorWidget(
              message: 'Could not load analytics.',
              onRetry: () => ref.invalidate(
                creatorAnalyticsProvider(uid: uid, tribeId: tribeId),
              ),
            ),
          );
        },
        loading: () => const EmergeLoadingSkeleton(itemCount: 6),
        error: (e, st) => AppErrorWidget(
          message: 'Could not load creator profile.',
          onRetry: () => ref.invalidate(creatorProfileProvider(uid)),
        ),
      ),
    );
  }
}

class _AnalyticsView extends StatelessWidget {
  final CreatorAnalytics analytics;
  const _AnalyticsView({required this.analytics});

  @override
  Widget build(BuildContext context) {
    if (analytics.tribeName.isEmpty && analytics.memberCount == 0) {
      return const _NoTribeState();
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.groups_rounded,
                value: analytics.memberCount.toString(),
                label: 'Members',
                color: EmergeColors.neonTeal,
              ),
            ),
            const Gap(12),
            Expanded(
              child: _KpiCard(
                icon: Icons.bolt_rounded,
                value: _formatXp(analytics.totalXp),
                label: 'Tribe XP',
                color: Colors.amber,
              ),
            ),
          ],
        ),
        const Gap(12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.check_circle_outline_rounded,
                value: analytics.totalHabitsCompleted.toString(),
                label: 'Habits done',
                color: Colors.blue,
              ),
            ),
            const Gap(12),
            Expanded(
              child: _KpiCard(
                icon: Icons.emoji_events_rounded,
                value: analytics.totalChallengesCompleted.toString(),
                label: 'Challenges',
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const Gap(16),
        CreatorTribeShareCard(
          tribeName: analytics.tribeName,
          creatorName: 'Your Tribe',
          memberCount: analytics.memberCount,
          totalXp: analytics.totalXp,
          totalHabitsCompleted: analytics.totalHabitsCompleted,
          totalChallengesCompleted: analytics.totalChallengesCompleted,
        ),
        const Gap(24),

        const _SectionHeader('MEMBER GROWTH'),
        const Gap(12),
        _MemberGrowthCard(analytics: analytics),
        const Gap(24),

        const _SectionHeader('ENGAGEMENT'),
        const Gap(12),
        _EngagementCard(analytics: analytics),
        const Gap(24),

        const _SectionHeader('BLUEPRINTS'),
        const Gap(12),
        if (analytics.blueprintStats.isEmpty)
          const _EmptyRow('No blueprints published yet.')
        else
          for (final b in analytics.blueprintStats) _BlueprintRow(stat: b),
        const Gap(24),

        const _SectionHeader('TOP MEMBERS'),
        const Gap(12),
        if (analytics.topMembers.isEmpty)
          const _EmptyRow('No member contributions yet.')
        else
          for (final m in analytics.topMembers) _MemberRow(member: m),
        const Gap(24),

        const _SectionHeader('CHALLENGES'),
        const Gap(12),
        if (analytics.challengeStats.isEmpty)
          const _EmptyRow('No challenges published yet.')
        else
          for (final c in analytics.challengeStats) _ChallengeRow(stat: c),
        const Gap(24),
      ],
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}K';
    return xp.toString();
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _KpiCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: Colors.white38,
      fontSize: 11,
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
    ),
  );
}

class _MemberGrowthCard extends StatelessWidget {
  final CreatorAnalytics analytics;
  const _MemberGrowthCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final trends = analytics.trends;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '+${analytics.newMembersThisWeek} new this week · '
            '${analytics.activeMembers} active (${(analytics.activeRate * 100).round()}%)',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const Gap(16),
          if (trends.isEmpty)
            const Text(
              'History builds as you open analytics daily.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            )
          else
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _maxMemberCount(trends).toDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= trends.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              trends[i].date.substring(5),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 9,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(trends.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: trends[index].memberCount.toDouble(),
                          color: EmergeColors.neonTeal,
                          width: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _maxMemberCount(List<DailyTrend> trends) {
    var max = 1;
    for (final t in trends) {
      if (t.memberCount > max) max = t.memberCount;
    }
    return max;
  }
}

class _EngagementCard extends StatelessWidget {
  final CreatorAnalytics analytics;
  const _EngagementCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final trends = analytics.trends;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: trends.isEmpty
          ? const Text(
              'Engagement trends appear once daily snapshots accumulate.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            )
          : SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  lineTouchData: LineTouchData(enabled: false),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(trends.length, (index) {
                        return FlSpot(
                          index.toDouble(),
                          trends[index].totalHabitsCompleted.toDouble(),
                        );
                      }),
                      isCurved: true,
                      color: Colors.amber,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.amber.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _BlueprintRow extends StatelessWidget {
  final BlueprintStat stat;
  const _BlueprintRow({required this.stat});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.widgets_rounded, color: EmergeColors.neonTeal, size: 20),
          const Gap(12),
          Expanded(
            child: Text(
              stat.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '${stat.adoptionCount} adoptions · ${stat.habitCount} habits',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final MemberStat member;
  const _MemberRow({required this.member});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.person_rounded, color: Colors.white38, size: 20),
          const Gap(12),
          Expanded(
            child: Text(
              member.name,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Text(
            '${member.xp} XP · ${member.habitsCompleted} habits',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ChallengeRow extends StatelessWidget {
  final ChallengeStat stat;
  const _ChallengeRow({required this.stat});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
          const Gap(12),
          Expanded(
            child: Text(
              stat.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '${stat.participants} participants · ${stat.status} · ${stat.xpReward} XP',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String message;
  const _EmptyRow(this.message);
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white10),
    ),
    child: Text(
      message,
      style: const TextStyle(color: Colors.white38, fontSize: 13),
    ),
  );
}

class _NoTribeState extends StatelessWidget {
  const _NoTribeState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.white24),
            Gap(16),
            Text(
              'No Analytics Yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Gap(8),
            Text(
              'Publish a blueprint to create your creator tribe, then your analytics appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
