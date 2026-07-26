# Plan 7: Habit Create Screen + Activity Screen + Undo Button

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the `AdvancedCreateHabitDialog` with a full-screen habit create screen featuring identity sentence builder with 4 tappable pill segments, typeahead suggestions, emoji picker, and smart defaults. Add a habit activity screen with GitHub-style heatmap and reflection log. Add an undo button to completed habit cards.

**Architecture:** Two new screens (`habit_create_screen.dart`, `habit_activity_screen.dart`), three new widgets (`emoji_picker_row.dart`, `habit_heatmap.dart`, `identity_sentence_builder.dart`), one new provider for activity data, router updates, and deletion of the old dialog. The undo button is a small visual addition to existing completed cards.

**Tech Stack:** Flutter, Riverpod, GoRouter, `habit_timeline_section.dart`, `habits_providers.dart`, `router.dart`.

**State: Pending Implementation**

---

### Task 1: Delete old dialog

**Files:**
- Delete: `lib/features/habits/presentation/screens/advanced_create_habit_dialog.dart`

- [ ] **Step 1: Check for imports**

Run: `grep -rn "advanced_create_habit_dialog" lib/`
Expected: Find all import references.

- [ ] **Step 2: Remove all imports and delete file**

```bash
git rm lib/features/habits/presentation/screens/advanced_create_habit_dialog.dart
```

- [ ] **Step 3: Commit**

```bash
git commit -m "refactor(habits): remove AdvancedCreateHabitDialog (replaced by full-screen creator)"
```

---

### Task 2: Identity sentence builder widget

**Files:**
- Create: `lib/features/habits/presentation/widgets/identity_sentence_builder.dart`
- Test: `test/features/habits/presentation/widgets/identity_sentence_builder_test.dart`

- [ ] **Step 1: Write the widget test**

```dart
testWidgets('shows static prefix and 4 tappable pill segments', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: IdentitySentenceBuilder(
        action: 'meditate',
        time: '7:00 AM',
        location: 'living room',
        frequency: 'daily',
        onActionChanged: (_) {},
        onTimeChanged: (_) {},
        onLocationChanged: (_) {},
        onFrequencyChanged: (_) {},
      ),
    ),
  ));
  expect(find.text('I am the type of person who'), findsOneWidget);
  expect(find.text('meditate'), findsOneWidget);
  expect(find.text('at 7:00 AM'), findsOneWidget);
  expect(find.text('in living room'), findsOneWidget);
  expect(find.text('daily'), findsOneWidget);
});
```

- [ ] **Step 2: Implement IdentitySentenceBuilder**

```dart
class IdentitySentenceBuilder extends StatelessWidget {
  final String action;
  final String time;
  final String location;
  final String frequency;
  final ValueChanged<String> onActionChanged;
  final ValueChanged<String> onTimeChanged;
  final ValueChanged<String> onLocationChanged;
  final ValueChanged<String> onFrequencyChanged;

  const IdentitySentenceBuilder({
    super.key,
    required this.action,
    required this.time,
    required this.location,
    required this.frequency,
    required this.onActionChanged,
    required this.onTimeChanged,
    required this.onLocationChanged,
    required this.onFrequencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am the type of person who',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PillSegment(
              label: action.isEmpty ? 'action ►' : action,
              onTap: () => onActionChanged(''), // Focus title field
              isSet: action.isNotEmpty,
            ),
            _PillSegment(
              label: time.isEmpty ? 'at ... ►' : 'at $time',
              onTap: () => _showTimePicker(context),
              isSet: time.isNotEmpty,
            ),
            _PillSegment(
              label: location.isEmpty ? 'where ... ►' : 'in $location',
              onTap: () => onLocationChanged(''), // Focus location field
              isSet: location.isNotEmpty,
            ),
            _PillSegment(
              label: _frequencyLabel(frequency),
              onTap: () => _showFrequencyPicker(context),
              isSet: frequency.isNotEmpty,
            ),
          ],
        ),
      ],
    );
  }

  String _frequencyLabel(String freq) {
    if (freq.isEmpty) return 'how often ... ►';
    return freq;
  }

  void _showTimePicker(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) onTimeChanged(time.format(context));
  }

  void _showFrequencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ['daily', 'weekly', 'weekdays', 'weekends', 'custom']
            .map((f) => ListTile(
                  title: Text(f),
                  onTap: () { onFrequencyChanged(f); Navigator.pop(ctx); },
                ))
            .toList(),
      ),
    );
  }
}

class _PillSegment extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSet;

  const _PillSegment({
    required this.label,
    required this.onTap,
    this.isSet = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSet
              ? Colors.cyanAccent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSet
                ? Colors.cyanAccent.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSet ? Colors.cyanAccent : Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: isSet ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Run test → pass**

- [ ] **Step 4: Commit**

```bash
git add lib/features/habits/presentation/widgets/identity_sentence_builder.dart
git commit -m "feat(habits): add identity sentence builder with 4 tappable pill segments"
```

---

### Task 3: Emoji picker row widget

**Files:**
- Create: `lib/features/habits/presentation/widgets/emoji_picker_row.dart`
- Test: `test/features/habits/presentation/widgets/emoji_picker_row_test.dart`

- [ ] **Step 1: Write the widget test**

```dart
testWidgets('shows recently used emojis and + button', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: EmojiPickerRow(
        selectedEmoji: '🔥',
        onEmojiSelected: (_) {},
        recentlyUsed: ['🔥', '💧', '🌿'],
      ),
    ),
  ));
  expect(find.text('🔥'), findsOneWidget);
  expect(find.text('💧'), findsOneWidget);
  expect(find.text('🌿'), findsOneWidget);
  expect(find.text('+'), findsOneWidget);
});
```

- [ ] **Step 2: Implement EmojiPickerRow**

```dart
class EmojiPickerRow extends StatelessWidget {
  final String selectedEmoji;
  final ValueChanged<String> onEmojiSelected;
  final List<String> recentlyUsed;

