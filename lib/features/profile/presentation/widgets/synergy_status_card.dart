import 'dart:ui';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:flutter/material.dart';

/// Synergy Status widget - displays top 2 attributes with XP
/// Shows "See More" button to view all attributes breakdown
class SynergyStatusCard extends StatelessWidget {
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
                _buildCardContent(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    final attributeXp = profile.avatarStats.attributeXp;
    final attributes = ['strength', 'intellect', 'vitality', 'creativity', 'focus', 'spirit'];

    // Sort by XP descending, take top 2
    final sortedAttrs = attributes
        .where((a) => attributeXp.containsKey(a) && (attributeXp[a] ?? 0) > 0)
        .toList()
      ..sort((a, b) => (attributeXp[b] ?? 0).compareTo(attributeXp[a] ?? 0));

    // If no attributes with XP, show empty state
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
              xp: attributeXp[attr] ?? 0,
              habits: _getHabitsForAttribute(attr),
            ),
          )).toList(),
        ),

        SizedBox(height: 12),

        // See More button
        if (sortedAttrs.length > 2)
          GestureDetector(
            onTap: () => _showAttributeBreakdownSheet(context),
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

  List<Habit> _getHabitsForAttribute(String attribute) {
    // Return habits that contribute to this attribute
    return habits.where((h) =>
      h.attribute.name.toLowerCase() == attribute.toLowerCase()
    ).take(3).toList();
  }

  void _showAttributeBreakdownSheet(BuildContext context) {
    final attributeXp = profile.avatarStats.attributeXp;
    final attributes = ['strength', 'intellect', 'vitality', 'creativity', 'focus', 'spirit'];
    final sortedAttrs = attributes
        .where((a) => attributeXp.containsKey(a))
        .toList()
      ..sort((a, b) => (attributeXp[b] ?? 0).compareTo(attributeXp[a] ?? 0));

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
                  final xp = attributeXp[attr] ?? 0;

                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: ArchetypeColors.forAttribute(attr).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getAttributeIcon(attr),
                        color: ArchetypeColors.forAttribute(attr),
                      ),
                    ),
                    title: Text(
                      attr.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Text(
                      '$xp XP',
                      style: TextStyle(
                        color: ArchetypeColors.forAttribute(attr),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
}

class _AttributeDisplay extends StatelessWidget {
  final String attribute;
  final int xp;
  final List<Habit> habits;

  const _AttributeDisplay({
    required this.attribute,
    required this.xp,
    required this.habits,
  });

  @override
  Widget build(BuildContext context) {
    final color = ArchetypeColors.forAttribute(attribute);
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
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            attribute.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$xp XP',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (habits.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '+${habits.first.impact} from ${habits.first.title}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

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
}
