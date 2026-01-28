import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/profile/presentation/widgets/evolving_silhouette.dart';
import 'package:emerge_app/features/profile/presentation/widgets/attribute_radar_chart.dart';
import 'package:emerge_app/features/profile/presentation/widgets/synergy_card.dart';
import 'package:emerge_app/features/settings/presentation/widgets/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The "Future Self Studio" - the new profile screen
/// Features: Full-body silhouette, hexagonal attribute radar, synergy card
class FutureSelfStudioScreen extends ConsumerWidget {
  const FutureSelfStudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: statsAsync.when(
        data: (profile) {
          final stats = profile.avatarStats;

          // Calculate attributes from stats
          final attributes = _calculateAttributes(stats);

          // Find top two attributes for synergy
          final sortedAttributes = attributes.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final primaryAttribute = sortedAttributes.isNotEmpty
              ? sortedAttributes[0].key
              : 'Focus';
          final secondaryAttribute = sortedAttributes.length > 1
              ? sortedAttributes[1].key
              : 'Discipline';

          // Calculate growth multiplier based on consistency
          final growthMultiplier = 1.0 + (stats.level * 0.05).clamp(0, 1);

          // Get archetype rank
          final archetypeRank = _getArchetypeRank(stats.level);

          // World theme based on archetype
          final worldTheme = _getWorldTheme(profile.archetype);
          final archetypeTheme = ArchetypeTheme.forArchetype(profile.archetype);
          final accentColor = archetypeTheme.primaryColor;

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                backgroundColor: Colors.transparent,
                floating: true,
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: AppTheme.textMainDark,
                    ),
                    onPressed: () => SettingsSheet.show(context),
                  ),
                ],
                title: Column(
                  children: [
                    Text(
                      'FUTURE SELF',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textMainDark,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '● IDENTITY CALIBRATED',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                centerTitle: true,
              ),

              // Identity header (archetype + level)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'IDENTITY',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppTheme.textSecondaryDark,
                                  letterSpacing: 1,
                                ),
                          ),
                          Text(
                            '${_getArchetypeName(profile.archetype)} Archetype',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppTheme.textMainDark,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'LVL ${stats.level}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // XP Progress bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${stats.totalXp % 500}/${500}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSecondaryDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (stats.totalXp % 500) / 500,
                          backgroundColor: accentColor.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation(accentColor),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Attribute Radar Chart
              SliverToBoxAdapter(
                child: Center(
                  child: AttributeRadarChart(
                    attributes: attributes,
                    size: 220,
                    onAttributeTap: (attr) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$attr: Boost with related habits'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: EmergeColors.teal,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Evolving Silhouette
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.4),
                        accentColor.withValues(alpha: 0.05),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Grid background effect
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _HolographicGridPainter(
                            color: accentColor.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Center(
                        child: EvolvingSilhouette(
                          archetype: profile.archetype,
                          level: stats.level,
                          consistency: (stats.totalXp / 1000).clamp(0.0, 1.0),
                          size: 160,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Synergy Card
              SliverToBoxAdapter(
                child: SynergyCard(
                  primaryAttribute: primaryAttribute,
                  secondaryAttribute: secondaryAttribute,
                  growthMultiplier: growthMultiplier,
                  archetypeRank: archetypeRank,
                  worldTheme: worldTheme,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Emerge Button (CTA)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [EmergeColors.teal, EmergeColors.violet],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: EmergeColors.teal.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => context.push('/create-habit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flash_on, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'EMERGE',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: EmergeColors.teal),
        ),
        error: (e, s) => Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: AppTheme.textMainDark),
          ),
        ),
      ),
    );
  }

  Map<String, double> _calculateAttributes(UserAvatarStats stats) {
    // Normalize stats to 0-1 range (cap at 500 XP per attribute)
    final maxXp = 500.0;
    return {
      'Creativity': (stats.creativityXp / maxXp).clamp(0.0, 1.0),
      'Focus': (stats.focusXp / maxXp).clamp(0.0, 1.0),
      'Output': (stats.intellectXp / maxXp).clamp(
        0.0,
        1.0,
      ), // Using intellect as output
      'Resilience': (stats.strengthXp / maxXp).clamp(
        0.0,
        1.0,
      ), // Using strength as resilience
      'Vitality': (stats.vitalityXp / maxXp).clamp(0.0, 1.0),
      'Discipline': ((stats.strengthXp + stats.focusXp) / 2 / maxXp).clamp(
        0.0,
        1.0,
      ),
    };
  }

  String _getArchetypeRank(int level) {
    if (level >= 50) return 'Legend';
    if (level >= 30) return 'Master';
    if (level >= 15) return 'Adept';
    return 'Initiate';
  }

  String _getArchetypeName(UserArchetype archetype) {
    switch (archetype) {
      case UserArchetype.athlete:
        return 'Athlete';
      case UserArchetype.scholar:
        return 'Scholar';
      case UserArchetype.creator:
        return 'Creator';
      case UserArchetype.stoic:
        return 'Stoic';
      case UserArchetype.mystic:
        return 'Mystic';
      case UserArchetype.none:
        return 'Explorer';
    }
  }

  String _getWorldTheme(UserArchetype archetype) {
    switch (archetype) {
      case UserArchetype.athlete:
        return 'Mountain Fortress';
      case UserArchetype.scholar:
        return 'Crystal Library';
      case UserArchetype.creator:
        return 'Living Forest';
      case UserArchetype.stoic:
        return 'Ancient Temple';
      case UserArchetype.mystic:
        return 'Ethereal Realm';
      case UserArchetype.none:
        return 'Living Forest';
    }
  }
}

class _HolographicGridPainter extends CustomPainter {
  final Color color;

  _HolographicGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final spacing = 20.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
