# "The Narrator IS The Guide" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the node-guide tutorial system with the narrator as the guide — a typed-voice Day Card with inline coach ask on the timeline, typewriter text everywhere, and first-visit tutorials that spotlight the exact sections they explain.

**Architecture:** Three new units inside the existing narrator feature: (1) `TypewriterText` core widget (pure `visibleCharCount` + tap-to-skip + reduced-motion instant); (2) `NarratorCard` Day Card (typed line + status chips + inline ask reusing the existing coach-quota/Groq plumbing); (3) a narrator guide engine (`NarratorGuideHost` + `SpotlightPainter` + `NarratorGuideCard` + pure registry) that replaces `lib/features/tutorials/`. The `NarratorSheet` modal, `NarratorSummaryCard`, `FeatureCoachMark`, and the tutorials feature are deleted once their call sites migrate. `docs/design.md` is amended (it currently bans typewriter text).

**Tech Stack:** Flutter/Dart, Riverpod 3 (annotation + codegen), go_router 17, fpdart (untouched), shared_preferences (seen-flags/quota), Drift (unchanged). No new dependencies.

**Spec:** `docs/superpowers/specs/2026-08-04-narrator-is-the-guide-design.md`

---

## Task 1: TypewriterText (pure function + widget)

**Files:**
- Create: `lib/core/presentation/widgets/typewriter_text.dart`
- Test: `test/core/presentation/widgets/typewriter_text_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/presentation/widgets/typewriter_text_test.dart`:

