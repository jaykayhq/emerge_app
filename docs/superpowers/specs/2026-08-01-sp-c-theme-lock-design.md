# SP-C Design — Theme Lock ("Coming Soon")

> **Date:** 2026-08-01
> **Status:** Approved (design review 2026-08-01)
> **Scope:** SP-C of an 8-sub-project program (A→H). Client-only; no backend changes, no codegen, no new assets, no paywall changes.
> **Predecessor:** `2026-04-26-cosmic-theme-extension-design.md` (introduced the 6-theme picker), `2026-04-19-world-background-system-design.md` (WorldBackground renderer). SP-A (`2026-08-01-narrator-coach-tutorials-premium-limits-design.md`) shifted `settings_screen.dart` (added the Tutorials section) but left the World Theme section and picker untouched.

---

## 1. Goals

1. **Keep the main theme fully selectable** — "Cosmic Nebula" (`AppWorldTheme.nebula`) remains the only selectable world theme, exactly as it is today.
2. **Lock every other theme** — `forest`, `city`, `mountain`, `ocean`, `volcanic` render dimmed in the Settings picker with a "COMING SOON" badge; tapping one shows a non-blocking "Coming soon" snackbar. **No paywall dialog, no premium gate** — the user's intent is "locked for now", not monetized (that is future SP-B territory).
3. **Guard at the source** — `WorldThemeNotifier.setTheme` refuses locked themes, so no call site (now or future) can bypass the lock; the persisted value can only ever be `nebula`.
4. **Pure, testable lock logic** — a tiny pure `ThemeLock` unit is the single source of truth for locked/unlocked, shared by the provider and the picker (project signature pattern: pure logic in `core/domain`, unit-tested without widgets).

## 2. Recorded design decisions

| # | Decision | Choice |
|---|---|---|
| D1 | Locked set | `nebula` fully selectable; `forest`, `city`, `mountain`, `ocean`, `volcanic` get a "COMING SOON" chip in the picker + a non-blocking snackbar on tap. **Not** a paywall dialog (user said "locked for now", not premium-gated). |
| D2 | Guard at the source | `WorldThemeNotifier.setTheme` ignores any locked theme (no state change, no prefs write); `_loadFromPrefs` clamps a saved locked value to `nebula` via `ThemeLock.safeTheme`. Consequence: pre-existing users who had selected a non-nebula theme (the picker was unlocked before) are silently reset to nebula on next launch — acceptable and documented (release note). A one-time migration notice was considered and rejected as scope creep. |
| D3 | UI | Modify the private `_WorldThemePicker` **in place** in `lib/features/settings/presentation/screens/settings_screen.dart` — it is 71 lines (lines 1342–1412), under the 100-line extraction threshold. Locked tiles dim (opacity) with a small "COMING SOON" chip (top-right); tap → snackbar; tap never calls `onSelect` for locked themes. Extraction to `lib/features/settings/presentation/widgets/world_theme_picker.dart` is deferred until the widget grows (e.g., SP-B premium previews). |
| D4 | Pure logic for testability | New `ThemeLock` in `lib/core/domain/services/theme_lock.dart`: `isLocked(AppWorldTheme)` + `safeTheme(AppWorldTheme)` + a single `unlockedTheme` constant. The provider guard and the picker both consume it. |
| D5 | Out of scope | No paywall changes (SP-B), no new themes, no premium gating of themes (future work — see §8). |
| D6 | Snackbar hygiene | Use `ScaffoldMessenger.maybeOf(context)` and `hideCurrentSnackBar()` before `showSnackBar(...)` — a repeat/double tap replaces the current snackbar instead of queueing a second one. `SnackBarBehavior.floating`, ~1.5 s duration. |
| D7 | Locked tile rendering | Emoji + label wrapped in `Opacity(0.4)`; tile border/background alpha reduced; a 6.5px bold "COMING SOON" chip (white 70% on white 12% pill) pinned top-right inside the 80px tile. The selected check-circle never appears on a locked tile (it can never be selected). |
| D8 | Provider semantics | `setTheme(locked)` returns early **before** any prefs write — a locked tap must not even overwrite the stored value. `_loadFromPrefs` clamps legacy/unknown values to `nebula`. `build()` still returns `nebula` synchronously (existing async-load contract unchanged). |
| D9 | No codegen | `worldThemeProvider` is a plain (non-annotated) `NotifierProvider` — this plan adds **no** `@Riverpod` annotations and requires **no** `build_runner` step. |

