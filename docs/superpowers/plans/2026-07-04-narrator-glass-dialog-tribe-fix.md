# Narrator Glass Dialog & Tribe Drift-First — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign NarratorSheet as a centered glass dialog, remove old node guide remnants, fix tribe lobby drift-first, fix onboarding redirect, and improve typewriter performance.

**Architecture:** NarratorSheet switches from `showModalBottomSheet` to `showDialog` with glassmorphic styling and animated size expansion. DriftTribeRepository emits local data immediately without waiting for Firestore. Typewriter uses ValueNotifier to scope rebuilds to the Text widget.

**Tech Stack:** Flutter, Riverpod, GoRouter, Drift, Firestore

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `lib/features/world_map/presentation/screens/world_map_screen.dart` | Remove old coach mark, add narrator first-visit |
| Modify | `lib/features/narrator/presentation/widgets/narrator_sheet.dart` | Bottom sheet → centered glass dialog, AnimatedSize, skip button |
| Modify | `lib/features/narrator/presentation/widgets/narrator_typewriter.dart` | Performance: ValueNotifier + ValueListenableBuilder |
| Test | `test/features/narrator/presentation/widgets/narrator_typewriter_test.dart` | Update for ValueNotifier change (should pass as-is) |
| Modify | `lib/features/onboarding/presentation/screens/world_reveal_screen.dart` | `'/'` → `'/timeline'` |
| Modify | `lib/core/router/router.dart` | `return '/'` → `return '/timeline'` |
| Modify | `lib/core/drift_repositories/drift_tribe_repository.dart` | Emit local immediately, background remote merge |
| Modify | `lib/features/social/presentation/providers/tribes_provider.dart` | Same drift-first fix for worldLeaderboardProvider |

---

### Task 1: Remove old node guide from world_map_screen, wire narrator

**Files:**
- Modify: `lib/features/world_map/presentation/screens/world_map_screen.dart`

- [ ] **Step 1: Remove coach mark fields and timer from world_map_screen.dart**

Delete the following from `_WorldMapScreenState`:

```dart
// DELETE
Timer? _initTimer;
bool _showFirstVisitGuide = false;
```

Delete from `initState`:
```dart
// DELETE
_initTimer = Timer(const Duration(milliseconds: 800), () {
  if (!mounted) return;
  final repo = ref.read(companionRepositoryProvider);
  if (!repo.hasVisited('/world-map')) {
    repo.markVisited('/world-map');
    ref
        .read(companionEngineProvider.notifier)
        .triggerEvent(
          eventType: CompanionEventType.firstFeatureVisit,
          userContext: {'route': '/world-map'},
        );
    setState(() => _showFirstVisitGuide = true);
  }
});
```

Delete from `dispose`:
```dart
// DELETE
_initTimer?.cancel();
```

Delete the rendering (around line 189):
```dart
// DELETE
if (_showFirstVisitGuide)
  _WorldMapCoachMark(
    primaryColor: mapConfig.primaryColor,
    onDismiss: () => setState(() => _showFirstVisitGuide = false),
  ),
```

And replace with:
```dart
// ADD after the stats bar or in place of the deleted coach mark
```

- [ ] **Step 2: Add first-visit narrator trigger to world_map_screen**

Add a `_checkFirstWorldMapVisit()` method using the same pattern as `level_immersive_screen.dart`:

```dart
// ADD to _WorldMapScreenState
Future<void> _checkFirstWorldMapVisit() async {
  await Future<void>.delayed(const Duration(milliseconds: 500));
  if (!mounted || _disposed) return;

  final repo = LocalSettingsRepository();
  if (repo.isFirstLaunch) return;
  if (!repo.isTutorialsEnabled()) return;

  final hasSeen = await repo.getHasSeenNodeGuide('world-map');
  if (!hasSeen && mounted && !_disposed) {
    await repo.setHasSeenNodeGuide('world-map');
    if (!_disposed && mounted) {
      await NarratorSheet.show(
        context,
        NarratorAppearance(
          trigger: NarratorTrigger.screenFirstVisit,
          shellText:
              'Welcome to your World Map. '
              'Each node represents a challenge area. '
              'Tap a node to begin your mission.',
          buttonA: 'Explore',
          buttonB: 'Got it',
          context: {
            'route': '/world-map',
          },
        ),
      );
    }
  }
}
```

