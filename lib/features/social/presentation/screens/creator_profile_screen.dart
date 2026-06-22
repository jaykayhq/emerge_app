import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_primary_button.dart';
import 'package:emerge_app/core/presentation/widgets/fallback_initial_avatar.dart';
import 'package:emerge_app/core/presentation/widgets/app_back_handler.dart';
import 'package:emerge_app/features/social/presentation/providers/creator_provider.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/social/presentation/widgets/glass_panel.dart';

class CreatorProfileScreen extends ConsumerWidget {
  final String creatorId;

  const CreatorProfileScreen({super.key, required this.creatorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(creatorProfileProvider(creatorId));
    final blueprintsAsync = ref.watch(allBlueprintsStreamProvider);
    final creatorBlueprints = blueprintsAsync.value
            ?.where((b) => b.creatorUserId == creatorId)
            .toList() ??
        const <Blueprint>[];
    final recruits =
        creatorBlueprints.fold<int>(0, (sum, b) => sum + b.adoptionCount);
    final missions = creatorBlueprints.length;

    return Scaffold(
      body: AppBackToHome(
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Creator')),
                body: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search_rounded,
                          size: 64, color: Colors.white38),
                      Gap(16),
                      Text('Creator not found',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 16)),
                    ],
                  ),
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                // ── Hero AppBar ──────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  backgroundColor: EmergeColors.nebulaBackground,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Hero image placeholder
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                EmergeColors.nebulaSecondary
                                    .withValues(alpha: 0.3),
                                EmergeColors.nebulaBackground,
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.person_rounded,
                                size: 80, color: Colors.white12),
                          ),
                        ),
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                EmergeColors.nebulaBackground
                                    .withValues(alpha: 0.9),
                              ],
                            ),
                          ),
                        ),
                        // Creator info at bottom of hero
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              FallbackInitialAvatar(
                                name: profile.displayName,
                                size: 80,
                                imageUrl: profile.avatarUrl,
                                borderColor: EmergeColors.nebulaSecondary,
                                borderWidth: 3,
                              ),
                              const Gap(16),
                              Text(
                                (profile.displayName ?? '').toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Syne',
                                ),
                              ),
                              const Gap(8),
                              // Verified badge row — only shown for real verified creators
                              if (profile.isVerifiedCreator)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: EmergeColors.nebulaPrimary
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: EmergeColors.nebulaPrimary
                                            .withValues(alpha: 0.5)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded,
                                          size: 14,
                                          color:
                                              EmergeColors.nebulaPrimary),
                                      Gap(4),
                                      Text('Vanguard Elite',
                                          style: TextStyle(
                                              color:
                                                  EmergeColors.nebulaPrimary,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Social Proof / Stats Bar ───────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: GlassPanel(
                      level: GlassLevel.level2,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatColumn(
                              label: 'RECRUITS',
                              value: _formatCount(recruits)),
                          Container(
                              width: 1,
                              height: 32,
                              color: Colors.white.withValues(alpha: 0.1)),
                          _StatColumn(
                              label: 'MISSIONS',
                              value: '$missions',
                              color: EmergeColors.nebulaSecondary),
                          Container(
                              width: 1,
                              height: 32,
                              color: Colors.white.withValues(alpha: 0.1)),
                          const _StatColumn(
                              label: 'RATING',
                              value: '—',
                              color: EmergeColors.nebulaPrimary),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Bio + Speciality Tags ─────────────────────────────
                if (profile.bio.isNotEmpty ||
                    profile.specialityTags.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'COMMANDER LOG',
                            style: TextStyle(
                              color: EmergeColors.nebulaPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const Gap(12),
                          if (profile.bio.isNotEmpty)
                            Text(
                              profile.bio,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.6),
                            ),
                          if (profile.specialityTags.isNotEmpty) ...[
                            const Gap(16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: profile.specialityTags
                                  .map(
                                    (tag) => Chip(
                                      label: Text(
                                        tag,
                                        style: const TextStyle(
                                          color:
                                              EmergeColors.nebulaPrimary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      backgroundColor:
                                          EmergeColors.nebulaPrimaryContainer
                                              .withValues(alpha: 0.18),
                                      side: BorderSide(
                                        color: EmergeColors
                                            .nebulaPrimaryContainer
                                            .withValues(alpha: 0.35),
                                      ),
                                      visualDensity:
                                          VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize
                                              .shrinkWrap,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          const Gap(32),
                        ],
                      ),
                    ),
                  ),

                // ── Blueprints Section ───────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'LATEST TRANSMISSIONS',
                      style: TextStyle(
                        color: EmergeColors.nebulaSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: Gap(16)),

                if (blueprintsAsync.isLoading && creatorBlueprints.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: EmergeLoadingSkeleton(itemCount: 2),
                    ),
                  )
                else if (blueprintsAsync.hasError &&
                    creatorBlueprints.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Could not load blueprints.',
                          style: TextStyle(color: Colors.white38)),
                    ),
                  )
                else if (creatorBlueprints.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GlassPanel(
                        level: GlassLevel.level1,
                        padding: const EdgeInsets.all(20),
                        child: const Text(
                          'No blueprints published yet.',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 200,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: creatorBlueprints.length,
                        separatorBuilder: (_, i) => const Gap(12),
                        itemBuilder: (context, index) {
                          final blueprint = creatorBlueprints[index];
                          return GestureDetector(
                            onTap: () => context.push(
                              '/blueprint/${blueprint.id}',
                              extra: blueprint,
                            ),
                            child: SizedBox(
                              width: 180,
                              child: GlassPanel(
                                level: GlassLevel.level1,
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.widgets_rounded,
                                      size: 28,
                                      color: EmergeColors.nebulaSecondary,
                                    ),
                                    const Spacer(),
                                    Text(
                                      blueprint.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Gap(6),
                                    Text(
                                      '${blueprint.habits.length} habits',
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // ── Bottom spacing for CTA ───────────────────────────
                const SliverToBoxAdapter(child: Gap(120)),
              ],
            );
          },

          // ── Loading State (shimmer) ──────────────────────────────────
          loading: () => Scaffold(
            appBar:
                AppBar(backgroundColor: Colors.transparent, elevation: 0),
            backgroundColor: Colors.transparent,
            body: const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EmergeLoadingSkeleton(itemCount: 1),
                  Gap(24),
                  EmergeLoadingSkeleton(itemCount: 3),
                ],
              ),
            ),
          ),

          // ── Error State (no raw exceptions) ──────────────────────────
          error: (e, st) => Scaffold(
            appBar: AppBar(title: const Text('Creator')),
            body: Center(
              child: AppErrorWidget(
                message:
                    'Could not load this creator profile. Please try again.',
                onRetry: () =>
                    ref.invalidate(creatorProfileProvider(creatorId)),
              ),
            ),
          ),
        ),
      ),

      // ── Primary CTA — fixed at bottom ───────────────────────────────
      bottomNavigationBar: profileAsync.maybeWhen(
        data: (profile) => profile == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Primary CTA — joins the creator's first blueprint
                      EmergePrimaryButton(
                        label: 'JOIN VANGUARD',
                        trailingIcon: Icons.arrow_forward_rounded,
                        onPressed: () {
                          if (creatorBlueprints.isNotEmpty) {
                            context.push(
                                '/blueprint/${creatorBlueprints.first.id}');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "This creator hasn't published any blueprints yet."),
                              ),
                            );
                          }
                        },
                      ),
                      const Gap(8),
                      // Secondary CTA — Share (outlined)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.share_outlined, size: 18),
                          label: const Text('Share Creator Profile'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side:
                                const BorderSide(color: Colors.white24),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            SharePlus.instance.share(
                              ShareParams(
                                text:
                                    'Check out this Creator Profile on Emerge: https://emerge.app/creators/$creatorId',
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        orElse: () => null,
      ),
    );
  }

  /// Formats an integer count with K/M suffixes when large.
  /// Examples: 942 -> "942", 1_234 -> "1,234", 14_500 -> "14.5K", 1_100_000 -> "1.1M"
  static String _formatCount(int n) {
    if (n >= 1000000) {
      final m = n / 1000000;
      return '${m.toStringAsFixed(m >= 10 ? 0 : 1)}M';
    }
    if (n >= 10000) {
      final k = n / 1000;
      return '${k.toStringAsFixed(k >= 100 ? 0 : 1)}K';
    }
    // Thousands-separated raw number (e.g. 1,234)
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ── Stat Column ────────────────────────────────────────────────────────────────
class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Syne',
          ),
        ),
        const Gap(4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