  static const fullEmojiList = [
    '🔥', '💧', '🌿', '📖', '💪', '🧠', '✨', '🎯',
    '🏃', '💤', '🍎', '🧘', '🎸', '🎨', '💼', '🏡',
    '🔋', '🚀',
  ];

  const EmojiPickerRow({
    super.key,
    required this.selectedEmoji,
    required this.onEmojiSelected,
    this.recentlyUsed = const [],
  });

  @override
  Widget build(BuildContext context) {
    final emojis = recentlyUsed.take(5).toList();
    return Row(
      children: [
        ...emojis.map((e) => _EmojiChip(
          emoji: e,
          isSelected: e == selectedEmoji,
          onTap: () => onEmojiSelected(e),
        )),
        _EmojiChip(
          emoji: '+',
          onTap: () => _showFullPicker(context),
          isSelected: false,
        ),
      ],
    );
  }

  void _showFullPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: fullEmojiList.map((e) => GestureDetector(
            onTap: () { onEmojiSelected(e); Navigator.pop(ctx); },
            child: Text(e, style: const TextStyle(fontSize: 32)),
          )).toList(),
        ),
      ),
    );
  }
}

class _EmojiChip extends StatelessWidget {
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Colors.cyanAccent)
              : null,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
```

- [ ] **Step 3: Run test → pass**

- [ ] **Step 4: Commit**

```bash
git add lib/features/habits/presentation/widgets/emoji_picker_row.dart
git commit -m "feat(habits): add emoji picker row with recently-used and full picker"
```

---

### Task 4: Typeahead suggestions widget

**Files:**
- Create: `lib/features/habits/presentation/widgets/habit_suggestions_grid.dart`

- [ ] **Step 1: Implement HabitSuggestionsGrid**

```dart
class HabitSuggestionsGrid extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSelected;
  final String query;

  const HabitSuggestionsGrid({
    super.key,
    required this.suggestions,
    required this.onSelected,
    this.query = '',
  });

  @override
  Widget build(BuildContext context) {
    final filtered = query.isEmpty
        ? suggestions
        : suggestions.where((s) =>
            s.toLowerCase().contains(query.toLowerCase())).toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    // Inline dropdown for typed queries
    if (query.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: filtered.map((s) => ListTile(
            dense: true,
            title: Text(s, style: const TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () => onSelected(s),
          )).toList(),
        ),
      );
    }

    // Grid for empty query
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.5,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) => GestureDetector(
        onTap: () => onSelected(filtered[index]),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt, size: 16, color: Colors.cyanAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(filtered[index],
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/habits/presentation/widgets/habit_suggestions_grid.dart
git commit -m "feat(habits): add typeahead suggestions grid with inline dropdown"
```

---

### Task 5: Habit Create Screen (full implementation)

**Files:**
- Create: `lib/features/habits/presentation/screens/habit_create_screen.dart`
- Modify: `lib/core/router/router.dart` (add route)

- [ ] **Step 1: Implement HabitCreateScreen**

```dart
@riverpod
class HabitCreateState extends _$HabitCreateState {
  @override
  HabitFormData build() => HabitFormData.empty();

  void updateTitle(String title) => state = state.copyWith(title: title);
  void updateEmoji(String emoji) => state = state.copyWith(emoji: emoji);
  void updateAction(String action) => state = state.copyWith(action: action);
  void updateTime(String time) => state = state.copyWith(time: time);
  void updateLocation(String loc) => state = state.copyWith(location: loc);
  void updateFrequency(String freq) => state = state.copyWith(frequency: freq);
  void updateTimer(int min) => state = state.copyWith(timerMinutes: min);
  void updateDifficulty(String diff) => state = state.copyWith(difficulty: diff);
  void updateTwoMinute(String v) => state = state.copyWith(twoMinuteVersion: v);
}

class HabitFormData {
  final String title;
  final String emoji;
  final String action;
  final String time;
  final String location;
  final String frequency;
  final int timerMinutes;
  final String difficulty;
  final String twoMinuteVersion;

  const HabitFormData({
    required this.title,
    required this.emoji,
    required this.action,
    required this.time,
    required this.location,
    required this.frequency,
    required this.timerMinutes,
    required this.difficulty,
    required this.twoMinuteVersion,
  });

  static const empty = HabitFormData(
    title: '',
    emoji: '🔥',
    action: '',
    time: '',
    location: '',
    frequency: '',
    timerMinutes: 5,
    difficulty: 'medium',
    twoMinuteVersion: '',
  );

  HabitFormData copyWith({
    String? title,
    String? emoji,
    String? action,
    String? time,
    String? location,
    String? frequency,
    int? timerMinutes,
    String? difficulty,
    String? twoMinuteVersion,
  }) {
    return HabitFormData(
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      action: action ?? this.action,
      time: time ?? this.time,
      location: location ?? this.location,
      frequency: frequency ?? this.frequency,
      timerMinutes: timerMinutes ?? this.timerMinutes,
      difficulty: difficulty ?? this.difficulty,
      twoMinuteVersion: twoMinuteVersion ?? this.twoMinuteVersion,
    );
  }
}
```

Full screen implementation:

```dart
class HabitCreateScreen extends ConsumerStatefulWidget {
  const HabitCreateScreen({super.key});

  @override
  ConsumerState<HabitCreateScreen> createState() => _HabitCreateScreenState();
}

class _HabitCreateScreenState extends ConsumerState<HabitCreateScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _twoMinuteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(habitCreateStateProvider);
    final defaults = ref.watch(smartDefaultsProvider);

    return Scaffold(
      appBar: AppBar(
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
            // 1. Emoji picker
            EmojiPickerRow(
              selectedEmoji: form.emoji,
              onEmojiSelected: (e) => ref.read(habitCreateStateProvider.notifier).updateEmoji(e),
            ),
            const Gap(20),

            // 2. Identity sentence builder
            IdentitySentenceBuilder(
              action: form.title,
              time: form.time.isEmpty ? defaults.time : form.time,
              location: form.location,
              frequency: form.frequency,
              onActionChanged: (_) => _titleController.requestFocus(),
              onTimeChanged: (t) => ref.read(habitCreateStateProvider.notifier).updateTime(t),
              onLocationChanged: (_) => _locationController.requestFocus(),
              onFrequencyChanged: (f) => ref.read(habitCreateStateProvider.notifier).updateFrequency(f),
            ),
            const Gap(16),

            // 3. Title text field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'What habit do you want to build?',
              ),
              onChanged: (v) {
                ref.read(habitCreateStateProvider.notifier).updateTitle(v);
                ref.read(habitCreateStateProvider.notifier).updateAction(v);
              },
            ),
            const Gap(16),

            // 4. Typeahead suggestions
            HabitSuggestionsGrid(
              suggestions: ref.watch(habitSuggestionsProvider),
              query: _titleController.text,
              onSelected: (s) {
                _titleController.text = s;
                ref.read(habitCreateStateProvider.notifier).updateTitle(s);
                ref.read(habitCreateStateProvider.notifier).updateAction(s);
              },
            ),
            const Gap(16),

            // 5. Attribute badge
            _buildAttributeBadge(defaults.attribute),

            const Gap(24),

            // 6. CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: form.title.isEmpty ? null : _createHabit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2BEE79),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('FORGE HABIT →',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createHabit() async {
    final form = ref.read(habitCreateStateProvider);
    final repo = ref.read(habitRepositoryProvider);
    final result = await repo.createHabit(
      HabitInput(
        title: form.title,
        emoji: form.emoji,
        time: form.time,
        location: form.location,
        frequency: form.frequency,
        timerMinutes: form.timerMinutes,
        difficulty: form.difficulty,
        twoMinuteVersion: form.twoMinuteVersion,
      ),
    );
    result.fold(
      (failure) => AppLogger.e('Habit creation failed', error: failure.message),
      (_) {
        ref.invalidate(todayHabitsProvider);
        if (mounted) context.pop();
      },
    );
  }
}
```

- [ ] **Step 2: Add route to router**

```dart
// In router.dart, inside the timeline shell route:
GoRoute(
  path: 'create-habit',
  pageBuilder: (context, state) => CustomTransitionPage(
    key: state.pageKey,
    child: const HabitCreateScreen(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
          child: child,
        ),
  ),
),
```

- [ ] **Step 3: Run analyze**

- [ ] **Step 4: Commit**

```bash
git add lib/features/habits/presentation/screens/habit_create_screen.dart lib/core/router/router.dart
git commit -m "feat(habits): add full-screen habit create screen with identity builder and typeahead"
```

---

### Task 6: Habit heatmap widget

**Files:**
- Create: `lib/features/habits/presentation/widgets/habit_heatmap.dart`
- Test: `test/features/habits/presentation/widgets/habit_heatmap_test.dart`

- [ ] **Step 1: Write the widget test**

```dart
testWidgets('renders 7x13 grid of cells', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: HabitHeatmap(
        data: List.generate(90, (i) => i % 3 == 0), // every 3rd day completed
      ),
    ),
  ));
  // Should find ~90 cells (container widgets)
  expect(find.byType(Container), findsAtLeast(80));
});
```

- [ ] **Step 2: Implement HabitHeatmap**

```dart
class HabitHeatmap extends StatelessWidget {
  final List<bool> data; // 90 booleans, index 0 = oldest
  final ValueChanged<int>? onCellTap;

