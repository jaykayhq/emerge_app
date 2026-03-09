import 'dart:ui';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/attribute_progress_provider.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Maps a [HabitAttribute] to its identity color.
Color attributeColor(HabitAttribute attribute) {
  switch (attribute) {
    case HabitAttribute.strength:
      return const Color(0xFFFF6B6B); // Coral red
    case HabitAttribute.intellect:
      return const Color(0xFF6C63FF); // Indigo purple
    case HabitAttribute.vitality:
      return const Color(0xFF2BEE79); // Emerge green
    case HabitAttribute.creativity:
      return const Color(0xFFE040FB); // Magenta pink
    case HabitAttribute.focus:
      return const Color(0xFFFFB74D); // Amber gold
    case HabitAttribute.spirit:
      return const Color(0xFF4DD0E1); // Cyan teal
  }
}

/// Utility function to get attribute icon
IconData _getAttributeIcon(String attribute) {
  switch (attribute.toLowerCase()) {
    case 'strength': return Icons.fitness_center;
    case 'intellect': return Icons.psychology;
    case 'vitality': return Icons.favorite;
    case 'creativity': return Icons.palette;
    case 'focus': return Icons.center_focus_strong;
    case 'spirit': return Icons.auto_awesome;
    default: return Icons.stars;
  }
}

/// Synergy Status widget - displays top 2 attributes with XP
/// Shows "See More" button to view all attributes breakdown
/// Now uses actual avatarStats to show contribution to overall level
class SynergyStatusCard extends ConsumerWidget {
  final UserProfile profile;
  final Color accentColor;
  final List<Habit> habits; // For showing which habits contribute to attributes

  const SynergyStatusCard({
    super.key,
    required this.profile,
    required this.accentColor,
    this.habits = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      'ATTRIBUTE PROGRESS',
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

                // Content
                _buildCardContent(context, ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, WidgetRef ref) {
    // Watch the new attribute progress provider
    final attributeProgress = ref.watch(attributeProgressFromHabitsProvider);
    final attributes = ['strength', 'intellect', 'vitality', 'creativity', 'focus', 'spirit'];

    // Sort by total XP descending, take top 2 (include 0 XP attributes)
    final sortedAttrs = attributes
        .where((a) => attributeProgress.containsKey(a))
        .toList()
      ..sort((a, b) => (attributeProgress[b]?.totalXp ?? 0).compareTo(attributeProgress[a]?.totalXp ?? 0));

    // If no attributes at all, show empty state
    if (sortedAttrs.isEmpty) {
      return _buildEmptyState();
    }

    final topAttrs = sortedAttrs.take(2).toList();

    return Column(
      children: [
        // Two attributes side by side
        Row(
          children: topAttrs.map((attr) => Expanded(
            child: _AttributeDisplay(
              attribute: attr,
              progress: attributeProgress[attr]!,
            ),
          )).toList(),
        ),

        SizedBox(height: 12),

        // See More button
        if (sortedAttrs.length > 2)
          GestureDetector(
            onTap: () => _showAttributeBreakdownSheet(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+${sortedAttrs.length - 2} See More',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.expand_more, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.hiking,
            color: Colors.white.withValues(alpha: 0.3),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete habits to earn attribute XP',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAttributeBreakdownSheet(BuildContext context, WidgetRef ref) {
    final attributeProgress = ref.watch(attributeProgressFromHabitsProvider);
    final attributes = ['strength', 'intellect', 'vitality', 'creativity', 'focus', 'spirit'];
    final sortedAttrs = attributes
        .where((a) => attributeProgress.containsKey(a))
        .toList()
      ..sort((a, b) => (attributeProgress[b]?.totalXp ?? 0).compareTo(attributeProgress[a]?.totalXp ?? 0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'All Attribute Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Total level
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Total Level: ${profile.avatarStats.level}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ),

            Divider(color: Colors.white.withValues(alpha: 0.1)),

            // Attribute list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sortedAttrs.length,
                itemBuilder: (context, index) {
                  final attr = sortedAttrs[index];
                  final progress = attributeProgress[attr]!;
                  final color = attributeColor(HabitAttribute.values.firstWhere(
                    (e) => e.name.toLowerCase() == attr,
                    orElse: () => HabitAttribute.strength,
                  ));

                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getAttributeIcon(attr),
                        color: color,
                      ),
                    ),
                    title: Text(
                      attr.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${progress.totalXp} XP • ${(progress.contributionPercent * 100).toStringAsFixed(1)}% of total',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Progress bar showing contribution to overall level
                        Stack(
                          children: [
                            // Background track
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            // Progress fill
                            FractionallySizedBox(
                              widthFactor: progress.progressPercent.clamp(0.0, 1.0),
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Contributes ${progress.contributionToOverall} XP to Level ${progress.overallLevel}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _AttributeDisplay extends StatelessWidget {
  final String attribute;
  final AttributeProgress progress;

  const _AttributeDisplay({
    required this.attribute,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final attrEnum = HabitAttribute.values.firstWhere(
      (e) => e.name.toLowerCase() == attribute,
      orElse: () => HabitAttribute.strength,
    );
    final color = attributeColor(attrEnum);
    final icon = _getAttributeIcon(attribute);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                attribute.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar showing contribution to overall level
          Stack(
            children: [
              // Background track
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // Progress fill
              FractionallySizedBox(
                widthFactor: progress.progressPercent.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${progress.totalXp} XP',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Contributes ${progress.contributionToOverall} to Level ${progress.overallLevel}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
