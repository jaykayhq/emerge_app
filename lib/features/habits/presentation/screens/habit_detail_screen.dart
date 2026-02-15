import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
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

  // State variables for editing
  late int _timerDurationMinutes;
  late List<String> _customRules;
  String? _anchorHabitId;
  bool _isInit = false;
  bool _hasChanges = false;

  @override
  void dispose() {
    _twoMinuteController.dispose();
    _rewardController.dispose();
    _customRulesController.dispose();
    super.dispose();
  }

  void _initializeState(Habit habit) {
    if (_isInit) return;
    _twoMinuteController.text = habit.twoMinuteVersion ?? '';
    _rewardController.text = habit.reward;
    _timerDurationMinutes = habit.timerDurationMinutes;
    _customRules = List.from(habit.customRules);
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