Call it from `initState`:
```dart
@override
void initState() {
  super.initState();
  _checkFirstWorldMapVisit();  // ADD
  // ... rest of initState
}
```

Add a `_disposed` field:
```dart
bool _disposed = false;  // ADD

@override
void dispose() {
  _disposed = true;  // ADD
  _scrollController.dispose();
  super.dispose();
}
```

- [ ] **Step 3: Add required imports**

Add at the top of the file:
```dart
import 'package:emerge_app/features/narrator/domain/models/narrator_appearance.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_trigger.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_sheet.dart';
import 'package:emerge_app/features/onboarding/data/repositories/local_settings_repository.dart';
```

Remove unused imports:
```dart
// REMOVE if no longer used elsewhere in the file
import 'package:emerge_app/features/companion/presentation/providers/companion_providers.dart';
import 'package:emerge_app/features/companion/domain/enums/companion_enums.dart';
```

- [ ] **Step 4: Delete _WorldMapCoachMark class**

Delete the entire `_WorldMapCoachMark` widget class and `_WorldMapCoachMarkState` class (lines ~896-970+).

- [ ] **Step 5: Run analyzer to verify**

```bash
dart analyze lib/features/world_map/presentation/screens/world_map_screen.dart
```

Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/features/world_map/presentation/screens/world_map_screen.dart
git commit -m "feat(world-map): remove old coach mark, add narrator first-visit"
```

---

### Task 2: Fix onboarding redirect to Timeline

**Files:**
- Modify: `lib/features/onboarding/presentation/screens/world_reveal_screen.dart`
- Modify: `lib/core/router/router.dart`
- Test: `test/core/router/router_redirect_test.dart`

- [ ] **Step 1: Change world_reveal_screen redirect**

In `world_reveal_screen.dart`, change line 116:
```dart
// FROM:
context.go('/');
// TO:
context.go('/timeline');
```

- [ ] **Step 2: Change router redirect default**

In `router.dart`, change line 217:
```dart
// FROM:
if (isOnAuthPath) return '/';
// TO:
if (isOnAuthPath) return '/timeline';
```

- [ ] **Step 3: Update router redirect test**

Open `test/core/router/router_redirect_test.dart` and find the test case that checks the redirect for completed onboarding. Change the expected result from `'/'` to `'/timeline'`.

Run tests:
```bash
flutter test test/core/router/router_redirect_test.dart
```

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/features/onboarding/presentation/screens/world_reveal_screen.dart lib/core/router/router.dart test/core/router/router_redirect_test.dart
git commit -m "fix: redirect onboarding completion to /timeline instead of /"
```

---

### Task 3: Typewriter performance — ValueNotifier instead of setState

**Files:**
- Modify: `lib/features/narrator/presentation/widgets/narrator_typewriter.dart`
- Test: `test/features/narrator/presentation/widgets/narrator_typewriter_test.dart`

- [ ] **Step 1: Rewrite NarratorTypewriter to use ValueNotifier**

Replace the internal state of `_NarratorTypewriterState`:

```dart
class _NarratorTypewriterState extends State<NarratorTypewriter> {
  final ValueNotifier<String> _displayedTextNotifier = ValueNotifier<String>('');
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(NarratorTypewriter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      _currentIndex = 0;
      _displayedTextNotifier.value = '';
      _startTyping();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _displayedTextNotifier.dispose();
    super.dispose();
  }

  void _startTyping() {
    _typeNextCharacter();
  }

  void _typeNextCharacter() {
    if (_currentIndex >= widget.text.length) {
      widget.onComplete?.call();
      return;
    }

    _displayedTextNotifier.value = widget.text.substring(0, _currentIndex + 1);

    final char = widget.text[_currentIndex];
    final pause = widget.pauseDurations[char] ?? widget.baseDelayMs;
    _currentIndex++;

    _timer = Timer(Duration(milliseconds: pause), _typeNextCharacter);
  }

  /// Instantly reveals all remaining text.
  void skipToEnd() {
    _timer?.cancel();
    _displayedTextNotifier.value = widget.text;
    _currentIndex = widget.text.length;
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _displayedTextNotifier,
      builder: (context, text, _) {
        return Text(
          text,
          style: widget.style,
        );
      },
    );
  }
}
```

Note: `skipToEnd()` is added here for use by the NarratorSheet skip button (Task 4). The typewriter now needs to expose this method. Change the typewriter to use a GlobalKey pattern or pass a callback.

