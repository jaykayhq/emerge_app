import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:emerge_app/core/presentation/widgets/app_back_handler.dart';
import 'package:emerge_app/core/presentation/widgets/app_error_widget.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_loading_skeleton.dart';
import 'package:emerge_app/features/pulse_feed/domain/models/pulse_feed_card.dart';
import 'package:emerge_app/features/pulse_feed/presentation/providers/pulse_feed_providers.dart';
import 'package:emerge_app/features/pulse_feed/presentation/widgets/pulse_card_widget.dart';

/// Pulse Feed — the identity-reinforcing social hub that replaces the
/// Tribe Lobby as the default view for the Social tab.
///
/// Displays a stream of [PulseFeedCard]s: identity votes, tribe activity,
/// and weekly insights, rendered as glassmorphism cards in a vertical feed.
///
/// Background is provided by the shell's [WorldBackground]; this screen
/// paints transparently over it.
class PulseFeedScreen extends ConsumerWidget {
  const PulseFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(pulseFeedProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackToHome(
        homeRoute: '/world-map',
        child: SafeArea(
          child: feedAsync.when(
            data: (cards) => _FeedContent(cards: cards),
            loading: () => const _FeedLoading(),
            error: (e, _) => Center(
              child: AppErrorWidget(
                message: 'Could not load feed',
                onRetry: () => ref.invalidate(pulseFeedProvider),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Feed Content ────────────────────────────────────────────────────────────

class _FeedContent extends StatelessWidget {
  final List<PulseFeedCard> cards;

  const _FeedContent({required this.cards});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const _EmptyState();
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: Gap(12)),
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PULSE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Syne',
                    letterSpacing: -0.5,
                  ),
                ),
                const Gap(4),
                Text(
                  'Your tribe. Your identity. In motion.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: Gap(20)),
        // Cards
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => PulseCardWidget(card: cards[index]),
            childCount: cards.length,
          ),
        ),
        const SliverToBoxAdapter(child: Gap(24)),
      ],
    );
  }
}

// ── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: Gap(12)),
        // Header still visible in empty state
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PULSE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Syne',
                    letterSpacing: -0.5,
                  ),
                ),
                const Gap(4),
                Text(
                  'Your tribe. Your identity. In motion.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite_outline_rounded,
                    size: 56,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  const Gap(16),
                  Text(
                    'No pulse yet',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Complete habits and engage with your tribe\n'
                    'to see activity here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Loading State ───────────────────────────────────────────────────────────

class _FeedLoading extends StatelessWidget {
  const _FeedLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: const [
          Gap(60),
          EmergeLoadingSkeleton(itemCount: 1),
          Gap(16),
          EmergeLoadingSkeleton(itemCount: 3),
        ],
      ),
    );
  }
}

