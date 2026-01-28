import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/archetype_theme.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
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

  const HabitTemplate({
    required this.title,
    required this.description,
    required this.anchor,
    required this.category,
    required this.icon,
    this.frequency = 'Daily',
    this.timeOfDay = 'Morning',
  });

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
/// Tap "See More" to open full template bottom sheet
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
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: theme.primaryColor, size: 18),
                  const Gap(8),
                  Text(
                    'Suggested for ${theme.archetypeName}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.textMainDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (onSeeMore != null) {
                    onSeeMore!();
                  } else {
                    _showAllTemplates(context, theme);
                  }
                },
                child: Text(
                  'See More',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Gap(8),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: templates.length,
            separatorBuilder: (_, __) => const Gap(12),
            itemBuilder: (context, index) {
              final template = templates[index];
              return _TemplateCard(
                template: template,
                accentColor: theme.primaryColor,
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

/// Individual template card for the carousel
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
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(template.icon, color: accentColor, size: 20),
            ),
            const Gap(8),
            Text(
              template.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMainDark,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(4),
            Text(
              template.anchor,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryDark,
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

/// Bottom sheet with categorized habit templates
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
    // ═══ HEALTH & FITNESS ═══
    const HabitTemplate(
      title: 'Morning Movement',
      description: '10 minutes of stretching or exercise',
      anchor: 'After waking up',
      category: 'Health',
      icon: Icons.fitness_center,
      timeOfDay: 'Morning',
    ),
    const HabitTemplate(
      title: 'Hydration',
      description: 'Drink a full glass of water',
      anchor: 'After waking up',
      category: 'Health',
      icon: Icons.water_drop,
      timeOfDay: 'Morning',
    ),
    const HabitTemplate(
      title: 'Evening Walk',
      description: '15 minute walk to decompress',
      anchor: 'After dinner',
      category: 'Health',
      icon: Icons.directions_walk,
      timeOfDay: 'Evening',
    ),
    const HabitTemplate(
      title: 'Power Workout',
      description: '30 minute strength training',
      anchor: 'After work',
      category: 'Health',
      icon: Icons.sports_gymnastics,
      timeOfDay: 'Afternoon',
    ),
    const HabitTemplate(
      title: 'Sleep Ritual',
      description: 'Prepare for restful sleep',
      anchor: 'Before bed',
      category: 'Health',
      icon: Icons.bedtime,
      timeOfDay: 'Night',
    ),

    // ═══ MINDFULNESS ═══
    const HabitTemplate(
      title: 'Morning Meditation',
      description: '5 minutes of silent reflection',
      anchor: 'After waking up',
      category: 'Mindfulness',
      icon: Icons.spa,
      timeOfDay: 'Morning',
    ),
    const HabitTemplate(
      title: 'Gratitude Practice',
      description: 'Write 3 things you\'re grateful for',
      anchor: 'After morning coffee',
      category: 'Mindfulness',
      icon: Icons.favorite,
      timeOfDay: 'Morning',
    ),
    const HabitTemplate(
      title: 'Breathing Exercise',
      description: '5 deep breaths to reset',
      anchor: 'Before meetings',
      category: 'Mindfulness',
      icon: Icons.air,
      timeOfDay: 'Anytime',
    ),
    const HabitTemplate(
      title: 'Digital Sunset',
      description: 'No screens 1 hour before bed',
      anchor: 'Before bed',
      category: 'Mindfulness',
      icon: Icons.phone_disabled,
      timeOfDay: 'Night',
    ),
    const HabitTemplate(
      title: 'Evening Reflection',
      description: 'Review your day mindfully',
      anchor: 'Before bed',
      category: 'Mindfulness',
      icon: Icons.nights_stay,
      timeOfDay: 'Night',
    ),

    // ═══ LEARNING ═══
    const HabitTemplate(
      title: 'Daily Reading',
      description: 'Read 10 pages of a book',
      anchor: 'After morning coffee',
      category: 'Learning',
      icon: Icons.menu_book,
      timeOfDay: 'Morning',
    ),
    const HabitTemplate(
      title: 'Learning Session',
      description: '20 minutes of focused study',
      anchor: 'After lunch',
      category: 'Learning',
      icon: Icons.school,
      timeOfDay: 'Afternoon',
    ),
    const HabitTemplate(
      title: 'Podcast Learning',
      description: 'Listen to educational content',
      anchor: 'During commute',
      category: 'Learning',
      icon: Icons.podcasts,
      timeOfDay: 'Morning',
    ),
    const HabitTemplate(
      title: 'Write & Reflect',
      description: 'Write 3 things you learned',
      anchor: 'Before bed',
      category: 'Learning',
      icon: Icons.edit_note,
      timeOfDay: 'Night',
    ),
    const HabitTemplate(
      title: 'Skill Practice',
      description: '15 minutes practicing a skill',
      anchor: 'After work',
      category: 'Learning',
      icon: Icons.psychology,
      timeOfDay: 'Evening',
    ),

    // ═══ PRODUCTIVITY ═══
    const HabitTemplate(
      title: 'Morning Planning',
      description: 'Set top 3 priorities for today',
      anchor: 'After waking up',
      category: 'Productivity',
      icon: Icons.checklist,
      timeOfDay: 'Morning',
    ),
    const HabitTemplate(
      title: 'Deep Work Block',
      description: '90 minutes of focused work',
      anchor: 'After morning coffee',
      category: 'Productivity',
      icon: Icons.timer,
      timeOfDay: 'Morning',
    ),
    const HabitTemplate(
      title: 'Inbox Zero',
      description: 'Process all messages to zero',
      anchor: 'After lunch',
      category: 'Productivity',
      icon: Icons.email,
      timeOfDay: 'Afternoon',
    ),
    const HabitTemplate(
      title: 'Weekly Review',
      description: 'Review and plan your week',
      anchor: 'Sunday evening',
      category: 'Productivity',
      icon: Icons.calendar_month,
      timeOfDay: 'Evening',
      frequency: 'Weekly',
    ),
    const HabitTemplate(
      title: 'Tomorrow\'s Prep',
      description: 'Prepare for the next day',
      anchor: 'Before bed',
      category: 'Productivity',
      icon: Icons.today,
      timeOfDay: 'Night',
    ),

    // ═══ CREATIVITY ═══
    const HabitTemplate(
      title: 'Creative Morning',
      description: '15 minutes of creative work',
      anchor: 'After waking up',
      category: 'Creativity',
      icon: Icons.palette,
      timeOfDay: 'Morning',
    ),
    const HabitTemplate(
      title: 'Idea Capture',
      description: 'Write down 3 new ideas',
      anchor: 'After morning coffee',
      category: 'Creativity',
      icon: Icons.lightbulb,
      timeOfDay: 'Morning',
    ),
    const HabitTemplate(
      title: 'Ship Something',
      description: 'Complete and share one creation',
      anchor: 'Before bed',
      category: 'Creativity',
      icon: Icons.rocket_launch,
      timeOfDay: 'Night',
    ),
    const HabitTemplate(
      title: 'Inspiration Hunt',
      description: 'Seek out creative inspiration',
      anchor: 'After lunch',
      category: 'Creativity',
      icon: Icons.explore,
      timeOfDay: 'Afternoon',
    ),
    const HabitTemplate(
      title: 'Daily Sketch',
      description: 'Draw or design for 10 minutes',
      anchor: 'After work',
      category: 'Creativity',
      icon: Icons.brush,
      timeOfDay: 'Evening',
    ),
  ];

  List<String> get _categories => [
    'All',
    'Health',
    'Mindfulness',
    'Learning',
    'Productivity',
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
    final theme = ArchetypeTheme.forArchetype(widget.archetype);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    Icon(
                      Icons.auto_stories,
                      color: theme.primaryColor,
                      size: 24,
                    ),
                    const Gap(12),
                    Text(
                      'Habit Templates',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textMainDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Choose a template to auto-fill your habit details',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
              ),
              const Gap(16),

              // Category chips
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const Gap(8),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = category == _selectedCategory;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCategory = category);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.primaryColor
                              : AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? theme.primaryColor
                                : AppTheme.textSecondaryDark.withValues(
                                    alpha: 0.2,
                                  ),
                          ),
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
              const Gap(16),

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
                      accentColor: theme.primaryColor,
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

/// List tile for bottom sheet templates
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
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.textSecondaryDark.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(template.icon, color: accentColor, size: 24),
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
                  const Gap(6),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.link,
                        label: template.anchor,
                        color: accentColor,
                      ),
                      const Gap(8),
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
            Icon(Icons.add_circle_outline, color: accentColor, size: 24),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const Gap(4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
