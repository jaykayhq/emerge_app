import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class EvolvingForestScreen extends ConsumerWidget {
  const EvolvingForestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuC9qVC2k_AKRjVBsLoyd0zQbT-EGc-NoKyTIlfg5McyBhTcAFG4lL13TFPNQtvoARrzDQrDC4dWhNgZertmRg-V0_zUAxxXMSnc0hvPHJ_EbByZkriSJr16ut2RCsfqjAR0CyTMlEEyS9_ouZy4byX2LyS22ZAdisrYP-ifpAebBp1FlHqHiac6EJ91GcWaPKbIL9tO2xiQ19ejRVJ7Jwl4G9W5-1yPZKvCjGiAQMZawXdrrG34ma7s5M70gYjbza9PU8CTmzXP1PQ',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.white54),
                      ),
                    );
                  },
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
                      _buildStatsRow(world),
                      const Spacer(),
                      // FAB for Time-lapse
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: FloatingActionButton(
                            onPressed: () => context.push('/world/recap'),
                            backgroundColor: AppTheme.primary,
                            child: const Icon(
                              Icons.movie_filter,
                              color: Colors.black,
                            ),
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

  Widget _buildStatsRow(dynamic world) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'World Health',
            value: '85%',
            icon: Icons.eco,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _StatCard(label: 'Lifeforms', value: '42', icon: Icons.pets),
        ),
        const Gap(12),
        Expanded(
          child: _StatCard(
            label: 'Streak',
            value: '14 Days',
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
