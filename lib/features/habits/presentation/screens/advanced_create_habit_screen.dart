import 'package:emerge_app/core/services/notification_templates.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/habits/presentation/widgets/habit_template_picker.dart';
import 'package:emerge_app/features/habits/presentation/widgets/habit_form_widgets.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/habit_timeline_section.dart';
import 'package:emerge_app/features/tutorial/presentation/providers/tutorial_provider.dart';
import 'package:emerge_app/features/tutorial/presentation/widgets/tutorial_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

/// Redesigned Create Habit Screen with Stitch-inspired cosmic glassmorphism
class AdvancedCreateHabitScreen extends ConsumerStatefulWidget {
  const AdvancedCreateHabitScreen({super.key});

  @override
  ConsumerState<AdvancedCreateHabitScreen> createState() =>
      _AdvancedCreateHabitScreenState();
}

class _AdvancedCreateHabitScreenState
    extends ConsumerState<AdvancedCreateHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();

  // Tutorial keys
  final GlobalKey _identityPreviewKey = GlobalKey();
  final GlobalKey _templatesKey = GlobalKey();
  final GlobalKey _nameInputKey = GlobalKey();
  final GlobalKey _frequencyKey = GlobalKey();
  final GlobalKey _timeLocationKey = GlobalKey();
  final GlobalKey _attributeKey = GlobalKey();
  final GlobalKey _createButtonKey = GlobalKey();

  HabitFrequency _frequency = HabitFrequency.daily;
  final List<int> _specificDays = [];
  TimeOfDayPreference _timeOfDay = TimeOfDayPreference.morning;
  TimeOfDay? _specificTime;
  String? _anchorHabitId;
  HabitAttribute _attribute = HabitAttribute.vitality;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_updateIdentityStatement);
    _locationController.addListener(_updateIdentityStatement);
    _checkTutorial();
  }

  void _checkTutorial() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tutorialState = ref.read(tutorialProvider);
      if (!tutorialState.isCompleted(TutorialStep.createHabit)) {
        _showTutorial();
      }
    });
  }

  void _showTutorial() {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => TutorialOverlay(
        steps: [
          const TutorialStepInfo(
            title: 'Craft Your Identity',
            description:
                'Every habit is a vote for the person you want to become. This statement reinforces your identity.',
          ),
          TutorialStepInfo(
            title: 'Quick Start Templates',
            description:
                'Swipe through these proven habit templates based on your archetype. Tap one to fill in the form instantly.',
            targetKey: _templatesKey,
            alignment: Alignment.center,
          ),
          TutorialStepInfo(
            title: 'Name Your Habit',
            description:
                'Choose a clear, specific name. "Read 10 pages" is better than "Read more."',
            targetKey: _nameInputKey,
          ),
          TutorialStepInfo(
            title: 'Set Your Frequency',
            description:
                'How often will you do this? Daily habits build momentum faster than weekly ones.',
            targetKey: _frequencyKey,
          ),
          TutorialStepInfo(
            title: 'Time & Location',
            description:
                'Attach your habit to a specific time and place. This uses implementation intentions to trigger action.',
            targetKey: _timeLocationKey,
          ),
          TutorialStepInfo(
            title: 'Choose Your Attribute',
            description:
                'Which aspect of yourself does this habit strengthen? Each habit levels up different parts of your identity.',
            targetKey: _attributeKey,
          ),
          TutorialStepInfo(
            title: 'Make It Official',
            description:
                'When you\'re ready, tap CREATE to forge your new identity vote. You can always edit it later.',
            targetKey: _createButtonKey,
          ),
        ],
        onCompleted: () {
          ref
              .read(tutorialProvider.notifier)
              .completeStep(TutorialStep.createHabit);
          entry.remove();
        },
      ),
    );
    Overlay.of(context).insert(entry);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();

    super.dispose();
  }

  void _updateIdentityStatement() {
    // This now serves mainly for non-text changes (attributes, etc)
    setState(() {});
  }

  Future<void> _selectTime(BuildContext context) async {
    final userProfile = ref.read(userStatsStreamProvider).valueOrNull;
    final archetype = userProfile?.archetype ?? UserArchetype.none;
    final defaultHour = NotificationTemplates.getDefaultHour(archetype);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _specificTime ?? TimeOfDay(hour: defaultHour, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: EmergeColors.teal,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceDark,
              onSurface: AppTheme.textMainDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _specificTime) {
      setState(() {
        _specificTime = picked;
        _updateIdentityStatement();
      });
    }
  }

  Future<void> _saveHabit() async {
    if (_formKey.currentState!.validate()) {
      // Validate required scheduled time
      if (_specificTime == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please set a scheduled time for this habit'),
              backgroundColor: Colors.orange[700],
            ),
          );
        }
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User not logged in')));
        }
        return;
      }

      final newHabit = Habit(
        id: const Uuid().v4(),
        userId: user.uid,
        title: _titleController.text,
        frequency: _frequency,
        specificDays: _specificDays,
        timeOfDayPreference: _timeOfDay,
        reminderTime: _specificTime,
        location: _locationController.text.isNotEmpty
            ? _locationController.text
            : null,
        anchorHabitId: _anchorHabitId,
        attribute: _attribute,
        createdAt: DateTime.now(),
        difficulty: HabitDifficulty.medium,
        twoMinuteVersion: null,
        reward: 'Complete and enjoy your progress!', // Default reward
        timerDurationMinutes: 2,
        customRules: const [],
      );

      try {
        await ref.read(createHabitProvider(newHabit).future);

        AppLogger.i(
          'Successfully created habit from Advanced Create: ${newHabit.id}',
        );

        if (context.mounted) {
          final contextRef = context;
          if (contextRef.mounted) {
            ScaffoldMessenger.of(contextRef).showSnackBar(
              const SnackBar(content: Text('Habit created successfully!')),
            );
          }
          contextRef.pop();
        }
      } catch (e, s) {
        AppLogger.e('Error creating habit from Advanced Create', e, s);
        if (context.mounted) {
          final contextRef = context;
          ScaffoldMessenger.of(
            contextRef,
          ).showSnackBar(SnackBar(content: Text('Error creating habit: $e')));
        }
      }
    }
  }

  void _applyTemplate(HabitTemplate template) {
    HapticFeedback.mediumImpact();
    setState(() {
      _titleController.text = template.title;
      switch (template.timeOfDay.toLowerCase()) {
        case 'morning':
          _timeOfDay = TimeOfDayPreference.morning;
          break;
        case 'afternoon':
          _timeOfDay = TimeOfDayPreference.afternoon;
          break;
        case 'evening':
          _timeOfDay = TimeOfDayPreference.evening;
          break;
        case 'night':
          _timeOfDay = TimeOfDayPreference.evening;
          break;
        default:
          _timeOfDay = TimeOfDayPreference.anytime;
      }
      if (template.frequency.toLowerCase() == 'weekly') {
        _frequency = HabitFrequency.weekly;
      } else {
        _frequency = HabitFrequency.daily;
      }
      _attribute = template.attribute;
      _updateIdentityStatement();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Applied "${template.title}" template'),
          duration: const Duration(seconds: 2),
          backgroundColor: EmergeColors.teal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final userProfile = ref.watch(userStatsStreamProvider).valueOrNull;

    return Scaffold(
      backgroundColor: EmergeColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.cosmicGradient),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  floating: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.close, color: AppTheme.textMainDark),
                    ),
                    onPressed: () => context.pop(),
                  ),
                  title: Text(
                    'NEW HABIT',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textMainDark,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.person_outline,
                        color: EmergeColors.teal,
                      ),
                      onPressed: () => context.push('/profile'),
                    ),
                  ],
                ),

                // Identity Statement Preview Card (Glassmorphism)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: RepaintBoundary(
                      child: IdentityStatementPreview(
                        key: _identityPreviewKey,
                        titleController: _titleController,
                        locationController: _locationController,
                        specificTime: _specificTime,
                        timeOfDay: _timeOfDay,
                        attributeName: _attribute.name,
                      ),
                    ),
                  ),
                ),

                // Quick Suggestions Carousel
                SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: HabitTemplateCarousel(
                      key: _templatesKey,
                      archetype: userProfile?.archetype ?? UserArchetype.none,
                      onTemplateSelected: _applyTemplate,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Habit Name Input
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RepaintBoundary(
                      child: GlassmorphismCard(
                        key: _nameInputKey,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextFormField(
                            controller: _titleController,
                            style: TextStyle(color: AppTheme.textMainDark),
                            decoration: InputDecoration(
                              labelText: 'Habit Name',
                              labelStyle: TextStyle(
                                color: AppTheme.textSecondaryDark,
                              ),
                              hintText: 'e.g., Read 10 pages',
                              hintStyle: TextStyle(
                                color: AppTheme.textSecondaryDark.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: EmergeColors.teal.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: EmergeColors.teal.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: EmergeColors.teal,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Please enter a habit name'
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Frequency Selector
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RepaintBoundary(
                      child: GlassmorphismCard(
                        key: _frequencyKey,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(title: 'Frequency'),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  FrequencyChip(
                                    label: 'Daily',
                                    isSelected:
                                        _frequency == HabitFrequency.daily,
                                    onTap: () => setState(
                                      () => _frequency = HabitFrequency.daily,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FrequencyChip(
                                    label: 'Weekly',
                                    isSelected:
                                        _frequency == HabitFrequency.weekly,
                                    onTap: () => setState(
                                      () => _frequency = HabitFrequency.weekly,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FrequencyChip(
                                    label: 'Specific',
                                    isSelected:
                                        _frequency ==
                                        HabitFrequency.specificDays,
                                    onTap: () => setState(
                                      () => _frequency =
                                          HabitFrequency.specificDays,
                                    ),
                                  ),
                                ],
                              ),
                              if (_frequency ==
                                  HabitFrequency.specificDays) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  children: List.generate(7, (index) {
                                    final day = index + 1;
                                    final isSelected = _specificDays.contains(
                                      day,
                                    );
                                    return GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          if (isSelected) {
                                            _specificDays.remove(day);
                                          } else {
                                            _specificDays.add(day);
                                          }
                                        });
                                      },
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? EmergeColors.teal
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? EmergeColors.teal
                                                : AppTheme.textSecondaryDark
                                                      .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            [
                                              'M',
                                              'T',
                                              'W',
                                              'T',
                                              'F',
                                              'S',
                                              'S',
                                            ][index],
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppTheme.textSecondaryDark,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Time & Location
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RepaintBoundary(
                      child: GlassmorphismCard(
                        key: _timeLocationKey,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(title: 'Time & Location'),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _selectTime(context),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.05,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: EmergeColors.teal.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              color: EmergeColors.teal,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    _specificTime != null
                                                        ? _specificTime!.format(
                                                            context,
                                                          )
                                                        : 'Set Time',
                                                    style: TextStyle(
                                                      color:
                                                          AppTheme.textMainDark,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  if (_specificTime == null)
                                                    Builder(
                                                      builder: (context) {
                                                        final userProfile = ref
                                                                .watch(
                                                          userStatsStreamProvider,
                                                        )
                                                                .valueOrNull;
                                                        final archetype =
                                                            userProfile?.archetype ??
                                                                UserArchetype
                                                                    .none;
                                                        final defaultHour =
                                                            NotificationTemplates
                                                                .getDefaultHour(
                                                          archetype,
                                                        );
                                                        return Text(
                                                          'Archetype default: $defaultHour:00 ${defaultHour < 12 ? "AM" : "PM"}',
                                                          style: TextStyle(
                                                            color: AppTheme
                                                                .textSecondaryDark,
                                                            fontSize: 11,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.05,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: EmergeColors.teal.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: TextFormField(
                                        controller: _locationController,
                                        style: TextStyle(
                                          color: AppTheme.textMainDark,
                                        ),
                                        decoration: InputDecoration(
                                          prefixIcon: Icon(
                                            Icons.place,
                                            color: EmergeColors.teal,
                                            size: 20,
                                          ),
                                          hintText: 'Location',
                                          hintStyle: TextStyle(
                                            color: AppTheme.textSecondaryDark
                                                .withValues(alpha: 0.5),
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 14,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: TimeOfDayPreference.values.map((
                                  time,
                                ) {
                                  final isSelected =
                                      _timeOfDay == time &&
                                      _specificTime == null;
                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _timeOfDay = time;
                                        _specificTime = null;
                                        _updateIdentityStatement();
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? EmergeColors.teal
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected
                                              ? EmergeColors.teal
                                              : AppTheme.textSecondaryDark
                                                    .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        time.name.toUpperCase(),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : AppTheme.textSecondaryDark,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Identity Attribute
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GlassmorphismCard(
                      key: _attributeKey,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(title: 'Identity Attribute'),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: HabitAttribute.values.map((attr) {
                                final isSelected = _attribute == attr;
                                final attrColor = attributeColor(attr);
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _attribute = attr;
                                      _updateIdentityStatement();
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? LinearGradient(
                                              colors: [
                                                attrColor,
                                                attrColor.withValues(
                                                  alpha: 0.7,
                                                ),
                                              ],
                                            )
                                          : null,
                                      color: isSelected
                                          ? null
                                          : attrColor.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? attrColor
                                            : attrColor.withValues(alpha: 0.3),
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: attrColor.withValues(
                                                  alpha: 0.3,
                                                ),
                                                blurRadius: 8,
                                                spreadRadius: -2,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      attr.name.toUpperCase(),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : attrColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Anchor Habit (Optional)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: habitsAsync.when(
                      data: (habits) {
                        if (habits.isEmpty) return const SizedBox.shrink();
                        return GlassmorphismCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionHeader(title: 'Anchor Habit (Optional)'),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: EmergeColors.teal.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _anchorHabitId,
                                    dropdownColor: AppTheme.surfaceDark,
                                    style: TextStyle(
                                      color: AppTheme.textMainDark,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Select an existing habit',
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: null,
                                        child: Text(
                                          'None',
                                          style: TextStyle(
                                            color: AppTheme.textSecondaryDark,
                                          ),
                                        ),
                                      ),
                                      ...habits.map(
                                        (habit) => DropdownMenuItem(
                                          value: habit.id,
                                          child: Text(habit.title),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _anchorHabitId = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => const SizedBox.shrink(),
                    ),
                  ),
                ),

                // Create Button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: GestureDetector(
                      key: _createButtonKey,
                      onTap: _saveHabit,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              EmergeColors.teal,
                              EmergeColors.teal.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: EmergeColors.teal.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'CREATE HABIT',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                          ),
                        ),
                      ),
                    ),
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

/// Specialized preview widget that avoids rebuilding the main screen on every keystroke
class IdentityStatementPreview extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController locationController;
  final TimeOfDay? specificTime;
  final TimeOfDayPreference timeOfDay;
  final String attributeName;

  const IdentityStatementPreview({
    super.key,
    required this.titleController,
    required this.locationController,
    required this.specificTime,
    required this.timeOfDay,
    required this.attributeName,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.auto_awesome, color: EmergeColors.teal, size: 24),
            const SizedBox(height: 12),
            ListenableBuilder(
              listenable: Listenable.merge([
                titleController,
                locationController,
              ]),
              builder: (context, _) {
                final behavior = titleController.text.isEmpty
                    ? '...'
                    : titleController.text;
                String timeString = "";
                if (specificTime != null) {
                  timeString = " at ${specificTime!.format(context)}";
                } else {
                  timeString = " in the ${timeOfDay.name}";
                }
                final location = locationController.text.isEmpty
                    ? ""
                    : " in ${locationController.text}";

                return Text(
                  "I will $behavior$timeString$location to become more $attributeName.",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textMainDark,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