## 3. Architecture

```
                    ThemeLock (pure, lib/core/domain/services/theme_lock.dart)
                     isLocked(t) / safeTheme(t) / unlockedTheme = nebula
                              ▲                    ▲
                              │                    │
        ┌─────────────────────┴──────┐      ┌──────┴──────────────────────┐
        │  WorldThemeNotifier        │      │  _WorldThemePicker          │
        │  (provider guard, D2)      │      │  (settings_screen.dart)     │
        │  setTheme: locked → no-op  │      │  locked → dim + chip        │
        │  load: clamp to nebula     │      │  tap locked → snackbar      │
        └──────────────┬─────────────┘      └──────────────┬──────────────┘
                       │                                    │
                shared_prefs                          Settings screen
                'app_world_theme' = 'nebula' only       (inside WorldBackground)
```

Layers:

- **Pure domain (new):** `ThemeLock` — the only place that knows which themes are locked. No Flutter, no storage, no Riverpod; trivially unit-testable (mirrors `CoachAskQuota` from SP-A and `resolveBackgroundAsset`).
- **Provider (modified):** `WorldThemeNotifier` — `setTheme` guards via `ThemeLock.isLocked`; `_loadFromPrefs` clamps via `ThemeLock.safeTheme`. Defense-in-depth: even if some future UI calls `setTheme(forest)` directly, it is a no-op.
- **Presentation (modified):** `_WorldThemePicker` in `settings_screen.dart` — renders locked tiles dimmed with the chip, intercepts taps with the snackbar, and only forwards unlocked selections to `onSelect` (the existing `ref.read(worldThemeProvider.notifier).setTheme(theme)` wiring at lines 85–86 stays unchanged).

## 4. Component specs

### 4.1 `ThemeLock` — pure lock logic (new file)

`lib/core/domain/services/theme_lock.dart` (new directory `lib/core/domain/services/`):

```dart
/// Single source of truth for which world themes are selectable.
///
/// `nebula` (Cosmic Nebula) is the main theme and stays unlocked; all
/// others are "coming soon" and locked. Deliberately free of Flutter,
/// storage, and Riverpod so it can be unit-tested without widgets
/// (mirrors CoachAskQuota / resolveBackgroundAsset).
class ThemeLock {
  /// The one theme users can select today.
  static const AppWorldTheme unlockedTheme = AppWorldTheme.nebula;

  static bool isLocked(AppWorldTheme theme) => theme != unlockedTheme;

  /// Clamps any theme to [unlockedTheme] when it is locked.
  /// Used on load so a legacy persisted locked value can never re-activate.
  static AppWorldTheme safeTheme(AppWorldTheme theme) =>
      isLocked(theme) ? unlockedTheme : theme;
}
```

Contract:
- `isLocked(nebula)` → `false`; `isLocked(any other)` → `true`.
- `safeTheme(nebula)` → `nebula`; `safeTheme(forest|city|mountain|ocean|volcanic)` → `nebula`.
- One constant (`unlockedTheme`) so a future unlock (e.g., SP-B premium themes) is a one-line change — no scattered `== AppWorldTheme.nebula` checks.

### 4.2 Provider guard (modify `lib/core/presentation/providers/world_theme_provider.dart`)

Current behavior (verified): plain `Notifier<AppWorldTheme>` + manual `NotifierProvider`; key `_kWorldThemeKey = 'app_world_theme'`; `build()` returns `nebula` synchronously then `_loadFromPrefs()` asynchronously; `setTheme` sets state then persists.

Changes:

1. `setTheme` — refuse locked themes before anything else:

```dart
Future<void> setTheme(AppWorldTheme theme) async {
  if (ThemeLock.isLocked(theme)) return; // locked: no state change, no write
  state = theme;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kWorldThemeKey, theme.name);
}
```

2. `_loadFromPrefs` — clamp legacy/unknown values:

```dart
final theme = AppWorldTheme.values.firstWhere(
  (t) => t.name == saved,
  orElse: () => AppWorldTheme.nebula,
);
state = ThemeLock.safeTheme(theme); // legacy 'forest' → nebula
```

Result: the persisted value can only ever be `nebula` from this point on; the async-load race cannot resurrect a locked theme because the clamp happens at read time.

### 4.3 Picker UI (modify `lib/features/settings/presentation/screens/settings_screen.dart`)

Usage site (verified, lines 78–90): section header "World Theme" → section container → `_WorldThemePicker(selected: selectedAppTheme, onSelect: (theme) => ref.read(worldThemeProvider.notifier).setTheme(theme))`. `selectedAppTheme = ref.watch(worldThemeProvider)` (line 49). The screen renders inside `WorldBackground` (line 51), which provides the `Scaffold` (world_background.dart:49) — snackbars work.

`_WorldThemePicker` (lines 1342–1412, 71 lines) changes, all inside `itemBuilder`:

1. Compute `final isLocked = ThemeLock.isLocked(theme);` alongside `isSelected`.
2. **Tap routing** — locked themes never reach `onSelect`:

```dart
onTap: () {
  if (isLocked) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Coming soon'),
          duration: Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    return;
  }
  onSelect(theme);
},
```

3. **Locked tile visuals** — wrap the emoji/label/check column in `Opacity(opacity: isLocked ? 0.4 : 1.0)`, reduce the unselected border alpha (0.15 → 0.1) and background alpha (0.05 → 0.03) when locked, and pin the chip top-right via a `Stack`:

```dart
if (isLocked)
  Positioned(
    top: 4,
    right: 4,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'COMING SOON',
        style: TextStyle(
          fontSize: 6.5,
          color: Colors.white70,
          letterSpacing: 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),
```

4. Add import `package:emerge_app/core/domain/services/theme_lock.dart`.