Actually, simplest approach: add a `NarratorTypewriterController` class that the parent can use to control the typewriter:

```dart
class NarratorTypewriterController {
  final ValueNotifier<String> displayedTextNotifier = ValueNotifier<String>('');
  final _skipCompleter = Completer<void>();

  String get displayedText => displayedTextNotifier.value;

  /// Waits for the typewriter to finish naturally.
  Future<void> get finished => _skipCompleter.future;

  /// Instantly completes the text.
  void skipToEnd() {
    // Signal handled by the state via a different mechanism
  }
}
```

Hmm, that adds complexity. Let me keep it simpler: just expose `skipToEnd` via a GlobalKey.

Actually the simplest is: the `NarratorTypewriter` state should expose `skipToEnd` via a public method on the State, accessible via a `GlobalKey<_NarratorTypewriterState>`. But `_NarratorTypewriterState` is private. 

Let me make the state class public or use a different approach. The cleanest: add a `skipToEnd` VoidCallback parameter to `NarratorTypewriter`:

```dart
class NarratorTypewriter extends StatefulWidget {
  // ... existing params ...
  final VoidCallback? onSkipRequested;  // ADD - the parent calls this to request skip
  
  const NarratorTypewriter({
    // ...
    this.onSkipRequested,
  });
}
```

Then in the state, listen for skip requests. Actually this is circular.

Simplest approach: Use a `TextEditingController`-like pattern:

```dart
class NarratorTypewriterController {
  void skip() {}
}

class NarratorTypewriter extends StatefulWidget {
  final NarratorTypewriterController? controller;
  // ...
}
```

Or even simpler: expose a `GlobalKey` approach. Let me just add a simple method:

```dart
// In NarratorTypewriter, add a static method to create a controller:

class NarratorTypewriterController {
  void Function()? _skip;
  void skip() => _skip?.call();
}
```

OK, this is getting overcomplicated. Let me just use a simpler approach: pass a `skipNotifier` ValueNotifier from the parent. When the parent increments it, the typewriter skips.

Actually, the absolute simplest: just pass the `skipToEnd` as a parameter callback. The parent creates a function, passes it to the typewriter, and the typewriter calls it when it wants to skip (triggered by the skip button in NarratorSheet). 

Wait no - the skip button is in the NarratorSheet, which contains the NarratorTypewriter. The NarratorSheet needs to tell the typewriter to skip. The simplest way: give the NarratorSheet a `GlobalKey` for the typewriter and call `skipToEnd()` on it. But the state is private.

Let me just make the state class public (rename to `NarratorTypewriterState`) and add `skipToEnd()` as a public method:

```dart
class NarratorTypewriter extends StatefulWidget {
  // ...
}

// Make state class public
class NarratorTypewriterState extends State<NarratorTypewriter> {
  // ... existing code ...
  
  /// Instantly reveals all remaining text.
  void skipToEnd() {
    _timer?.cancel();
    _displayedTextNotifier.value = widget.text;
    _currentIndex = widget.text.length;
    widget.onComplete?.call();
  }
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _displayedTextNotifier,
      builder: (context, text, _) {
        return Text(text, style: widget.style);
      },
    );
  }
}
```

Then in NarratorSheet:
```dart
final _typewriterKey = GlobalKey<NarratorTypewriterState>();
// ...
NarratorTypewriter(key: _typewriterKey, ...)
// ...
_typewriterKey.currentState?.skipToEnd();
```

This is the cleanest approach. Let me use it.

- [ ] **Step 2: Run existing typewriter test to verify it still passes**

```bash
flutter test test/features/narrator/presentation/widgets/narrator_typewriter_test.dart
```

Expected: All tests pass (the Text widget still renders the same output, just internal mechanism changed).

- [ ] **Step 3: Commit**

```bash
git add lib/features/narrator/presentation/widgets/narrator_typewriter.dart
git commit -m "perf(narrator): use ValueNotifier for typewriter to scope rebuilds to Text widget"
```

---

### Task 4: NarratorSheet → centered glass dialog with expanding size and skip button

**Files:**
- Modify: `lib/features/narrator/presentation/widgets/narrator_sheet.dart`
- Create (optional): `test/features/narrator/presentation/widgets/narrator_sheet_test.dart`

- [ ] **Step 1: Rewrite NarratorSheet as a centered glass dialog**

Replace the entire file content with:

