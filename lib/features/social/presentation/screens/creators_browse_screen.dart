// Browse all verified creators — a 2-column grid of GlassPanels.
//
// Falls back to inline CircleAvatar initials while the shared
// `FallbackInitialAvatar` widget (built by a parallel agent) is not yet
// merged. Once that widget lands, swap the inline helper for the import.
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/social/domain/entities/creator_profile.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/glass_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class CreatorsBrowseScreen extends ConsumerWidget {
  const CreatorsBrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creatorsAsync = ref.watch(verifiedCreatorsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'CREATORS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 16,
              ),
            ),
            centerTitle: true,
          ),
          creatorsAsync.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: EmergeLoadingSkeleton(itemCount: 6, showAvatar: true),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: AppErrorWidget(
                message: 'Could not load creators: $e',
                onRetry: () =>
                    ref.invalidate(verifiedCreatorsStreamProvider),
              ),
            ),
            data: (creators) {
              if (creators.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No creators yet — check back soon.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _CreatorTile(creator: creators[index]),
                    childCount: creators.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: Gap(24)),
        ],
      ),
    );
  }
}

class _CreatorTile extends StatelessWidget {
  final CreatorProfile creator;
  const _CreatorTile({required this.creator});

  @override
  Widget build(BuildContext context) {
    final displayName = creator.displayName?.isNotEmpty == true
        ? creator.displayName!
        : 'Creator';
    final seedColor = _colorForCreator(creator);
    final count = creator.blueprintCount;
    final blueprintsLabel =
        '$count ${count == 1 ? 'blueprint' : 'blueprints'}';

    return GlassPanel(
      level: GlassLevel.level1,
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      onTap: () =>
          context.push('/social/creator/${creator.userId}'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _InitialAvatar(
            name: displayName,
            size: 80,
            seedColor: seedColor,
          ),
          const Gap(12),
          Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const Gap(4),
          Text(
            blueprintsLabel,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Inline initials avatar. Will be replaced by `FallbackInitialAvatar`
/// once Agent A's widget lands. Kept private to this file.
class _InitialAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color seedColor;
  const _InitialAvatar({
    required this.name,
    required this.size,
    required this.seedColor,
  });

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: seedColor.withValues(alpha: 0.18),
        border: Border.all(
          color: EmergeColors.nebulaPrimary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          _initials(name),
          style: TextStyle(
            color: seedColor,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.36,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Picks a stable accent colour for a creator so each tile feels distinct
/// without needing an archetype field (CreatorProfile only carries tags).
Color _colorForCreator(CreatorProfile creator) {
  const palette = <Color>[
    EmergeColors.nebulaPrimary, // ice blue
    EmergeColors.nebulaSecondary, // violet
    EmergeColors.neonTeal, // mint
    Color(0xFFFFB86B), // amber
    Color(0xFFFF7AA2), // pink
    Color(0xFF7AC0FF), // sky
  ];
  final source = creator.userId.isNotEmpty
      ? creator.userId
      : (creator.displayName ?? 'creator');
  final hash = source.codeUnits.fold<int>(0, (acc, c) => acc + c);
  return palette[hash % palette.length];
}