```dart
import 'package:emerge_app/core/presentation/widgets/typewriter_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('visibleCharCount', () {
    test('returns 0 at t=0', () {
      expect(visibleCharCount('hello', 0, 35), 0);
    });

    test('advances linearly with elapsed time', () {
      expect(visibleCharCount('hello', 100, 35), 3); // 3.5 → floor 3
    });

    test('saturates at full length', () {
      expect(visibleCharCount('hello', 10000, 35), 5);
    });

    test('empty text stays 0', () {
      expect(visibleCharCount('', 1000, 35), 0);
    });

    test('zero cps stays 0', () {
      expect(visibleCharCount('hello', 1000, 0), 0);
    });
  });

  group('TypewriterText widget', () {
    // NOTE: never use pumpAndSettle with TypewriterText — the blinking
    // caret repeats forever. Always pump explicit durations.
    testWidgets('types out text progressively', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypewriterText(text: 'Hello world', charsPerSecond: 100),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50)); // 5 chars
      // .first: the caret renders as a nested Text inside the main Text.rich.
      expect(tester.widget<Text>(find.byType(Text).first).textPlain, 'Hello');
      await tester.pump(const Duration(seconds: 1));
      expect(tester.widget<Text>(find.byType(Text).first).textPlain, 'Hello world');
    });

    testWidgets('tap completes instantly and fires onComplete', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypewriterText(
              text: 'Hello world',
              charsPerSecond: 1,
              onComplete: () => completed = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.widget<Text>(find.byType(Text).first).textPlain, '');
      await tester.tap(find.byType(TypewriterText));
      await tester.pump();
      expect(tester.widget<Text>(find.byType(Text).first).textPlain, 'Hello world');
      expect(completed, true);
    });

    testWidgets('reduced motion renders instantly with no caret', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: TypewriterText(text: 'Hello world', charsPerSecond: 1),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.widget<Text>(find.byType(Text).first).textPlain, 'Hello world');
    });
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/presentation/widgets/typewriter_text_test.dart`
Expected: FAIL — "Error: Type 'TypewriterText' is not a subtype of type 'Widget'" (file doesn't exist).

- [ ] **Step 3: Implement `TypewriterText`**

Create `lib/core/presentation/widgets/typewriter_text.dart`:

```dart
import 'package:flutter/material.dart';

/// Number of characters of [text] visible after [elapsedMs] at
/// [charsPerSecond]. Pure — the single source of truth for typing progress,
/// unit-tested without a widget tree.
int visibleCharCount(String text, int elapsedMs, int charsPerSecond) {
  if (text.isEmpty || charsPerSecond <= 0) return 0;
  final chars = (elapsedMs / 1000 * charsPerSecond).floor();
  return chars.clamp(0, text.length);
}

/// Types [text] out character-by-character with a blinking caret.
///
/// - Tap anywhere on the text → completes instantly (and fires [onComplete]).
/// - Reduced motion (system accessibility setting) → full text instantly,
///   no caret.
/// - [onComplete] fires once per text when typing finishes (naturally or
///   via tap-skip); when [text] changes, typing restarts and it fires again.
class TypewriterText extends StatefulWidget {
  final String text;
  final int charsPerSecond;
  final bool showCaret;
  final VoidCallback? onComplete;

  const TypewriterText({
    super.key,
    required this.text,
    this.charsPerSecond = 35,
    this.showCaret = true,
    this.onComplete,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _caretCtrl;
  bool _completed = false;

  bool get _instant => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _durationFor(widget.text));
    _caretCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _start();
  }

  Duration _durationFor(String text) {
    if (widget.charsPerSecond <= 0) return Duration.zero;
    final ms = text.length * 1000 ~/ widget.charsPerSecond;
    return Duration(milliseconds: ms < 1 ? 1 : ms);
  }

  void _start() {
    _completed = false;
    if (_instant) {
      _completed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete?.call());
      return;
    }
    _ctrl
      ..duration = _durationFor(widget.text)
      ..forward(from: 0);
    // Restart the caret blink for the new text.
    _caretCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _ctrl.stop();
      _start();
    }
  }

  void _complete() {
    if (_completed) return;
    _completed = true;
    _ctrl.stop();
    // Stop the caret blink so the tree goes idle (also keeps pumpAndSettle
    // usable once typing is done).
    _caretCtrl.stop();
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _caretCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final full = widget.text;
    final showCaret = widget.showCaret && !_instant && !_completed;
    return Semantics(
      label: full,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _instant || _completed ? null : _complete,
        child: AnimatedBuilder(
          animation: Listenable.merge([_ctrl, _caretCtrl]),
          builder: (context, _) {
            final elapsed = _ctrl.lastElapsedDuration?.inMilliseconds ?? 0;
            final count = _instant || _completed
                ? full.length
                : visibleCharCount(full, elapsed, widget.charsPerSecond);
            final caretVisible = showCaret && _caretCtrl.value > 0.5;
            return Text.rich(
              TextSpan(
                text: full.substring(0, count),
                children: [
                  // WidgetSpan (not TextSpan) so toPlainText() stays clean —
                  // tests and semantics never see the caret.
                  if (caretVisible)
                    WidgetSpan(
                      child: const Text(
                        '▍',
                        style: TextStyle(color: Color(0xFF9D8FFF)),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/core/presentation/widgets/typewriter_text_test.dart`
Expected: PASS (all 8 tests). `flutter analyze lib/core/presentation/widgets/typewriter_text.dart` clean.

- [ ] **Step 5: Commit**

```bash
git add lib/core/presentation/widgets/typewriter_text.dart test/core/presentation/widgets/typewriter_text_test.dart
git commit -m "feat(narrator): TypewriterText widget with tap-to-skip and reduced-motion support"
```

---

## Task 2: NarratorGuideRegistry (pure data)

**Files:**
- Create: `lib/features/narrator/domain/services/narrator_guide_registry.dart`
- Test: `test/features/narrator/domain/services/narrator_guide_registry_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:emerge_app/features/narrator/domain/services/narrator_guide_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NarratorGuideRegistry', () {
    test('registers exactly the 9 live nodes', () {
      expect(NarratorGuideRegistry.all.length, 9);
      expect(
        NarratorGuideRegistry.all.map((n) => n.nodeId).toSet(),
        {
          'timeline',
          'habit_create',
          'streak_recovery',
          'world_map',
          'leveling',
          'future_self',
          'challenges',
          'all_tribes',
          'tribe_lobby',
        },
      );
    });

    test('node ids are unique', () {
      final ids = NarratorGuideRegistry.all.map((n) => n.nodeId).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every node has 2-4 steps, each with a script and a targetKey', () {
      for (final node in NarratorGuideRegistry.all) {
        expect(node.steps.length, inInclusiveRange(2, 4),
            reason: 'node ${node.nodeId}');
        for (final step in node.steps) {
          expect(step.script.trim(), isNotEmpty, reason: '${node.nodeId} script');
          expect(step.targetKey.trim(), isNotEmpty, reason: '${node.nodeId} target');
        }
      }
    });

    test('targetKeys are unique within a node', () {
      for (final node in NarratorGuideRegistry.all) {
        final keys = node.steps.map((s) => s.targetKey).toList();
        expect(keys.toSet().length, keys.length, reason: 'node ${node.nodeId}');
      }
    });

    test('forNode returns null for unknown nodes', () {
      expect(NarratorGuideRegistry.forNode('nope'), isNull);
    });
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/narrator/domain/services/narrator_guide_registry_test.dart`
Expected: FAIL — import not found.

- [ ] **Step 3: Implement the registry**

Create `lib/features/narrator/domain/services/narrator_guide_registry.dart`:

```dart
/// One narrator-voiced guide step: a script the narrator types while the
/// spotlight highlights the section [targetKey] points at.
class NarratorGuideStep {
  final String script;
  final String targetKey;

  const NarratorGuideStep({required this.script, required this.targetKey});
}

/// Static configuration for a first-visit narrator guide on one screen.
///
/// [targetKey] values must match the keys of the `targets` map passed to
/// `NarratorGuideHost` on the corresponding screen (see the guide registry
/// test and the screen tasks in the plan).
class NarratorGuideDefinition {
  final String nodeId;
  final List<NarratorGuideStep> steps;

  const NarratorGuideDefinition({required this.nodeId, required this.steps});
}

/// Pure registry of all narrator guides.
///
/// One entry per live, front-facing screen. Scripts are first-person
/// narrator voice: they name the section they explain, because the
/// spotlight points at it while the line types.
class NarratorGuideRegistry {
  static const List<NarratorGuideDefinition> all = [
    NarratorGuideDefinition(nodeId: 'timeline', steps: [
      NarratorGuideStep(
        script: "See the + down there? That's where habits are born.",
        targetKey: 'fab',
      ),
      NarratorGuideStep(
        script:
            "The ring around it is today's score — green when you're on track.",
        targetKey: 'ring',
      ),
      NarratorGuideStep(
        script:
            "This card is me. It tells you what's left today — and you can ask me anything.",
        targetKey: 'card',
      ),
    ]),
    NarratorGuideDefinition(nodeId: 'habit_create', steps: [
      NarratorGuideStep(
        script:
            "Start here — a habit is a promise with a name you'll keep.",
        targetKey: 'name_field',
      ),
      NarratorGuideStep(
        script: "When it feels real, press this. Small steps, on purpose.",
        targetKey: 'create_button',
      ),
    ]),
    NarratorGuideDefinition(nodeId: 'streak_recovery', steps: [
      NarratorGuideStep(
        script:
            "One miss is a slip, not a fall. This is where your momentum rebuilds.",
        targetKey: 'momentum_visual',
      ),
      NarratorGuideStep(
        script: "The smallest step first — that's how a streak comes back.",
        targetKey: 'restart_cta',
      ),
    ]),
    NarratorGuideDefinition(nodeId: 'world_map', steps: [
      NarratorGuideStep(
        script:
            "This is your world. It thrives when you do — every habit you keep keeps it alive.",
        targetKey: 'map_body',
      ),
      NarratorGuideStep(
        script: "Your realm, your rules. Explore as you grow.",
        targetKey: 'map_header',
      ),
    ]),
    NarratorGuideDefinition(nodeId: 'leveling', steps: [
      NarratorGuideStep(
        script:
            "Every completed habit feeds this — your level is the sum of your days.",
        targetKey: 'level_header',
      ),
      NarratorGuideStep(
        script: "Watch it fill. XP is just proof you showed up.",
        targetKey: 'level_bar',
      ),
    ]),
    NarratorGuideDefinition(nodeId: 'future_self', steps: [
      NarratorGuideStep(
        script:
            "This is who you're becoming. Give them a face, a name, a reason.",
        targetKey: 'studio_header',
      ),
      NarratorGuideStep(
        script: "Press this when the vision is ready — I'll hold you to it.",
        targetKey: 'generate_button',
      ),
    ]),
    NarratorGuideDefinition(nodeId: 'challenges', steps: [
      NarratorGuideStep(
        script: "A public challenge is a promise with witnesses. Join one.",
        targetKey: 'join_fab',
      ),
      NarratorGuideStep(
        script:
            "Compete on progress, not perfection — the leaderboard knows.",
        targetKey: 'challenge_list',
      ),
    ]),
    NarratorGuideDefinition(nodeId: 'all_tribes', steps: [
      NarratorGuideStep(
        script: "These are your people — tribes sorted by how you grow.",
        targetKey: 'tribes_header',
      ),
      NarratorGuideStep(
        script:
            "Pick one. You can switch anytime; belonging should feel chosen.",
        targetKey: 'tribe_list',
      ),
    ]),
    NarratorGuideDefinition(nodeId: 'tribe_lobby', steps: [
      NarratorGuideStep(
        script:
            "Your circle, your partners, your tribe's pulse — it all lives here.",
        targetKey: 'member_list',
      ),
      NarratorGuideStep(
        script:
            "Jump to challenges, or find a new tribe — the door's always open.",
        targetKey: 'lobby_actions',
      ),
    ]),
  ];

  static NarratorGuideDefinition? forNode(String nodeId) {
    for (final d in all) {
      if (d.nodeId == nodeId) return d;
    }
    return null;
  }
}
```

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/features/narrator/domain/services/narrator_guide_registry_test.dart`
Expected: PASS (all 5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/narrator/domain/services/narrator_guide_registry.dart test/features/narrator/domain/services/narrator_guide_registry_test.dart
git commit -m "feat(narrator): pure narrator guide registry (9 nodes, spotlight target keys)"
```

---

## Task 3: LocalSettingsRepository — narrator guide flags + migration

Renames the seen-flag API to `hasSeenNarratorGuide_*`, adds the idempotent migration, retargets the legacy companion migration, and updates the two remaining consumers (the tutorials controller, kept temporarily, and the two test fakes) so the tree stays green.

**Files:**
- Modify: `lib/features/onboarding/data/repositories/local_settings_repository.dart`
- Modify: `lib/features/tutorials/presentation/providers/node_guide_controller.dart`
- Test: `test/features/onboarding/data/repositories/visited_flags_migration_test.dart` (create — this test file may exist; if it does, extend it)
- Modify: `test/features/settings/presentation/screens/settings_screen_test.dart` (fake method names only)
- Modify: `test/features/tutorials/presentation/node_guide_host_test.dart` (fake method names only)

- [ ] **Step 1: Write the failing test**

Check whether `test/features/onboarding/data/repositories/visited_flags_migration_test.dart` exists. If it exists, append these tests to the existing `main()`; otherwise create it:

```dart
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('migrateNarratorGuideFlags', () {
    test('migrates hasSeenNodeGuide_* to hasSeenNarratorGuide_*', () async {
      SharedPreferences.setMockInitialValues({
        'hasSeenNodeGuide_timeline': true,
        'hasSeenNodeGuide_world_map': true,
      });
      final repo = LocalSettingsRepository();
      await repo.init();
      await repo.migrateNarratorGuideFlags();

      expect(await repo.getHasSeenNarratorGuide('timeline'), true);
      expect(await repo.getHasSeenNarratorGuide('world_map'), true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasSeenNodeGuide_timeline'), isNull);
      expect(prefs.getBool('hasSeenNodeGuide_world_map'), isNull);
    });

    test('never overwrites existing narrator flags', () async {
      SharedPreferences.setMockInitialValues({
        'hasSeenNodeGuide_challenges': true,
        'hasSeenNarratorGuide_challenges': false, // user deliberately reset
      });
      final repo = LocalSettingsRepository();
      await repo.init();
      await repo.migrateNarratorGuideFlags();

      expect(await repo.getHasSeenNarratorGuide('challenges'), false);
    });

    test('writes nothing when no legacy keys exist', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = LocalSettingsRepository();
      await repo.init();
      await repo.migrateNarratorGuideFlags();
      expect(await repo.getHasSeenNarratorGuide('timeline'), false);
    });
  });

  group('migrateVisitedFlags (retargeted)', () {
    test('maps companion_visited_* to narrator guide flags', () async {
      SharedPreferences.setMockInitialValues({
        'companion_visited_/timeline': true,
        'companion_visited_/challenges': true,
      });
      final repo = LocalSettingsRepository();
      await repo.init();
      await repo.migrateVisitedFlags();

      expect(await repo.getHasSeenNarratorGuide('timeline'), true);
      expect(await repo.getHasSeenNarratorGuide('challenges'), true);
    });

    test('idempotent: second run changes nothing', () async {
      SharedPreferences.setMockInitialValues({
        'companion_visited_/timeline': true,
      });
      final repo = LocalSettingsRepository();
      await repo.init();
      await repo.migrateVisitedFlags();
      final prefs = await SharedPreferences.getInstance();
      final keysAfterFirstRun = prefs.getKeys().toSet();
      await repo.migrateVisitedFlags();
      expect(prefs.getKeys().toSet(), keysAfterFirstRun);
    });
  });

  group('resetTutorials', () {
    test('clears narrator guide flags, not other prefs', () async {
      SharedPreferences.setMockInitialValues({
        'hasSeenNarratorGuide_timeline': true,
        'hasSeenNarratorGuide_leveling': true,
        'tutorialsEnabled': true,
      });
      final repo = LocalSettingsRepository();
      await repo.init();
      await repo.resetTutorials();

      expect(await repo.getHasSeenNarratorGuide('timeline'), false);
      expect(await repo.getHasSeenNarratorGuide('leveling'), false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('tutorialsEnabled'), true);
    });
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/onboarding/data/repositories/visited_flags_migration_test.dart`
Expected: FAIL — `getHasSeenNarratorGuide` not defined (and `migrateNarratorGuideFlags` missing).

- [ ] **Step 3: Implement the repository changes**

In `lib/features/onboarding/data/repositories/local_settings_repository.dart`, replace the node-guide flag block (lines 105–111):

```dart
  Future<bool> getHasSeenNarratorGuide(String nodeId) async {
    return _getBool('hasSeenNarratorGuide_$nodeId');
  }

  Future<void> setHasSeenNarratorGuide(String nodeId) async {
    await _setBool('hasSeenNarratorGuide_$nodeId', true);
  }
```

Replace `resetTutorials()` (lines 124–130) so it clears the new prefix:

```dart
  /// Clears all per-node "seen" flags so guides re-appear next visit.
  Future<void> resetTutorials() async {
    final keys = _getKeys().where((k) => k.startsWith('hasSeenNarratorGuide_'));
    for (final key in keys) {
      await _remove(key);
    }
  }
```

Replace `migrateVisitedFlags()` (lines 209–235) to write narrator flags, and add `migrateNarratorGuideFlags()` right after it:

```dart
  /// Migrates legacy companion visited flags into the narrator-guide system.
  /// Idempotent: only migrates keys that exist; never overwrites already-seen
  /// guide flags. Legacy flags for retired nodes (e.g. the blueprints page's
  /// `/discover`) are dropped, not migrated.
  Future<void> migrateVisitedFlags() async {
    final keys = _getKeys().where((k) => k.startsWith('companion_visited_'));
    if (keys.isEmpty) return;

    const routeToNode = {
      '/timeline': 'timeline',
      '/world-map': 'world_map',
      '/profile/reflections': 'coach',
      '/challenges': 'challenges',
    };

    for (final key in keys) {
      final route = key.substring('companion_visited_'.length);
      final nodeId = routeToNode[route];
      final keyWasSeen = _getBool(key);
      final nodeAlreadySeen = nodeId != null &&
          _getBool('hasSeenNarratorGuide_$nodeId');
      if (nodeId != null && keyWasSeen && !nodeAlreadySeen) {
        await _setBool('hasSeenNarratorGuide_$nodeId', true);
      }
      await _remove(key);
    }
  }

  /// Migrates the SP-A node-guide seen flags (`hasSeenNodeGuide_*`) to the
  /// narrator-guide keys (`hasSeenNarratorGuide_*`). Idempotent: only copies
  /// keys that exist; never overwrites an already-seen narrator flag.
  Future<void> migrateNarratorGuideFlags() async {
    final keys = _getKeys().where((k) => k.startsWith('hasSeenNodeGuide_'));
    for (final key in keys) {
      final nodeId = key.substring('hasSeenNodeGuide_'.length);
      final keyWasSeen = _getBool(key);
      final nodeAlreadySeen = _getBool('hasSeenNarratorGuide_$nodeId');
      if (keyWasSeen && !nodeAlreadySeen) {
        await _setBool('hasSeenNarratorGuide_$nodeId', true);
      }
      await _remove(key);
    }
  }
```

Note: `/profile/reflections` maps to `'coach'` above — the companion migration writes `hasSeenNarratorGuide_coach`, a key no node reads anymore. That is intentional and harmless (the key is simply never consulted); do NOT add a `coach` node.

- [ ] **Step 4: Update the two remaining consumers of the old API**

In `lib/features/tutorials/presentation/providers/node_guide_controller.dart` (kept temporarily until Task 13 deletes it), swap the two repo calls:

```dart
  Future<bool> shouldShow(String nodeId) async {
    if (!_repo.isTutorialsEnabled()) return false;
    return !(await _repo.getHasSeenNarratorGuide(nodeId));
  }

  Future<void> markSeen(String nodeId) async {
    await _repo.setHasSeenNarratorGuide(nodeId);
  }
```

In `test/features/settings/presentation/screens/settings_screen_test.dart`, rename the fake's methods `getHasSeenNodeGuide` → `getHasSeenNarratorGuide` and `setHasSeenNodeGuide` → `setHasSeenNarratorGuide` (lines ~126 and ~129).

In `test/features/tutorials/presentation/node_guide_host_test.dart`, rename the fake's overrides the same way (lines 18 and 21).

- [ ] **Step 5: Run tests to verify they pass**

Run:
- `flutter test test/features/onboarding/data/repositories/visited_flags_migration_test.dart` — PASS
- `flutter test test/features/tutorials/presentation/node_guide_host_test.dart` — PASS
- `flutter test test/features/settings/presentation/screens/settings_screen_test.dart` — PASS
- `flutter analyze` — clean

- [ ] **Step 6: Commit**

```bash
git add lib/features/onboarding/data/repositories/local_settings_repository.dart lib/features/tutorials/presentation/providers/node_guide_controller.dart test/features/onboarding/data/repositories/visited_flags_migration_test.dart test/features/settings/presentation/screens/settings_screen_test.dart test/features/tutorials/presentation/node_guide_host_test.dart
git commit -m "feat(narrator): narrator-guide seen flags + idempotent migration from node-guide keys"
```

---

## Task 4: NarratorGuideController (provider)

**Files:**
- Create: `lib/features/narrator/presentation/providers/narrator_guide_controller.dart`
- Test: `test/features/narrator/presentation/providers/narrator_guide_controller_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:emerge_app/features/narrator/presentation/providers/narrator_guide_controller.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettings extends LocalSettingsRepository {
  _FakeSettings({required this.tutorialsEnabled, this.seen = const {}});
  final bool tutorialsEnabled;
  final Set<String> seen;
  final Set<String> recorded = {};

  @override
  bool isTutorialsEnabled() => tutorialsEnabled;

  @override
  Future<bool> getHasSeenNarratorGuide(String nodeId) async =>
      seen.contains(nodeId);

  @override
  Future<void> setHasSeenNarratorGuide(String nodeId) async {
    recorded.add(nodeId);
  }
}

void main() {
  ProviderContainer container(_FakeSettings settings) => ProviderContainer(
        overrides: [
          localSettingsRepositoryProvider.overrideWithValue(settings),
        ],
      );

  test('shouldShow is true on first visit when tutorials are enabled',
      () async {
    final c = container(_FakeSettings(tutorialsEnabled: true));
    addTearDown(c.dispose);
    final controller = c.read(narratorGuideControllerProvider);
    expect(await controller.shouldShow('timeline'), true);
  });

  test('shouldShow is false when tutorials are disabled', () async {
    final c = container(_FakeSettings(tutorialsEnabled: false));
    addTearDown(c.dispose);
    final controller = c.read(narratorGuideControllerProvider);
    expect(await controller.shouldShow('timeline'), false);
  });

  test('shouldShow is false after markSeen', () async {
    final c = container(_FakeSettings(tutorialsEnabled: true));
    addTearDown(c.dispose);
    final controller = c.read(narratorGuideControllerProvider);
    await controller.markSeen('timeline');
    expect(await controller.shouldShow('timeline'), false);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/narrator/presentation/providers/narrator_guide_controller_test.dart`
Expected: FAIL — import not found.

- [ ] **Step 3: Implement the controller**

Create `lib/features/narrator/presentation/providers/narrator_guide_controller.dart`:

```dart
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'narrator_guide_controller.g.dart';

/// Stateless controller for the narrator-guide tutorial system.
///
/// Screens ask [shouldShow] on first frame and call [markSeen] when the
/// guide is dismissed. Reads the existing `tutorialsEnabled` toggle so the
/// Settings switch governs all guides app-wide.
@Riverpod(keepAlive: true)
NarratorGuideController narratorGuideController(Ref ref) {
  return NarratorGuideController(ref: ref);
}

class NarratorGuideController {
  NarratorGuideController({required this.ref});
  final Ref ref;

  LocalSettingsRepository get _repo => ref.read(localSettingsRepositoryProvider);

  Future<bool> shouldShow(String nodeId) async {
    if (!_repo.isTutorialsEnabled()) return false;
    return !(await _repo.getHasSeenNarratorGuide(nodeId));
  }

  Future<void> markSeen(String nodeId) async {
    await _repo.setHasSeenNarratorGuide(nodeId);
  }
}
```

- [ ] **Step 4: Generate the `.g.dart` and run tests**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Then: `flutter test test/features/narrator/presentation/providers/narrator_guide_controller_test.dart`
Expected: PASS (3 tests). `flutter analyze` clean.

- [ ] **Step 5: Commit**

```bash
git add lib/features/narrator/presentation/providers/narrator_guide_controller.dart lib/features/narrator/presentation/providers/narrator_guide_controller.g.dart test/features/narrator/presentation/providers/narrator_guide_controller_test.dart
git commit -m "feat(narrator): NarratorGuideController provider honoring tutorialsEnabled + seen flags"
```

---

## Task 5: SpotlightPainter + NarratorGuideCard

**Files:**
- Create: `lib/features/narrator/presentation/widgets/spotlight_painter.dart`
- Create: `lib/features/narrator/presentation/widgets/narrator_guide_card.dart`

- [ ] **Step 1: Implement `SpotlightPainter`**

Create `lib/features/narrator/presentation/widgets/spotlight_painter.dart`:

```dart
import 'package:flutter/material.dart';

/// Dims the whole screen except a rounded-rect "spotlight hole" around the
/// section a narrator guide step explains. No hole → full dim (card-only
/// step). The hole rect must be in the same coordinate space as the painter
/// (global/screen space — `RenderBox.localToGlobal`).
class SpotlightPainter extends CustomPainter {
  final Rect? holeRect;
  final double cornerRadius;
  final Color scrimColor;

  const SpotlightPainter({
    this.holeRect,
    this.cornerRadius = 16,
    this.scrimColor = const Color(0x99000000),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final hole = holeRect;
    final hasHole = hole != null && !hole.isEmpty && bounds.overlaps(hole);
    var path = Path()..addRect(bounds);
    if (hasHole) {
      final holePath = Path()
        ..addRRect(RRect.fromRectAndRadius(hole, Radius.circular(cornerRadius)));
      path = Path.combine(PathOperation.difference, path, holePath);
    }
    canvas.drawPath(path, Paint()..color = scrimColor);
    if (hasHole) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          hole.inflate(2),
          Radius.circular(cornerRadius + 2),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(SpotlightPainter oldDelegate) =>
      oldDelegate.holeRect != holeRect ||
      oldDelegate.cornerRadius != cornerRadius ||
      oldDelegate.scrimColor != scrimColor;
}
```

- [ ] **Step 2: Implement `NarratorGuideCard`**

Create `lib/features/narrator/presentation/widgets/narrator_guide_card.dart`:

```dart
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/presentation/widgets/typewriter_text.dart';
import 'package:flutter/material.dart';

/// Bottom narrator card for a first-visit guide step: the script types out,
/// then the advance button enables. Skip (✕) is always available.
class NarratorGuideCard extends StatefulWidget {
  final String script;
  final int stepIndex;
  final int stepCount;
  final VoidCallback onAdvance;
  final VoidCallback onSkip;

  const NarratorGuideCard({
    super.key,
    required this.script,
    required this.stepIndex,
    required this.stepCount,
    required this.onAdvance,
    required this.onSkip,
  });

  @override
  State<NarratorGuideCard> createState() => _NarratorGuideCardState();
}

class _NarratorGuideCardState extends State<NarratorGuideCard> {
  bool _typingDone = false;
  bool get _isLast => widget.stepIndex == widget.stepCount - 1;

  @override
  void didUpdateWidget(NarratorGuideCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.script != widget.script) _typingDone = false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmergeColors.violet.withValues(alpha: 0.5)),
        gradient: LinearGradient(
          colors: [
            EmergeColors.violet.withValues(alpha: 0.28),
            const Color(0xFF12122A).withValues(alpha: 0.92),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: EmergeColors.violet.withValues(alpha: 0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _GuideAvatar(),
              const SizedBox(width: 8),
              const Text(
                'NARRATOR',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.bold,
                  color: EmergeColors.teal,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.stepIndex + 1}/${widget.stepCount}',
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
              IconButton(
                onPressed: widget.onSkip,
                icon: const Icon(Icons.close, size: 18, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TypewriterText(
            text: widget.script,
            onComplete: () => setState(() => _typingDone = true),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _typingDone ? widget.onAdvance : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _typingDone
                      ? EmergeColors.teal
                      : Colors.white.withValues(alpha: 0.08),
                ),
                child: Text(
                  _isLast ? 'Got it' : 'Next →',
                  style: TextStyle(
                    color: _typingDone ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideAvatar extends StatelessWidget {
  const _GuideAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [EmergeColors.violet, EmergeColors.teal],
        ),
      ),
      child: const Center(
        child: Text('✦', style: TextStyle(fontSize: 12, color: Colors.white)),
      ),
    );
  }
}
```

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/features/narrator/presentation/widgets/spotlight_painter.dart lib/features/narrator/presentation/widgets/narrator_guide_card.dart`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/narrator/presentation/widgets/spotlight_painter.dart lib/features/narrator/presentation/widgets/narrator_guide_card.dart
git commit -m "feat(narrator): spotlight hole-punch painter and typed guide card"
```

---

## Task 6: NarratorGuideHost + widget test

**Files:**
- Create: `lib/features/narrator/presentation/widgets/narrator_guide_host.dart`
- Test: `test/features/narrator/presentation/widgets/narrator_guide_host_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:emerge_app/features/narrator/presentation/providers/narrator_guide_controller.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_guide_host.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/spotlight_painter.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettings extends LocalSettingsRepository {
  _FakeSettings({required this.tutorialsEnabled, this.seen = const {}});
  final bool tutorialsEnabled;
  final Set<String> seen;
  final Set<String> recorded = {};

  @override
  bool isTutorialsEnabled() => tutorialsEnabled;

  @override
  Future<bool> getHasSeenNarratorGuide(String nodeId) async =>
      seen.contains(nodeId);

  @override
  Future<void> setHasSeenNarratorGuide(String nodeId) async {
    recorded.add(nodeId);
  }
}

void main() {
  final fabKey = GlobalKey();

  Widget host({required _FakeSettings settings}) {
    return ProviderScope(
      overrides: [
        localSettingsRepositoryProvider.overrideWithValue(settings),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: NarratorGuideHost(
            nodeId: 'habit_create',
            targets: {'name_field': fabKey},
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(key: fabKey, width: 100, height: 40, child: const Text('field')),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the guide on first visit when tutorials are enabled',
      (tester) async {
    await tester.pumpWidget(host(settings: _FakeSettings(tutorialsEnabled: true)));
    await tester.pump(const Duration(milliseconds: 400)); // post-frame + show
    expect(find.textContaining('Start here'), findsOneWidget);
    expect(find.text('field'), findsOneWidget);
  });

  testWidgets('does not show when tutorials are disabled', (tester) async {
    await tester.pumpWidget(host(settings: _FakeSettings(tutorialsEnabled: false)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Start here'), findsNothing);
  });

  testWidgets('does not show when the node was already seen', (tester) async {
    await tester.pumpWidget(
      host(settings: _FakeSettings(tutorialsEnabled: true, seen: {'habit_create'})),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Start here'), findsNothing);
  });

  testWidgets('Next advances to the final step and Got it marks seen',
      (tester) async {
    final settings = _FakeSettings(tutorialsEnabled: true);
    await tester.pumpWidget(host(settings: settings));
    await tester.pump(const Duration(milliseconds: 400));
    // Let the first script finish typing.
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Next →'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('press this'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Got it'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Start here'), findsNothing);
    expect(settings.recorded, contains('habit_create'));
  });

  testWidgets('Skip dismisses and marks seen', (tester) async {
    final settings = _FakeSettings(tutorialsEnabled: true);
    await tester.pumpWidget(host(settings: settings));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Start here'), findsNothing);
    expect(settings.recorded, contains('habit_create'));
  });

  testWidgets('the spotlight painter is present with a hole rect',
      (tester) async {
    await tester.pumpWidget(host(settings: _FakeSettings(tutorialsEnabled: true)));
    await tester.pump(const Duration(milliseconds: 400));
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .whereType<SpotlightPainter>()
        .first;
    expect(painter.holeRect, isNotNull);
  });
}
```

Note: never use `pumpAndSettle` in this file — the guide card's caret blinks forever.

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/narrator/presentation/widgets/narrator_guide_host_test.dart`
Expected: FAIL — import not found.

- [ ] **Step 3: Implement the host**

Create `lib/features/narrator/presentation/widgets/narrator_guide_host.dart`:

```dart
import 'package:emerge_app/features/narrator/domain/services/narrator_guide_registry.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_guide_controller.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_guide_card.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/spotlight_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps a screen and shows its first-visit narrator guide.
///
/// [targets] maps registry `targetKey`s to [GlobalKey]s of the widgets the
/// spotlight should highlight. Rects are resolved via
/// `RenderBox.localToGlobal` (the overlay Stack sits in the same coordinate
/// space as the screen), so no route/Overlay indirection is needed. The hole
/// glides between steps (200ms); scrolls of the target's scrollable re-resolve
/// rects instantly. A target that is unmounted or off-screen yields no hole —
/// the card-only step still advances.
class NarratorGuideHost extends ConsumerStatefulWidget {
  final String nodeId;
  final Map<String, GlobalKey> targets;
  final Widget child;

  const NarratorGuideHost({
    super.key,
    required this.nodeId,
    required this.targets,
    required this.child,
  });

  @override
  ConsumerState<NarratorGuideHost> createState() => _NarratorGuideHostState();
}

class _NarratorGuideHostState extends ConsumerState<NarratorGuideHost> {
  bool _visible = false;
  int _step = 0;
  bool _animateHole = false;
  final List<ScrollPosition> _scrollPositions = [];

  List<NarratorGuideStep> get _steps =>
      NarratorGuideRegistry.forNode(widget.nodeId)?.steps ?? const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  Future<void> _maybeShow() async {
    final controller = ref.read(narratorGuideControllerProvider);
    if (await controller.shouldShow(widget.nodeId) && mounted) {
      setState(() => _visible = true);
      _attachScrollListeners();
    }
  }

  void _attachScrollListeners() {
    for (final key in widget.targets.values) {
      final ctx = key.currentContext;
      if (ctx == null) continue;
      final position = Scrollable.maybeOf(ctx)?.position;
      if (position != null && !_scrollPositions.contains(position)) {
        _scrollPositions.add(position);
        position.addListener(_onScroll);
      }
    }
  }

  void _onScroll() => setState(() {}); // re-resolve hole rect next paint

  @override
  void dispose() {
    for (final position in _scrollPositions) {
      position.removeListener(_onScroll);
    }
    super.dispose();
  }

  Rect? _rectFor(String targetKey) {
    final ctx = widget.targets[targetKey]?.currentContext;
    final box = ctx?.findRenderObject();
    if (box is! RenderBox || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _advance() {
    if (_step < _steps.length - 1) {
      setState(() {
        _step++;
        _animateHole = true;
      });
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await ref.read(narratorGuideControllerProvider).markSeen(widget.nodeId);
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final step = _visible && _step < steps.length ? steps[_step] : null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Stack(
      children: [
        widget.child,
        if (step != null)
          Positioned.fill(
            child: TweenAnimationBuilder<Rect?>(
              tween: _RectTween(
                begin: _step == 0 ? null : _rectFor(steps[_step - 1].targetKey),
                end: _rectFor(step.targetKey),
              ),
              duration: _animateHole && !reduceMotion
                  ? const Duration(milliseconds: 200)
                  : Duration.zero,
              curve: Curves.easeInOut,
              onEnd: () {
                if (_animateHole) setState(() => _animateHole = false);
              },
              builder: (context, rect, _) =>
                  CustomPaint(painter: SpotlightPainter(holeRect: rect)),
            ),
          ),
        if (step != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24 + MediaQuery.paddingOf(context).bottom,
            child: NarratorGuideCard(
              script: step.script,
              stepIndex: _step,
              stepCount: steps.length,
              onAdvance: _advance,
              onSkip: _finish,
            ),
          ),
      ],
    );
  }
}

/// Null-safe rect tween: first step (null begin) jumps straight to the hole;
/// a vanished target (null end) hides the hole without animating.
class _RectTween extends Tween<Rect?> {
  _RectTween({required Rect? begin, required Rect? end})
      : super(begin: begin, end: end);

  @override
  Rect? lerp(double t) {
    if (begin == null) return end;
    if (end == null) return null;
    return Rect.lerp(begin!, end!, t);
  }
}
```

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/features/narrator/presentation/widgets/narrator_guide_host_test.dart`
Expected: PASS (6 tests). `flutter analyze` clean.

- [ ] **Step 5: Commit**

```bash
git add lib/features/narrator/presentation/widgets/narrator_guide_host.dart test/features/narrator/presentation/widgets/narrator_guide_host_test.dart
git commit -m "feat(narrator): NarratorGuideHost overlay with scroll-aware spotlight and typed steps"
```

---

## Task 7: CardLineResolver (pure day-status line)

**Files:**
- Create: `lib/features/narrator/domain/services/card_line_resolver.dart`
- Test: `test/features/narrator/domain/services/card_line_resolver_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/services/card_line_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const day = DayStatus(
    completed: 1,
    total: 3,
    streak: 4,
    firstIncompleteName: 'Read 10 pages',
  );

  group('dayStatusLine', () {
    test('empty day invites the first habit', () {
      expect(
        dayStatusLine(const DayStatus(completed: 0, total: 0, streak: 0)),
        'This is where your day takes shape. Add a habit and I\'ll keep watch.',
      );
    });

    test('remaining habits name the first incomplete one', () {
      expect(
        dayStatusLine(day),
        '2 left today — start with Read 10 pages.',
      );
    });

    test('all done with a streak names the streak', () {
      expect(
        dayStatusLine(const DayStatus(completed: 3, total: 3, streak: 4)),
        'All done for today. 4-day streak is starting to hold you.',
      );
    });

    test('all done without a streak stays simple', () {
      expect(
        dayStatusLine(const DayStatus(completed: 3, total: 3, streak: 0)),
        'All done for today. That\'s how momentum starts.',
      );
    });
  });

  group('resolveCardLine', () {
    test('pending milestone line wins', () {
      const pending = GenericLine('You are on fire.');
      final line = resolveCardLine(
        pendingLine: pending,
        insightText: 'Some old insight',
        day: day,
      );
      expect(line, same(pending));
    });

    test('insight text is used when nothing is pending', () {
      final line = resolveCardLine(
        pendingLine: null,
        insightText: 'Your best day is Thursday.',
        day: day,
      );
      expect(line, const GenericLine('Your best day is Thursday.'));
    });

    test('day status is the fallback', () {
      final line = resolveCardLine(
        pendingLine: null,
        insightText: null,
        day: day,
      );
      expect(line, const GenericLine('2 left today — start with Read 10 pages.'));
    });
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/narrator/domain/services/card_line_resolver_test.dart`
Expected: FAIL — import not found.

- [ ] **Step 3: Implement the resolver**

Create `lib/features/narrator/domain/services/card_line_resolver.dart`:

```dart
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';

/// Snapshot of the user's day used to compose the narrator card's line.
class DayStatus {
  final int completed;
  final int total;
  final int streak;
  final String? firstIncompleteName;

  const DayStatus({
    required this.completed,
    required this.total,
    required this.streak,
    this.firstIncompleteName,
  });
}

/// The narrator's no-LLM day-status line. Pure — unit-tested directly.
String dayStatusLine(DayStatus day) {
  if (day.total == 0) {
    return 'This is where your day takes shape. Add a habit and I\'ll keep watch.';
  }
  if (day.completed >= day.total) {
    if (day.streak > 0) {
      return 'All done for today. $streak-day streak is starting to hold you.';
    }
    return 'All done for today. That\'s how momentum starts.';
  }
  final remaining = day.total - day.completed;
  final name = day.firstIncompleteName;
  if (name != null && name.isNotEmpty) {
    return '$remaining left today — start with $name.';
  }
  return '$remaining left today.';
}

/// Day Card line priority: pending milestone line → latest insight → day
/// status. Pure — the widget only wires providers into this.
NarratorLine? resolveCardLine({
  required NarratorLine? pendingLine,
  required String? insightText,
  required DayStatus day,
}) {
  if (pendingLine != null) return pendingLine;
  if (insightText != null && insightText.isNotEmpty) {
    return GenericLine(insightText);
  }
  return GenericLine(dayStatusLine(day));
}
```

Note: `GenericLine` must be a `const`-constructible class for the `same(pending)` test — it is (`NarratorLine` sealed, `GenericLine` const, `narrator_line.dart:5-24`).

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/features/narrator/domain/services/card_line_resolver_test.dart`
Expected: PASS (7 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/narrator/domain/services/card_line_resolver.dart test/features/narrator/domain/services/card_line_resolver_test.dart
git commit -m "feat(narrator): pure day-status line resolver for the Day Card"
```

---

## Task 8: NarratorCard — the Day Card

**Files:**
- Create: `lib/features/narrator/presentation/widgets/narrator_card.dart`
- Modify: `lib/features/narrator/presentation/providers/narrator_providers.dart` (add `NarratorCardDismissed` + `NarratorAskFocus` notifiers)
- Test: `test/features/narrator/presentation/widgets/narrator_card_test.dart`

- [ ] **Step 1: Add the two session notifiers**

Append to `lib/features/narrator/presentation/providers/narrator_providers.dart` (before the `part` directive's file end — anywhere after the last provider):

```dart
/// Session-scoped: the Day Card has been dismissed for this app session.
@riverpod
class NarratorCardDismissed extends _$NarratorCardDismissed {
  @override
  bool build() => false;

  void dismiss() => state = true;
  void restore() => state = false;
}

/// Session-scoped: bump to ask the Day Card to expand and focus its ask
/// field (driven by the timeline header avatar tap).
@riverpod
class NarratorAskFocus extends _$NarratorAskFocus {
  @override
  int build() => 0;

  void request() => state++;
}
```

- [ ] **Step 2: Write the failing widget test**

```dart
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_card.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Habit _habit(String title) => Habit(
      id: title,
      userId: 'u',
      title: title,
      cue: '',
      routine: '',
      reward: '',
      createdAt: DateTime.now(),
      difficulty: HabitDifficulty.medium,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> container({List<Habit> habits = const []}) async {
    SharedPreferences.setMockInitialValues({});
    return ProviderContainer(
      overrides: [
        habitsProvider.overrideWith((ref) => Stream.value(habits)),
        userStatsStreamProvider.overrideWith(
          (ref) => Stream.value(UserProfile(uid: 'u')),
        ),
        latestNarratorInsightProvider.overrideWith((ref) async => null),
        isPremiumProvider.overrideWith((ref) async => false),
      ],
    );
  }

  Future<void> pumpCard(WidgetTester tester, ProviderContainer c) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(
          home: Scaffold(body: NarratorCard()),
        ),
      ),
    );
    // Let the typed line finish (no pumpAndSettle — blinking caret).
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('shows the day-status line when nothing is pending',
      (tester) async {
    final c = await container();
    addTearDown(c.dispose);
    await pumpCard(tester, c);
    expect(
      find.textContaining('Add a habit'),
      findsOneWidget,
    );
  });

  testWidgets('shows remaining-habits chip with a non-empty day',
      (tester) async {
    final c = await container(habits: [_habit('Read'), _habit('Run')]);
    addTearDown(c.dispose);
    await pumpCard(tester, c);
    expect(find.textContaining('left today'), findsWidgets);
    expect(find.text('2 left today'), findsOneWidget);
  });

  testWidgets('dismiss hides the card for the session', (tester) async {
    final c = await container();
    addTearDown(c.dispose);
    await pumpCard(tester, c);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.textContaining('Add a habit'), findsNothing);
  });

  testWidgets('ask chip expands, free ask consumes quota and types a reply',
      (tester) async {
    SharedPreferences.setMockInitialValues({'coach_asks_2026-08-04': 0});
    final c = await container();
    addTearDown(c.dispose);
    await pumpCard(tester, c);
    await tester.tap(find.text('✎ Ask the narrator'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'hi');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2)); // quota + typed reply
    // 'hi'.length % 5 == 2 → pool index 2
    expect(
      find.textContaining("One miss is a slip, not a fall"),
      findsOneWidget,
    );
  });

  testWidgets('exhausted quota opens the premium limit dialog',
      (tester) async {
    SharedPreferences.setMockInitialValues({'coach_asks_2026-08-04': 3});
    final c = await container();
    addTearDown(c.dispose);
    await pumpCard(tester, c);
    await tester.tap(find.text('✎ Ask the narrator'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'hi');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.text("You've used your 3 free coach asks today"), findsOneWidget);
  });
}
```

Notes:
- The `coach_asks_2026-08-04` key uses the fixed date because `CoachAskQuota.dateKeyFor(DateTime.now())` produces `yyyy-MM-dd`; the widget test cannot freeze `DateTime.now()`, so the exhausted test seeds `used = 3` for *today's* key instead of a hardcoded date. Replace the literal with `'coach_asks_${CoachAskQuota.dateKeyFor(DateTime.now())}'` (import `coach_ask_quota.dart`) — the hardcoded `2026-08-04` here is only correct on the date the plan runs; use the computed key in the actual test.
- `pumpAndSettle` is only safe in the last test because the premium dialog has no blinking caret.

- [ ] **Step 3: Run it to verify it fails**

Run: `flutter test test/features/narrator/presentation/widgets/narrator_card_test.dart`
Expected: FAIL — `NarratorCard` not defined.

- [ ] **Step 4: Implement `NarratorCard`**

Create `lib/features/narrator/presentation/widgets/narrator_card.dart`:

```dart
import 'package:emerge_app/core/presentation/widgets/glassmorphism_card.dart';
import 'package:emerge_app/core/presentation/widgets/typewriter_text.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/ai/data/services/groq_ai_service.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/monetization/presentation/providers/coach_ask_quota_provider.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/monetization/presentation/widgets/premium_limit_dialog.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/services/card_line_resolver.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Day Card — the narrator's always-visible timeline surface.
///
/// Typed day-line (pending milestone → latest insight → computed day status),
/// glanceable status chips (streak, remaining today), and an inline coach
/// ask that reuses the premium quota + Groq plumbing that used to live in
/// NarratorSheet.
class NarratorCard extends ConsumerStatefulWidget {
  const NarratorCard({super.key});

  @override
  ConsumerState<NarratorCard> createState() => _NarratorCardState();
}

class _NarratorCardState extends ConsumerState<NarratorCard> {
  final GlobalKey _rootKey = GlobalKey();
  final TextEditingController _askController = TextEditingController();
  final FocusNode _askFocus = FocusNode();
  bool _askOpen = false;
  bool _isAsking = false;
  NarratorLine? _replyLine;

  static const List<String> _genericAskPool = [
    'Small steps compound. Pick the tiniest version of this and do it now.',
    'What would your future self thank you for today? Start there.',
    "One miss is a slip, not a fall. What's the smallest next move?",
    'Consistency beats intensity. Can you make this 2 minutes easier?',
    'Your habits are votes for the person you are becoming. Cast one today.',
  ];

  @override
  void initState() {
    super.initState();
    _askFocus.addListener(_onAskFocusChanged);
  }

  void _onAskFocusChanged() {
    if (_askFocus.hasFocus && !_askOpen) setState(() => _askOpen = true);
  }

  @override
  void dispose() {
    _askController.dispose();
    _askFocus.dispose();
    super.dispose();
  }

  void _openAskFromAvatar() {
    setState(() => _askOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        _rootKey.currentContext!,
        duration: const Duration(milliseconds: 200),
      );
      _askFocus.requestFocus();
    });
  }

  Future<void> _submitAsk(String raw) async {
    final question = raw.trim();
    if (question.isEmpty || _isAsking) return;
    // Set synchronously BEFORE the first await so concurrent submits are
    // serialized and the button shows the busy state during quota load.
    setState(() => _isAsking = true);
    try {
      final quotaCtrl = ref.read(coachAskQuotaControllerProvider.notifier);
      final quota = await ref.read(coachAskQuotaControllerProvider.future);
      if (!quota.canAsk) {
        if (mounted) {
          showPremiumLimitDialog(context, limitType: PremiumLimitType.coachAsk);
        }
        return;
      }
      final isPremium = ref.read(isPremiumProvider).value ?? false;
      final NarratorLine line;
      if (isPremium) {
        // Ground the LLM in the user's real progress so the DATA-GROUNDED
        // badge is honest. Empty context when the profile hasn't loaded.
        final profile = ref.read(userStatsStreamProvider).value;
        final context = profile == null
            ? ''
            : 'Level ${profile.avatarStats.level}, '
                '${profile.avatarStats.totalXp} total XP, '
                'archetype ${profile.archetype.name}, '
                'streak ${profile.avatarStats.streak}';
        final groq = GroqAiService();
        final advice = await groq.getCoachAdvice(context, question);
        line = PersonalLine(text: advice, dataBasis: 'groq_coach');
      } else {
        line = GenericLine(
          _genericAskPool[question.length % _genericAskPool.length],
        );
      }
      await quotaCtrl.consume();
      if (mounted) {
        setState(() {
          _replyLine = line;
          _askController.clear();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _replyLine = const GenericLine("I'm here — keep going."));
      }
    } finally {
      if (mounted) setState(() => _isAsking = false);
    }
  }

  String _quotaHint() {
    final isPremium = ref.watch(isPremiumProvider).value ?? false;
    if (isPremium) return 'Unlimited coach asks';
    final remaining =
        ref.watch(coachAskQuotaControllerProvider).value?.remaining ?? 3;
    return '$remaining of 3 coach asks left today';
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(narratorCardDismissedProvider)) {
      return const SizedBox.shrink();
    }
    ref.listen(narratorAskFocusProvider, (previous, next) {
      if ((next ?? 0) > (previous ?? 0)) _openAskFromAvatar();
    });

    final pendingLine = ref.watch(pendingMilestoneProvider)?.line;
    final insightAsync = ref.watch(latestNarratorInsightProvider);
    final insightText = insightAsync.value?.data['shellText'] as String?;

    final habits = ref.watch(habitsProvider).value ?? const <Habit>[];
    final now = DateTime.now();
    final active = habits.where((h) => h.isActiveOnDay(now)).toList();
    final completed = active.where((h) => h.isCompletedOn(now)).length;
    final firstIncomplete = active
        .where((h) => !h.isCompletedOn(now))
        .map((h) => h.title)
        .firstOrNull;
    final streak = ref.watch(userStatsStreamProvider).value?.avatarStats.streak ?? 0;

    final line = resolveCardLine(
      pendingLine: pendingLine,
      insightText: insightText,
      day: DayStatus(
        completed: completed,
        total: active.length,
        streak: streak,
        firstIncompleteName: firstIncomplete,
      ),
    );
    if (line == null) return const SizedBox.shrink();

    final isPersonal = line is PersonalLine;
    final remaining = active.length - completed;

    return GlassmorphismCard(
      key: _rootKey,
      glowColor: EmergeColors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _CardAvatar(),
              const SizedBox(width: 10),
              const Text(
                'NARRATOR',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.bold,
                  color: EmergeColors.teal,
                ),
              ),
              const Spacer(),
              if (isPersonal)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: EmergeColors.warmGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'DATA-GROUNDED',
                    style: TextStyle(
                      fontSize: 8,
                      color: EmergeColors.warmGold,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              IconButton(
                onPressed: () =>
                    ref.read(narratorCardDismissedProvider.notifier).dismiss(),
                icon: const Icon(Icons.close, size: 18, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TypewriterText(
            key: ValueKey('card-line-${line.text}'),
            text: line.text,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (streak > 0)
                _StatusChip(
                  icon: '🔥',
                  label: '$streak-day streak',
                  emphasized: true,
                ),
              if (active.isNotEmpty)
                _StatusChip(
                  icon: remaining == 0 ? '✓' : '',
                  label: remaining == 0 ? 'All done' : '$remaining left today',
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_askOpen)
            GestureDetector(
              onTap: () => setState(() => _askOpen = true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined, size: 14, color: Colors.white54),
                    SizedBox(width: 6),
                    Text(
                      '✎ Ask the narrator',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _askController,
                  focusNode: _askFocus,
                  minLines: 1,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _isAsking
                        ? 'Consulting your coach…'
                        : 'Ask your coach anything…',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  onSubmitted: _submitAsk,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _quotaHint(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isAsking
                          ? null
                          : () => _submitAsk(_askController.text),
                      icon: const Icon(Icons.send, color: EmergeColors.teal),
                    ),
                  ],
                ),
              ],
            ),
          if (_replyLine != null) ...[
            const SizedBox(height: 12),
            TypewriterText(
              key: ValueKey('reply-${_replyLine!.text}'),
              text: _replyLine!.text,
            ),
          ],
        ],
      ),
    );
  }
}

class _CardAvatar extends StatelessWidget {
  const _CardAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [EmergeColors.violet, EmergeColors.teal],
        ),
      ),
      child: const Center(
        child: Text('✦', style: TextStyle(fontSize: 12, color: Colors.white)),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String icon;
  final String label;
  final bool emphasized;

  const _StatusChip({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: emphasized
            ? EmergeColors.warmGold.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.07),
        border: Border.all(
          color: emphasized
              ? EmergeColors.warmGold.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        '$icon $label'.trim(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: emphasized ? FontWeight.bold : FontWeight.w500,
          color: emphasized ? EmergeColors.warmGold : Colors.white70,
        ),
      ),
    );
  }
}
```

Notes:
- `firstOrNull` needs `package:collection`'s extension — it is exported by Flutter's `foundation` via `package:flutter/foundation.dart` re-export? No. Add `import 'package:collection/collection.dart';` (collection is already a transitive dependency; if `dart analyze` flags it, use the explicit `active.where(...).isEmpty ? null : ...` instead). Preferred: avoid the import — compute `firstIncomplete` as:
  ```dart
  final incomplete = active.where((h) => !h.isCompletedOn(now)).toList();
  final firstIncomplete = incomplete.isEmpty ? null : incomplete.first.title;
  ```
- `UserProfile.totalXp` — used in the premium context string exactly as `NarratorSheet` did; verify the field name exists (the sheet used `profile.avatarStats.totalXp`).

- [ ] **Step 5: Regenerate providers and run tests**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Then: `flutter test test/features/narrator/presentation/widgets/narrator_card_test.dart`
Expected: PASS (5 tests). `flutter analyze` clean.

- [ ] **Step 6: Commit**

```bash
git add lib/features/narrator/presentation/widgets/narrator_card.dart lib/features/narrator/presentation/providers/narrator_providers.dart lib/features/narrator/presentation/providers/narrator_providers.g.dart test/features/narrator/presentation/widgets/narrator_card_test.dart
git commit -m "feat(narrator): Day Card with typed line, status chips, and inline coach ask"
```

---

## Task 9: NarratorMilestoneCard — typed text + optional actions

**Files:**
- Modify: `lib/features/narrator/presentation/widgets/narrator_milestone_card.dart`
- Test: `test/features/narrator/presentation/widgets/narrator_milestone_card_test.dart` (create)

- [ ] **Step 1: Write the failing test**

```dart
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_milestone_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const line = GenericLine('You missed a step. But you did not stop.');

  testWidgets('types the line out and tap-to-skips', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NarratorMilestoneCard(
            line: line,
            trigger: NarratorTrigger.streakBreakFirstMiss,
          ),
        ),
      ),
    );
    // The typed line is the only text containing 'You' (the label is
    // 'STREAK', the hint is 'Swipe ↑').
    await tester.pump(const Duration(milliseconds: 100)); // partial
    final partial = tester.widget<Text>(find.textContaining('You')).textPlain;
    expect(partial.length, lessThan(line.text.length));
    await tester.tap(find.textContaining('You')); // tap-to-skip
    await tester.pump();
    expect(
      tester.widget<Text>(find.textContaining('You')).textPlain,
      line.text,
    );
  });

  testWidgets('renders action chips and fires them', (tester) async {
    var tapped = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NarratorMilestoneCard(
            line: line,
            trigger: NarratorTrigger.eveningReflection,
            actions: [
              NarratorMilestoneAction(
                label: 'Log Reflection',
                onTap: () => tapped = 'log',
              ),
              NarratorMilestoneAction(
                label: 'Skip',
                onTap: () => tapped = 'skip',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2)); // finish typing
    await tester.tap(find.text('Log Reflection'));
    expect(tapped, 'log');
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/narrator/presentation/widgets/narrator_milestone_card_test.dart`
Expected: FAIL — `NarratorMilestoneAction` not defined.

- [ ] **Step 3: Implement**

Modify `lib/features/narrator/presentation/widgets/narrator_milestone_card.dart`:

Add the action model at the top (after the imports):

```dart
/// One tappable chip on a milestone card (e.g. "Log Reflection").
class NarratorMilestoneAction {
  final String label;
  final VoidCallback onTap;

  const NarratorMilestoneAction({required this.label, required this.onTap});
}
```

Add the field to the widget (line 10–21):

```dart
  final List<NarratorMilestoneAction>? actions;
  ...
  const NarratorMilestoneCard({
    super.key,
    required this.line,
    required this.trigger,
    this.autoDismissAfter = const Duration(seconds: 6),
    this.actions,
    this.onDismissed,
  });
```

Replace the body `Text(widget.line.text, ...)` (lines 125–132) with a typed line + actions column:

```dart
                  TypewriterText(
                    text: widget.line.text,
                    onComplete: () {},
                  ),
                  if (widget.actions != null && widget.actions!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final action in widget.actions!)
                          GestureDetector(
                            onTap: action.onTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white.withValues(alpha: 0.18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                action.label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
```

Add the import at the top:

```dart
import 'package:emerge_app/core/presentation/widgets/typewriter_text.dart';
```

Note: tap-to-skip on the milestone card comes for free — `TypewriterText` is tappable. The card's auto-dismiss (6s) is unchanged.

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/features/narrator/presentation/widgets/narrator_milestone_card_test.dart`
Expected: PASS (2 tests). `flutter analyze lib/features/narrator/presentation/widgets/narrator_milestone_card.dart` clean.

- [ ] **Step 5: Commit**

```bash
git add lib/features/narrator/presentation/widgets/narrator_milestone_card.dart test/features/narrator/presentation/widgets/narrator_milestone_card_test.dart
git commit -m "feat(narrator): milestone card types text and supports optional action chips"
```

---

## Task 10: Timeline migration (Day Card, guide host, avatar ask, evening)

**Files:**
- Modify: `lib/features/timeline/presentation/screens/timeline_screen.dart`

- [ ] **Step 1: Imports**

Replace the narrator/tutorials imports (lines 35–48) with:

```dart
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_note.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_card.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_guide_host.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_milestone_card.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_avatar.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/domain/services/narrator_open_evaluator.dart';
```

(Removed: `narrator_summary_card.dart`, `narrator_sheet.dart`, `narrator_appearance.dart`, `narrator_trigger_engine.dart`, `tutorials/node_guide_host.dart`.)

- [ ] **Step 2: Remove `_eveningAppearance` and `_openCoach`**

Delete the `_eveningAppearance` const (lines 71–80). Delete `_openCoach` (lines 253–267).

- [ ] **Step 3: Add guide target keys**

Add to the state class fields (after `_celebrationKey`, line 68–69):

```dart
  final GlobalKey _fabGuideKey = GlobalKey();
  final GlobalKey _ringGuideKey = GlobalKey();
  final GlobalKey _cardGuideKey = GlobalKey();
```

- [ ] **Step 4: Rewrite `_checkEveningReflection` to a milestone card**

Replace the `NarratorSheet.show(...)` block (lines 232–249) with:

```dart
      ref.read(pendingMilestoneProvider.notifier).set(
            PendingMilestoneLine(
              line: const GenericLine(
                'Evening check-in. How did your habits serve you today? Take a moment to reflect on what worked and what you\'ll adjust tomorrow.',
              ),
              trigger: NarratorTrigger.eveningReflection,
            ),
          );
```

The once-per-day prefs key (`evening_reflection_...`, lines 224–229) stays as-is.

- [ ] **Step 5: Avatar tap → ask focus**

Replace line 435:

```dart
            trailing: NarratorAvatar(
              onTap: () =>
                  ref.read(narratorAskFocusProvider.notifier).request(),
            ),
```

- [ ] **Step 6: Host swap + keys + milestone actions**

Replace `return NodeGuideHost(...)` (lines 325–409):

```dart
    return NarratorGuideHost(
      nodeId: 'timeline',
      targets: {
        'fab': _fabGuideKey,
        'ring': _ringGuideKey,
        'card': _cardGuideKey,
      },
      child: WorldBackground(
        useSafeArea: false,
        themeOverride: AppWorldTheme.nebula,
        child: Stack(
          children: [
            SafeArea(
              child: habits.isNotEmpty
                  ? _buildTimelineList(context, habits, statsAsync)
                  : habitsAsync.when(
                      data: (_) => _buildEmptyTimeline(
                        context: context,
                        onCreateHabit: () =>
                            context.push('/timeline/create-habit'),
                      ),
                      loading: () => const EmergeLoadingSkeleton(
                        itemCount: 3,
                        itemHeight: 100,
                      ),
                      error: (e, s) => _buildErrorView(context),
                    ),
            ),
            Positioned(
              right: 16,
              bottom: 16 + MediaQuery.paddingOf(context).bottom,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  KeyedSubtree(
                    key: _ringGuideKey,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final fraction =
                            ref.watch(completionFractionProvider);
                        return SizedBox(
                          width: 64,
                          height: 64,
                          child: CircularProgressIndicator(
                            value: fraction,
                            strokeWidth: 3,
                            strokeCap: StrokeCap.round,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _ringColor(fraction),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  KeyedSubtree(
                    key: _fabGuideKey,
                    child: FloatingActionButton(
                      heroTag: 'timeline_create_habit',
                      backgroundColor: EmergeColors.teal,
                      tooltip: 'Log Habit',
                      onPressed: () => context.push('/timeline/create-habit'),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            if (_showOverlay && _pendingOverlayLine != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 100 + MediaQuery.paddingOf(context).bottom,
                child: NarratorMilestoneCard(
                  line: _pendingOverlayLine!.line,
                  trigger: _pendingOverlayLine!.trigger,
                  actions: _pendingOverlayLine!.trigger ==
                          NarratorTrigger.eveningReflection
                      ? [
                          NarratorMilestoneAction(
                            label: 'Log Reflection',
                            onTap: () {
                              ref
                                  .read(narratorLocalDatasourceProvider)
                                  .recordNote(
                                    type: NarratorNoteType.reflectionLogged,
                                    data: {
                                      'completedCount': _pendingOverlayLine ==
                                              null
                                          ? 0
                                          : _countCompletedToday(),
                                      'totalHabits': _pendingOverlayLine ==
                                              null
                                          ? 0
                                          : _countHabitsToday(),
                                      'response': 'Log Reflection',
                                    },
                                  );
                              _dismissMilestone();
                            },
                          ),
                          NarratorMilestoneAction(
                            label: 'Skip',
                            onTap: _dismissMilestone,
                          ),
                        ]
                      : null,
                  onDismissed: _dismissMilestone,
                ),
              ),
            Positioned.fill(child: AllDoneCelebration(key: _celebrationKey)),
          ],
        ),
      ),
    );
```

Add the two helpers next to `_onPendingMilestoneChange`:

```dart
  int _countHabitsToday() => ref
      .read(dashboardStateProvider)
      .habits
      .where((h) => h.isActiveOnDay(DateTime.now()))
      .length;

  int _countCompletedToday() => ref
      .read(dashboardStateProvider)
      .habits
      .where((h) => h.isCompletedOn(DateTime.now()))
      .length;

  void _dismissMilestone() {
    setState(() {
      _showOverlay = false;
      _pendingOverlayLine = null;
    });
    ref.read(pendingMilestoneProvider.notifier).clear();
  }
```

And point `_onPendingMilestoneChange`'s dismissal callback at `_dismissMilestone` (replace the body of the `onDismissed:` closure inside the milestone Positioned — the `NarratorMilestoneCard` at lines 392–401 — with `onDismissed: _dismissMilestone`).

- [ ] **Step 7: Card mount**

Replace `const SliverToBoxAdapter(child: NarratorSummaryCard())` (line 558) with:

```dart
        SliverToBoxAdapter(
          child: NarratorCard(key: _cardGuideKey),
        ),
```

- [ ] **Step 8: Verify**

Run: `flutter analyze lib/features/timeline/presentation/screens/timeline_screen.dart`
Expected: No issues. If `narrator_trigger_engine.dart` was only used by `_openCoach`, the import was already removed in Step 1 — confirm no other engine references remain (grep `NarratorTriggerEngine` in the file: should be zero).

- [ ] **Step 9: Commit**

```bash
git add lib/features/timeline/presentation/screens/timeline_screen.dart
git commit -m "feat(timeline): mount Day Card + narrator guide host; avatar opens card ask; evening as typed milestone"
```

---

## Task 11: Streak recovery migration

**Files:**
- Modify: `lib/features/habits/presentation/screens/streak_recovery_screen.dart`

- [ ] **Step 1: Imports**

Replace lines 6–11 (narrator + tutorials imports) with:

```dart
import 'package:emerge_app/features/narrator/domain/models/narrator_line.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_guide_controller.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_guide_host.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_milestone_card.dart';
```

(Removed: `narrator_appearance.dart`, `narrator_sheet.dart`, `node_guide_controller.dart`, `node_guide_host.dart`.)

- [ ] **Step 2: Convert the narrator sheet to a local milestone card**

Replace `_showNarrator` (lines 40–67) with:

```dart
  bool _showMessage = false;
  final GlobalKey _momentumKey = GlobalKey();
  final GlobalKey _restartCtaKey = GlobalKey();

  Future<void> _showNarrator() async {
    // Wait a brief moment for the screen to settle.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // The first-visit guide covers the first visit — only show the
    // streak-break message once the guide has been seen.
    final guideDue = await ref
        .read(narratorGuideControllerProvider)
        .shouldShow('streak_recovery');
    if (guideDue || !mounted) return;

    setState(() => _showMessage = true);
  }
```

- [ ] **Step 3: Host swap**

Replace `return NodeGuideHost(...)` (lines 71–73) with:

```dart
    return NarratorGuideHost(
      nodeId: 'streak_recovery',
      targets: {
        'momentum_visual': _momentumKey,
        'restart_cta': _restartCtaKey,
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Stack(
          children: [
            // Background blur/particles (unchanged, lines 77–…)
            ...
```

- [ ] **Step 4: Add the milestone card to the Stack**

Inside the `Stack`'s `children`, after the existing children (before the closing `]` of the Stack), add:

```dart
            if (_showMessage)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24 + MediaQuery.paddingOf(context).bottom,
                child: NarratorMilestoneCard(
                  line: const GenericLine(
                    'You missed a step. But you did not stop. That is what separates the dedicated from the dreamers.',
                  ),
                  trigger: NarratorTrigger.streakBreakFirstMiss,
                  onDismissed: () => setState(() => _showMessage = false),
                ),
              ),
```

- [ ] **Step 5: Wrap the two guide targets**

Find the screen's main momentum visual (the large central card/visual in the Stack — the one showing streak/momentum) and wrap it in `KeyedSubtree(key: _momentumKey, child: ...)`. Find the primary restart CTA button (the "Let's keep going"-style action) and wrap it in `KeyedSubtree(key: _restartCtaKey, child: ...)`. Read the full file first to locate them.

- [ ] **Step 6: Verify**

Run: `flutter analyze lib/features/habits/presentation/screens/streak_recovery_screen.dart`
Expected: No issues.

- [ ] **Step 7: Commit**

```bash
git add lib/features/habits/presentation/screens/streak_recovery_screen.dart
git commit -m "feat(habits): streak recovery uses narrator guide host + typed milestone message"
```

---

## Task 12: Migrate the 7 remaining guide screens

For each screen: swap the `NodeGuideHost` import + widget for `NarratorGuideHost` (with its `targets` map), add the two `GlobalKey` fields, and wrap the two named widgets in `KeyedSubtree(key: ...)`. The registry target keys (Task 2) must match the map keys below exactly.

**Files (modify all 7):**

- [ ] **Step 1: `habit_create_screen.dart`** (`lib/features/habits/presentation/screens/`)

Swap import: `tutorials/presentation/widgets/node_guide_host.dart` → `narrator/presentation/widgets/narrator_guide_host.dart`.
Add fields: `final GlobalKey _nameFieldKey = GlobalKey();` and `final GlobalKey _createButtonKey = GlobalKey();`.
Wrap the habit-name `TextField` (line 331) in `KeyedSubtree(key: _nameFieldKey, ...)` and the primary create `ElevatedButton` (line 423 — the one that persists the habit) in `KeyedSubtree(key: _createButtonKey, ...)`.
Replace (lines 136–138):

```dart
    return NarratorGuideHost(
      nodeId: 'habit_create',
      targets: {
        'name_field': _nameFieldKey,
        'create_button': _createButtonKey,
      },
      child: Stack(
```

(keep the existing `children:` from the old host's child onward — the host body structure is identical.)

- [ ] **Step 2: `world_map_screen.dart`** (`lib/features/world_map/presentation/screens/`)

Swap import. Add `_mapBodyKey` + `_mapHeaderKey`. Wrap the map body (the `healthAsync.when(data: ...)` content) and the screen header/app-bar area. Replace (lines 73–75):

```dart
    return NarratorGuideHost(
      nodeId: 'world_map',
      targets: {
        'map_body': _mapBodyKey,
        'map_header': _mapHeaderKey,
      },
      child: Scaffold(
```

- [ ] **Step 3: `leveling_screen.dart`** (`lib/features/gamification/presentation/screens/`)

Swap import. Add `_levelHeaderKey` + `_levelBarKey`. Wrap the `AppBar` (line 33) and the `LinearProgressIndicator` (line 115). Replace (lines 30–32):

```dart
    return NarratorGuideHost(
      nodeId: 'leveling',
      targets: {
        'level_header': _levelHeaderKey,
        'level_bar': _levelBarKey,
      },
      child: GrowthBackground(
```

- [ ] **Step 4: `future_self_studio_screen.dart`** (`lib/features/profile/presentation/screens/`)

Swap import. Add `_studioHeaderKey` + `_generateButtonKey`. Wrap the `SliverAppBar` (line 124) and the primary action `ElevatedButton.icon` (line 536). Replace (lines 78–80):

```dart
    return NarratorGuideHost(
      nodeId: 'future_self',
      targets: {
        'studio_header': _studioHeaderKey,
        'generate_button': _generateButtonKey,
      },
      child: statsAsync.when(
```

- [ ] **Step 5: `challenges_screen.dart`** (`lib/features/social/presentation/screens/`)

Swap import. Add `_joinFabKey` + `_challengeListKey`. Wrap the `FloatingActionButton` (line 97) and the challenge list content. Replace (lines 93–95):

```dart
    return NarratorGuideHost(
      nodeId: 'challenges',
      targets: {
        'join_fab': _joinFabKey,
        'challenge_list': _challengeListKey,
      },
      child: Scaffold(
```

- [ ] **Step 6: `all_tribes_screen.dart`** (`lib/features/social/presentation/screens/`)

Swap import. Add `_tribesHeaderKey` + `_tribeListKey`. Wrap the `AppBar` (line 36) and the tribe list content. Replace (lines 32–34):

```dart
    return NarratorGuideHost(
      nodeId: 'all_tribes',
      targets: {
        'tribes_header': _tribesHeaderKey,
        'tribe_list': _tribeListKey,
      },
      child: Scaffold(
```

- [ ] **Step 7: `tribe_lobby_screen.dart`** (`lib/features/social/presentation/screens/`)

Swap import. Add `_memberListKey` + `_lobbyActionsKey`. Wrap the members list and the actions row (`_BackButton`-style buttons at lines 186–194). Replace (lines 136–138):

```dart
    return NarratorGuideHost(
      nodeId: 'tribe_lobby',
      targets: {
        'member_list': _memberListKey,
        'lobby_actions': _lobbyActionsKey,
      },
      child: Scaffold(
```

- [ ] **Step 8: Verify all 7**

Run: `flutter analyze lib/features/habits/presentation/screens/habit_create_screen.dart lib/features/world_map/presentation/screens/world_map_screen.dart lib/features/gamification/presentation/screens/leveling_screen.dart lib/features/profile/presentation/screens/future_self_studio_screen.dart lib/features/social/presentation/screens/challenges_screen.dart lib/features/social/presentation/screens/all_tribes_screen.dart lib/features/social/presentation/screens/tribe_lobby_screen.dart`
Expected: No issues.

- [ ] **Step 9: Commit**

```bash
git add lib/features/habits/presentation/screens/habit_create_screen.dart lib/features/world_map/presentation/screens/world_map_screen.dart lib/features/gamification/presentation/screens/leveling_screen.dart lib/features/profile/presentation/screens/future_self_studio_screen.dart lib/features/social/presentation/screens/challenges_screen.dart lib/features/social/presentation/screens/all_tribes_screen.dart lib/features/social/presentation/screens/tribe_lobby_screen.dart
git commit -m "feat(narrator): migrate 7 screens from node guides to narrator guide host"
```

---

## Task 13: Deletions — tutorials feature, FeatureCoachMark, NarratorSheet, NarratorSummaryCard

All importers were migrated in Tasks 10–12. Verify with grep first.

**Files:**
- Delete: `lib/features/tutorials/` (entire directory, incl. `node_guide_controller.g.dart`)
- Delete: `lib/core/presentation/widgets/feature_coach_mark.dart`
- Delete: `lib/features/narrator/presentation/widgets/narrator_sheet.dart`
- Delete: `lib/features/narrator/presentation/widgets/narrator_summary_card.dart`
- Modify: `lib/features/narrator/presentation/providers/narrator_providers.dart` (delete `NarratorState`, `NarratorStateNotifier`, and the now-unused `narrator_appearance.dart` import)
- Delete: `test/features/tutorials/` (entire directory)
- Delete: `test/core/presentation/widgets/feature_coach_mark_test.dart`
- Delete: `test/features/narrator/presentation/widgets/narrator_coach_flow_test.dart`
- Delete: `test/features/narrator/presentation/widgets/narrator_sheet_test.dart`
- Delete: `test/features/narrator/presentation/widgets/narrator_summary_card_test.dart`

- [ ] **Step 1: Verify zero importers**

Run:
```bash
grep -rn "feature_coach_mark\|node_guide\|NarratorSheet\|NarratorSummaryCard\|narrator_sheet\|narrator_summary_card" lib/ | grep -v ".g.dart"
grep -rn "NarratorAppearance" lib/
```
Expected: `NarratorAppearance` appears only in `narrator_providers.dart` (the state notifier); all others: zero hits.

- [ ] **Step 2: Delete the files**

```bash
rm -r lib/features/tutorials test/features/tutorials
rm lib/core/presentation/widgets/feature_coach_mark.dart test/core/presentation/widgets/feature_coach_mark_test.dart
rm lib/features/narrator/presentation/widgets/narrator_sheet.dart lib/features/narrator/presentation/widgets/narrator_summary_card.dart
rm test/features/narrator/presentation/widgets/narrator_coach_flow_test.dart test/features/narrator/presentation/widgets/narrator_sheet_test.dart test/features/narrator/presentation/widgets/narrator_summary_card_test.dart
```

- [ ] **Step 3: Delete the dead state notifier**

In `lib/features/narrator/presentation/providers/narrator_providers.dart`, remove the `NarratorState` class, the `NarratorStateNotifier` block, and the `narrator_appearance.dart` import. (`NarratorAppearance` is a model with no remaining producers or consumers — if `dart analyze` disagrees, keep the notifier and note the analyzer's reason.)

- [ ] **Step 4: Regenerate and verify**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Then: `flutter analyze`
Expected: No issues.

- [ ] **Step 5: Run the focused narrator + tutorials-adjacent tests**

Run:
- `flutter test test/features/narrator/`
- `flutter test test/features/settings/presentation/screens/settings_screen_test.dart`
Expected: All PASS (settings test may need the copy update from Task 14 — if it fails on 'Show first-visit guides', run Task 14 first and re-run).

- [ ] **Step 6: Commit**

```bash
git add -A lib/features/tutorials lib/features/narrator lib/core/presentation/widgets/feature_coach_mark.dart test
git commit -m "refactor(narrator): delete node guides, FeatureCoachMark, NarratorSheet, NarratorSummaryCard"
```

---

## Task 14: Settings copy + design.md amendments

**Files:**
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`
- Modify: `test/features/settings/presentation/screens/settings_screen_test.dart`
- Modify: `lib/core/presentation/widgets/scaffold_with_nav_bar.dart` (comment)
- Modify: `docs/design.md`

- [ ] **Step 1: Settings copy**

In `lib/features/settings/presentation/screens/settings_screen.dart` (Tutorials section, lines ~324–362), change the two labels:
- `'Show first-visit guides'` → `'Show narrator guides'`
- `'Replay first-visit guides'` → `'Replay narrator guides'`

Update `test/features/settings/presentation/screens/settings_screen_test.dart`:
- line 260: `expect(find.text('Show first-visit guides'), findsOneWidget);` → `'Show narrator guides'`
- line 264: `'Replay first-visit guides'` → `'Replay narrator guides'`
- line 278: `await tester.ensureVisible(find.text('Show first-visit guides'));` → `'Show narrator guides'`
- If the test navigates the "Replay" dialog, update the dialog's confirm button reference to match the screen's copy (read the test around line 278 to confirm).

- [ ] **Step 2: Scaffold comment**

In `lib/core/presentation/widgets/scaffold_with_nav_bar.dart` line 20, replace:

```dart
/// inline guidance via NarratorSheet / NarratorSummaryCard.
```

with:

```dart
/// inline guidance via the Narrator Day Card and typed milestone cards.
```

- [ ] **Step 3: design.md amendments**

In `docs/design.md`:

(a) §11.5 "The Narrator as Feedback" (lines 780–789) → replace the bullet list with:

```markdown
The Narrator is the app's guide — one voice across first-visit tutorials, the Day Card, event milestones, and the coach ask:

- The narrator owns first-visit tutorials: a typed script walks 2–4 steps per screen while a spotlight hole highlights the exact section each line explains (see `docs/superpowers/specs/2026-08-04-narrator-is-the-guide-design.md`)
- Narrator text types out at ~35 chars/sec with a blinking caret; tap-to-skip completes instantly; reduced motion renders instantly (never unskippable)
- Free users see generic lines; Pro users see personalized data-grounded lines
- The Narrator never interrupts onboarding
- The Day Card (timeline) is the always-visible narrator surface: typed day-line, streak/remaining chips, inline coach ask (3 free/day, unlimited for Pro)
- Event moments (streak break, level up, evening) surface as non-blocking typed milestone cards, never modals
```

(b) §12.4 anti-pattern table (line 851) → replace the row:

```markdown
| Unskippable typewriter text | Feels slow, blocks fast readers | ~35 cps with tap-to-skip; instant under reduced motion |
```

(c) §6 Animation tokens — add to the duration table (near line 436–475):

```markdown
| Narrator typewriter pace | 35 chars/sec |
| Spotlight hole glide | 200ms easeInOut |
```

- [ ] **Step 4: Verify**

Run: `flutter test test/features/settings/presentation/screens/settings_screen_test.dart`
Expected: PASS. `flutter analyze` clean.

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/presentation/screens/settings_screen.dart test/features/settings/presentation/screens/settings_screen_test.dart lib/core/presentation/widgets/scaffold_with_nav_bar.dart docs/design.md
git commit -m "docs(design): narrator is the guide — settings copy, typewriter + spotlight tokens, anti-pattern update"
```

---

## Task 15: Final verification

- [ ] **Step 1: Leftover-reference grep**

Run:
```bash
grep -rn "hasSeenNodeGuide\|node_guide\|NodeGuide\|FeatureCoachMark\|NarratorSheet\|NarratorSummaryCard\|narrator_sheet\|narrator_summary_card" lib/ test/ | grep -v ".g.dart"
```
Expected: Zero hits (except intentional `hasSeenNodeGuide` strings inside the migration function in `local_settings_repository.dart`).

- [ ] **Step 2: Full static analysis**

Run: `flutter analyze`
Expected: No issues.

- [ ] **Step 3: Focused test sweep**

Run:
```bash
flutter test test/core/presentation/widgets/typewriter_text_test.dart
flutter test test/features/narrator/
flutter test test/features/onboarding/data/repositories/visited_flags_migration_test.dart
flutter test test/features/timeline/
flutter test test/features/settings/presentation/screens/settings_screen_test.dart
flutter test test/features/habits/presentation/screens/streak_recovery_screen_test.dart
```
(If any test file in these paths doesn't exist, note it and move on — the sweep is for regressions in touched features.)

- [ ] **Step 4: Manual smoke checklist** (optional, device/emulator)
1. Fresh install → timeline guide shows: FAB → ring → Day Card steps, spotlight follows, text types.
2. Tap-to-skip on the guide card; `Got it` marks seen; Settings → Replay narrator guides → re-appears.
3. Day Card: streak + remaining chips; ✎ ask → free reply types in place; 4th ask → premium dialog.
4. Avatar tap → card expands ask + scrolls into view.
5. Complete a habit → typed milestone slide-up; evening (≥18:00) → typed milestone with Log Reflection/Skip.
6. Reduced motion (system) → all narrator text instant, no caret, spotlight jumps.

- [ ] **Step 5: Final commit if anything was touched in this task**

```bash
git status
# commit any stragglers with a descriptive message
```
