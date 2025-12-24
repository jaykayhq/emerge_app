import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/gamification/presentation/widgets/world_visualizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class EvolvingForestScreen extends ConsumerStatefulWidget {
  const EvolvingForestScreen({super.key});

  @override
  ConsumerState<EvolvingForestScreen> createState() =>
      _EvolvingForestScreenState();
}

class _EvolvingForestScreenState extends ConsumerState<EvolvingForestScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for Level Changes
    ref.listen<AsyncValue<UserProfile>>(userStatsStreamProvider, (
      previous,
      next,
    ) {
      next.whenData((currentProfile) {
        previous?.whenData((prevProfile) {
          if (currentProfile.avatarStats.level >
              prevProfile.avatarStats.level) {
            _confettiController.play();
            _showLevelUpDialog(context, currentProfile.avatarStats.level);
          }
        });
      });
    });

    final statsAsync = ref.watch(userStatsStreamProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Evolving World'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.movie_filter),
            onPressed: () => context.push('/world/recap'),
            tooltip: 'Cinematic Recap',
          ),
        ],
      ),
      body: statsAsync.when(
        data: (profile) {
          final world = profile.worldState;
          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Full Screen Background
              Positioned.fill(
                child: WorldVisualizer(
                  // Use overall level to drive the world stage (capped at 5 for now)
                  stage: profile.avatarStats.level,
                ),
              ),

              // Confetti Overlay
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: pi / 2,
                  maxBlastForce: 5,
                  minBlastForce: 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 50,
                  gravity: 0.1,
                ),
              ),

              // 2. Gradient Overlays
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 200,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 300,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Stats Overlay (Top)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Gap(60), // Space for AppBar
                      const Gap(60), // Space for AppBar
                      _buildStatsRow(world, profile.avatarStats.streak),
                      const Gap(24),
                      _buildXpBar(profile.avatarStats),
                      const Spacer(),
                      // FAB Row for Daily Report and Time-lapse
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FloatingActionButton.extended(
                                heroTag: 'daily_report',
                                onPressed: () =>
                                    context.push('/world/daily-report'),
                                backgroundColor: AppTheme.primary,
                                icon: const Icon(
                                  Icons.today,
                                  color: Colors.black,
                                ),
                                label: const Text(
                                  'Daily Report',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Gap(12),
                              FloatingActionButton(
                                heroTag: 'recap',
                                onPressed: () => context.push('/world/recap'),
                                backgroundColor: AppTheme.surfaceDark,
                                child: const Icon(
                                  Icons.movie_filter,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showLevelUpDialog(BuildContext context, int newLevel) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          'LEVEL UP!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star,
              color: Colors.amber,
              size: 64,
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const Gap(16),
            Text(
              'You reached Level $newLevel',
              style: const TextStyle(color: Colors.white),
            ),
            const Text(
              'Your world is evolving.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Awesome'),
          ),
        ],
      ),
    );
  }

  Widget _buildXpBar(dynamic stats) {
    // XP to next level = 100 * level (simple formula based on repository)
    // Current Level starts at 1. Level 1 -> 2 needs 100 XP.
    // Repo formula: newLevel = (newXp / 100).floor() + 1
    // So distinct levels are at 0, 100, 200...
    final currentLevelBaseXp = (stats.level - 1) * 100;
    final nextLevelXp = stats.level * 100;
    final progress =
        (stats.totalXp - currentLevelBaseXp) /
        (nextLevelXp - currentLevelBaseXp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level ${stats.level}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${stats.totalXp} XP',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const Gap(8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            minHeight: 8,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildStatsRow(dynamic world, int streak) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'World Health',
            // Display inverse of entropy as health
            value: '${((1.0 - world.entropy) * 100).toInt()}%',
            icon: Icons.eco,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _StatCard(
            label: 'Forest Level',
            value: '${world.forestLevel}',
            icon: Icons.forest,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _StatCard(
            label: 'Streak',
            value: '$streak Days',
            icon: Icons.local_fire_department,
            isHighlight: true,
          ),
        ),
      ],
    ).animate().slideY(begin: -0.5, end: 0, duration: 600.ms);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isHighlight;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight
              ? Colors.amber.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isHighlight ? Colors.amber : Colors.white70,
              ),
              const Gap(4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Gap(4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
