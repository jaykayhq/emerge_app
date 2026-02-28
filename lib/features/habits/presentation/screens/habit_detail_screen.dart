import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:emerge_app/core/services/notification_service.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/habits/presentation/widgets/habit_form_widgets.dart';
import 'package:emerge_app/features/habits/presentation/widgets/habit_timer_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

/// Full screen habit detail view with editing capabilities
class HabitDetailScreen extends ConsumerStatefulWidget {
  final String habitId;

  const HabitDetailScreen({required this.habitId, super.key});

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  final _twoMinuteController = TextEditingController();
  final _rewardController = TextEditingController();
  final _customRulesController = TextEditingController();
  final _primingController = TextEditingController();

  // State variables for editing
  late int _timerDurationMinutes;
  late List<String> _customRules;
  late List<String> _environmentPriming;
  String? _anchorHabitId;
  bool _isInit = false;
  bool _hasChanges = false;

  @override
  void dispose() {
    _twoMinuteController.dispose();
    _rewardController.dispose();
    _customRulesController.dispose();
    _primingController.dispose();
    super.dispose();
  }

  void _initializeState(Habit habit) {
    if (_isInit) return;
    _twoMinuteController.text = habit.twoMinuteVersion ?? '';
    _rewardController.text = habit.reward;
    _timerDurationMinutes = habit.timerDurationMinutes;
    _customRules = List.from(habit.customRules);
    _environmentPriming = List.from(habit.environmentPriming);
    _anchorHabitId = habit.anchorHabitId;

    // Listeners to detect changes
    _twoMinuteController.addListener(_checkForChanges);
    _rewardController.addListener(_checkForChanges);
    _isInit = true;
  }

  void _checkForChanges() {
    // This is a simplified check. We could do a deep comparison with the original habit
    // but for now, we'll just enable the save button if *any* interaction happens
    // that implies a change, or better yet, compare values.
    // For simplicity in this iteration, I'll set hasChanges = true on any update.
    // However, to avoid enabling it initially, I won't auto-set it here.
    // I'll update it explicitly in specific setters.
    setState(() {
      _hasChanges = true;
    });
  }

