import 'package:emerge_app/core/presentation/widgets/glassmorphism_card.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_suggestions_provider.dart';
import 'package:emerge_app/features/habits/presentation/providers/smart_defaults_provider.dart';
import 'package:emerge_app/features/habits/presentation/widgets/emoji_picker_row.dart';
import 'package:emerge_app/features/habits/presentation/widgets/identity_sentence_builder.dart';
import 'package:emerge_app/features/monetization/presentation/widgets/premium_limit_dialog.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/habit_timeline_section.dart'
    show attributeColor;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'habit_create_screen.g.dart';

/// Mutable form state for the create-habit screen.
class HabitFormData {
  final String title;
  final String emoji;
  final String time; // formatted display string, e.g. "7:00 AM"
  final TimeOfDay? reminderTime;
  final String location;
  final String frequency;
  final int timerMinutes;
  final HabitDifficulty difficulty;
  final HabitAttribute attribute;
  final String twoMinuteVersion;

  const HabitFormData({
    required this.title,
    required this.emoji,
    required this.time,
    required this.reminderTime,
    required this.location,
    required this.frequency,
    required this.timerMinutes,
    required this.difficulty,
    required this.attribute,
    required this.twoMinuteVersion,
  });

  static const empty = HabitFormData(
    title: '',
    emoji: '🔥',
    time: '',
    reminderTime: null,
    location: '',
    frequency: 'daily',
    timerMinutes: 5,
    difficulty: HabitDifficulty.medium,
    attribute: HabitAttribute.vitality,
    twoMinuteVersion: '',
  );

  HabitFormData copyWith({
    String? title,
    String? emoji,
    String? time,
    TimeOfDay? reminderTime,
    String? location,
    String? frequency,
    int? timerMinutes,
    HabitDifficulty? difficulty,
    HabitAttribute? attribute,
    String? twoMinuteVersion,
  }) {
    return HabitFormData(
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      time: time ?? this.time,
      reminderTime: reminderTime ?? this.reminderTime,
      location: location ?? this.location,
      frequency: frequency ?? this.frequency,
      timerMinutes: timerMinutes ?? this.timerMinutes,
      difficulty: difficulty ?? this.difficulty,
      attribute: attribute ?? this.attribute,
      twoMinuteVersion: twoMinuteVersion ?? this.twoMinuteVersion,
    );
  }
}

@riverpod
class HabitCreateState extends _$HabitCreateState {
  @override
  HabitFormData build() => HabitFormData.empty;

  void updateTitle(String title) => state = state.copyWith(title: title);
  void updateEmoji(String emoji) => state = state.copyWith(emoji: emoji);
  void updateTime(String time, TimeOfDay reminderTime) =>
      state = state.copyWith(time: time, reminderTime: reminderTime);
  void updateLocation(String loc) => state = state.copyWith(location: loc);
  void updateFrequency(String freq) => state = state.copyWith(frequency: freq);
  void updateTimer(int min) => state = state.copyWith(timerMinutes: min);
  void updateDifficulty(HabitDifficulty d) =>
      state = state.copyWith(difficulty: d);
  void updateAttribute(HabitAttribute a) =>
      state = state.copyWith(attribute: a);
  void updateTwoMinute(String v) =>
      state = state.copyWith(twoMinuteVersion: v);

  void reset() => state = HabitFormData.empty;
}

class HabitCreateScreen extends ConsumerStatefulWidget {
  const HabitCreateScreen({super.key});

  @override
  ConsumerState<HabitCreateScreen> createState() => _HabitCreateScreenState();
}

