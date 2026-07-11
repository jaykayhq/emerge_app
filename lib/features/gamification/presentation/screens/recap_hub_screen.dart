import 'package:emerge_app/core/presentation/widgets/cosmic_background.dart';
import 'package:emerge_app/core/presentation/widgets/glassmorphism_card.dart';
import 'package:emerge_app/features/gamification/domain/entities/weekly_recap.dart';
import 'package:emerge_app/features/gamification/presentation/providers/recap_hub_provider.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RecapHubScreen extends ConsumerWidget {
  const RecapHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recapsAsync = ref.watch(historicalRecapsProvider);
    final isPremium = ref.watch(isPremiumProvider).value ?? false;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Reflection Hub'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const CosmicBackground(child: SizedBox.shrink()),
          SafeArea(
            child: recapsAsync.when(
              data: (recaps) => _buildContent(context, ref, recaps, isPremium),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading recaps: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: isPremium
          ? FloatingActionButton.extended(
              onPressed: () => _showDateRangePicker(context, ref),
              label: const Text('Custom Range'),
              icon: const Icon(Icons.date_range),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : null,
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<UserWeeklyRecap> recaps,
    bool isPremium,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 1. Featured Section (Current Week)
        _buildFeaturedSection(context, ref, recaps, isPremium),

        const SizedBox(height: 32),

        // 2. Journey Archive
        const Text(
          'Journey History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        if (recaps.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'Your journey is just beginning.\nComplete a week of habits to see your first recap.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),
          )
        else
          ...recaps.map((recap) => _buildRecapItem(context, recap, isPremium)),

        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }

  Widget _buildFeaturedSection(
    BuildContext context,
    WidgetRef ref,
    List<UserWeeklyRecap> recaps,
    bool isPremium,
  ) {
    return GestureDetector(
      onTap: () => context.push('/world-map/recap'), // Launch passive recap
      child: GlassmorphismCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'YOUR WEEK IN REVIEW',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: Colors.white70,
                  ),
                ),
                if (isPremium)
                  const Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${DateFormat('MMM d').format(DateTime.now().subtract(const Duration(days: 7)))} - ${DateFormat('MMM d').format(DateTime.now())}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap to witness your transformation.',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 20),
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecapItem(
    BuildContext context,
    UserWeeklyRecap recap,
    bool isPremium,
  ) {
    final dateStr =
        "${DateFormat('MMM d').format(recap.startDate)} - ${DateFormat('MMM d').format(recap.endDate)}";
    final isLocked = recap.isLocked && !isPremium;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          if (isLocked) {
            context.push('/paywall');
          } else {
            // Push with ID to view specific historical recap
            context.push('/world-map/recap?id=${recap.id}');
          }
        },
        child: GlassmorphismCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  recap.isAiGenerated ? Icons.auto_awesome : Icons.bar_chart,
                  color: recap.isAiGenerated ? Colors.amber : Colors.white70,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${recap.totalHabitsCompleted} habits · ${recap.totalXpEarned} XP',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLocked)
                const Icon(Icons.lock_outline, color: Colors.white30, size: 16)
              else
                const Icon(Icons.chevron_right, color: Colors.white30),
            ],
          ),
        ),
      ),
    );
  }

  void _showDateRangePicker(BuildContext context, WidgetRef ref) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: const Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      final start = DateFormat('yyyy-MM-dd').format(picked.start);
      final end = DateFormat('yyyy-MM-dd').format(picked.end);
      context.push('/world-map/recap?start=$start&end=$end');
    }
  }
}
