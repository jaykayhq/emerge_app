import 'package:emerge_app/core/services/notification_service.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/habits/presentation/widgets/habit_timer_dialog.dart';
import 'package:emerge_app/features/reflections/domain/entities/mood.dart';
import 'package:emerge_app/features/reflections/presentation/providers/habit_reflection_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

/// Modal bottom sheet for per-habit editing and reflection.
///
/// Sections (top to bottom):
/// 1. Header (title + close X)
/// 2. Start Timer -> opens [HabitTimerDialog]
/// 3. Environment Priming (list + add/remove)
/// 4. Set Reward (text + suggestions)
/// 5. Log Reflection (mood + note + save)
/// 6. Delete Habit (confirmation -> deleteHabit)
class HabitOptionsSheet extends ConsumerStatefulWidget {
  final Habit habit;
  final DateTime selectedDate;

  const HabitOptionsSheet({
    required this.habit,
    required this.selectedDate,
    super.key,
  });

  /// Show the sheet from any context.
  static Future<void> show(
    BuildContext context,
    Habit habit,
    DateTime selectedDate,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) =>
            HabitOptionsSheet(habit: habit, selectedDate: selectedDate),
      ),
    );
  }

  @override
  ConsumerState<HabitOptionsSheet> createState() => _HabitOptionsSheetState();
}

class _HabitOptionsSheetState extends ConsumerState<HabitOptionsSheet> {
  final _primingCtrl = TextEditingController();
  final _rewardCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  Mood? _mood;
  bool _initReward = false;

  @override
  void dispose() {
    _primingCtrl.dispose();
    _rewardCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _startTimer() async {
    final result = await showDialog<int?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => HabitTimerDialog(
        habitTitle: widget.habit.title,
        neonColor: EmergeColors.teal,
        durationMinutes: widget.habit.timerDurationMinutes,
        onComplete: () {
          ref.read(completeHabitProvider(widget.habit.id));
          Navigator.of(context).pop(); // pop timer dialog only
        },
      ),
    );
    if (mounted) {
      if (result != null && result > 0) {
        Navigator.of(context).pop(result);
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _addPriming() async {
    final rule = _primingCtrl.text.trim();
    if (rule.isEmpty) return;
    final updated = widget.habit.copyWith(
      environmentPriming: [...widget.habit.environmentPriming, rule],
    );
    await ref.read(habitRepositoryProvider).updateHabit(updated);
    _primingCtrl.clear();
    if (mounted) setState(() {});
  }

  Future<void> _removePriming(int idx) async {
    final list = [...widget.habit.environmentPriming]..removeAt(idx);
    await ref
        .read(habitRepositoryProvider)
        .updateHabit(widget.habit.copyWith(environmentPriming: list));
    if (mounted) setState(() {});
  }

  Future<void> _saveReward() async {
    final text = _rewardCtrl.text.trim();
    if (text == widget.habit.reward) return;
    await ref
        .read(habitRepositoryProvider)
        .updateHabit(widget.habit.copyWith(reward: text));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reward saved')));
    }
  }

  Future<void> _saveReflection() async {
    if (_mood == null) return;
    final userId = ref.read(authStateChangesProvider).value?.id;
    if (userId == null) return;
    await ref.read(
      saveHabitReflectionProvider(
        userId: userId,
        habitId: widget.habit.id,
        date: widget.selectedDate,
        mood: _mood!,
        note: _noteCtrl.text.trim(),
      ).future,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reflection saved')));
  }

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Delete Habit?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will permanently delete this habit and all its history.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(habitRepositoryProvider).deleteHabit(widget.habit.id);
    await ref
        .read(notificationServiceProvider)
        .cancelHabitNotifications(widget.habit.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider).value;
    final userId = user?.id ?? '';
    final asyncReflection = ref.watch(
      habitReflectionProvider(
        userId: userId,
        habitId: widget.habit.id,
        date: widget.selectedDate,
      ),
    );
    final notCompleted = !widget.habit.isCompletedOn(widget.selectedDate);

    if (!_initReward) {
      _rewardCtrl.text = widget.habit.reward;
      _initReward = true;
    }
    asyncReflection.whenData((existing) {
      if (existing != null && _mood == null) {
        _mood = existing.mood;
        _noteCtrl.text = existing.note;
      }
    });

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.habit.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Gap(16),

              // 1. Start Timer
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _startTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Timer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EmergeColors.teal,
                    side: BorderSide(
                      color: EmergeColors.teal.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const Gap(24),

              // 2. Environment Priming
              _sectionTitle('Environment Priming'),
              const Gap(8),
              ...widget.habit.environmentPriming.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_box_outline_blank,
                        size: 16,
                        color: EmergeColors.teal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.value,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white70,
                        ),
                        onPressed: () => _removePriming(e.key),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.habit.environmentPriming.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No priming steps yet. Add one to reduce friction.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                ),
              const Gap(8),
              TextField(
                controller: _primingCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., Lay out workout clothes',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add, color: EmergeColors.teal),
                    onPressed: _addPriming,
                  ),
                ),
                onSubmitted: (_) => _addPriming(),
              ),
              const Gap(24),

              // 3. Set Reward
              _sectionTitle('Set Reward'),
              const Gap(8),
              TextField(
                controller: _rewardCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., Watch 1 episode',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _saveReward(),
                onEditingComplete: _saveReward,
              ),
              const Gap(8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      'Watch 1 episode',
                      'Check social media',
                      'Coffee/Tea',
                      'Podcast',
                    ].map((s) {
                      return ActionChip(
                        label: Text(
                          s,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        side: BorderSide.none,
                        onPressed: () {
                          _rewardCtrl.text = s;
                          _saveReward();
                        },
                      );
                    }).toList(),
              ),
              const Gap(24),

              // 4. Log Reflection
              _sectionTitle('Log Reflection'),
              const Gap(8),
              if (notCompleted)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Habit not yet completed today.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              asyncReflection.when(
                loading: () => const SizedBox(
                  height: 2,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
                error: (_, _) => const Text(
                  'Could not load reflection.',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
                data: (_) => const SizedBox.shrink(),
              ),
              const Gap(8),
              Row(
                children: [
                  for (final m in Mood.values)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _mood = m),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: _mood == m
                                  ? EmergeColors.teal.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.06),
                              border: Border.all(
                                color: _mood == m
                                    ? EmergeColors.teal
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                m.emoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const Gap(8),
              TextField(
                controller: _noteCtrl,
                maxLength: 140,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add a note... (140 chars)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  counterStyle: const TextStyle(color: Colors.white38),
                ),
              ),
              const Gap(8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _mood == null ? null : _saveReflection,
                  style: FilledButton.styleFrom(
                    backgroundColor: EmergeColors.teal,
                  ),
                  child: const Text(
                    'Save Reflection',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Gap(24),

              // 5. Delete Habit
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _confirmAndDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Delete Habit',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 11,
        letterSpacing: 1.5,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
