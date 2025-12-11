import 'package:emerge_app/core/presentation/widgets/growth_background.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class AccountabilityScreen extends StatelessWidget {
  const AccountabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GrowthBackground(
      appBar: AppBar(
        title: const Text('Accountability'),
        backgroundColor: Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPartnerCard(context),
            const Gap(24),
            Text(
              'The Stakes',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Gap(16),
            _buildStakesCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.handshake, size: 64, color: AppTheme.primary),
            const Gap(16),
            Text(
              'Find a Partner',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Gap(8),
            const Text(
              'Habits are easier when you have someone to share the journey with.',
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            FilledButton.icon(
              onPressed: () {
                // Implement partner matching logic
                debugPrint('Finding accountability partner...');
              },
              icon: const Icon(Icons.search),
              label: const Text('Find Accountability Partner'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStakesCard(BuildContext context) {
    return Card(
      color: Colors.red.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.warning, size: 48, color: Colors.red),
            const Gap(16),
            Text(
              'Set the Stakes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const Gap(8),
            const Text(
              'Commit to a penalty if you miss your habits. E.g., Donate \$5 to a charity you dislike.',
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            OutlinedButton(
              onPressed: () {
                // Implement stakes logic
                debugPrint('Stakes set: \$5');
              },
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Set Stakes'),
            ),
          ],
        ),
      ),
    );
  }
}
