import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_suggestions_provider.dart';
import 'package:emerge_app/features/habits/presentation/providers/smart_defaults_provider.dart';
import 'package:emerge_app/features/habits/presentation/widgets/emoji_picker_row.dart';
import 'package:emerge_app/features/habits/presentation/widgets/habit_suggestions_grid.dart';
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
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _titleFocus = FocusNode();
  final _locationFocus = FocusNode();
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _titleFocus.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(habitCreateStateProvider);
    final defaults = ref.watch(smartDefaultsProvider);
    final suggestions = ref.watch(habitSuggestionsProvider);

    // Effective time display: explicit form time, else smart default.
    final effectiveTime = form.time.isNotEmpty
        ? form.time
        : defaults.time.format(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('CREATE HABIT'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EmojiPickerRow(
              selectedEmoji: form.emoji,
              recentlyUsed: EmojiPickerRow.fullEmojiList,
              onEmojiSelected: (e) =>
                  ref.read(habitCreateStateProvider.notifier).updateEmoji(e),
            ),
            const Gap(20),
            IdentitySentenceBuilder(
              action: form.title,
              time: effectiveTime,
              location: form.location,
              frequency: form.frequency,
              onActionChanged: (_) => _titleFocus.requestFocus(),
              onTimeChanged: (t) {
                // The builder returns a formatted string; also try to parse hh:mm.
                ref
                    .read(habitCreateStateProvider.notifier)
                    .updateTime(t, form.reminderTime ?? defaults.time);
              },
              onLocationChanged: (_) => _locationFocus.requestFocus(),
              onFrequencyChanged: (f) =>
                  ref.read(habitCreateStateProvider.notifier).updateFrequency(f),
            ),
            const Gap(16),
            TextField(
              controller: _titleController,
              focusNode: _titleFocus,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'What habit do you want to build?',
                hintStyle: TextStyle(color: Colors.white38),
              ),
              onChanged: (v) =>
                  ref.read(habitCreateStateProvider.notifier).updateTitle(v),
            ),
            const Gap(8),
            HabitSuggestionsGrid(
              suggestions: suggestions,
              query: form.title,
              onSelected: (s) {
                _titleController.text = s;
                ref.read(habitCreateStateProvider.notifier).updateTitle(s);
                _titleFocus.unfocus();
              },
            ),
            const Gap(16),
            TextField(
              controller: _locationController,
              focusNode: _locationFocus,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Where? (optional)',
                hintStyle: TextStyle(color: Colors.white38),
              ),
              onChanged: (v) =>
                  ref.read(habitCreateStateProvider.notifier).updateLocation(v),
            ),
            const Gap(16),
            _AttributeBadge(
              attribute: form.attribute,
              onTap: _showAttributePicker,
            ),
            const Gap(24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: form.title.trim().isEmpty || _saving
                    ? null
                    : _createHabit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2BEE79),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor:
                      const Color(0xFF2BEE79).withValues(alpha: 0.3),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'FORGE HABIT →',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttributePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: HabitAttribute.values
              .map((a) => ListTile(
                    title: Text(
                      a.name.toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      ref
                          .read(habitCreateStateProvider.notifier)
                          .updateAttribute(a);
                      Navigator.pop(ctx);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<void> _createHabit() async {
    final form = ref.read(habitCreateStateProvider);
    final defaults = ref.read(smartDefaultsProvider);
    final userId = ref.read(authStateChangesProvider).value?.id;

    if (userId == null || userId.isEmpty) {
      _showSnack('You must be logged in to create a habit.');
      return;
    }

    setState(() => _saving = true);

    final frequency = form.frequency == 'weekly'
        ? HabitFrequency.weekly
        : HabitFrequency.daily;

    final habit = Habit(
      id: const Uuid().v4(),
      userId: userId,
      title: form.title.trim(),
      frequency: frequency,
      reminderTime: form.reminderTime ?? defaults.time,
      location: form.location.isNotEmpty ? form.location : null,
      attribute: form.attribute,
      createdAt: DateTime.now(),
      difficulty: form.difficulty,
      currentStreak: 1,
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

class _AttributeBadge extends StatelessWidget {
  final HabitAttribute attribute;
  final VoidCallback onTap;

  const _AttributeBadge({required this.attribute, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = attributeColor(attribute);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              attribute.name.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
