import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/ai/domain/services/ai_personalization_service.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AiReflectionsScreen extends ConsumerWidget {
  const AiReflectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      backgroundColor: EmergeColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: HexMeshBackground()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: habitsAsync.when(
                    data: (habits) {
                      return FutureBuilder<List<AiInsight>>(
                        future: ref
                            .read(aiPersonalizationServiceProvider)
                            .generateIdentityInsights(habits),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: EmergeColors.violet,
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'AI is meditating... (Error: ${snapshot.error})',
                                style: const TextStyle(
                                  color: AppTheme.textSecondaryDark,
                                ),
                              ),
                            );
                          }

                          final insights = snapshot.data ?? [];
                          // If no dynamic insights, show a default welcome one
                          if (insights.isEmpty) {
                            insights.add(
                              AiInsight(
                                type: InsightType.identity,
                                title: "Identity Affirmation",
                                description:
                                    "You are taking the first steps towards a better you.",
                                action: "Embrace the journey.",
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: insights.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              return _InsightCard(insight: insights[index]);
                            },
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(
                      child: Text(
                        "Error: $e",
                        style: const TextStyle(color: AppTheme.error),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppTheme.textMainDark,
                ),
              ),
              Expanded(
                child: Text(
                  'AI Insights & Reflections',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMainDark,
                  ),
                ),
              ),
              const SizedBox(width: 48), // Balance for back button
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final AiInsight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final isIdentity = insight.type == InsightType.identity;
    final iconColor = isIdentity ? EmergeColors.teal : EmergeColors.yellow;
    final bgColor = isIdentity
        ? EmergeColors.teal.withValues(alpha: 0.1)
        : EmergeColors.yellow.withValues(alpha: 0.1);
    final icon = isIdentity ? Icons.verified_user : Icons.lightbulb;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EmergeColors.hexLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                insight.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMainDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textMainDark,
              height: 1.5,
            ),
          ),
          if (insight.action.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EmergeColors.violet.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: EmergeColors.violet.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '"${insight.action}"',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: EmergeColors.violet,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (isIdentity)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Embrace this identity?',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
                const SizedBox(width: 8),
                _CircleButton(
                  Icons.close,
                  AppTheme.surfaceDark,
                  AppTheme.textSecondaryDark,
                ),
                const SizedBox(width: 8),
                _CircleButton(
                  Icons.check,
                  EmergeColors.teal.withValues(alpha: 0.2),
                  EmergeColors.teal,
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('AI Coach is a premium feature coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: EmergeColors.violet,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Adjust My Schedule'),
            ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;

  const _CircleButton(this.icon, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, size: 18, color: fg),
    );
  }
}
