import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/presentation/providers/partner_activity_provider.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';

/// Honest destination for the live feed. Two tabs:
/// - Tribe:    full club activity feed (club-scoped)
/// - Partners: live partner-activity events (new data source)
///
/// Replaces the previous routing where the feed's "View More" wrongly
/// opened the partner-management screen.
class SocialActivityScreen extends ConsumerStatefulWidget {
  final String tribeId;
  const SocialActivityScreen({super.key, required this.tribeId});

  @override
  ConsumerState<SocialActivityScreen> createState() =>
      _SocialActivityScreenState();
}

class _SocialActivityScreenState extends ConsumerState<SocialActivityScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('ACTIVITY'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _SegmentedTabs(
            current: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const Gap(12),
          Expanded(
            child: _tab == 0
                ? _TribeFeed(tribeId: widget.tribeId)
                : const _PartnersFeed(),
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;
  const _SegmentedTabs({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'TRIBE',
              selected: current == 0,
              onTap: () => onChanged(0),
            ),
          ),
          const Gap(8),
          Expanded(
            child: _TabButton(
              label: 'PARTNERS',
              selected: current == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? EmergeColors.nebulaPrimary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? EmergeColors.nebulaPrimary : Colors.white24,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _TribeFeed extends ConsumerWidget {
  final String tribeId;
  const _TribeFeed({required this.tribeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(clubActivityProvider(tribeId));
    return activityAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(
        child: Text(
          'Could not load activity.',
          style: TextStyle(color: Colors.white54),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Text(
              'No tribe activity yet.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: entries.length,
          itemBuilder: (_, i) => _ActivityTile(entry: entries[i]),
        );
      },
    );
  }
}

class _PartnersFeed extends ConsumerWidget {
  const _PartnersFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(partnerActivityProvider);
    return activityAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(
        child: Text(
          'Could not load partner activity.',
          style: TextStyle(color: Colors.white54),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No partner activity yet.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
                const Gap(12),
                TextButton(
                  onPressed: () => context.push('/social/accountability'),
                  child: const Text('Find a partner →'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: entries.length,
          itemBuilder: (_, i) => _ActivityTile(entry: entries[i]),
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _ActivityTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final userName = entry['userName'] as String? ?? 'Someone';
    final type = entry['type'] as String? ?? 'activity';
    final data =
        (entry['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final detail = _describe(type, data);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: EmergeColors.glassWhite,
            child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?'),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(2),
                Text(
                  detail,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _describe(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'habit_complete':
        return 'Completed ${data['habitTitle'] ?? 'a habit'}';
      case 'streak_milestone':
        return 'Hit a ${data['streakDays'] ?? ''}-day streak';
      case 'challenge_complete':
        return 'Completed ${data['challengeTitle'] ?? 'a quest'}';
      case 'partner_joined':
        return 'Added a partner: ${data['partnerName'] ?? ''}';
      case 'contract_committed':
        return 'Committed to ${data['habitTitle'] ?? 'a contract'}';
      default:
        return 'New activity';
    }
  }
}