  const HabitHeatmap({
    super.key,
    required this.data,
    this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final weeks = <List<bool>>[];
    for (int w = 0; w < 13; w++) {
      final week = <bool>[];
      for (int d = 0; d < 7; d++) {
        final index = w * 7 + d;
        week.add(index < data.length ? data[index] : false);
      }
      weeks.add(week);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day labels
        Row(
          children: ['Mon', '', 'Wed', '', 'Fri', '', 'Sun']
              .map((d) => SizedBox(
                    width: 14,
                    child: Text(d, style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 8,
                    )),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        // Grid
        Row(
          children: weeks.map((week) => Column(
            children: week.map((completed) => GestureDetector(
              onTap: onCellTap != null ? () => onCellTap!(weeks.indexOf(week) * 7 + week.indexOf(completed)) : null,
              child: Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  color: completed
                      ? Color.lerp(
                          const Color(0xFF2BEE79).withValues(alpha: 0.3),
                          const Color(0xFF2BEE79),
                          (data.where((d) => d).length / data.length).clamp(0, 1),
                        )
                      : const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )).toList(),
          )).toList(),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Run test → pass**

- [ ] **Step 4: Commit**

```bash
git add lib/features/habits/presentation/widgets/habit_heatmap.dart
git commit -m "feat(habits): add GitHub-style habit heatmap widget"
```

---

### Task 7: Habit activity provider

**Files:**
- Create: `lib/features/habits/presentation/providers/habit_activity_provider.dart`

- [ ] **Step 1: Create the provider**

```dart
@riverpod
class HabitActivity extends _$HabitActivity {
  @override
  Future<HabitActivityData> build(String habitId) async {
    final repo = ref.watch(habitRepositoryProvider);
    final result = await repo.getActivityData(habitId);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (data) => data,
    );
  }
}

class HabitActivityData {
  final String habitId;
  final String title;
  final String identityStatement;
  final String emoji;
  final int currentStreak;
  final int bestStreak;
  final int totalCompletions;
  final double momentum; // 0.0-1.0
  final List<bool> heatmapData; // 90 days
  final List<HabitReflection> reflections;

  const HabitActivityData({
    required this.habitId,
    required this.title,
    required this.identityStatement,
    required this.emoji,
    required this.currentStreak,
    required this.bestStreak,
    required this.totalCompletions,
    required this.momentum,
    required this.heatmapData,
    required this.reflections,
  });
}

class HabitReflection {
  final String text;
  final DateTime createdAt;
  const HabitReflection({required this.text, required this.createdAt});
}
```

- [ ] **Step 2: Run build_runner**

- [ ] **Step 3: Commit**

---

### Task 8: Habit Activity Screen

**Files:**
- Create: `lib/features/habits/presentation/screens/habit_activity_screen.dart`

- [ ] **Step 1: Implement HabitActivityScreen**

```dart
class HabitActivityScreen extends ConsumerWidget {
  final String habitId;

  const HabitActivityScreen({super.key, required this.habitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(habitActivityProvider(habitId));

    return activity.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: AppErrorWidget(
          message: "Couldn't load activity data.",
          onRetry: () => ref.invalidate(habitActivityProvider(habitId)),
        ),
      ),
      data: (data) => Scaffold(
        appBar: AppBar(
          title: Text('${data.emoji} ${data.title}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/timeline/create-habit', extra: data.habitId),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Identity card
              _IdentityCard(statement: data.identityStatement),
              const Gap(24),

              // Stats row
              Row(
                children: [
                  _StatChip(label: '🔥 Streak', value: '${data.currentStreak}'),
                  const SizedBox(width: 12),
                  _StatChip(label: '🏆 Best', value: '${data.bestStreak}'),
                  const SizedBox(width: 12),
                  _StatChip(label: '📊 Total', value: '${data.totalCompletions}'),
                ],
              ),
              const Gap(24),

              // Heatmap
              Text('ACTIVITY', style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              )),
              const SizedBox(height: 12),
              HabitHeatmap(data: data.heatmapData),
              const Gap(24),

              // Reflection log
              Text('REFLECTIONS', style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              )),
              const SizedBox(height: 12),
              _buildReflectionInput(context, ref, data.habitId),
              const SizedBox(height: 12),
              ...data.reflections.map((r) => _buildReflectionTile(r)),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add route to router**

```dart
// Top-level route (with parentNavigatorKey: _rootNavigatorKey):
GoRoute(
  path: 'timeline/habit/:habitId',
  builder: (context, state) => HabitActivityScreen(
    habitId: state.pathParameters['habitId']!,
  ),
),
```

- [ ] **Step 3: Run analyze**

- [ ] **Step 4: Commit**

```bash
git add lib/features/habits/presentation/screens/habit_activity_screen.dart lib/core/router/router.dart
git commit -m "feat(habits): add habit activity screen with heatmap, stats, and reflection log"
```

---

### Task 9: Undo button on completed habit cards

**Files:**
- Modify: `lib/features/timeline/presentation/widgets/habit_timeline_section.dart`

- [ ] **Step 1: Read current _buildCompleted() method**

- [ ] **Step 2: Add undo icon after XP badge**

```dart
// In the completed card row, after the XP badge:
Row(
  children: [
    // ... existing completed content (check icon, title, XP badge)
    const Spacer(),
    Text('+$xp XP', style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
    const SizedBox(width: 8),
    GestureDetector(
      onTap: () => onCheckboxTap(habit), // Same callback as checkbox toggle
      child: Icon(
        Icons.undo,
        size: 18,
        color: Colors.white.withValues(alpha: 0.6),
      ),
    ),
  ],
)
```

- [ ] **Step 3: Run analyze**

```dart
dart analyze lib/features/timeline/presentation/widgets/habit_timeline_section.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/timeline/presentation/widgets/habit_timeline_section.dart
git commit -m "feat(timeline): add undo button on completed habit cards"
```

---

### Task 10: Full verification

- [ ] **Step 1: Run build_runner**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 2: Run analyze + test**

```bash
flutter analyze
flutter test
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat(habit-features): verify all habit create, activity, undo features"
```
