import 'package:emerge_app/core/services/notification_templates.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/data/repositories/habit_notification_repository_provider.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/habits/presentation/widgets/habit_template_picker.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/habit_timeline_section.dart';
import 'package:emerge_app/features/tutorial/presentation/providers/tutorial_provider.dart';
import 'package:emerge_app/features/tutorial/presentation/widgets/tutorial_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

/// Redesigned Create Habit Dialog with Stitch-inspired cosmic glassmorphism
class AdvancedCreateHabitDialog extends ConsumerStatefulWidget {
  const AdvancedCreateHabitDialog({super.key});

  @override
  ConsumerState<AdvancedCreateHabitDialog> createState() =>
      _AdvancedCreateHabitDialogState();
}

class _AdvancedCreateHabitDialogState
    extends ConsumerState<AdvancedCreateHabitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();

  final GlobalKey _templatesKey = GlobalKey();
  final GlobalKey _nameInputKey = GlobalKey();
  final GlobalKey _frequencyKey = GlobalKey();
  final GlobalKey _timeLocationKey = GlobalKey();
  final GlobalKey _attributeKey = GlobalKey();
  final GlobalKey _createButtonKey = GlobalKey();

  // New state variables for advanced features
  bool _isAdvancedExpanded = false;
  String _emoji = '🔥';
  String? _twoMinuteVersion;
  HabitDifficulty _difficulty = HabitDifficulty.medium;
  int _timerDuration = 2; // Default 2 minutes

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
    // Add delay to ensure dialog has fully settled and animations are complete
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final tutorialNotifier = ref.read(tutorialProvider.notifier);
        final tutorialState = ref.watch(tutorialProvider);
        // Re-enable auto-show when entering this screen (for one-time show per visit)
        tutorialNotifier.enableTutorialAutoShow();

        // Only show tutorial if not completed AND tutorials are enabled AND auto-show is active
        if (!tutorialState.isCompleted(TutorialStep.createHabit) &&
            tutorialNotifier.shouldShowTutorial()) {
          _showTutorial();
        }
      });
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
    final userProfile = ref.read(userStatsStreamProvider).value;
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

        // Auto-select time of day based on the time picked
        final hour = picked.hour;
        if (hour >= 5 && hour < 12) {
          // 5AM-12PM: After you wake up
          _timeOfDay = TimeOfDayPreference.morning;
        } else if (hour >= 12 && hour < 15) {
          // 12PM-3PM: During lunch
          _timeOfDay = TimeOfDayPreference.afternoon;
        } else if (hour >= 15 && hour < 21) {
          // 3PM-8PM: After work
          _timeOfDay = TimeOfDayPreference.evening;
        } else {
          // 9PM-5AM: Before bed
          _timeOfDay = TimeOfDayPreference.anytime;
        }

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
        difficulty: _difficulty,
        currentStreak: 1,
        twoMinuteVersion: _twoMinuteVersion,
        reward: 'Complete and enjoy your progress!', // Default reward
        timerDurationMinutes: _timerDuration,
        customRules: const [],
        imageUrl: _emoji, // Using imageUrl to store emoji for now
      );

      try {
        await ref.read(createHabitProvider(newHabit).future);

        AppLogger.i(
          'Successfully created habit from Advanced Create: ${newHabit.id}',
        );

        // Schedule notifications for the new habit
        final userProfile = ref.read(userStatsStreamProvider).value;
        if (userProfile != null) {
          try {
            await ref
                .read(notificationRepositoryProvider)
                .scheduleHabitNotifications(newHabit, userProfile.archetype);
            AppLogger.i(
              'Successfully scheduled notifications for habit: ${newHabit.id}',
            );
          } catch (notificationError, notificationStack) {
            // Log notification error but don't fail the habit creation
            AppLogger.e(
              'Failed to schedule notifications for habit: ${newHabit.id}',
              notificationError,
              notificationStack,
            );
          }
        }

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
      _titleController.text = template.description; // Use action as the title
      _emoji = template.emoji; // Set emoji from template
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
    final userProfile = ref.watch(userStatsStreamProvider).value;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMainDialog(context, userProfile, habitsAsync),
                  const SizedBox(height: 24),
                  _buildForgeButton(context),
                ],
              ),
            ),
          ),
          // Close button at top right of the box
          Positioned(
            top: -12,
            right: -12,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getAttributeColor(
                      _attribute,
                    ).withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getAttributeColor(
                        _attribute,
                      ).withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainDialog(
    BuildContext context,
    userProfile,
    AsyncValue<List<Habit>> habitsAsync,
  ) {
    final primaryColor = _getAttributeColor(_attribute);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF1A1A2E), const Color(0xFF0F0F1A)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildIdentitySection(context),
          const SizedBox(height: 20),
          _buildCoreSettings(context),
          const SizedBox(height: 20),
          _buildTemplates(userProfile),
          const SizedBox(height: 20),
          _buildAdvancedToggle(context, habitsAsync),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ICON',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showEmojiPicker,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getAttributeColor(
                        _attribute,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getAttributeColor(
                          _attribute,
                        ).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(_emoji, style: const TextStyle(fontSize: 32)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Habit Title Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HABIT TITLE',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    child: TextFormField(
                      key: _nameInputKey,
                      controller: _titleController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Morning Meditation',
                        hintStyle: TextStyle(
                          color: Colors.white24,
                          fontSize: 18,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Badges Row
        Row(
          children: [
            GestureDetector(
              onTap: () => _showAttributePicker(),
              child: _buildBadge(
                _attribute.name.toUpperCase(),
                _getAttributeColor(_attribute),
                icon: _getAttributeIcon(_attribute),
                key: _attributeKey,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _showFrequencyPicker(),
              child: _buildBadge(
                _frequency.name.toUpperCase(),
                EmergeColors.teal,
                icon: Icons.calendar_today,
                key: _frequencyKey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color, {IconData? icon, Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            color: color.withValues(alpha: 0.5),
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection(BuildContext context) {
    final attributeColor = _getAttributeColor(_attribute);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Identity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildEditButton(),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Defining your character path...',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          ListenableBuilder(
            listenable: _titleController,
            builder: (context, _) {
              final habitAction = _titleController.text.isEmpty
                  ? 'prioritizes mental clarity'
                  : _titleController.text.toLowerCase();
              return RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: '"I am the type of person who '),
                    TextSpan(
                      text: '$habitAction...',
                      style: TextStyle(
                        color: attributeColor,
                        decoration: TextDecoration.underline,
                        decorationColor: attributeColor.withValues(alpha: 0.5),
                        decorationThickness: 2,
                      ),
                    ),
                    const TextSpan(text: '"'),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getAttributeColor(_attribute).withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        'EDIT',
        style: TextStyle(
          color: _getAttributeColor(_attribute),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildCoreSettings(BuildContext context) {
    return Row(
      key: _timeLocationKey,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TRIGGER TIME',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              _buildCompactInput(
                icon: Icons.access_time_filled,
                label:
                    _specificTime?.format(context) ??
                    '07:00 AM', // Default to 7:00 AM if null for UI preview
                onTap: () => _selectTime(context),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SANCTUARY',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: _getAttributeColor(_attribute),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _locationController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Living Room',
                          hintStyle: TextStyle(
                            color: Colors.white12,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactInput({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _getAttributeColor(_attribute), size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplates(dynamic userProfile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUGGESTED ARCHETYPES',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        HabitTemplateCarousel(
          key: _templatesKey,
          archetype: userProfile?.archetype ?? UserArchetype.none,
          onTemplateSelected: _applyTemplate,
        ),
      ],
    );
  }

  Widget _buildAdvancedToggle(
    BuildContext context,
    AsyncValue<List<Habit>> habitsAsync,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: () =>
              setState(() => _isAdvancedExpanded = !_isAdvancedExpanded),
          child: Row(
            children: [
              Text(
                'ADVANCED',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Icon(
                _isAdvancedExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.white38,
                size: 16,
              ),
            ],
          ),
        ),
        if (_isAdvancedExpanded) ...[
          const SizedBox(height: 16),
          _buildAdvancedSettings(habitsAsync),
        ],
      ],
    );
  }

  Widget _buildAdvancedSettings(AsyncValue<List<Habit>> habitsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Two-Minute Version
        const Text(
          'TWO-MINUTE VERSION (ENTRY RITUAL)',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildAdvancedTextField(
          initialValue: _twoMinuteVersion,
          hint: 'e.g., Put on running shoes',
          onChanged: (v) => _twoMinuteVersion = v,
        ),
        const SizedBox(height: 16),

        // Anchor Time (Time of Day Slot)
        const Text(
          'TIME OF THE DAY (ANCHOR)',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildAnchorTimeDropdown(),
        const SizedBox(height: 16),

        // Difficulty & Frequency (Using simpler selects for now)
        _buildDifficultyPicker(),
        const SizedBox(height: 16),
        // Timer Duration
        const Text(
          'TIMER DURATION (MINUTES)',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildTimerPicker(),
      ],
    );
  }

  Widget _buildAdvancedTextField({
    String? initialValue,
    required String hint,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white12, fontSize: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  void _showAttributePicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: _getAttributeColor(_attribute).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'CHOOSE ATTRIBUTE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: HabitAttribute.values.map((attr) {
                final isSelected = _attribute == attr;
                return GestureDetector(
                  onTap: () {
                    setState(() => _attribute = attr);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getAttributeColor(attr).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? _getAttributeColor(attr)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getAttributeIcon(attr),
                          size: 16,
                          color: isSelected
                              ? _getAttributeColor(attr)
                              : Colors.white54,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          attr.name.toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showFrequencyPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'CHOOSE FREQUENCY',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: HabitFrequency.values.map((freq) {
                final isSelected = _frequency == freq;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _frequency = freq);
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getAttributeColor(
                                _attribute,
                              ).withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? _getAttributeColor(_attribute)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            freq == HabitFrequency.daily
                                ? Icons.calendar_today
                                : Icons.calendar_view_week,
                            color: isSelected ? Colors.white : Colors.white38,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            freq.name.toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAnchorTimeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TimeOfDayPreference>(
          value: _timeOfDay,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1A2E),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: [
            const DropdownMenuItem(
              value: TimeOfDayPreference.morning,
              child: Text('AFTER YOU WAKE UP (5AM-12PM)'),
            ),
            const DropdownMenuItem(
              value: TimeOfDayPreference.afternoon,
              child: Text('DURING LUNCH (12PM-3PM)'),
            ),
            const DropdownMenuItem(
              value: TimeOfDayPreference.evening,
              child: Text('AFTER WORK (3PM-8PM)'),
            ),
            const DropdownMenuItem(
              value: TimeOfDayPreference.anytime,
              child: Text('BEFORE BED (9PM-5AM)'),
            ),
          ],
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _timeOfDay = v;
                _updateIdentityStatement();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildDifficultyPicker() {
    return Row(
      children: HabitDifficulty.values.map((d) {
        final isSelected = _difficulty == d;
        final displayName = d.name[0].toUpperCase() + d.name.substring(1);
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _difficulty = d),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? _getAttributeColor(_attribute)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  displayName,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildForgeButton(BuildContext context) {
    return ElevatedButton.icon(
      key: _createButtonKey,
      onPressed: _saveHabit,
      icon: const Icon(Icons.bolt, color: Colors.white),
      label: const Text(
        'FORGE HABIT',
        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _getAttributeColor(_attribute),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 12,
        shadowColor: _getAttributeColor(_attribute).withValues(alpha: 0.5),
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 6,
          children:
              [
                    '🔥',
                    '💧',
                    '🌿',
                    '📖',
                    '💪',
                    '🧠',
                    '✨',
                    '🎯',
                    '🏃',
                    '💤',
                    '🍎',
                    '🧘',
                    '🎸',
                    '🎨',
                    '💼',
                    '🏡',
                    '🔋',
                    '🚀',
                  ]
                  .map(
                    (e) => Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _emoji = e);
                          Navigator.pop(context);
                        },
                        child: Text(e, style: const TextStyle(fontSize: 32)),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Widget _buildTimerPicker() {
    return Row(
      children: [1, 2, 5, 10, 15, 20].map((m) {
        final isSelected = _timerDuration == m;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _timerDuration = m),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? _getAttributeColor(_attribute)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${m}M',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getAttributeColor(HabitAttribute attr) {
    return attributeColor(attr);
  }

  IconData _getAttributeIcon(HabitAttribute attr) {
    switch (attr) {
      case HabitAttribute.vitality:
        return Icons.favorite;
      case HabitAttribute.intellect:
        return Icons.menu_book;
      case HabitAttribute.creativity:
        return Icons.palette;
      case HabitAttribute.focus:
        return Icons.center_focus_strong;
      case HabitAttribute.strength:
        return Icons.fitness_center;
      case HabitAttribute.spirit:
        return Icons.auto_awesome;
    }
  }
}