  Future<void> _saveChanges(Habit originalHabit) async {
    final updatedHabit = originalHabit.copyWith(
      twoMinuteVersion: _twoMinuteController.text.trim(),
      reward: _rewardController.text.trim(),
      timerDurationMinutes: _timerDurationMinutes,
      customRules: _customRules,
      environmentPriming: _environmentPriming,
      anchorHabitId: _anchorHabitId,
    );

    try {
      await ref.read(habitRepositoryProvider).updateHabit(updatedHabit);
      if (mounted) {
        setState(() => _hasChanges = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Changes saved successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving changes: $e')));
      }
    }
  }

  void _addCustomRule() {
    final rule = _customRulesController.text.trim();
    if (rule.isNotEmpty) {
      setState(() {
        _customRules.add(rule);
        _customRulesController.clear();
        _hasChanges = true;
      });
    }
  }

  void _removeCustomRule(int index) {
    setState(() {
      _customRules.removeAt(index);
      _hasChanges = true;
    });
  }

  void _addPrimingRule() {
    final rule = _primingController.text.trim();
    if (rule.isNotEmpty) {
      setState(() {
        _environmentPriming.add(rule);
        _primingController.clear();
        _hasChanges = true;
      });
    }
  }

  void _removePrimingRule(int index) {
    setState(() {
      _environmentPriming.removeAt(index);
      _hasChanges = true;
    });
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 28),
                const Gap(12),
                Text(
                  'Delete Habit?',
                  style: TextStyle(
                    color: AppTheme.textMainDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'This will permanently delete this habit and all its history. This action cannot be undone.',
              style: TextStyle(color: AppTheme.textSecondaryDark),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.textSecondaryDark),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.white),
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: () {
                habitsAsync.whenData((habits) {
                  final habit = habits
                      .where((h) => h.id == widget.habitId)
                      .firstOrNull;
                  if (habit != null) {
                    _saveChanges(habit);
                  }
                });
              },
              icon: const Icon(Icons.save, color: EmergeColors.teal),
              label: Text(
                'Save',
                style: TextStyle(
                  color: EmergeColors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF1A1A2E), const Color(0xFF0F0F1A)],
          ),
        ),
        child: habitsAsync.when(
          data: (habits) {
            final habit = habits
                .where((h) => h.id == widget.habitId)
                .firstOrNull;
            if (habit == null) {
              return const Center(
                child: Text(
                  'Habit not found',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            _initializeState(habit);

            final now = DateTime.now();
            final lastCompleted = habit.lastCompletedDate;
            final isCompleted =
                lastCompleted != null &&
                lastCompleted.year == now.year &&
                lastCompleted.month == now.month &&
                lastCompleted.day == now.day;

            final neonColor = _getAttributeColor(habit.attribute);

            // Filter habits for anchor dropdown (exclude current habit)
            final availableAnchors = habits
                .where((h) => h.id != habit.id)
                .toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 100, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, habit, neonColor, isCompleted),
                  const Gap(32),

                  // Complete Button
                  _buildCompleteButton(
                    context,
                    ref,
                    habit,
                    neonColor,
                    isCompleted,
                  ),
                  const Gap(32),

                  // Two-Minute Rule Section
                  GlassmorphismCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(title: 'Two-Minute Rule'),
                        const Gap(16),
                        TextFormField(
                          controller: _twoMinuteController,
                          style: TextStyle(color: AppTheme.textMainDark),
                          onChanged: (_) => _checkForChanges(),
                          decoration: InputDecoration(
                            helperText: 'Make it easy (e.g., "Read 1 page")',
                            helperStyle: TextStyle(
                              color: AppTheme.textSecondaryDark.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.timer_outlined,
                              color: EmergeColors.teal,
                              size: 20,
                            ),
                            hintText: 'Enter 2-minute version',
                            hintStyle: TextStyle(
                              color: AppTheme.textSecondaryDark.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            border: InputBorder.none,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.textSecondaryDark.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: EmergeColors.teal),
                            ),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.2),
                          ),
                        ),
                        const Gap(16),
                        Text(
                          'Timer Duration:',
                          style: TextStyle(
                            color: AppTheme.textSecondaryDark,
                            fontSize: 13,
                          ),
                        ),
                        const Gap(12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [1, 2, 5, 10].map((mins) {
                            final isSelected = _timerDurationMinutes == mins;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _timerDurationMinutes = mins;
                                  _hasChanges = true;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? EmergeColors.teal
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? EmergeColors.teal
                                        : AppTheme.textSecondaryDark.withValues(
                                            alpha: 0.3,
                                          ),
                                  ),
                                ),
                                child: Text(
                                  '${mins}m',
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
                        const Gap(24),
                        // Start Timer Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => TwoMinuteTimerDialog(
                                  habitTitle:
                                      _twoMinuteController.text.isNotEmpty
                                      ? _twoMinuteController.text
                                      : habit.title,
                                  neonColor: neonColor,
                                  durationMinutes: _timerDurationMinutes,
                                  onComplete: () {
                                    ref.read(completeHabitProvider(habit.id));
                                    // Optionally show a success effect or pop
                                    Navigator.of(context).pop();
                                  },
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: Text(
                              'Start $_timerDurationMinutes-Min Timer',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: neonColor,
                              side: BorderSide(
                                color: neonColor.withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Gap(24),

                  // Temptation Bundling Section
                  GlassmorphismCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(title: 'Temptation Bundling'),
                        const Gap(16),
                        TextFormField(
                          controller: _rewardController,
                          style: TextStyle(color: AppTheme.textMainDark),
                          onChanged: (_) => _checkForChanges(),
                          decoration: InputDecoration(
                            helperText: 'Reward yourself after completion',
                            helperStyle: TextStyle(
                              color: AppTheme.textSecondaryDark.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.card_giftcard,
                              color: EmergeColors.teal,
                              size: 20,
                            ),
                            hintText: 'e.g., Watch 1 episode',
                            hintStyle: TextStyle(
                              color: AppTheme.textSecondaryDark.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            border: InputBorder.none,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.textSecondaryDark.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: EmergeColors.teal),
                            ),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.2),
                          ),
                        ),
                        const Gap(12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              [
                                'Watch 1 episode',
                                'Check social media',
                                'Coffee/Tea',
                                'Podcast',
                              ].map((suggestion) {
                                return ActionChip(
                                  label: Text(suggestion),
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.05,
                                  ),
                                  side: BorderSide.none,
                                  labelStyle: TextStyle(
                                    color: AppTheme.textSecondaryDark,
                                    fontSize: 12,
                                  ),
                                  onPressed: () {
                                    _rewardController.text = suggestion;
                                    _checkForChanges();
                                  },
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const Gap(24),

                  // Integrations Section
                  GlassmorphismCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: 'Data Integration (Auto-Complete)',
                        ),
                        const Gap(16),
                        Text(
                          'Automatically track progress using device data.',
                          style: TextStyle(
                            color: AppTheme.textSecondaryDark,
                            fontSize: 13,
                          ),
                        ),
                        const Gap(16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<HabitIntegrationType>(
                              value: habit.integrationType,
                              isExpanded: true,
                              dropdownColor: AppTheme.surfaceDark,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: EmergeColors.teal,
                              ),
                              style: TextStyle(
                                color: AppTheme.textMainDark,
                                fontSize: 14,
                              ),
                              onChanged: (HabitIntegrationType? newValue) {
                                if (newValue != null) {
                                  _hasChanges = true;
                                  ref
                                      .read(habitsProvider.notifier)
                                      .updateHabit(
                                        habit.copyWith(
                                          integrationType: newValue,
                                        ),
                                      );
                                  setState(() {});
                                }
                              },
                              items: const [
                                DropdownMenuItem(
                                  value: HabitIntegrationType.none,
                                  child: Text('No Integration (Manual)'),
                                ),
                                DropdownMenuItem(
                                  value: HabitIntegrationType.healthSteps,
                                  child: Text(
                                    'Google Fit / Health Connect (Steps)',
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: HabitIntegrationType.screenTimeLimit,
                                  child: Text('Android Screen Time (Limit)'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (habit.integrationType !=
                            HabitIntegrationType.none) ...[
                          const Gap(16),
                          TextFormField(
                            initialValue:
                                habit.integrationTarget?.toString() ?? '',
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppTheme.textMainDark),
                            onChanged: (val) {
                              _hasChanges = true;
                              ref
                                  .read(habitsProvider.notifier)
                                  .updateHabit(
                                    habit.copyWith(
                                      integrationTarget: int.tryParse(val),
                                    ),
                                  );
                            },
                            decoration: InputDecoration(
                              helperText:
                                  habit.integrationType ==
                                      HabitIntegrationType.healthSteps
                                  ? 'Daily Step Goal (e.g. 10000)'
                                  : 'Daily Screen Time Limit in Minutes (e.g. 120)',
                              helperStyle: TextStyle(
                                color: AppTheme.textSecondaryDark.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              prefixIcon: Icon(
                                habit.integrationType ==
                                        HabitIntegrationType.healthSteps
                                    ? Icons.directions_walk
                                    : Icons.timer,
                                color: EmergeColors.teal,
                                size: 20,
                              ),
                              hintText: 'Enter target number',
                              border: InputBorder.none,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppTheme.textSecondaryDark.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: EmergeColors.teal,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.2),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const Gap(24),

                  // Custom Rules Section
                  GlassmorphismCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(title: 'Custom Rules'),
                        const Gap(16),
                        TextFormField(
                          controller: _customRulesController,
                          style: TextStyle(color: AppTheme.textMainDark),
                          onFieldSubmitted: (_) => _addCustomRule(),
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              color: EmergeColors.teal,
                              onPressed: _addCustomRule,
                            ),
                            hintText: 'Add a new rule...',
                            hintStyle: TextStyle(
                              color: AppTheme.textSecondaryDark.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            border: InputBorder.none,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.textSecondaryDark.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: EmergeColors.teal),
                            ),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.2),
                          ),
                        ),
                        const Gap(16),
                        if (_customRules.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'No custom rules yet.\nAdd rules to define success.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.textSecondaryDark.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _customRules.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.rule,
                                      size: 16,
                                      color: EmergeColors.teal,
                                    ),
                                    const Gap(12),
                                    Expanded(
                                      child: Text(
                                        _customRules[index],
                                        style: TextStyle(
                                          color: AppTheme.textMainDark,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: AppTheme.textSecondaryDark,
                                      ),
                                      onPressed: () => _removeCustomRule(index),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  const Gap(24),

                  // Environment Priming Section
                  GlassmorphismCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(title: 'Environment Priming'),
                        const Gap(16),
                        Text(
                          'Prepare your environment the night before to reduce friction.',
                          style: TextStyle(
                            color: AppTheme.textSecondaryDark,
                            fontSize: 13,
                          ),
                        ),
                        const Gap(16),
                        TextFormField(
                          controller: _primingController,
                          style: TextStyle(color: AppTheme.textMainDark),
                          onFieldSubmitted: (_) => _addPrimingRule(),
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              color: EmergeColors.teal,
                              onPressed: _addPrimingRule,
                            ),
                            hintText: 'e.g., Lay out workout clothes...',
                            hintStyle: TextStyle(
                              color: AppTheme.textSecondaryDark.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            border: InputBorder.none,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.textSecondaryDark.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: EmergeColors.teal),
                            ),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.2),
                          ),
                        ),
                        const Gap(16),
                        if (_environmentPriming.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'No environment priming tasks.\nAdd setup steps to make starting easier.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.textSecondaryDark.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _environmentPriming.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_box_outline_blank,
                                      size: 16,
                                      color: EmergeColors.teal,
                                    ),
                                    const Gap(12),
                                    Expanded(
                                      child: Text(
                                        _environmentPriming[index],
                                        style: TextStyle(
                                          color: AppTheme.textMainDark,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: AppTheme.textSecondaryDark,
                                      ),
                                      onPressed: () =>
                                          _removePrimingRule(index),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  const Gap(24),

                  // Anchor Habit Section (Optional)
                  if (availableAnchors.isNotEmpty)
                    GlassmorphismCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(title: 'Anchor Habit (Optional)'),
                          const Gap(16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.textSecondaryDark.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              initialValue: _anchorHabitId,
                              dropdownColor: AppTheme.surfaceDark,
                              style: TextStyle(color: AppTheme.textMainDark),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Select a habit to anchor to',
                                hintStyle: TextStyle(color: Colors.white54),
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
                                ...availableAnchors.map(
                                  (h) => DropdownMenuItem(
                                    value: h.id,
                                    child: Text(h.title),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _anchorHabitId = value;
                                  _hasChanges = true;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Gap(32),

                  // Delete Habit Section
                  GlassmorphismCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.delete_forever,
                          color: Colors.red.withValues(alpha: 0.7),
                          size: 36,
                        ),
                        const Gap(12),
                        Text(
                          'Delete Habit',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          'Permanently delete this habit and all its history.',
                          style: TextStyle(
                            color: AppTheme.textSecondaryDark,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Gap(16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final confirmed =
                                  await _showDeleteConfirmationDialog(context);
                              if (confirmed) {
                                try {
                                  // Delete habit from repository
                                  await ref
                                      .read(habitRepositoryProvider)
                                      .deleteHabit(habit.id);
                                  // Cancel all notifications
                                  await ref
                                      .read(notificationServiceProvider)
                                      .cancelHabitNotifications(habit.id);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Habit deleted successfully',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Navigator.of(
                                      context,
                                    ).pop(); // Close detail screen
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error deleting habit: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withValues(
                                alpha: 0.2,
                              ),
                              foregroundColor: Colors.red,
                              side: BorderSide(
                                color: Colors.red.withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Delete Forever',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text('Error: $err', style: TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Habit habit,
    Color neonColor,
    bool isCompleted,
  ) {
    return Row(
      children: [
        // Large progress ring
        Hero(
          tag: 'habit_icon_${habit.id}',
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: neonColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
              border: Border.all(
                color: neonColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                _getAttributeIcon(habit.attribute),
                color: neonColor,
                size: 32,
              ),
            ),
          ),
        ),
        const Gap(20),
        // Title and streak
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                habit.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textMainDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(8),
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: EmergeColors.coral,
                    size: 20,
                  ),
                  const Gap(4),
                  Text(
                    '${habit.currentStreak} day streak',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: EmergeColors.coral,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (isCompleted) ...[
                const Gap(8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'COMPLETED TODAY',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteButton(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
    Color neonColor,
    bool isCompleted,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: FilledButton.icon(
        onPressed: isCompleted
            ? null
            : () {
                ref.read(completeHabitProvider(habit.id));
                // Optional: Show celebration?
                // For now just toggle state which updates UI
              },
        icon: Icon(isCompleted ? Icons.check : Icons.bolt, size: 28),
        label: Text(
          isCompleted ? 'Completed Today!' : 'Mark Complete',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: isCompleted
              ? Colors.green.withValues(alpha: 0.3)
              : neonColor,
          foregroundColor: isCompleted ? Colors.green : Colors.white,
          disabledBackgroundColor: Colors.green.withValues(alpha: 0.3),
          disabledForegroundColor: Colors.green,
          elevation: isCompleted ? 0 : 8,
          shadowColor: neonColor.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Color _getAttributeColor(HabitAttribute attribute) {
    switch (attribute) {
      case HabitAttribute.vitality:
        return const Color(0xFF00E5FF);
      case HabitAttribute.intellect:
        return const Color(0xFFE040FB);
      case HabitAttribute.creativity:
        return const Color(0xFF76FF03);
      case HabitAttribute.focus:
        return const Color(0xFFFFAB00);
      case HabitAttribute.strength:
        return const Color(0xFFFF5252);
      case HabitAttribute.spirit:
        return const Color(0xFFFFD700); // Golden color
    }
  }

  IconData _getAttributeIcon(HabitAttribute attribute) {
    switch (attribute) {
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
