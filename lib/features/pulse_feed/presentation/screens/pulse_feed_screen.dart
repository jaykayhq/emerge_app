import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

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
                  // Animated pulse ring
                  _PulseRing(),
                  const Gap(24),
                  Text(
                    'Your Pulse is just getting started',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(12),
                  Text(
                    'Complete habits, join tribes, and share progress\nto see activity from your crew here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const Gap(32),
                  // Quick actions
                  Column(
                    children: [
                      _EmptyActionButton(
                        icon: Icons.bolt,
                        label: 'Complete a habit',
                        onTap: () {
                          context.go('/timeline');
                        },
                      ),
                      const Gap(12),
                      _EmptyActionButton(
                        icon: Icons.groups,
                        label: 'Explore tribes',
                        onTap: () {
                          context.go('/social/all');
                        },
                        isSecondary: true,
                      ),
                      const Gap(12),
                      _EmptyActionButton(
                        icon: Icons.person_add,
                        label: 'Invite friends',
                        onTap: () {
                          context.go('/social/contacts');
                        },
                        isSecondary: true,
                      ),
                    ],
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

class _PulseRing extends StatefulWidget {
  const _PulseRing();

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer expanding rings
            ...List.generate(3, (index) {
              final delay = index * 0.33;
              final progress = (_controller.value + delay) % 1.0;
              return Opacity(
                opacity: (1.0 - progress) * 0.3,
                child: Container(
                  width: 80 + progress * 100,
                  height: 80 + progress * 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2BEE79).withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                ),
              );
            }),
            // Center icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2BEE79).withValues(alpha: 0.2),
                    const Color(0xFF2BEE79).withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF2BEE79).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.favorite_outline_rounded,
                size: 40,
                color: Color(0xFF2BEE79),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSecondary;

  const _EmptyActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: isSecondary
          ? OutlinedButton.icon(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                foregroundColor: Colors.white,
              ),
              icon: Icon(icon, size: 20, color: Colors.white70),
              label: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2BEE79),
                foregroundColor: const Color(0xFF05100B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(icon, size: 20),
              label: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
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

