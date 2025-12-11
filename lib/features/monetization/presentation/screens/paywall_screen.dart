import 'package:emerge_app/core/presentation/widgets/growth_background.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremiumAsync = ref.watch(isPremiumProvider);

    return GrowthBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              ),
              const Gap(20),
              Text(
                'Unlock Emerge Premium',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(10),
              Text(
                'Become who you are, faster.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Gap(40),
              _BenefitRow(
                icon: Icons.block,
                title: 'Ad-Free Experience',
                description: 'Focus on your habits without distractions.',
              ),
              const Gap(16),
              _BenefitRow(
                icon: Icons.all_inclusive,
                title: 'Unlimited Habits',
                description: 'Track as many habits as you need.',
              ),
              const Gap(16),
              _BenefitRow(
                icon: Icons.layers,
                title: 'Habit Stacking',
                description: 'Link habits together for better retention.',
              ),
              const Gap(16),
              _BenefitRow(
                icon: Icons.handshake,
                title: 'Habit Contracts',
                description: 'Add accountability with social penalties.',
              ),
              const Gap(16),
              _BenefitRow(
                icon: Icons.groups,
                title: 'Tribes Access',
                description:
                    'Join exclusive communities of like-minded people.',
              ),
              const Gap(16),
              _BenefitRow(
                icon: Icons.bar_chart,
                title: 'Advanced Analytics',
                description: 'Deep dive into your progress and trends.',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isPremiumAsync.isLoading
                      ? null
                      : () async {
                          await ref.read(isPremiumProvider.notifier).purchase();
                        },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isPremiumAsync.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Subscribe Now'),
                ),
              ),
              const Gap(16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      ref.read(isPremiumProvider.notifier).restore();
                    },
                    child: const Text('Restore Purchases'),
                  ),
                  const Text('•'),
                  TextButton(
                    onPressed: () {
                      launchUrl(Uri.parse('https://example.com/terms'));
                    },
                    child: const Text('Terms & Privacy'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const Gap(16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
