import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:flutter/material.dart';

/// Card showing how attribute combinations affect world growth
/// and displaying growth multiplier and archetype rank
class SynergyCard extends StatelessWidget {
  final String primaryAttribute;
  final String secondaryAttribute;
  final double growthMultiplier;
  final String archetypeRank;
  final String worldTheme;

  const SynergyCard({
    super.key,
    required this.primaryAttribute,
    required this.secondaryAttribute,
    required this.growthMultiplier,
    required this.archetypeRank,
    this.worldTheme = 'Living Forest',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EmergeColors.teal.withValues(alpha: 0.1),
            EmergeColors.violet.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: EmergeColors.teal.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.auto_awesome, color: EmergeColors.teal, size: 20),
              const SizedBox(width: 8),
              Text(
                'ATTRIBUTE SYNERGY',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: EmergeColors.teal,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Synergy description
          Text(
            'Your high $primaryAttribute and $secondaryAttribute synergy will cause the $worldTheme to bloom with bioluminescent flora ${(growthMultiplier * 10).toInt()}% faster.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textMainDark,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              // Growth Multiplier
              Expanded(
                child: _StatBox(
                  label: 'GROWTH MULTIPLIER',
                  value: 'x${growthMultiplier.toStringAsFixed(2)}',
                  color: EmergeColors.teal,
                ),
              ),
              const SizedBox(width: 16),
              // Archetype Rank
              Expanded(
                child: _StatBox(
                  label: 'ARCHETYPE RANK',
                  value: archetypeRank,
                  color: EmergeColors.violet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.textSecondaryDark,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
