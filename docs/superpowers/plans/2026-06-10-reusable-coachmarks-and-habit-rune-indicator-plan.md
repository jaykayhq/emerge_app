# Reusable Feature Coach Marks & Habit Rune Indicator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a reusable onboarding guide coach-mark overlay system across all key feature screens, and add a dynamic pulsing "Rune & Socket" indicator on habit cards to signal the availability of detailed settings.

**Architecture:** 
1. Build a generic `FeatureCoachMark` widget that replicates `_WorldMapCoachMark` and displays customizable orientation details. Apply it across 9 target screens checking the `companionRepositoryProvider` visit history.
2. Build a custom `HabitRuneIndicator` widget that reads habit advanced fields and draws a pulsing dashed socket if empty (Dormant) or a glowing neon circle if active (Awakened).

**Tech Stack:** Flutter, Riverpod, GoRouter, CustomPainter, Dart 3.5+

---

### Task 1: Reusable Feature Coach Mark Component

**Files:**
- Create: `lib/core/presentation/widgets/feature_coach_mark.dart`
- Create: `test/core/presentation/widgets/feature_coach_mark_test.dart`

- [ ] **Step 1: Write a failing widget test for FeatureCoachMark**
  Write a test in `test/core/presentation/widgets/feature_coach_mark_test.dart` to verify rendering:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:emerge_app/core/presentation/widgets/feature_coach_mark.dart';

  void main() {
    testWidgets('FeatureCoachMark renders title, items, and triggers onDismiss', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FeatureCoachMark(
            title: 'Test Coach Mark',
            primaryColor: Colors.blue,
            items: const [
              CoachItemData(icon: Icons.star, title: 'Item 1', body: 'Body 1'),
            ],
            onDismiss: () => dismissed = true,
          ),
        ),
      ));

      expect(find.text('Test Coach Mark'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Body 1'), findsOneWidget);

      await tester.tap(find.text("GOT IT — LET'S GO"));
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);
    });
  }
  ```

- [ ] **Step 2: Run test to verify it fails**
  Run: `flutter test test/core/presentation/widgets/feature_coach_mark_test.dart`
  Expected: FAIL (compilation error, FeatureCoachMark not found).

- [ ] **Step 3: Implement FeatureCoachMark component**
  Create `lib/core/presentation/widgets/feature_coach_mark.dart`:
  ```dart
  import 'dart:ui';
  import 'package:flutter/material.dart';

  class CoachItemData {
    final IconData icon;
    final String title;
    final String body;

    const CoachItemData({
      required this.icon,
      required this.title,
      required this.body,
    });
  }

  class FeatureCoachMark extends StatefulWidget {
    final String title;
    final Color primaryColor;
    final List<CoachItemData> items;
    final VoidCallback onDismiss;

    const FeatureCoachMark({
      super.key,
      required this.title,
      required this.primaryColor,
      required this.items,
      required this.onDismiss,
    });

    @override
    State<FeatureCoachMark> createState() => _FeatureCoachMarkState();
  }

  class _FeatureCoachMarkState extends State<FeatureCoachMark>
      with SingleTickerProviderStateMixin {
    late final AnimationController _controller;
    late final Animation<double> _fadeAnim;

    @override
    void initState() {
      super.initState();
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
      _controller.forward();
    }

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

    void _dismiss() {
      _controller.reverse().then((_) => widget.onDismiss());
    }

    @override
    Widget build(BuildContext context) {
      return FadeTransition(
        opacity: _fadeAnim,
        child: GestureDetector(
          onTap: _dismiss,
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.black.withValues(alpha: 0.55),
            child: SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onTap: () {}, // Prevent dismissal on clicking card
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12122A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.primaryColor.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withValues(alpha: 0.2),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: widget.primaryColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.info_outline,
                                color: widget.primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const Text(
                              'Tap anywhere to close',
                              style: TextStyle(
                                color: Colors.white30,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...widget.items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(item.icon, color: widget.primaryColor, size: 18),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.body,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _dismiss,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.primaryColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "GOT IT — LET'S GO",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
  ```

- [ ] **Step 4: Run test to verify it passes**
  Run: `flutter test test/core/presentation/widgets/feature_coach_mark_test.dart`
  Expected: PASS.

- [ ] **Step 5: Commit changes**
  Run: `git add lib/core/presentation/widgets/feature_coach_mark.dart test/core/presentation/widgets/feature_coach_mark_test.dart; git commit -m "feat: add reusable FeatureCoachMark component"`

---

### Task 2: Habit Rune Indicator Component

**Files:**
- Create: `lib/features/timeline/presentation/widgets/habit_rune_indicator.dart`
- Create: `test/features/timeline/presentation/widgets/habit_rune_indicator_test.dart`

- [ ] **Step 1: Write a failing widget test for HabitRuneIndicator**
  Create `test/features/timeline/presentation/widgets/habit_rune_indicator_test.dart` to verify active vs dormant states:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:emerge_app/features/habits/domain/entities/habit.dart';
  import 'package:emerge_app/features/timeline/presentation/widgets/habit_rune_indicator.dart';

  void main() {
    // Helper to generate a baseline habit
    Habit makeHabit({
      String twoMinute = '',
      String reward = '',
    }) {
      return Habit(
        id: '1',
        title: 'Test Habit',
        attribute: HabitAttribute.mind,
        difficulty: HabitDifficulty.easy,
        twoMinuteVersion: twoMinute,
        reward: reward,
        environmentPriming: [],
        createdAt: DateTime.now(),
      );
    }

    testWidgets('HabitRuneIndicator renders dormant custom painter when unconfigured', (tester) async {
      final habit = makeHabit();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HabitRuneIndicator(habit: habit),
        ),
      ));

      expect(find.byType(CustomPaint), findsOneWidget);
    });
  }
  ```

- [ ] **Step 2: Run test to verify it fails**
  Run: `flutter test test/features/timeline/presentation/widgets/habit_rune_indicator_test.dart`
  Expected: FAIL.

- [ ] **Step 3: Implement HabitRuneIndicator with CustomPainter dashed border**
  Create `lib/features/timeline/presentation/widgets/habit_rune_indicator.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:emerge_app/features/habits/domain/entities/habit.dart';
  import 'package:emerge_app/core/theme/emerge_colors.dart';

  class DashedCirclePainter extends CustomPainter {
    final Color color;
    DashedCirclePainter({required this.color});

    @override
    void paint(Canvas canvas, Size size) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final double radius = size.width / 2;
      const int dashCount = 8;
      final double circumference = 2 * 3.1415926535 * radius;
      final double dashLength = circumference / (dashCount * 2);

      for (int i = 0; i < dashCount; i++) {
        final double angleStart = (i * 2 * 3.1415926535) / dashCount;
        final double angleEnd = angleStart + (3.1415926535 / dashCount);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(radius, radius), radius: radius),
          angleStart,
          angleEnd - angleStart,
          false,
          paint,
        );
      }
    }

    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
  }

  class HabitRuneIndicator extends StatefulWidget {
    final Habit habit;
    const HabitRuneIndicator({required this.habit, super.key});

    @override
    State<HabitRuneIndicator> createState() => _HabitRuneIndicatorState();
  }

  class _HabitRuneIndicatorState extends State<HabitRuneIndicator>
      with SingleTickerProviderStateMixin {
    late final AnimationController _controller;
    late final Animation<double> _pulseAnim;

    @override
    void initState() {
      super.initState();
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat(reverse: true);
      _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
    }

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

    bool get _isForged {
      final h = widget.habit;
      return (h.twoMinuteVersion != null && h.twoMinuteVersion!.isNotEmpty) ||
          h.reward.isNotEmpty ||
          h.environmentPriming.isNotEmpty ||
          h.integrationType != HabitIntegrationType.none ||
          h.anchorHabitId != null;
    }

    Color _getAttributeColor(HabitAttribute attr) {
      switch (attr) {
        case HabitAttribute.physical:
          return const Color(0xFFFF7F50);
        case HabitAttribute.mind:
          return const Color(0xFF7E57C2);
        case HabitAttribute.spirit:
          return const Color(0xFF64B5F6);
        case HabitAttribute.social:
          return const Color(0xFF2BEE79);
      }
    }

    @override
    Widget build(BuildContext context) {
      final color = _getAttributeColor(widget.habit.attribute);
      final forged = _isForged;

      return AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) {
          return Opacity(
            opacity: _pulseAnim.value,
            child: Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(right: 8),
              child: forged
                  ? Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.6),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    )
                  : CustomPaint(
                      painter: DashedCirclePainter(color: color.withValues(alpha: 0.6)),
                    ),
            ),
          );
        },
      );
    }
  }
  ```

- [ ] **Step 4: Run test to verify it passes**
  Run: `flutter test test/features/timeline/presentation/widgets/habit_rune_indicator_test.dart`
  Expected: PASS.

- [ ] **Step 5: Commit changes**
  Run: `git add lib/features/timeline/presentation/widgets/habit_rune_indicator.dart test/features/timeline/presentation/widgets/habit_rune_indicator_test.dart; git commit -m "feat: implement HabitRuneIndicator component"`

---

### Task 3: Integrating Rune Indicator into Habit Card

**Files:**
- Modify: `lib/features/timeline/presentation/widgets/habit_timeline_section.dart`

- [ ] **Step 1: Modify layout to add indicator preceding attribute badge**
  In `lib/features/timeline/presentation/widgets/habit_timeline_section.dart` around line 782:
  ```dart
  // Import:
  import 'package:emerge_app/features/timeline/presentation/widgets/habit_rune_indicator.dart';

  // Target Content inside _buildPending:
  // Attribute indicator
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    ...
  )

  // Replace Content with:
  Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      HabitRuneIndicator(habit: widget.habit),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  )
  ```
  Ensure similar integration inside `_buildCompleted` (around line 828) next to the XP display if appropriate, or just keep it in pending state. (Keep it in both so users can always tap completed habits too).

- [ ] **Step 2: Run flutter tests to make sure layout builds correctly**
  Run: `flutter test`
  Expected: PASS.

- [ ] **Step 3: Commit changes**
  Run: `git add lib/features/timeline/presentation/widgets/habit_timeline_section.dart; git commit -m "feat: integrate HabitRuneIndicator into Timeline habit list items"`

---

### Task 4: Integrating Timeline Screen Coach Mark

**Files:**
- Modify: `lib/features/timeline/presentation/screens/timeline_screen.dart`

- [ ] **Step 1: Integrate guide logic in initState and layout**
  In `lib/features/timeline/presentation/screens/timeline_screen.dart`:
  ```dart
  // Import:
  import 'package:emerge_app/core/presentation/widgets/feature_coach_mark.dart';

  // State variable:
  bool _showFirstVisitGuide = false;

  // Inside initState delay callback:
  if (!repo.hasVisited('/timeline')) {
    repo.markVisited('/timeline');
    ref.read(companionEngineProvider.notifier).triggerEvent(
      eventType: CompanionEventType.firstFeatureVisit,
      userContext: {'route': '/timeline'},
    );
    setState(() => _showFirstVisitGuide = true);
  }

  // Inside build:
  // Wrap SafeArea or WorldBackground child in a Stack to support overlay:
  return WorldBackground(
    useSafeArea: false,
    themeOverride: AppWorldTheme.nebula,
    child: Stack(
      children: [
        SafeArea(
          child: habits.isNotEmpty ...
        ),
        if (_showFirstVisitGuide)
          FeatureCoachMark(
            title: "Your Timeline Command Center",
            primaryColor: EmergeColors.teal,
            items: const [
              CoachItemData(
                icon: Icons.calendar_today_outlined,
                title: "Daily Consistency Calendar",
                style: TextStyle(), // if customized
                body: "Traverse your complete habit history and log daily reflections.",
              ),
              CoachItemData(
                icon: Icons.timer_outlined,
                title: "Awaken Modifications",
                body: "Look for the small pulsing Rune next to the badge on your cards. Tap the card to forge a 2-minute limit or rewards.",
              ),
            ],
            onDismiss: () => setState(() => _showFirstVisitGuide = false),
          ),
      ],
    ),
  );
  ```

- [ ] **Step 2: Run flutter tests**
  Run: `flutter test`
  Expected: PASS.

- [ ] **Step 3: Commit changes**
  Run: `git add lib/features/timeline/presentation/screens/timeline_screen.dart; git commit -m "feat: add first-visit coach marks on TimelineScreen"`

---

### Task 5: Integrating Coach Marks across all other Screens

Apply the exact same model to the other 8 files checking `repo.hasVisited(route)`.

**Files:**
- Modify: `lib/features/ai/presentation/screens/ai_reflections_screen.dart`
- Modify: `lib/features/gamification/presentation/screens/leveling_screen.dart`
- Modify: `lib/features/habits/presentation/screens/advanced_create_habit_dialog.dart`
- Modify: `lib/features/profile/presentation/screens/future_self_studio_screen.dart`
- Modify: `lib/features/social/presentation/screens/challenges_screen.dart`
- Modify: `lib/features/social/presentation/screens/social_discover_tab.dart`
- Modify: `lib/features/social/presentation/screens/tribe_tab_content.dart`
- Modify: `lib/features/world_map/presentation/screens/level_immersive_screen.dart`

- [ ] **Step 1: Add Coach Mark to AI Reflections Screen**
  Update `lib/features/ai/presentation/screens/ai_reflections_screen.dart` (Route: `/profile/reflections`):
  Wrap content in a Stack. In the visit check, trigger `setState(() => _showFirstVisitGuide = true)`. Add `FeatureCoachMark(title: "AI Reflections", primaryColor: EmergeColors.violet, items: [...])`. On dismiss, clear the state.

- [ ] **Step 2: Add Coach Mark to Leveling Screen**
  Update `lib/features/gamification/presentation/screens/leveling_screen.dart` (Route: `/gamification`):
  Same pattern, accent color: Amber/Gold. Explains leveling progression, tiers, and archetype-specific cosmetics.

- [ ] **Step 3: Add Coach Mark to Advanced Create Habit Dialog**
  Update `lib/features/habits/presentation/screens/advanced_create_habit_dialog.dart` (Route: `/habits/create`):
  Same pattern, accent color: Teal. Explains anchor habits, triggers, and friction-reducing two-minute rules.

- [ ] **Step 4: Add Coach Mark to Future Self Studio Screen**
  Update `lib/features/profile/presentation/screens/future_self_studio_screen.dart` (Route: `/profile/future-self`):
  Same pattern, accent color: Orchid/Pink. Explains setting motives, assigning attribute XP stats, and selecting base avatars.

- [ ] **Step 5: Add Coach Mark to Challenges Screen**
  Update `lib/features/social/presentation/screens/challenges_screen.dart` (Route: `/challenges`):
  Same pattern, accent color: Orange. Explains public challenges, progress leaderboards, and completion badges.

- [ ] **Step 6: Add Coach Mark to Social Discover Tab**
  Update `lib/features/social/presentation/screens/social_discover_tab.dart` (Route: `/discover`):
  Same pattern, accent color: Teal. Explains searching public tribes, membership applications, and matching user archetypes.

- [ ] **Step 7: Add Coach Mark to Tribe Tab Content**
  Update `lib/features/social/presentation/screens/tribe_tab_content.dart` (Route: `/tribes`):
  Same pattern, accent color: Green. Explains tribe momentum scoring, chat log updates, and territory expansions.

- [ ] **Step 8: Add Coach Mark to Immersive Level Map Screen**
  Update `lib/features/world_map/presentation/screens/level_immersive_screen.dart` (Route: `/world-map/immersive`):
  Same pattern, accent color: Emerald. Explains traversing the biome maps, tapping nodes, and viewing procedural terrain shifts.

- [ ] **Step 9: Run complete test suite and verify no compile errors**
  Run: `flutter test`
  Expected: PASS.

- [ ] **Step 10: Commit all final changes**
  Run: `git add . ; git commit -m "feat: complete unified coach mark system across all feature screens"`
