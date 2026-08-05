import 'package:emerge_app/core/presentation/widgets/glassmorphism_card.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/domain/services/habit_time_slots.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_recommendations_provider.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_suggestions_provider.dart';
import 'package:emerge_app/features/habits/presentation/providers/smart_defaults_provider.dart';
import 'package:emerge_app/features/habits/presentation/widgets/emoji_picker_row.dart';
import 'package:emerge_app/features/habits/presentation/widgets/habit_template_picker.dart';
import 'package:emerge_app/features/habits/presentation/widgets/identity_sentence_builder.dart';
import 'package:emerge_app/features/monetization/presentation/widgets/premium_limit_dialog.dart';
import 'package:emerge_app/features/timeline/presentation/widgets/habit_timeline_section.dart'
    show attributeColor;
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_guide_host.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/nebula_background.dart';
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
  final HabitIntegrationType integrationType;
  final int? integrationTarget;

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
    this.integrationType = HabitIntegrationType.none,
    this.integrationTarget,
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
    HabitIntegrationType? integrationType,
    int? integrationTarget,
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
      integrationType: integrationType ?? this.integrationType,
      integrationTarget: integrationTarget ?? this.integrationTarget,
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
  void updateTwoMinute(String v) => state = state.copyWith(twoMinuteVersion: v);
  void updateIntegration(HabitIntegrationType type, int? target) =>
      state = state.copyWith(integrationType: type, integrationTarget: target);

  void reset() => state = HabitFormData.empty;
}

class HabitCreateScreen extends ConsumerStatefulWidget {
  const HabitCreateScreen({super.key});

  @override
  ConsumerState<HabitCreateScreen> createState() => _HabitCreateScreenState();
}

class _HabitCreateScreenState extends ConsumerState<HabitCreateScreen> {
  bool _saving = false;
  // Narrator guide targets: the hero sentence card (where the habit's name is
  // set) and the FORGE HABIT CTA that persists the habit.
  final GlobalKey _nameFieldKey = GlobalKey();
  final GlobalKey _createButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(habitCreateStateProvider);
    final defaults = ref.watch(smartDefaultsProvider);
    final suggestions = ref.watch(habitSuggestionsProvider);

    final effectiveTime = form.time.isNotEmpty
        ? form.time
        : defaults.time.format(context);

