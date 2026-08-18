import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/blueprints/presentation/widgets/blueprint_artwork.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/social/presentation/screens/blueprint_detail_screen.dart';

/// Dominant time-of-day slot ('Morning'/'Afternoon'/'Evening') across the
/// habit stack, or null when no habit carries one.
String? dominantBlueprintTimeOfDay(Blueprint blueprint) {
  final counts = <String, int>{};
  for (final habit in blueprint.habits) {
    final slot = habit.timeOfDay;
    if (slot != null) counts[slot] = (counts[slot] ?? 0) + 1;
  }
  if (counts.isEmpty) return null;
  return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

/// Dominant attribute across the habit stack, or null for an empty stack.
HabitAttribute? dominantBlueprintAttribute(Blueprint blueprint) {
  if (blueprint.habits.isEmpty) return null;
  final counts = <HabitAttribute, int>{};
  for (final habit in blueprint.habits) {
    counts[habit.attribute] = (counts[habit.attribute] ?? 0) + 1;
  }
  return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

/// Display label for a [HabitAttribute], matching the timeline section.
String blueprintAttributeLabel(HabitAttribute attribute) {
  switch (attribute) {
    case HabitAttribute.strength:
      return 'STRENGTH';
    case HabitAttribute.intellect:
      return 'INTELLECT';
    case HabitAttribute.vitality:
      return 'VITALITY';
    case HabitAttribute.creativity:
      return 'CREATIVITY';
    case HabitAttribute.focus:
      return 'FOCUS';
    case HabitAttribute.spirit:
      return 'SPIRIT';
  }
}

class BlueprintCard extends StatelessWidget {
  final Blueprint blueprint;

  const BlueprintCard({super.key, required this.blueprint});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlueprintDetailScreen(blueprint: blueprint),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.05),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BlueprintArtwork(imageUrl: blueprint.imageUrl),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        blueprint.difficulty.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blueprint.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'By ${blueprint.creatorName}',
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_border,
                        size: 12,
                        color: Colors.white24,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${blueprint.adoptionCount}',
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  if (dominantBlueprintTimeOfDay(blueprint) != null ||
                      dominantBlueprintAttribute(blueprint) != null) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (dominantBlueprintTimeOfDay(blueprint) != null)
                          _InfoChip(
                            icon: Icons.wb_sunny,
                            label: dominantBlueprintTimeOfDay(blueprint)!,
                          ),
                        if (dominantBlueprintAttribute(blueprint) != null)
                          _InfoChip(
                            icon: Icons.bolt_rounded,
                            label: blueprintAttributeLabel(
                              dominantBlueprintAttribute(blueprint)!,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact glass chip matching the difficulty badge's visual language.
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: EmergeColors.warmGold),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
