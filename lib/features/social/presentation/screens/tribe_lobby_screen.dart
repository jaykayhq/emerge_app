import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:emerge_app/core/presentation/widgets/app_back_handler.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_primary_button.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';

import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/domain/models/tribe.dart';
import 'package:emerge_app/features/social/presentation/providers/tribes_provider.dart';
import 'package:emerge_app/features/social/presentation/widgets/glass_panel.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_circle_section.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_creators_strip.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_live_compact.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_pulse_status_row.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_quests_for_you_section.dart';
import 'package:emerge_app/features/social/presentation/widgets/tribe_your_quests_section.dart';

/// Tribe lobby — the canonical social hub (dual hub: tribe + friends).
///
/// Sequence (identity-first):
///   Hero → Stats → Status chips → Your Circle (partners) →
///   Live (feed / leaderboard) → Creators (faces only) →
///   Your Quests (active) → Quests For You (featured) → sticky CTA bar
///
/// Background is provided by the shell's [WorldBackground]; this screen
/// paints transparently over it. Hardware back returns to the world map
/// (home) instead of exiting the app.
class TribeLobbyScreen extends ConsumerWidget {
  const TribeLobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userStatsStreamProvider);
    final clubsAsync = ref.watch(allArchetypeClubsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackToHome(
        homeRoute: '/',
        child: SafeArea(
          child: clubsAsync.when(
            data: (clubs) => profileAsync.when(
              data: (profile) {
                final userClub = _resolveUserClub(clubs, profile);
                if (userClub == null) {
                  return const _ErrorState(
                    message: 'No tribe found.',
                  );
                }

                final archetypeTheme =
                    ArchetypeTheme.forArchetype(profile.archetype);
                final momentumPct =
                    (profile.momentumScore.clamp(0.0, 1.0) * 100).round();

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: Gap(12)),
                    SliverToBoxAdapter(
                      child: _Hero(
                        userClub: userClub,
                        archetypeTheme: archetypeTheme,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: _StatsBar(
                          userClub: userClub,
                          profile: profile,
                          momentumPct: momentumPct,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: Gap(20)),
                    SliverToBoxAdapter(
                      child: TribePulseStatusRow(
                        userClub: userClub,
                        profile: profile,
                      ),
                    ),
                    const SliverToBoxAdapter(child: Gap(8)),
                    const SliverToBoxAdapter(child: TribeCircleSection()),
                    const SliverToBoxAdapter(child: Gap(8)),
                    SliverToBoxAdapter(
                      child: TribeLiveCompact(
                        clubId: userClub.id,
                        profile: profile,
                      ),
                    ),
                    const SliverToBoxAdapter(child: Gap(8)),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: TribeCreatorsStrip(),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: TribeYourQuestsSection(),
                    ),
                    const SliverToBoxAdapter(child: Gap(4)),
                    const SliverToBoxAdapter(
                      child: TribeQuestsForYouSection(),
                    ),
                    const SliverToBoxAdapter(child: Gap(24)),
                  ],
                );
              },
              loading: () => const _LobbyLoading(),
              error: (_, _) => const _ErrorState(
                message: 'Could not load profile.',
              ),
            ),
            loading: () => const _LobbyLoading(),
            error: (_, _) => const _ErrorState(
              message: 'Could not load tribes.',
            ),
          ),
        ),
      ),
      bottomNavigationBar: profileAsync.value == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.swap_horiz_rounded,
                          size: 16,
                        ),
                        label: const Text('SWITCH TRIBE'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding:
                              const EdgeInsets.symmetric(vertical: 22),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        onPressed: () => context.push('/social/all'),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: EmergePrimaryButton(
                        label: 'BROWSE CREATORS',
                        leadingIcon: Icons.explore_rounded,
                        onPressed: () => context.push('/creators'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  static Tribe? _resolveUserClub(List<Tribe> clubs, UserProfile profile) {
    if (clubs.isEmpty) return null;
    final matchIndex = clubs.indexWhere(
      (c) => c.archetypeId == profile.archetype.name,
    );
    if (matchIndex != -1) return clubs[matchIndex];
    return clubs.first;
  }
}

// ── Hero ────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final Tribe userClub;
  final ArchetypeTheme archetypeTheme;

  const _Hero({required this.userClub, required this.archetypeTheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  archetypeTheme.primaryColor,
                  archetypeTheme.accentColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: archetypeTheme.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                archetypeTheme.emoji,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          const Gap(16),
          Text(
            userClub.name.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: 'Syne',
              letterSpacing: -0.5,
            ),
          ),
          const Gap(8),
          Text(
            'Your node in the ${userClub.archetypeId} network.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Bar ──────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final Tribe userClub;
  final UserProfile profile;
  final int momentumPct;

  const _StatsBar({
    required this.userClub,
    required this.profile,
    required this.momentumPct,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      level: GlassLevel.level2,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatColumn(
            label: 'MEMBERS',
            value: '${userClub.memberCount}',
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          _StatColumn(
            label: 'DAY STREAK',
            value: '${profile.avatarStats.streak}',
            color: EmergeColors.nebulaSecondary,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          _StatColumn(
            label: 'MOMENTUM',
            value: '$momentumPct%',
            color: EmergeColors.nebulaPrimary,
          ),
        ],
      ),
    );
  }
}

// ── Stat Column ─────────────────────────────────────────────────────────────

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
            fontSize: 24,
            fontWeight: FontWeight.w800,
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

// ── States ──────────────────────────────────────────────────────────────────

class _LobbyLoading extends StatelessWidget {
  const _LobbyLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: const [
          EmergeLoadingSkeleton(itemCount: 1),
          Gap(16),
          EmergeLoadingSkeleton(itemCount: 3),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.white54),
      ),
    );
  }
}
