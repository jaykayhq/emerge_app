import 'dart:ui';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:flutter/material.dart';

/// Synergy Status widget matching Stitch design
/// Shows which attributes are boosted by which habits
class SynergyStatusCard extends StatelessWidget {
  final List<AttributeBoost> boosts;
  final Color accentColor;

  const SynergyStatusCard({
    super.key,
    required this.boosts,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
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
                color: accentColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.bolt, color: accentColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'SYNERGY STATUS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Attribute boosts
                ...boosts.map(
                  (boost) => _AttributeBoostRow(
                    boost: boost,
                    accentColor: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AttributeBoost {
  final String attribute;
  final String boostedBy;
  final IconData icon;
  final double boostPercentage;

  const AttributeBoost({
    required this.attribute,
    required this.boostedBy,
    required this.icon,
    this.boostPercentage = 0.0,
  });
}

class _AttributeBoostRow extends StatelessWidget {
  final AttributeBoost boost;
  final Color accentColor;

  const _AttributeBoostRow({required this.boost, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final attributeColor = _getAttributeColor(boost.attribute);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Attribute icon with glow
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: attributeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: attributeColor.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: attributeColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Icon(boost.icon, color: attributeColor, size: 20),
          ),
          const SizedBox(width: 14),

          // Attribute info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  boost.attribute,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textMainDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.trending_up, size: 12, color: EmergeColors.teal),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Boosted by ${boost.boostedBy}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Boost indicator
          if (boost.boostPercentage > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: EmergeColors.teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${boost.boostPercentage.toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: EmergeColors.teal,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getAttributeColor(String attribute) {
    switch (attribute.toLowerCase()) {
      case 'vitality':
        return const Color(0xFF00E5FF); // Cyan
      case 'intellect':
        return const Color(0xFFE040FB); // Magenta
      case 'creativity':
        return const Color(0xFF76FF03); // Lime
      case 'focus':
        return const Color(0xFFFFAB00); // Amber
      case 'strength':
        return const Color(0xFFFF5252); // Red
      default:
        return EmergeColors.teal;
    }
  }
}
