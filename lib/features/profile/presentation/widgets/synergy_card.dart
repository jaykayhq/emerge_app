import 'dart:ui';

import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:flutter/material.dart';

/// Card showing how attribute combinations affect world growth
/// and displaying growth multiplier and archetype rank
/// Redesigned with glassmorphism effect
class SynergyCard extends StatefulWidget {
  final String primaryAttribute;
  final String secondaryAttribute;
  final double growthMultiplier;
  final String archetypeRank;
  final String worldTheme;
  final Color? accentColor;

  const SynergyCard({
    super.key,
    required this.primaryAttribute,
    required this.secondaryAttribute,
    required this.growthMultiplier,
    required this.archetypeRank,
    this.worldTheme = 'Living Forest',
    this.accentColor,
  });

  @override
  State<SynergyCard> createState() => _SynergyCardState();
}

class _SynergyCardState extends State<SynergyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor ?? EmergeColors.teal;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: accentColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'ATTRIBUTE SYNERGY',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Synergy description
                Text(
                  'Your high ${widget.primaryAttribute} and ${widget.secondaryAttribute} synergy will cause the ${widget.worldTheme} to bloom with bioluminescent flora ${(widget.growthMultiplier * 10).toInt()}% faster.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMainDark,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Stats row with shimmer
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Row(
                      children: [
                        // Growth Multiplier with shimmer
                        Expanded(
                          child: _GlassStatBox(
                            label: 'GROWTH MULTIPLIER',
                            value:
                                'x${widget.growthMultiplier.toStringAsFixed(2)}',
                            color: accentColor,
                            shimmerProgress: _shimmerController.value,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Archetype Rank
                        Expanded(
                          child: _GlassStatBox(
                            label: 'ARCHETYPE RANK',
                            value: widget.archetypeRank,
                            color: EmergeColors.violet,
                            shimmerProgress: _shimmerController.value,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassStatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double shimmerProgress;

  const _GlassStatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.shimmerProgress,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate shimmer opacity (subtle pulse)
    final shimmerOpacity = 0.8 + (shimmerProgress * 0.2);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondaryDark,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [
                  color,
                  color.withValues(alpha: shimmerOpacity),
                  color,
                ],
                stops: [
                  (shimmerProgress - 0.3).clamp(0.0, 1.0),
                  shimmerProgress,
                  (shimmerProgress + 0.3).clamp(0.0, 1.0),
                ],
              ).createShader(bounds);
            },
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