```dart
import 'dart:async';
import 'dart:ui';

import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/narrator/domain/models/narrator_appearance.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_providers.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_pulse_indicator.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_typewriter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows the Narrator as a centered glassmorphic dialog.
///
/// Callers should use [NarratorSheet.show] to display it.
class NarratorSheet extends ConsumerStatefulWidget {
  final NarratorAppearance appearance;
  final void Function(String buttonLabel, String? typedText)? onResponse;

  const NarratorSheet({
    super.key,
    required this.appearance,
    this.onResponse,
  });

  /// Displays the Narrator as a centered dialog.
  static Future<void> show(
    BuildContext context,
    NarratorAppearance appearance, {
    void Function(String buttonLabel, String? typedText)? onResponse,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => NarratorSheet(
        appearance: appearance,
        onResponse: onResponse,
      ),
    );
  }

  @override
  ConsumerState<NarratorSheet> createState() => _NarratorSheetState();
}

class _NarratorSheetState extends ConsumerState<NarratorSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  final _typewriterKey = GlobalKey<NarratorTypewriterState>();
  bool _textComplete = false;
  final _noteController = TextEditingController();
  bool _actionButtonADone = false;
  bool _actionButtonBDone = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _skipTyping() {
    _typewriterKey.currentState?.skipToEnd();
  }

  @override
  Widget build(BuildContext context) {
    final appearance = widget.appearance;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.85).clamp(0.0, 400.0);

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // prevent dismiss when tapping inside card
            child: Container(
              width: cardWidth,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2BEE79).withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Main content
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          alignment: Alignment.topCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                children: [
                                  NarratorPulseIndicator(
                                    color: EmergeColors.teal,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'EMERGE',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: EmergeColors.teal,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 3,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Typewriter text
                              NarratorTypewriter(
                                key: _typewriterKey,
                                text: appearance.shellText,
                                baseDelayMs: 28,
                                pauseDurations: const {
                                  '.': 250,
                                  '?': 300,
                                  '!': 300,
                                  ',': 150,
                                },
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      height: 1.6,
                                    ),
                                onComplete: () {
                                  if (mounted) {
                                    setState(() => _textComplete = true);
                                  }
                                },
                              ),

                              // Optional text field
                              if (appearance.hasTextField) ...[
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _noteController,
                                  maxLines: 3,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'How was your day?',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.4),
                                    ),
                                    filled: true,
                                    fillColor:
                                        Colors.white.withValues(alpha: 0.08),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: EmergeColors.teal,
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16),

                              // Action buttons
                              AnimatedOpacity(
                                opacity: _textComplete ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 500),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _ActionButton(
                                        label: appearance.buttonA,
                                        color: EmergeColors.teal,
                                        isSelected: _actionButtonADone,
                                        onTap: () {
                                          setState(() =>
                                              _actionButtonADone = true);
                                          _onButtonTap(appearance.buttonA);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _ActionButton(
                                        label: appearance.buttonB,
                                        color: EmergeColors.violet,
                                        isSelected: _actionButtonBDone,
                                        onTap: () {
                                          setState(() =>
                                              _actionButtonBDone = true);
                                          _onButtonTap(appearance.buttonB);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Skip button (top-right, only visible during typing)
                        if (!_textComplete)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _skipTyping,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  '✕',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onButtonTap(String buttonLabel) {
    widget.onResponse?.call(
      buttonLabel,
      _noteController.text.isEmpty ? null : _noteController.text,
    );
    try {
      ref.read(narratorStateProvider.notifier).dismiss();
    } catch (_) {
      // Provider might not be available in test context
    }
    Navigator.of(context).pop();
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSelected ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.3)
              : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.6)
                : color.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Text(
            isSelected ? '✓ $label' : label,
            style: TextStyle(
              color: isSelected ? color : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyzer to verify**

```bash
dart analyze lib/features/narrator/presentation/widgets/narrator_sheet.dart
```

Expected: No errors.

- [ ] **Step 3: Run all narrator tests**

```bash
flutter test test/features/narrator/
```

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/features/narrator/presentation/widgets/narrator_sheet.dart
git commit -m "feat(narrator): redesign as centered glass dialog with AnimatedSize and skip button"
```

---

### Task 5: Tribe lobby drift-first — emit local immediately

**Files:**
- Modify: `lib/core/drift_repositories/drift_tribe_repository.dart`
- Test: `test/core/drift_repositories/drift_tribe_repository_test.dart`

