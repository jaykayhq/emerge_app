import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/habit_timeline_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

/// Callback when a habit template is selected
typedef OnTemplateSelected = void Function(HabitTemplate template);

/// Extended habit template with all creation fields
class HabitTemplate {
  final String title;
  final String description;
  final String anchor;
  final String category;
  final IconData icon;
  final String frequency;
  final String timeOfDay;
  final HabitAttribute attribute;

  const HabitTemplate({
    required this.title,
    required this.description,
    required this.anchor,
    required this.category,
    required this.icon,
    this.frequency = 'Daily',
    this.timeOfDay = 'Morning',
    this.attribute = HabitAttribute.vitality,
  });

  /// Get the identity color for this template's attribute
  Color get color => attributeColor(attribute);

  /// Convert from ArchetypeHabitSuggestion
  factory HabitTemplate.fromSuggestion(
    ArchetypeHabitSuggestion suggestion, {
    String category = 'General',
  }) {
    return HabitTemplate(
      title: suggestion.title,
      description: suggestion.description,
      anchor: suggestion.anchor,
      category: category,
      icon: suggestion.icon,
    );
  }
}

/// Inline horizontal carousel showing archetype-specific habit templates
/// Redesigned with cosmic glassmorphism aesthetic
class HabitTemplateCarousel extends StatelessWidget {
  final UserArchetype archetype;
  final OnTemplateSelected onTemplateSelected;
  final VoidCallback? onSeeMore;

