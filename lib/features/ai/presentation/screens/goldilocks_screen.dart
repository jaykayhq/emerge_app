import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/ai/domain/services/ai_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class GoldilocksScreen extends ConsumerStatefulWidget {
  const GoldilocksScreen({super.key});

  @override
  ConsumerState<GoldilocksScreen> createState() => _GoldilocksScreenState();
}

class _GoldilocksScreenState extends ConsumerState<GoldilocksScreen> {
  @override
  Widget build(BuildContext context) {
    final aiService = ref.watch(aiServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Training Partner'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Gap(24),
            // AI Avatar
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceDark,
                border: Border.all(color: Colors.cyanAccent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 60,
                color: Colors.cyanAccent,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const Gap(32),
            Text(
              'Goldilocks Analysis',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const Gap(16),
            FutureBuilder<String>(
              future: aiService.getGoldilocksAdjustment(6, 0.5), // Mock data
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        snapshot.data ?? 'Analyzing...',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Gap(24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent.withValues(
                                alpha: 0.2,
                              ),
                              foregroundColor: Colors.redAccent,
                            ),
                            child: const Text('Too Hard'),
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent.withValues(
                                alpha: 0.2,
                              ),
                              foregroundColor: Colors.greenAccent,
                            ),
                            child: const Text('Just Right'),
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent.withValues(
                                alpha: 0.2,
                              ),
                              foregroundColor: Colors.orangeAccent,
                            ),
                            child: const Text('Too Easy'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0);
              },
            ),
          ],
        ),
      ),
    );
  }
}