class _HabitCreateScreenState extends ConsumerState<HabitCreateScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(habitCreateStateProvider);
    final defaults = ref.watch(smartDefaultsProvider);
    final suggestions = ref.watch(habitSuggestionsProvider);

    final effectiveTime =
        form.time.isNotEmpty ? form.time : defaults.time.format(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('CREATE HABIT'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero sentence card
            GlassmorphismCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(20),
              glowColor: EmergeColors.teal,
              glassOpacity: 0.06,
              child: IdentitySentenceBuilder(
                emoji: form.emoji,
                action: form.title,
                time: effectiveTime,
                location: form.location,
                frequency: form.frequency,
                onEmojiTap: () => _showEmojiSheet(form.emoji),
                onActionTap: () => _showActionSheet(suggestions),
                onTimeTap: _showTimeSheet,
                onLocationTap: _showLocationSheet,
                onFrequencyTap: _showFrequencySheet,
              ),
            ),
            const Gap(20),

            // 2. Secondary pills row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Difficulty chips
                ...HabitDifficulty.values.map((d) {
                  final selected = form.difficulty == d;
                  return _SecondaryPill(
                    label: d.name.toUpperCase(),
                    isSelected: selected,
                    onTap: () => ref
                        .read(habitCreateStateProvider.notifier)
                        .updateDifficulty(d),
                  );
                }),
                const SizedBox(width: 8),
                // Attribute pill
                _SecondaryPill(
                  label: form.attribute.name.toUpperCase(),
                  isSelected: true,
                  color: attributeColor(form.attribute),
                  onTap: _showAttributeSheet,
                ),
                // Timer pill
                _SecondaryPill(
                  label: '${form.timerMinutes} min',
                  isSelected: true,
                  onTap: () => _showTimerSheet(form.timerMinutes),
                ),
              ],
            ),
            const Gap(16),

            // 3. Expandable 2-minute version
            _ExpandableTwoMinute(
              value: form.twoMinuteVersion,
              onChanged: (v) =>
                  ref.read(habitCreateStateProvider.notifier).updateTwoMinute(v),
            ),
            const Gap(24),

            // 4. Create button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: form.title.trim().isEmpty || _saving
                    ? null
                    : _createHabit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EmergeColors.teal,
                  foregroundColor: const Color(0xFF05100B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor:
                      EmergeColors.teal.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF05100B),
                        ),
                      )
                    : const Text(
                        'FORGE HABIT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Sheets ──────────────────────────────────────────────────────

  void _showEmojiSheet(String current) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GlassSheet(
        title: 'CHOOSE EMOJI',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EmojiPickerRow.fullEmojiList.map((e) {
            final isSelected = e == current;
            return GestureDetector(
              onTap: () {
                ref
                    .read(habitCreateStateProvider.notifier)
                    .updateEmoji(e);
                Navigator.pop(ctx);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? EmergeColors.teal.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? EmergeColors.teal.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Text(e, style: const TextStyle(fontSize: 28)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showActionSheet(List<String> suggestions) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _GlassSheet(
        title: 'WHAT ACTION?',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type or choose...',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.38)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: EmergeColors.teal.withValues(alpha: 0.5)),
                ),
              ),
            ),
            const Gap(12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions.map((s) {
                return GestureDetector(
                  onTap: () {
                    ref
                        .read(habitCreateStateProvider.notifier)
                        .updateTitle(s);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      s,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Gap(12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    ref
                        .read(habitCreateStateProvider.notifier)
                        .updateTitle(controller.text.trim());
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: EmergeColors.teal,
                  foregroundColor: const Color(0xFF05100B),
                ),
                child: const Text('CONFIRM'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeSheet() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    ).then((picked) {
      if (picked != null && mounted) {
        ref.read(habitCreateStateProvider.notifier).updateTime(
              picked.format(context),
              picked,
            );
      }
    });
  }

  void _showLocationSheet() {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GlassSheet(
        title: 'WHERE?',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. at home, at the gym...',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.38)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: EmergeColors.teal.withValues(alpha: 0.5)),
                ),
              ),
            ),
            const Gap(12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref
                      .read(habitCreateStateProvider.notifier)
                      .updateLocation(controller.text.trim());
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: EmergeColors.teal,
                  foregroundColor: const Color(0xFF05100B),
                ),
                child: const Text('CONFIRM'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFrequencySheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GlassSheet(
        title: 'HOW OFTEN?',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['daily', 'weekly', 'weekdays', 'weekends'].map((f) {
            return ListTile(
              title: Text(
                f,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                ref
                    .read(habitCreateStateProvider.notifier)
                    .updateFrequency(f);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAttributeSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GlassSheet(
        title: 'ATTRIBUTE',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: HabitAttribute.values.map((a) {
            final color = attributeColor(a);
            return ListTile(
              leading: Icon(Icons.bolt, color: color),
              title: Text(
                a.name.toUpperCase(),
                style: TextStyle(color: color),
              ),
              onTap: () {
                ref
                    .read(habitCreateStateProvider.notifier)
                    .updateAttribute(a);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showTimerSheet(int current) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GlassSheet(
        title: 'TIMER DURATION',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, color: Colors.white70),
              onPressed: current <= 1
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _showTimerSheet(current - 1);
                      ref
                          .read(habitCreateStateProvider.notifier)
                          .updateTimer(current - 1);
                    },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '$current min',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white70),
              onPressed: current >= 120
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _showTimerSheet(current + 1);
                      ref
                          .read(habitCreateStateProvider.notifier)
                          .updateTimer(current + 1);
                    },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Habit Creation Logic ───────────────────────────────────────────────

  Future<void> _createHabit() async {
    final form = ref.read(habitCreateStateProvider);
    final defaults = ref.read(smartDefaultsProvider);
    final userId = ref.read(authStateChangesProvider).value?.id;

    if (userId == null || userId.isEmpty) {
      _showSnack('You must be logged in to create a habit.');
      return;
    }

    setState(() => _saving = true);

    final HabitFrequency frequency;
    List<int> specificDays = const [];
    switch (form.frequency) {
      case 'weekly':
        frequency = HabitFrequency.weekly;
        break;
      case 'weekdays':
        frequency = HabitFrequency.specificDays;
        specificDays = const [1, 2, 3, 4, 5];
        break;
      case 'weekends':
        frequency = HabitFrequency.specificDays;
        specificDays = const [6, 7];
        break;
      case 'daily':
      default:
        frequency = HabitFrequency.daily;
    }

    final habit = Habit(
      id: const Uuid().v4(),
      userId: userId,
      title: form.title.trim(),
      frequency: frequency,
      specificDays: specificDays,
      reminderTime: form.reminderTime ?? defaults.time,
      location: form.location.isNotEmpty ? form.location : null,
      attribute: form.attribute,
      createdAt: DateTime.now(),
      difficulty: form.difficulty,
      currentStreak: 0,
      twoMinuteVersion:
          form.twoMinuteVersion.isNotEmpty ? form.twoMinuteVersion : null,
      reward: 'Complete and enjoy your progress!',
      timerDurationMinutes: form.timerMinutes,
      imageUrl: form.emoji,
    );

    try {
      await ref.read(createHabitProvider(habit).future);
      AppLogger.i('Created habit from create screen: ${habit.id}');
      if (!mounted) return;
      ref.read(habitCreateStateProvider.notifier).reset();
      _showSnack('Habit created successfully!');
      context.pop();
    } on SubscriptionLimitReachedException catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showPremiumLimitDialog(context, limitType: PremiumLimitType.habit);
    } catch (e, s) {
      AppLogger.e('Error creating habit from create screen', e, s);
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack('Couldn\'t create habit. Please try again.');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

// ─── Private Helper Widgets ────────────────────────────────────────────────

/// Small glass pill for secondary options (difficulty, attribute, timer).
class _SecondaryPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _SecondaryPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? EmergeColors.teal;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? c.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? c.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? c
                : Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Expandable 2-minute version text field.
class _ExpandableTwoMinute extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _ExpandableTwoMinute({
    required this.value,
    required this.onChanged,
  });

  @override
  State<_ExpandableTwoMinute> createState() => _ExpandableTwoMinuteState();
}

class _ExpandableTwoMinuteState extends State<_ExpandableTwoMinute> {
  bool _expanded = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      return GestureDetector(
        onTap: () {
          setState(() => _expanded = true);
          if (widget.value.isNotEmpty) _controller.text = widget.value;
        },
        child: Text(
          '+ Scale it down (2-minute version)',
          style: TextStyle(
            color: EmergeColors.teal.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
      );
    }
    return TextField(
      controller: _controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Scale it down so it feels effortless',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: EmergeColors.teal.withValues(alpha: 0.5)),
        ),
      ),
      onChanged: widget.onChanged,
    );
  }
}

/// Shared glass bottom sheet container.
class _GlassSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const _GlassSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: const Border(
            top: BorderSide(color: Color(0x26FFFFFF)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(16),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const Gap(12),
            child,
          ],
        ),
      ),
    );
  }
}