  const HabitTemplateCarousel({
    super.key,
    required this.archetype,
    required this.onTemplateSelected,
    this.onSeeMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ArchetypeTheme.forArchetype(archetype);
    final templates = theme.suggestedHabits
        .map(
          (h) => HabitTemplate.fromSuggestion(h, category: theme.archetypeName),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: EmergeColors.teal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: EmergeColors.teal,
                        size: 16,
                      ),
                    ),
                    const Gap(10),
                    Flexible(
                      child: Text(
                        'Quick Start',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.textMainDark,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (onSeeMore != null) {
                    onSeeMore!();
                  } else {
                    _showAllTemplates(context, theme);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: EmergeColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: EmergeColors.teal.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(
                          color: EmergeColors.teal,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const Gap(4),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: EmergeColors.teal,
                        size: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Gap(12),
        SizedBox(
          height: 115, // Increased from 100 to prevent 1px overflow
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: templates.length,
            separatorBuilder: (_, __) => const Gap(12),
            itemBuilder: (context, index) {
              final template = templates[index];
              return _TemplateCard(
                template: template,
                accentColor: template.color,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onTemplateSelected(template);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAllTemplates(BuildContext context, ArchetypeTheme theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HabitTemplateSheet(
        archetype: archetype,
        onTemplateSelected: (template) {
          Navigator.of(context).pop();
          onTemplateSelected(template);
        },
      ),
    );
  }
}

/// Individual template card with glassmorphism design
class _TemplateCard extends StatelessWidget {
  final HabitTemplate template;
  final Color accentColor;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.2),
                    accentColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Icon(template.icon, color: accentColor, size: 16),
            ),
            const Gap(8),
            Text(
              template.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMainDark,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(2),
            Text(
              template.anchor,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryDark,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet with categorized habit templates - cosmic glassmorphism design
class HabitTemplateSheet extends StatefulWidget {
  final UserArchetype archetype;
  final OnTemplateSelected onTemplateSelected;

  const HabitTemplateSheet({
    super.key,
    required this.archetype,
    required this.onTemplateSelected,
  });

  @override
  State<HabitTemplateSheet> createState() => _HabitTemplateSheetState();
}

class _HabitTemplateSheetState extends State<HabitTemplateSheet> {
  String _selectedCategory = 'All';

  /// Expanded template library with categories
  List<HabitTemplate> get _allTemplates => [
    // ═══ STRENGTH & VITALITY (Physical) ═══
    const HabitTemplate(
      title: 'Morning Movement',
      description: '10 minutes of stretching or exercise',
      anchor: 'After waking up',
      category: 'Vitality',
      icon: Icons.fitness_center,
      timeOfDay: 'Morning',
      attribute: HabitAttribute.vitality,
    ),
    const HabitTemplate(
      title: 'Hydration',
      description: 'Drink a full glass of water',
      anchor: 'After waking up',
      category: 'Vitality',
      icon: Icons.water_drop,
      timeOfDay: 'Morning',
      attribute: HabitAttribute.vitality,
    ),
    const HabitTemplate(
      title: 'Evening Walk',
      description: '15 minute walk to decompress',
      anchor: 'After dinner',
      category: 'Vitality',
      icon: Icons.directions_walk,
      timeOfDay: 'Evening',
      attribute: HabitAttribute.vitality,
    ),
    const HabitTemplate(
      title: 'Power Workout',
      description: '30 minute strength training',
      anchor: 'After work',
      category: 'Strength',
      icon: Icons.sports_gymnastics,
      timeOfDay: 'Afternoon',
      attribute: HabitAttribute.strength,
    ),
    const HabitTemplate(
      title: 'Sleep Ritual',
      description: 'Prepare for restful sleep',
      anchor: 'Before bed',
      category: 'Vitality',
      icon: Icons.bedtime,
      timeOfDay: 'Night',
      attribute: HabitAttribute.vitality,
    ),

    // ═══ SPIRIT (Mindfulness) ═══
    const HabitTemplate(
      title: 'Morning Meditation',
      description: '5 minutes of silent reflection',
      anchor: 'After waking up',
      category: 'Spirit',
      icon: Icons.spa,
      timeOfDay: 'Morning',
      attribute: HabitAttribute.spirit,
    ),
    const HabitTemplate(
      title: 'Gratitude Practice',
      description: 'Write 3 things you\'re grateful for',
      anchor: 'After morning coffee',
      category: 'Spirit',
      icon: Icons.favorite,
      timeOfDay: 'Morning',
      attribute: HabitAttribute.spirit,
    ),
    const HabitTemplate(
      title: 'Breathing Exercise',
      description: '5 deep breaths to reset',
      anchor: 'Before meetings',
      category: 'Spirit',
      icon: Icons.air,
      timeOfDay: 'Anytime',
      attribute: HabitAttribute.spirit,
    ),
    const HabitTemplate(
      title: 'Digital Sunset',
      description: 'No screens 1 hour before bed',
      anchor: 'Before bed',
      category: 'Spirit',
      icon: Icons.phone_disabled,
      timeOfDay: 'Night',
      attribute: HabitAttribute.spirit,
    ),
    const HabitTemplate(
      title: 'Evening Reflection',
      description: 'Review your day mindfully',
      anchor: 'Before bed',
      category: 'Spirit',
      icon: Icons.nights_stay,
      timeOfDay: 'Night',
      attribute: HabitAttribute.spirit,
    ),

    // ═══ INTELLECT (Learning) ═══
    const HabitTemplate(
      title: 'Daily Reading',
      description: 'Read 10 pages of a book',
      anchor: 'After morning coffee',
      category: 'Intellect',
      icon: Icons.menu_book,
      timeOfDay: 'Morning',
      attribute: HabitAttribute.intellect,
    ),
    const HabitTemplate(
      title: 'Learning Session',
      description: '20 minutes of focused study',
      anchor: 'After lunch',
      category: 'Intellect',
      icon: Icons.school,
      timeOfDay: 'Afternoon',
      attribute: HabitAttribute.intellect,
    ),
    const HabitTemplate(
      title: 'Podcast Learning',
      description: 'Listen to educational content',
      anchor: 'During commute',
      category: 'Intellect',
      icon: Icons.podcasts,
      timeOfDay: 'Morning',
      attribute: HabitAttribute.intellect,
    ),
    const HabitTemplate(
      title: 'Write & Reflect',
      description: 'Write 3 things you learned',
      anchor: 'Before bed',
      category: 'Intellect',
      icon: Icons.edit_note,
      timeOfDay: 'Night',
      attribute: HabitAttribute.intellect,
    ),
    const HabitTemplate(
      title: 'Skill Practice',
      description: '15 minutes practicing a skill',
      anchor: 'After work',
      category: 'Intellect',
      icon: Icons.psychology,
      timeOfDay: 'Evening',
      attribute: HabitAttribute.intellect,
    ),

    // ═══ FOCUS (Productivity) ═══
    const HabitTemplate(
      title: 'Morning Planning',
      description: 'Set top 3 priorities for today',
      anchor: 'After waking up',
      category: 'Focus',
      icon: Icons.checklist,
      timeOfDay: 'Morning',
      attribute: HabitAttribute.focus,
    ),
    const HabitTemplate(
      title: 'Deep Work Block',
      description: '90 minutes of focused work',
      anchor: 'After morning coffee',
      category: 'Focus',
      icon: Icons.timer,
      timeOfDay: 'Morning',
      attribute: HabitAttribute.focus,
    ),
    const HabitTemplate(
      title: 'Inbox Zero',
      description: 'Process all messages to zero',
      anchor: 'After lunch',
      category: 'Focus',
      icon: Icons.email,
      timeOfDay: 'Afternoon',
      attribute: HabitAttribute.focus,
    ),
    const HabitTemplate(
      title: 'Weekly Review',
      description: 'Review and plan your week',
      anchor: 'Sunday evening',
      category: 'Focus',
      icon: Icons.calendar_month,
      timeOfDay: 'Evening',
      frequency: 'Weekly',
      attribute: HabitAttribute.focus,
    ),
    const HabitTemplate(
      title: 'Tomorrow\'s Prep',
      description: 'Prepare for the next day',
      anchor: 'Before bed',
      category: 'Focus',
      icon: Icons.today,
      timeOfDay: 'Night',
      attribute: HabitAttribute.focus,
    ),

    // ═══ CREATIVITY ═══
    const HabitTemplate(
      title: 'Creative Morning',
      description: '15 minutes of creative work',
      anchor: 'After waking up',
      category: 'Creativity',
      icon: Icons.palette,
      timeOfDay: 'Morning',
      attribute: HabitAttribute.creativity,
    ),
    const HabitTemplate(
      title: 'Idea Capture',
      description: 'Write down 3 new ideas',
      anchor: 'After morning coffee',
      category: 'Creativity',
      icon: Icons.lightbulb,
      timeOfDay: 'Morning',
      attribute: HabitAttribute.creativity,
    ),
    const HabitTemplate(
      title: 'Ship Something',
      description: 'Complete and share one creation',
      anchor: 'Before bed',
      category: 'Creativity',
      icon: Icons.rocket_launch,
      timeOfDay: 'Night',
      attribute: HabitAttribute.creativity,
    ),
    const HabitTemplate(
      title: 'Inspiration Hunt',
      description: 'Seek out creative inspiration',
      anchor: 'After lunch',
      category: 'Creativity',
      icon: Icons.explore,
      timeOfDay: 'Afternoon',
      attribute: HabitAttribute.creativity,
    ),
    const HabitTemplate(
      title: 'Daily Sketch',
      description: 'Draw or design for 10 minutes',
      anchor: 'After work',
      category: 'Creativity',
      icon: Icons.brush,
      timeOfDay: 'Evening',
      attribute: HabitAttribute.creativity,
    ),
  ];

  List<String> get _categories => [
    'All',
    'Strength',
    'Vitality',
    'Spirit',
    'Intellect',
    'Focus',
    'Creativity',
  ];

  List<HabitTemplate> get _filteredTemplates {
    if (_selectedCategory == 'All') {
      return _allTemplates;
    }
    return _allTemplates.where((t) => t.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1A)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondaryDark.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            EmergeColors.teal.withValues(alpha: 0.2),
                            EmergeColors.teal.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: EmergeColors.teal.withValues(alpha: 0.2),
                            blurRadius: 12,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.auto_stories,
                        color: EmergeColors.teal,
                        size: 22,
                      ),
                    ),
                    const Gap(14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Habit Templates',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppTheme.textMainDark,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Gap(2),
                        Text(
                          'Tap to quick-fill your habit',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondaryDark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Gap(20),

              // Category chips
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const Gap(10),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = category == _selectedCategory;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCategory = category);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    EmergeColors.teal,
                                    EmergeColors.teal.withValues(alpha: 0.8),
                                  ],
                                )
                              : null,
                          color: isSelected
                              ? null
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? EmergeColors.teal
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: EmergeColors.teal.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 12,
                                    spreadRadius: -2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondaryDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Gap(20),

              // Template grid
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  itemCount: _filteredTemplates.length,
                  separatorBuilder: (_, __) => const Gap(12),
                  itemBuilder: (context, index) {
                    final template = _filteredTemplates[index];
                    return _TemplateListTile(
                      template: template,
                      accentColor: template.color,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.onTemplateSelected(template);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// List tile for bottom sheet templates with glassmorphism
class _TemplateListTile extends StatelessWidget {
  final HabitTemplate template;
  final Color accentColor;
  final VoidCallback onTap;

  const _TemplateListTile({
    required this.template,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.2),
                    accentColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Icon(template.icon, color: accentColor, size: 22),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.textMainDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    template.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryDark,
                    ),
                  ),
                  const Gap(8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _InfoChip(
                        icon: Icons.link,
                        label: template.anchor,
                        color: accentColor,
                      ),
                      _InfoChip(
                        icon: Icons.schedule,
                        label: template.timeOfDay,
                        color: accentColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.add, color: accentColor, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small info chip for template details
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color.withValues(alpha: 0.8)),
          const Gap(4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
