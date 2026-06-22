import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

class CreatorTribeManagementTab extends ConsumerWidget {
  const CreatorTribeManagementTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final profileAsync = ref.watch(creatorProfileProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tribe Management'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_rounded),
            onPressed: () => _showAnnouncementDialog(context),
            tooltip: 'Post announcement',
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null || profile.tribeId == null) {
            return _NoTribeState();
          }
          return _TribeManagementView(
            tribeId: profile.tribeId!,
            ref: ref,
          );
        },
        loading: () => const EmergeLoadingSkeleton(itemCount: 5),
        error: (e, st) => AppErrorWidget(
          message: 'Could not load your tribe.',
          onRetry: () => ref.invalidate(creatorProfileProvider(uid)),
        ),
      ),
    );
  }

  void _showAnnouncementDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A2A),
        title: const Text('📢 Post Announcement',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Write your message to the tribe...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white24),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: EmergeColors.neonTeal,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (controller.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Announcement posted to your tribe! 📢'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}

// ── Tribe Management View ────────────────────────────────────────────────────
class _TribeManagementView extends ConsumerWidget {
  final String tribeId;
  final WidgetRef ref;

  const _TribeManagementView({required this.tribeId, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(realTimeTribeStatsProvider(tribeId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Stats Row ────────────────────────────────────────────────
        statsAsync.when(
          data: (stats) => Row(
            children: [
              _StatChip(
                icon: Icons.groups_rounded,
                value: stats.memberCount.toString(),
                label: 'Members',
              ),
              const Gap(12),
              _StatChip(
                icon: Icons.bolt_rounded,
                value: '${(stats.totalXp / 1000).toStringAsFixed(1)}K',
                label: 'Tribe XP',
              ),
              const Gap(12),
              _StatChip(
                icon: Icons.check_circle_outline_rounded,
                value: stats.totalHabitsCompleted.toString(),
                label: 'Habits done',
              ),
            ],
          ),
          loading: () => const EmergeLoadingSkeleton(itemCount: 1),
          error: (e, st) => const SizedBox.shrink(),
        ),

        const Gap(24),

        // ── Quick Actions ─────────────────────────────────────────────
        Text(
          'QUICK ACTIONS',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const Gap(12),

        _ActionCard(
          icon: Icons.campaign_rounded,
          title: 'Post Announcement',
          subtitle: 'Broadcast a message to all tribe members',
          color: EmergeColors.neonTeal,
          onTap: () => _showAnnouncementFromView(context),
        ),
        const Gap(8),
        _ActionCard(
          icon: Icons.emoji_events_rounded,
          title: 'Create Challenge',
          subtitle: 'Launch a tribe-wide habit challenge',
          color: Colors.amber,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Challenge creator launching soon 🏆'),
              behavior: SnackBarBehavior.floating,
            ),
          ),
        ),
        const Gap(8),
        _ActionCard(
          icon: Icons.settings_rounded,
          title: 'Tribe Settings',
          subtitle: 'Name, cover art, visibility, member cap',
          color: Colors.blue,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tribe settings launching soon ⚙️'),
              behavior: SnackBarBehavior.floating,
            ),
          ),
        ),

        const Gap(24),

        // ── Member Roster placeholder ────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MEMBERS',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text('See All →',
                  style: TextStyle(color: EmergeColors.neonTeal, fontSize: 12)),
            ),
          ],
        ),
        const Gap(8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: const Text(
            'Member list available in full analytics view.',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ),
      ],
    );
  }

  void _showAnnouncementFromView(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A2A),
        title: const Text('📢 Post Announcement',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Write your message to the tribe...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: EmergeColors.neonTeal,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Announcement posted! 📢'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}

// ── Stat Chip ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: EmergeColors.neonTeal.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EmergeColors.neonTeal.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: EmergeColors.neonTeal, size: 20),
            const Gap(4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ── Action Card ──────────────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}

// ── No Tribe State ───────────────────────────────────────────────────────────
class _NoTribeState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 64, color: Colors.white24),
            const Gap(16),
            const Text('No Tribe Yet',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const Gap(8),
            const Text(
              'Publish a blueprint to automatically create your creator tribe.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