- [ ] **Step 1: Fix `watchArchetypeClubs()` to emit local immediately**

Change `watchArchetypeClubs()` to emit local data without waiting for remote:

```dart
@override
Stream<List<Tribe>> watchArchetypeClubs() {
  final controller = StreamController<List<Tribe>>();

  StreamSubscription<List<TribeStatsTableData>>? localSub;
  StreamSubscription<QuerySnapshot>? remoteSub;

  var remoteDocs = <String, Map<String, dynamic>>{};

  void emitMerged() {
    // Read fresh local data each time
    _db.tribeStatsDao.getAll().then((localRows) {
      final tribes = localRows.map((row) {
        final remote = remoteDocs[row.tribeId];
        final memberCount =
            (remote?['memberCount'] as num?)?.toInt() ?? row.memberCount;
        final totalXp = (remote?['totalXp'] as num?)?.toInt() ?? row.totalXp;
        final totalHabits =
            (remote?['totalHabitsCompleted'] as num?)?.toInt() ??
            row.totalHabitsCompleted;
        final totalChallenges =
            (remote?['totalChallengesCompleted'] as num?)?.toInt() ??
            row.totalChallengesCompleted;
        final tribeName = (remote?['name'] as String?)?.isNotEmpty == true
            ? remote!['name'] as String
            : row.tribeName ?? '';
        final description = remote?['description'] as String? ?? '';
        final imageUrl = remote?['imageUrl'] as String? ?? '';

        return Tribe(
          id: row.tribeId,
          name: tribeName,
          description: description,
          imageUrl: imageUrl,
          ownerId: remote?['ownerId'] as String? ?? '',
          tags: List<String>.from(remote?['tags'] ?? const []),
          levelRequirement: 0,
          rank: 0,
          totalXp: totalXp,
          memberCount: memberCount,
          archetypeId: row.archetypeId,
          isVerified: remote?['isVerified'] as bool? ?? false,
          totalHabitsCompleted: totalHabits,
          totalChallengesCompleted: totalChallenges,
        );
      }).toList();

      if (!controller.isClosed) controller.add(tribes);
    });
  }

  // Bootstrap: seed local if empty
  _db.tribeStatsDao
      .getAll()
      .then((rows) async {
        if (rows.isEmpty) await _seedLocalClubs();

        // Listen to local changes — emit immediately on every change
        localSub = _db.tribeStatsDao.watchAll().listen(
          (updatedRows) {
            emitMerged();
          },
          onError: controller.addError,
        );

        // Remote: background sync, never blocks
        remoteSub = _firestore
            .collection('tribes')
            .where('type', isEqualTo: TribeType.official.name)
            .snapshots()
            .listen(
              (snapshot) {
                remoteDocs = {
                  for (final doc in snapshot.docs) doc.id: doc.data(),
                };
                emitMerged();
              },
              onError: (Object err) {
                // Remote failure: just log, stay on local data
                // UI was already rendered with local data
              },
            );
      })
      .catchError((Object e) {
        controller.addError(e);
        return null;
      });

  controller.onCancel = () {
    localSub?.cancel();
    remoteSub?.cancel();
  };

  return controller.stream;
}
```

Key change: `emitMerged()` now reads fresh local data on every emission and never blocks on remote readiness. Remote updates are merged silently in the background.

- [ ] **Step 2: Update `worldLeaderboardProvider` in tribes_provider.dart with same fix**

Apply the same pattern: emit local immediately, merge remote asynchronously.

- [ ] **Step 3: Run tribe repository tests**

```bash
flutter test test/core/drift_repositories/drift_tribe_repository_test.dart
```

Expected: All tests pass.

- [ ] **Step 4: Run tribe provider tests**

```bash
flutter test test/features/social/presentation/providers/tribe_providers_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/drift_repositories/drift_tribe_repository.dart lib/features/social/presentation/providers/tribes_provider.dart
git commit -m "fix(tribes): emit local Drift data immediately, Firestore sync non-blocking"
```

---

### Task 6: Verify everything together

- [ ] **Step 1: Run full analyzer**

```bash
dart analyze
```

Expected: No new errors (pre-existing warnings are acceptable).

- [ ] **Step 2: Run all tests**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 3: Final commit if any fixes needed**

```bash
git add -A
git commit -m "chore: final fixes after full verification"
```