Copy: chip text **"COMING SOON"** (uppercase, tile); snackbar text **"Coming soon"** (sentence case, exactly per the user's phrasing).

## 5. File inventory

### New files

| Path | Responsibility |
|---|---|
| `lib/core/domain/services/theme_lock.dart` | Pure lock logic (`isLocked` / `safeTheme` / `unlockedTheme`) |
| `test/core/domain/services/theme_lock_test.dart` | Unit tests for the full theme matrix |
| `test/core/presentation/providers/world_theme_provider_test.dart` | Provider guard tests (setTheme ignore/no-write, persistence, legacy clamp) |

### Modified files

| Path | Change |
|---|---|
| `lib/core/presentation/providers/world_theme_provider.dart` | `setTheme` lock guard; `_loadFromPrefs` clamp via `ThemeLock.safeTheme` |
| `lib/features/settings/presentation/screens/settings_screen.dart` | `_WorldThemePicker` locked-tile rendering + snackbar tap routing; import |
| `test/features/settings/presentation/screens/settings_screen_test.dart` | New "World theme lock" group (chip count, tap snackbar, unlocked selection); `FakeWorldThemeNotifier` gains a recording `setCalls` list |

### Deleted files

None.

## 6. Error handling & edge cases

1. **Legacy persisted non-nebula value** (users who picked `forest`/`city`/etc. while the picker was unlocked): `_loadFromPrefs` clamps to `nebula` via `ThemeLock.safeTheme` — a silent one-time reset to the main theme. Acceptable per D2; call out in release notes. Rejected alternative: a one-time "your theme is coming soon" dialog (scope creep).
2. **Unknown/garbage saved value** (e.g., `'jupiter'`): existing `firstWhere(orElse: nebula)` already falls back to `nebula`; the clamp is a no-op on top.
3. **Double-tap / repeat taps on a locked tile**: `hideCurrentSnackBar()` before `showSnackBar(...)` replaces rather than queues; the guard means no state or prefs change can occur regardless of tap count.
4. **Picker inside WorldBackground**: the Settings background derives from `worldThemeProvider` (world_background.dart:33). Because the provider refuses locked themes, the background can never swap to a locked theme from the picker. The snackbar surfaces above the Scaffold that `WorldBackground` provides.
5. **Other call sites**: grep-verified — `setTheme` has exactly one caller today (settings_screen.dart:86). The notifier-level guard (D2) covers any future caller; this is the point of guarding at the source.
6. **Prefs write failure**: `setTheme` was already unawaited and silent; the guard adds no new failure surface. Locked taps now perform zero async work.
7. **Async load race**: `build()` returns `nebula` synchronously and `_loadFromPrefs` resolves later; the clamp runs at read time, so a stale locked value can never flip the state after load.
8. **ScaffoldMessenger absence**: `ScaffoldMessenger.maybeOf` — if the picker is ever rendered outside a Scaffold, a locked tap is a silent no-op instead of a crash.
9. **Horizontal overflow**: 6 tiles × 80px + 5 × 10px separators = 530px; on a ~390px phone the last tiles ('Ocean Abyss', 'Volcanic Realm') require scrolling — expected, unchanged from today (the picker already scrolls). Locked styling applies identically to off-screen tiles.

## 7. Testing strategy

| Level | File | Coverage |
|---|---|---|
| Pure unit | `test/core/domain/services/theme_lock_test.dart` | All 6 themes × `isLocked`; `safeTheme` identity for nebula and clamp for all locked; `unlockedTheme == AppWorldTheme.nebula` |
| Provider | `test/core/presentation/providers/world_theme_provider_test.dart` | `setTheme(forest)` → state stays `nebula` **and** prefs key absent; `setTheme(nebula)` → state + prefs `'nebula'`; prefs seeded `'forest'` → loads as `nebula`; prefs seeded `'jupiter'` → loads as `nebula` (uses `SharedPreferences.setMockInitialValues`) |
| Widget | `test/features/settings/presentation/screens/settings_screen_test.dart` (new "World theme lock" group) | Exactly 5 `COMING SOON` chips; tapping a locked tile ('Living') shows the `Coming soon` snackbar and records **no** `setTheme` call; tapping the unlocked tile ('Cosmic') selects and shows no snackbar |

Harness notes (verified against the existing test file): reuse `createTest()`; extend `FakeWorldThemeNotifier` (currently only overrides `build()`) with a `setCalls` list whose override records then calls `super.setTheme` — the real guard runs, so `setCalls` stays empty for locked taps. Follow the file's existing `await tester.pump()` ×2 rhythm — **do not** use `pumpAndSettle` (WorldBackground runs continuous animations). 'Living' (forest) is the second tile, visible at 800px test width without scrolling; add `ensureVisible` for robustness.

Regression: existing settings tests ('renders settings screen', Tutorials group) must stay green — the picker change is additive.

## 8. Out of scope

- **Paywall / premium gating of themes (SP-B):** locked themes are NOT a premium perk here. The existing `PremiumThemePreview` widget (`lib/features/monetization/presentation/widgets/premium_theme_preview.dart`) is currently **unused** (grep-verified: zero imports in `lib/`); SP-C does not wire it. Future work: re-enable themes as premium unlocks — at that point the lock moves from `ThemeLock` to a premium check and the preview widget may become the picker's locked-tile treatment.
- **New themes / asset work:** the 5 image themes' asset folders already exist (`assets/images/backgrounds/{city,forest,mountain,ocean,volcanic}/`); they are simply unreachable through the UI.
- **WorldBackground rendering changes:** no renderer edits; `themeOverride` hardcode in the timeline stays.
- **One-time migration notice** for legacy non-nebula users (rejected in D2).
- **Deleting `PremiumThemePreview`** — optional cleanup for a later housekeeping pass, not SP-C.

## 9. Risks

| Risk | Mitigation |
|---|---|
| Legacy users silently reset to nebula | Accepted (D2); release-note item; no data loss (single prefs string) |
| Widget tests hang on continuous WorldBackground animations | Use the existing `pump()` rhythm; never `pumpAndSettle` in the settings harness |
| Lock logic duplicated across picker + provider | `ThemeLock` is the single source of truth; both consumers import it (D4) |
| Future unlock requires touching many files | Unlock = flip `ThemeLock.unlockedTheme` (or swap to premium check in SP-B); picker/provider need no structural change |
| `settings_screen.dart` keeps growing (SP-A already added the Tutorials section) | Picker stays under ~115 lines after the lock treatment; extraction decision re-checked when it exceeds ~150 lines or gains premium previews |

## 10. Open questions

None — all decisions recorded above.