    // Nebula backdrop behind the glass form (matches the timeline's world
    // theme so the slide-up page never flashes a flat background).
    return NarratorGuideHost(
      nodeId: 'habit_create',
      targets: {'name_field': _nameFieldKey, 'create_button': _createButtonKey},
      child: Stack(
        children: [
          const Positioned.fill(
            child: NebulaBackground(
              primaryColor: Color(0xFF00FFCC),
              accentColor: Color(0xFF6C63FF),
            ),
          ),
          Scaffold(
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
                  KeyedSubtree(
                    key: _nameFieldKey,
                    child: GlassmorphismCard(
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
                      // Integration pill
                      _SecondaryPill(
                        label: _integrationLabel(form),
                        isSelected: true,
                        color: EmergeColors.teal,
                        onTap: _showIntegrationSheet,
                      ),
                    ],
                  ),
                  const Gap(16),

                  // 3. Expandable 2-minute version
                  _ExpandableTwoMinute(
                    value: form.twoMinuteVersion,
                    onChanged: (v) => ref
                        .read(habitCreateStateProvider.notifier)
                        .updateTwoMinute(v),
                  ),
                  const Gap(24),

                  // 4. Create button
                  KeyedSubtree(
                    key: _createButtonKey,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: form.title.trim().isEmpty || _saving
                            ? null
                            : _createHabit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EmergeColors.teal,
                          foregroundColor: const Color(0xFF05100B),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          disabledBackgroundColor: EmergeColors.teal.withValues(
                            alpha: 0.3,
                          ),
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
                  ),
                ],
              ),
            ),
          ),
        ],
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
                ref.read(habitCreateStateProvider.notifier).updateEmoji(e);
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          // Live typeahead: re-filter as the user types, so the closest
          // matching recommendations surface immediately.
          final matches = filterHabitRecommendations(
            term: controller.text,
            templates: habitTemplateCatalog,
            suggestions: suggestions,
          );
          return _GlassSheet(
            title: 'WHAT ACTION?',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  onChanged: (_) => setSheetState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type or choose...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: EmergeColors.teal.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const Gap(12),
                if (matches.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No matches — type your own below',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.38),
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: matches.map((m) {
                      return GestureDetector(
                        onTap: () {
                          final notifier = ref.read(
                            habitCreateStateProvider.notifier,
                          );
                          notifier.updateTitle(m.title);
                          // Templates carry the habit's visual identity and
                          // defaults — fill them so the hero sentence and
                          // card match the recommendation.
                          if (m.emoji != null) notifier.updateEmoji(m.emoji!);
                          if (m.attribute != null) {
                            notifier.updateAttribute(m.attribute!);
                          }
                          if (m.timerMinutes != null) {
                            notifier.updateTimer(m.timerMinutes!);
                          }
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Text(
                            m.emoji != null ? '${m.emoji} ${m.title}' : m.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
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
          );
        },
      ),
    );
  }

  void _showTimeSheet() {
    showTimePicker(context: context, initialTime: TimeOfDay.now()).then((
      picked,
    ) {
      if (picked != null && mounted) {
        ref
            .read(habitCreateStateProvider.notifier)
            .updateTime(picked.format(context), picked);
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
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.38),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: EmergeColors.teal.withValues(alpha: 0.5),
                  ),
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
              title: Text(f, style: const TextStyle(color: Colors.white)),
              onTap: () {
                ref.read(habitCreateStateProvider.notifier).updateFrequency(f);
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
              title: Text(a.name.toUpperCase(), style: TextStyle(color: color)),
              onTap: () {
                ref.read(habitCreateStateProvider.notifier).updateAttribute(a);
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

  void _showIntegrationSheet() {
    final form = ref.read(habitCreateStateProvider);
    var selected = form.integrationType;
    var targetError = '';
    final targetController = TextEditingController(
      text: form.integrationTarget?.toString() ??
          (selected == HabitIntegrationType.healthSteps
              ? '10000'
              : selected == HabitIntegrationType.screenTimeLimit
                  ? '30'
                  : ''),
    );
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          void selectType(HabitIntegrationType type) {
            setSheetState(() {
              selected = type;
              targetError = '';
              // Reset the target to the newly selected type's default; keep
              // an applied target only when re-selecting its own type.
              targetController.text = switch (type) {
                HabitIntegrationType.healthSteps =>
                  form.integrationType == HabitIntegrationType.healthSteps &&
                          form.integrationTarget != null
                      ? form.integrationTarget!.toString()
                      : '10000',
                HabitIntegrationType.screenTimeLimit =>
                  form.integrationType == HabitIntegrationType.screenTimeLimit &&
                          form.integrationTarget != null
                      ? form.integrationTarget!.toString()
                      : '30',
                HabitIntegrationType.none => '',
              };
            });
          }

          return _GlassSheet(
            title: 'LINK INTEGRATION',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IntegrationOption(
                  label: 'No Integration',
                  icon: Icons.block,
                  isSelected: selected == HabitIntegrationType.none,
                  onTap: () => selectType(HabitIntegrationType.none),
                ),
                _IntegrationOption(
                  label: 'Health Steps',
                  icon: Icons.directions_walk,
                  isSelected: selected == HabitIntegrationType.healthSteps,
                  onTap: () => selectType(HabitIntegrationType.healthSteps),
                ),
                _IntegrationOption(
                  label: 'Screen Time Limit',
                  icon: Icons.phone_android_outlined,
                  isSelected: selected == HabitIntegrationType.screenTimeLimit,
                  onTap: () => selectType(HabitIntegrationType.screenTimeLimit),
                ),
                if (selected != HabitIntegrationType.none) ...[
                  const Gap(12),
                  TextField(
                    key: const Key('integration_target_field'),
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: selected == HabitIntegrationType.healthSteps
                          ? 'Daily step goal (e.g. 10000)'
                          : 'Daily screen time limit in minutes (e.g. 30)',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.38),
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Requires the matching permission — enable it under '
                    'Settings > Integrations & Data.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ],
                if (targetError.isNotEmpty) ...[
                  const Gap(8),
                  Text(
                    targetError,
                    style: const TextStyle(
                      color: Color(0xFFEF5350),
                      fontSize: 12,
                    ),
                  ),
                ],
                const Gap(16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final target = int.tryParse(targetController.text.trim());
                      if (selected == HabitIntegrationType.none) {
                        ref
                            .read(habitCreateStateProvider.notifier)
                            .updateIntegration(HabitIntegrationType.none, null);
                        Navigator.pop(ctx);
                      } else if (target != null && target > 0) {
                        ref
                            .read(habitCreateStateProvider.notifier)
                            .updateIntegration(selected, target);
                        Navigator.pop(ctx);
                      } else {
                        // Invalid target — keep the sheet open and surface why.
                        setSheetState(() {
                          targetError = 'Enter a valid target above 0.';
                        });
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
          );
        },
      ),
    );
  }

  // ─── Habit Creation Logic ───────────────────────────────────────────────

  String _integrationLabel(HabitFormData form) {
    switch (form.integrationType) {
      case HabitIntegrationType.healthSteps:
        return 'STEPS ${form.integrationTarget ?? 10000}';
      case HabitIntegrationType.screenTimeLimit:
        return 'SCREEN ${form.integrationTarget ?? 30} MIN';
      case HabitIntegrationType.none:
        return 'NO INTEGRATION';
    }
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
      timeOfDayPreference: timeOfDayPreferenceFrom(
        timelineSlotKeyFor(form.reminderTime ?? defaults.time),
      ),
      location: form.location.isNotEmpty ? form.location : null,
      attribute: form.attribute,
      createdAt: DateTime.now(),
      difficulty: form.difficulty,
      currentStreak: 0,
      twoMinuteVersion: form.twoMinuteVersion.isNotEmpty
          ? form.twoMinuteVersion
          : null,
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

// ─── Private Helper Widgets ────────────────────────────────────────────────

/// Option row for the integration picker sheet.
class _IntegrationOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _IntegrationOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? EmergeColors.teal : Colors.white54,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? EmergeColors.teal : Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? const Icon(
                Icons.check_circle,
                color: EmergeColors.teal,
                size: 20,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}

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
            color: isSelected ? c : Colors.white.withValues(alpha: 0.5),
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

  const _ExpandableTwoMinute({required this.value, required this.onChanged});

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
          borderSide: BorderSide(
            color: EmergeColors.teal.withValues(alpha: 0.5),
          ),
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
          border: const Border(top: BorderSide(color: Color(0x26FFFFFF))),
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
