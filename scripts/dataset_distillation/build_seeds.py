#!/usr/bin/env python3
"""Build seeds.jsonl — the curated fine-tuning dataset for emerge_app.

Each example is a ShareGPT-style conversation:
    {"category": str,
     "conversations": [
        {"from": "system", "value": <SYSTEM_PROMPT.md>},
        {"from": "human", "value": <prompt>},
        {"from": "gpt",    "value": <response>},
     ]}

The system prompt is read from SYSTEM_PROMPT.md (single source of truth).
Run:  python build_seeds.py
Writes: seeds.jsonl (in this directory).
"""

from __future__ import annotations

import json
from pathlib import Path

HERE = Path(__file__).parent
SYSTEM_PROMPT = (HERE / "SYSTEM_PROMPT.md").read_text(encoding="utf-8")


def ex(category: str, prompt: str, response: str) -> dict:
    return {
        "category": category,
        "conversations": [
            {"from": "system", "value": SYSTEM_PROMPT},
            {"from": "human", "value": prompt.strip()},
            {"from": "gpt", "value": response.strip()},
        ],
    }


EXAMPLES: list[dict] = []

# ---------------------------------------------------------------------------
# 1. ARCHITECTURE & LAYOUT
# ---------------------------------------------------------------------------
ARCH = "architecture_layout"

EXAMPLES += [
    ex(ARCH,
    "Where should I put a new 'rewards' feature in emerge_app?",
    """Feature-first layout. Create the three-layer folder under `lib/features/rewards/`:

```
lib/features/rewards/
├── presentation/
│   ├── screens/rewards_screen.dart
│   └── providers/rewards_provider.dart
├── domain/
│   ├── entities/reward.dart
│   └── repositories/reward_repository.dart   // abstract interface
└── data/
    └── repositories/firebase_reward_repository.dart
```

Mirror it under `test/features/rewards/...`. `presentation` = widgets/screens/providers, `domain` = entities + repository interfaces, `data` = Firebase implementations. Shared/cross-feature code goes in `lib/core/`. Follow the pattern already used by `lib/features/social/` and `lib/features/auth/`."""),

    ex(ARCH,
    "Should this helper go in lib/core/ or the feature folder?",
    """If it's used by more than one feature, `lib/core/` (e.g. `lib/core/utils/app_logger.dart`, `lib/core/presentation/widgets/emerge_primary_button.dart`). If it's only used inside one feature, keep it inside `lib/features/<feature>/` so the feature stays cohesive and removable. A good test: could you delete the feature folder and leave `core/` compiling? If yes, the boundary is right."""),

    ex(ARCH,
    "How do I add a new Riverpod provider the emerge_app way?",
    """Annotated + codegen. Create the file, annotate, declare the `part`, then run build_runner.

```dart
// lib/features/rewards/presentation/providers/rewards_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rewards_provider.g.dart';

@riverpod
Future<List<Reward>> rewards(Ref ref) async {
  final repo = ref.watch(rewardRepositoryProvider);
  return repo.fetchAll();
}
```

Then generate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Never hand-edit `rewards_provider.g.dart`. For singletons (Firebase instances, repos) use `@Riverpod(keepAlive: true)` — see `lib/features/auth/presentation/providers/auth_providers.dart` for the established pattern (`firebaseAuth`, `firestore`, `authRepository`)."""),

    ex(ARCH,
    "I added @riverpod but my provider name isn't found. What's wrong?",
    """You need to run code generation — the `*Provider` symbol lives in the generated `*.g.dart`. Check three things:

1. The file has `part 'your_file.g.dart';` matching the filename.
2. The parameter is `Ref ref` (Riverpod 3.x), not the old `WidgetRef`/`ProviderRef`.
3. Run build_runner:

```bash
dart run build_runner build --delete-conflicting-outputs
```

If it still fails, check the analyzer output — `dart analyze lib/` will point at the exact file. Compare against a working one like `lib/features/auth/presentation/providers/auth_providers.dart`."""),
]

EXAMPLES += [
    ex(ARCH,
    "Should I use ConsumerWidget or ConsumerStatefulWidget?",
    """Default to `ConsumerWidget` (the project norm — e.g. `lib/features/social/presentation/screens/tribe_lobby_screen.dart`, `lib/features/social/presentation/widgets/tribe_creators_strip.dart`). Use `ConsumerStatefulWidget` only when you need a `TickerProvider` (animations, `SingleTickerProviderStateMixin`, `AppLifecycleState` listeners), local mutable UI state with `initState`/`dispose`, or a `ScrollController`/`TextEditingController` you must dispose.

Inside `ConsumerWidget.build` you get `WidgetRef ref` as a parameter — `ref.watch` here. Avoid `StatefulWidget` + manual `ProviderScope`; that's the pre-Riverpod pattern. If you find yourself reaching for `setState`, ask whether the state belongs in a provider instead."""),

    ex(ARCH,
    "How do I represent a domain entity in this project?",
    """Plain Dart class, typically `Equatable` for value equality (the project depends on `equatable: ^2.0.7`). See `lib/features/social/domain/entities/creator_profile.dart`:

```dart
import 'package:equatable/equatable.dart';

class CreatorProfile extends Equatable {
  final String userId;
  final String role;
  final String displayName;
  final bool isVerifiedCreator;

  const CreatorProfile({
    required this.userId,
    required this.role,
    required this.displayName,
    required this.isVerifiedCreator,
  });

  @override
  List<Object?> get props => [userId, role, displayName, isVerifiedCreator];
}
```

Entities live in `domain/entities/`, hold no Flutter imports, and carry no persistence logic. Equality via `props` matters because Riverpod/`AsyncValue` and `Equatable`-based widgets rely on `==` to skip rebuilds."""),

    ex(ARCH,
    "Where does a repository interface live vs its implementation?",
    """Interface in `domain/repositories/`, implementation in `data/repositories/`. The provider wires them:

```
domain/repositories/auth_repository.dart      // abstract class AuthRepository
data/repositories/firebase_auth_repository.dart // class FirebaseAuthRepository implements AuthRepository
```

In `auth_providers.dart`, `authRepositoryProvider` returns `FirebaseAuthRepository(ref.watch(firebaseAuthProvider), ref.watch(firestoreProvider))`. This is what makes fakes/overrides possible in tests — you override the *provider*, not the class. Don't put a concrete Firebase type in the `domain/` interface; that couples your domain to a vendor."""),

    ex(ARCH,
    "I keep seeing AppLogger.d / AppLogger.w. Why not print()?",
    """`print()` ships to release builds and clutters prod logs; `AppLogger` (in `lib/core/utils/app_logger.dart`) routes through the `logger` package and respects build mode. The project uses it wherever providers do real work — e.g. `AppLogger.d('signUpCreator: wrote creator_profiles/${user.uid}')`, and failures via `AppLogger.w(..., error: e, stackTrace: s)`.

Use `AppLogger.d` for debug, `.w` for warnings with stack traces, `.e` for errors. Never `print`. This also keeps Crashlytics (already wired via `firebase_crashlytics`) fed with structured records rather than raw strings."""),

    ex(ARCH,
    "How do I add a new image asset the right way?",
    """Two steps, both required. First declare it under `flutter: assets:` in `pubspec.yaml` (the project lists subdirectories like `assets/images/challenges/`, `assets/images/levels/athlete/`). A new subdirectory needs its own list entry:

```yaml
flutter:
  assets:
    - assets/images/campaigns/   # new line
```

If you skip the pubspec entry you'll get an "unable to load asset" error at runtime that `dart analyze` won't catch — that's a build/runtime check, not static. After editing pubspec run `flutter pub get`. Verify the asset loads with `flutter run`."""),

    ex(ARCH,
    "What state management should I pick for a new feature?",
    """Riverpod — it's the only choice in this codebase (no Bloc/Provider packages in `pubspec.yaml`). Use annotated providers:

- `@riverpod` (auto-dispose) for screen-scoped / transient data.
- `@Riverpod(keepAlive: true)` for singletons (`firebaseAuth`, `firestore`, `authRepository`) and long-lived global state.
- `Future<...>` provider for one-shot async (reads, signups).
- `Stream<...>` provider for reactive Firebase data (`authStateChangesProvider`, `userStatsStreamProvider`).
- `Notifier`/`AsyncNotifier` for stateful controllers (see `onboardingControllerProvider`).

Don't introduce `setState`-driven architecture or a second state library. For local UI-only state (a toggle, a text field), `ConsumerStatefulWidget` + `TextEditingController` is fine."""),

    ex(ARCH,
    "main.dart is missing something — how is the app bootstrapped with Riverpod and Firebase?",
    """Wrap the root in `ProviderScope` and initialize Firebase before `runApp`. The project's `lib/main.dart` follows this. The skeleton:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: EmergeApp()));
}
```

`ProviderScope` must be the outermost widget — every `ref.watch` in the tree depends on it being an ancestor. If a widget test redscreens with "ProviderScope is required", you forgot it in `pumpWidget`. Crashlytics/Remote Config init also belongs here, before `runApp`."""),
]

EXAMPLES += [
    ex(ARCH,
    "How do I pass dependencies into a provider — constructor or ref.watch?",
    """`ref.watch` inside the provider body, never constructor injection. The provider function receives `Ref ref` and pulls its collaborators from other providers:

```dart
@riverpod
Future<bool> isCreator(Ref ref, String uid) async {
  final firestore = ref.watch(firestoreProvider);   // collaborator via watch
  final doc = await firestore.collection('creator_profiles').doc(uid).get();
  return doc.exists;
}
```

This is what makes overrides work in tests (`firestoreProvider.overrideWithValue(fakeFirestore)`). If you hardcoded `FirebaseFirestore.instance` directly, you couldn't fake it. Watch the granular provider (`firestoreProvider`), not a god-object — small providers compose and override independently."""),

    ex(ARCH,
    "What's the difference between @riverpod and @Riverpod(keepAlive: true)?",
    """Lifecycle. `@riverpod` is **auto-dispose**: the provider's state is destroyed when no widget is listening, so it re-runs next time it's watched. Use it for screen-scoped/transient data (a detail screen's fetch, a form's state).

`@Riverpod(keepAlive: true)` keeps the state alive for the app's lifetime even with zero listeners. Use it for singletons and expensive global state — in `auth_providers.dart`, `firebaseAuth`, `firestore`, and `authRepository` are all `keepAlive: true` because they're process-wide and cheap to hold. `signOut` is also keepAlive (it's an action you call from anywhere).

Picking wrong has real symptoms: auto-dispose on something that should persist → data refetches on every navigation (slow, flicker); keepAlive on screen state → memory leak + stale data after leaving and returning. When in doubt, default to auto-dispose `@riverpod` and promote to keepAlive only when you observe unnecessary refetch."""),

    ex(ARCH,
    "Should a screen reach into multiple feature folders?",
    """Prefer not — if `features/social/` screens import heavily from `features/auth/` and vice versa, the feature boundary is leaking. Two legitimate cross-feature patterns:

1. **Through `lib/core/`** — shared widgets (`EmergePrimaryButton`), utils (`AppLogger`), theme. These are designed to be shared.
2. **Through providers** — a social screen reading `currentUserRoleProvider` (from auth) is fine; providers are the public API across features.

What's *not* fine: a social screen directly importing an auth-private widget or repository class. If two features need the same domain concept, lift it to `core/` (a shared entity/provider), don't reach across. The feature folders should remain independently deletable."""),

    ex(ARCH,
    "How do I name providers and their generated symbols?",
    """Name the function for what it *returns/does*, in camelCase; the generator appends `Provider`. Examples from the codebase: `firestore` → `firestoreProvider`, `authStateChanges` → `authStateChangesProvider`, `isCreator` → `isCreatorProvider`, `signUpCreator` → `signUpCreatorProvider`.

For family providers (parameterized), the parameter follows: `isCreator('uid')` → `isCreatorProvider('uid')`. Keep names behavior-focused (`isCreator`, `currentUserRole`) not implementation-focused (`firestoreQueryForUserDoc`). One provider = one responsibility; if the name needs "and", split it."""),

    ex(ARCH,
    "Where does drift (SQLite) code live and how is it accessed?",
    """Drift repositories live under `lib/core/drift_repositories/` (cross-feature local storage, e.g. `drift_user_stats_repository.dart`) or under a feature's `data/` if it's feature-specific. Access always goes through a Riverpod provider that returns the drift database, so tests can override it with an in-memory drift instance.

Don't call drift directly from widgets or even from other providers' bodies without going through the provider. The provider boundary is what lets you swap remote/local sources and run tests offline. Keep the drift schema/tables in one place and regenerate with build_runner alongside Riverpod."""),

    ex(ARCH,
    "How should I structure a feature that has both a UI and a background task?",
    """Split along the presentation/domain/data line and keep the background work in `domain/services/` (pure-ish orchestration) triggered by a provider. The social feature models this: `lib/features/social/domain/services/club_activity_service.dart` and `contact_resolver.dart` hold the logic, with providers in `presentation/providers/` exposing it, and tests like `club_activity_service_partner_fanout_test.dart` and `contact_resolver_test.dart` unit-testing the services directly.

The background task is a provider (often `keepAlive`) that calls the service. The UI watches a separate provider for the user-facing state. This keeps the fanout/resolution logic testable without Flutter, and the UI thin. Don't bury background logic inside a widget's lifecycle method."""),

    ex(ARCH,
    "What imports does a typical provider file have?",
    """The standard set, visible in `auth_providers.dart`: `flutter_riverpod` (for `Ref` if not via annotation), `riverpod_annotation`, the domain interfaces + entities it depends on, the Firebase packages aliased to avoid clashes (`firebase_auth` as `firebase_auth`), and `part 'this_file.g.dart'`. Plus `fpdart` if returning `Either`.

A common mistake is importing `flutter_riverpod`'s old `Provider`/`StateProvider` and mixing manual providers with annotated ones — pick the annotated codegen style the project already uses. Keep imports sorted (the project's `analysis_options` uses `flutter_lints`); run `dart format` + `dart analyze` before committing."""),

    ex(ARCH,
    "How do I keep a provider's output from rebuilding the whole screen?",
    """Scope what you `select`. With `AsyncValue`, watch the provider and `.when`-render, but for a large object where only one field drives a sub-widget, use `.select` to watch just that field so the rest of the screen doesn't rebuild on unrelated changes:

```dart
final name = ref.watch(userProvider.select((u) => u.valueOrNull?.displayName));
```

Also: keep providers granular (one concern each) so a change in one doesn't invalidate a giant tree. And put expensive sub-trees in their own widgets with their own `Consumer`, so a parent rebuild doesn't re-run their `build`. Avoid watching a high-frequency stream provider high in the tree — push it down to the leaf that needs it."""),

    ex(ARCH,
    "Should error/empty/loading states be shared widgets?",
    """Yes — reuse the project's shared states. `AppErrorWidget` (used by `_BlueprintByIdLoader`) standardizes the error + retry surface; a centered `CircularProgressIndicator` in a `Scaffold` is the loading norm. Don't invent per-screen error widgets; consistency matters and `AppErrorWidget` already wires `onRetry`.

For empty states, a shared widget or at least a consistent layout (icon + message + CTA) is preferable to ad-hoc `Text('nothing here')`. If you find a third screen reimplementing the same error card, extract it to `lib/core/presentation/widgets/`."""),

    ex(ARCH,
    "How do I decide if a provider belongs in lib/core/ vs the feature?",
    """If more than one feature consumes it, `lib/core/` (e.g. `firestoreProvider`, `firebaseAuthProvider`, theme, nav shell, `AppLogger`). If exactly one feature uses it, keep it in `lib/features/<feature>/presentation/providers/` so the feature stays cohesive and removable.

A litmus test: delete the feature folder — does `core/` still compile and mean something? If a provider in the feature is actually used across features, it's misllocated: move it to `core/` (and its test to `test/core/`). Don't let `core/` accumulate feature-specific junk either — that breaks the symmetry."""),
]

# ---------------------------------------------------------------------------
# 2. TESTABLE DESIGN (the project's signature pattern)
# ---------------------------------------------------------------------------
TEST = "testable_design"

EXAMPLES += [
    ex(TEST,
    "My router redirect logic is hard to test. How does emerge_app handle this?",
    """The project's house style: extract the decision into a **pure function + plain data struct**, then unit-test it directly without GoRouter/Riverpod/Firebase.

The canonical example is `lib/core/router/router.dart`:

```dart
class RedirectContext {
  final bool isLoggedIn;
  final UserRole? role;
  final bool isFirstLaunch;
  final int? userOnboardingProgress;
  // ...const constructor
}

String? decideRedirect({required String currentPath, required RedirectContext ctx}) {
  if (currentPath == '/splash') return null;
  // pure decisions, no ref.read, no side effects
}
```

The real `router()` provider builds the `RedirectContext` from providers and calls `decideRedirect` inside the `redirect:` closure. Tests in `test/core/router/router_redirect_test.dart` just construct a `RedirectContext` and assert the return — no framework spin-up. Apply the same split to your feature: pure decider + thin framework adapter."""),

    ex(TEST,
    "I have a signup form with validation, API call, and navigation all in onPressed. How do I make this testable?",
    """Split it into three layers and test the pure one:

1. **Pure validation** — a top-level function taking inputs, returning `Either<String, T>` or a result object. No Flutter imports.
2. **Side-effecting action** — a Riverpod `Future` provider that calls the repo and throws on failure (see `signInProvider` / `signUpCreatorProvider` in `lib/features/auth/presentation/providers/auth_providers.dart`).
3. **Widget** — reads the provider, calls `ref.read(signInProvider(...).future)`, navigates on success.

Test layer 1 exhaustively with `flutter_test` (no mocks needed). Test the widget with `fake_cloud_firestore` / `firebase_auth_mocks`. The button handler becomes thin glue — it shouldn't contain logic worth testing in isolation."""),

    ex(TEST,
    "How do I test a provider that reads Firestore without hitting real Firebase?",
    """Override the `firestoreProvider` with `fake_cloud_firestore`'s instance. Seed it, then read your provider from a `ProviderContainer`.

```dart
final fakeFirestore = FakeCloudFirestore();
await fakeFirestore.collection('users').doc('u1').set({'role': 'creator'});

final container = ProviderContainer(overrides: [
  firestoreProvider.overrideWithValue(fakeFirestore),
]);

addTearDown(container.dispose);

final result = await container.read(isCreatorProvider('u1').future);
expect(result, isTrue);
```

This mirrors how `lib/features/auth/presentation/providers/auth_providers.dart` injects `firestoreProvider` — you only override that one provider, and everything downstream resolves to the fake. Prefer fakes over `mocktail` mocks for Firestore/auth; reserve mocks for things with no fake available."""),

    ex(TEST,
    "How should I structure a redirect-gated screen like the social hub?",
    """Follow `/social` in `router.dart`: keep the *gate* as a tiny `redirect:` on the route, but push the *decision* into a testable place. The social hub checks `socialOnboardingCompletedProvider`:

```dart
GoRoute(
  path: '/social',
  builder: (context, state) => const TribeLobbyScreen(),
  redirect: (context, state) {
    final asyncComplete = ref.read(socialOnboardingCompletedProvider);
    if (asyncComplete.isLoading) return null;          // hold while resolving
    final isComplete = asyncComplete.value ?? false;
    if (!isComplete && !state.uri.path.startsWith('/social/onboarding')) {
      return '/social/onboarding';
    }
    return null;
  },
  routes: [ /* child routes */ ],
),
```

Note `ref.read` inside `redirect` (not `ref.watch` — that loops), and "hold while loading" to avoid flapping. The completion predicate itself (`socialOnboardingCompletedProvider`) is what you unit-test, not the GoRoute."""),
]

EXAMPLES += [
    ex(TEST,
    "I want to unit-test the onboarding-step → next-route mapping. How?",
    """Don't test it through the router — extract a pure mapping and test it directly, the way `decideRedirect` works. For example, a function that takes a progress int + role and returns the next step path:

```dart
String nextOnboardingStep({required UserRole role, required int progress}) {
  if (role == UserRole.creator) {
    return switch (progress) {
      0 => '/onboarding/creator/archetype',
      1 => '/onboarding/creator/profile',
      _ => '/onboarding/creator/reveal',
    };
  }
  // ...normal-user mapping
}
```

Test it with a table of `(role, progress) → expectedPath` inputs. No `ProviderContainer`, no GoRouter. Then the router's `decideRedirect` just *calls* it. This is the exact split `router_redirect_test.dart` exploits — pure function, plain inputs, exhaustive branch coverage cheaply."""),

    ex(TEST,
    "What's the difference between a unit test and a widget test here, and when do I use each?",
    """- **Unit test** (`test/...`, plain `test('...', () {})`): pure logic, providers, mappers, `decideRedirect`. No Flutter widget tree. Fast. Use these for anything with no rendering.
- **Widget test** (`testWidgets('...', (tester) async {})`): pumps a widget with `ProviderScope`/`MaterialApp`, asserts on the rendered tree. Slower. Use for screens/widgets and their `ref.watch` wiring.

Rule of thumb: if the logic can live in a top-level function or a provider, pull it out and unit-test it (see `test/features/social/domain/services/contact_resolver_test.dart`, `club_activity_service_partner_fanout_test.dart` — domain services are unit-tested, not widget-tested). Reserve widget tests for things that only make sense as widgets."""),

    ex(TEST,
    "How do I test a widget that calls a FutureProvider on button press?",
    """Pump the widget inside `ProviderScope`, override the provider with a controllable fake, tap the button, pump until settled, then assert.

```dart
testWidgets('calls signIn on press', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [signInProvider.overrideWith((ref, e, p) async {})],
      child: const MaterialApp(home: LoginScreen()),
    ),
  );

  await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
  await tester.pump();

  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();   // resolve the async provider
});
```

The `pumpAndSettle` is essential — the FutureProvider resolves asynchronously and the tree won't settle until it does. Override the *provider*, not the repository, so the widget stays real. Avoid `sleep`; use `pumpAndSettle`."""),

    ex(TEST,
    "Should my repository tests use mocktail or fake_cloud_firestore?",
    """Prefer `fake_cloud_firestore` for Firestore-backed repos, because it exercises your real query logic (where clauses, ordering, transforms) against an in-memory stand-in — mocks only check that a method was called, not that the query is correct.

For Firebase Auth, use `firebase_auth_mocks`. Reserve `mocktail` for true collaborators you don't own (an HTTP API, a Cloud Function callable with no fake) where you need to assert *interaction* or inject specific responses. The project keeps both in dev_dependencies precisely for this split. Don't mock Firestore — fake it."""),

    ex(TEST,
    "How do I test the _BlueprintByIdLoader's error path?",
    """`_BlueprintByIdLoader` in `router.dart` uses `.when()` on an `AsyncValue` and renders `AppErrorWidget` with a retry that calls `ref.invalidate`. Test by overriding `blueprintByIdProvider` to emit an `AsyncError`:

```dart
testWidgets('shows error + retry on failure', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        blueprintByIdProvider('x').overrideWith((ref) => Stream.error(Exception('boom'))),
      ],
      child: const MaterialApp(home: _BlueprintByIdLoader(blueprintId: 'x')),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.byType(AppErrorWidget), findsOneWidget);
  expect(find.textContaining('Failed to load'), findsOneWidget);
});
```

The lesson is general: providers that return `AsyncValue` have loading/error/data branches — your test should cover all three by overriding the provider's output, not by mocking deep internals."""),
]

EXAMPLES += [
    ex(TEST,
    "My service class has 8 dependencies. It's hard to test. What do I do?",
    """That's a design signal, not a test problem — the TDD skill's "When Stuck" table says "Must mock everything → code too coupled." 8 dependencies means the class is doing 8 things. Refactor before testing:

1. Split the service into smaller collaborators, each with 1-2 dependencies (see how `club_activity_service` and `contact_resolver` are separate services in `lib/features/social/domain/services/`).
2. Each smaller service is independently unit-testable with one or two fakes.
3. The orchestrator that wires them is tested with a couple of fakes for the leaf collaborators.

You'll end up with more, smaller tests that each pin one behavior — far better than one brittle mega-test. The difficulty *was* the feedback; don't power through it with 8 mocks."""),

    ex(TEST,
    "How do I test a provider that depends on three other providers?",
    """Override only the *leaf* collaborators and let the rest resolve naturally in a `ProviderContainer`:

```dart
final container = ProviderContainer(overrides: [
  firestoreProvider.overrideWithValue(fakeFirestore),
  firebaseAuthProvider.overrideWith(() => ...mock auth...),
]);
addTearDown(container.dispose);

// myProvider depends on firestore + auth providers internally; they resolve.
final result = await container.read(myProvider('uid').future);
expect(result, expected);
```

Don't override `myProvider` itself (that defeats the test) and don't mock the intermediate providers — override the leaves (`firestoreProvider`, `firebaseAuthProvider`) so the real dependency graph under test is exercised. This catches wiring bugs that mocking the whole chain would hide."""),

    ex(TEST,
    "How do I test that a side effect (a Firestore write) happened?",
    """Use `fake_cloud_firestore`, perform the action, then *read back from the fake* to assert the write:

```dart
final fake = FakeCloudFirestore();
// ...override firestoreProvider with `fake`...
await container.read(signUpCreatorProvider(email, pass, name).future);

final snap = await fake.collection('creator_profiles').doc(uid).get();
expect(snap.exists, isTrue);
expect(snap.data()!['role'], 'creator');
```

This tests the *outcome* (the doc exists with the right shape), not the implementation (that a specific method was called). Mocks assert interaction; fakes let you assert real effects. Prefer the latter — it survives internal refactors and catches query/data bugs that mocks can't see."""),

    ex(TEST,
    "What's a 'characterization test' and when do I write one?",
    """A characterization test pins the *current* behavior of existing code (it passes today) so you can refactor safely underneath it. You write it when adopting untested legacy code: capture behavior with tests, *then* refactor, keeping them green.

It differs from TDD red-green: a characterization test doesn't fail first (the behavior already exists). But it must assert something *meaningful* — if no plausible change could break it, it's noise, delete it. Use characterization tests as a safety net for the `decideRedirect`-style pure functions when you find old, untested logic; then evolve them toward proper red-green as you change behavior."""),

    ex(TEST,
    "How do I test the splash screen's routing without a real navigator?",
    """Splash's routing decision should be pure or in a provider you can read directly — test that, not the `context.go` call. If splash reads `authStateChangesProvider` + `currentUserRoleProvider` and picks a destination, extract the pick into a function/provider:

```dart
String splashDestination({required bool loggedIn, required UserRole? role, ...}) { ... }
```

Then unit-test `splashDestination` across the states (logged out → `/welcome`, creator mid-resolve → hold, creator complete → `/creator/dashboard`). The widget test only needs to verify it *calls* `context.go` with the provider's result. This is the same pure-extraction pattern `decideRedirect` uses — keep the decision out of the widget."""),

    ex(TEST,
    "How much should one test assert?",
    """One behavior. The TDD skill: a test name with "and" should be split. Each test sets up the minimum, exercises one thing, and asserts one contract:

```dart
test('redirects unauthenticated user on / to /welcome', () {
  final ctx = const RedirectContext(isLoggedIn: false, role: null, ...);
  expect(decideRedirect(currentPath: '/', ctx: ctx), '/welcome');
});
```

Note how `router_redirect_test.dart` has ~20 tiny tests, each one branch — that's the style. When one breaks you know exactly which contract. Avoid the "testEverything" test with 15 assertions that fails opaquely. More, smaller tests beat fewer, bigger ones."""),

    ex(TEST,
    "Should I test private (`_`) functions?",
    """Generally no — test through the public API. Private helpers are implementation details; a test that calls `_helper` directly breaks on every refactor and doesn't prove user-facing behavior. If a private function has genuinely complex logic worth testing, that's usually a signal to extract it into a public, pure function in the same file or a sibling — then test *that* (this is exactly how `decideRedirect` came to be a top-level function).

The exception is a private widget like `_BlueprintByIdLoader` — test it via `pumpWidget`, treating it as public from the test's perspective. The rule: test behavior exposed through the public surface; refactor to expose behavior that's currently hard to reach."""),

    ex(TEST,
    "How do I keep widget tests from being flaky around async providers?",
    """Two habits eliminate most widget-test flakiness:

1. **`await tester.pumpAndSettle()`** after any action that triggers an async provider — it pumps frames until no animation/schedule is pending, so the `AsyncValue` has resolved. Don't assert before settling.
2. **Override async providers with synchronous fakes** where you can, so there's no race to settle through — e.g. override `myProvider` with `overrideWith((ref) => ValueNotifier(Data(x)))` style or a fake that returns immediately.

Never use `sleep`/`Future.delayed` to "wait" in a test — it masks races and slows the suite. If `pumpAndSettle` times out, you have an animation or stream that never settles; fix *that*, don't extend the timeout."""),

    ex(TEST,
    "How do I test error handling in a provider that catches exceptions?",
    """Force the error via an override and assert the provider's *output* reflects it gracefully (not that it threw). For a provider that catches Firestore failures and returns `Failure`:

```dart
final container = ProviderContainer(overrides: [
  rewardRepositoryProvider.overrideWithValue(_ThrowingRepo()),
]);
final result = await container.read(fetchRewardsProvider('u').future);
expect(result.isLeft(), isTrue);
expect(result.fold((f) => f, (_) => null).message, 'network');
```

The `_ThrowingRepo` is a tiny fake implementing the repo interface that throws. You're asserting the provider *handled* the error (returned `Left(Failure)`), which is the contract that matters — not the exception type internally. This is more valuable than testing that it rethrows."""),

    ex(TEST,
    "What testing libraries are already available in this repo?",
    """From `pubspec.yaml` dev_dependencies: `flutter_test` (SDK), `mocktail: ^1.0.0` (mocks), `fake_cloud_firestore: ^4.1.1` (Firestore fake), `firebase_auth_mocks: ^0.15.2` (Auth fake), `mockito: ^5.6.4` (also present — but prefer `mocktail` for new tests; the project leans mocktail), `integration_test` (SDK, for integration tests), `build_runner` (codegen), `flutter_lints`.

Don't add a new test framework. Use `fake_cloud_firestore` + `firebase_auth_mocks` for Firebase, `mocktail` for external collaborators, `flutter_test` for everything else. Check existing tests (`test/features/social/...`) for the established idioms before inventing new helpers."""),

    ex(TEST,
    "How do I test a Notifier/AsyncNotifier state transition?",
    """Drive the notifier through its public methods and assert the state after each, using a `ProviderContainer`:

```dart
final container = ProviderContainer();
addTearDown(container.dispose);
final notifier = container.read(onboardingControllerProvider.notifier);

expect(container.read(onboardingControllerProvider).progress, 0);
notifier.advance();
expect(container.read(onboardingControllerProvider).progress, 1);
```

Use `.notifier` to get the controller and call its methods; re-`read` the provider to observe state. One transition per test. For `AsyncNotifier`, assert on `AsyncData`/`AsyncLoading`/`AsyncError` appropriately. Don't reach into private fields — exercise the public surface that real code uses."""),

    ex(TEST,
    "When is it OK to skip writing a test?",
    """The TDD skill lists the exceptions and they're narrow: throwaway prototypes, generated code (`*.g.dart`), and pure configuration files — and even then, "ask your human partner first." Everything else (features, bugfixes, refactors, behavior changes) gets a test.

"This is trivial" / "I'll add it later" / "The existing tests cover it" are *rationalizations* in the skill's table, not valid exceptions. If you're tempted to skip, that's the moment to stop and write the test — the trivial case is exactly when the test is cheap to write and the omission is costliest later. If you genuinely believe an exception applies, surface it and get a yes before skipping."""),
]

# ---------------------------------------------------------------------------
# 3. TDD DISCIPLINE
# ---------------------------------------------------------------------------
TDD = "tdd_discipline"

EXAMPLES += [
    ex(TDD,
    "I've already written the function, can I just add tests now?",
    """That's tests-after, not TDD — and tests written after code pass immediately, which proves nothing (you might be testing the wrong thing, or testing implementation instead of behavior).

Per the project's TDD Iron Law: delete the implementation, write the test first, watch it fail for the right reason, then reimplement minimally.

Concretely:
1. Delete your function (or git-stash it out of sight — don't peek).
2. Write one test naming the behavior.
3. `flutter test path/...` — confirm it **fails** because the feature is missing (not because of a typo).
4. Write the simplest code that passes.
5. Run again — green.

It feels slower, but it's faster than debugging an untested assumption later. If the function is throwaway/exploratory, that's the one documented exception — confirm with me first."""),

    ex(TDD,
    "The test I just wrote passes immediately. Is that bad?",
    """Yes — a test that passes on the first run isn't proving anything. Either you're testing existing behavior, or the test isn't actually exercising the new code.

Fix it: temporarily break the implementation (comment out the key line, or invert a condition) and re-run. The test **must** fail. If it still passes, your test isn't wired to the behavior you think it is — fix the test before trusting it.

This is the "watch it fail for the right reason" step from the TDD skill. It's mandatory, not optional."""),

    ex(TDD,
    "What's the red-green-refactor cycle in Dart?",
    """**RED** — write one minimal `flutter_test` test for the behavior:

```dart
test('rejects empty email', () {
  expect(validateEmail(''), 'Email required');
});
```

Run `flutter test path/...` — watch it fail because `validateEmail` doesn't exist.

**GREEN** — write the minimal implementation:

```dart
String validateEmail(String email) {
  if (email.trim().isEmpty) return 'Email required';
  return '';
}
```

Run — watch it pass.

**REFACTOR** — clean up while staying green. Don't add behavior here.

Then the next test. One behavior per test; if the name has "and", split it."""),
]

EXAMPLES += [
    ex(TDD,
    "I'm refactoring an existing untested function. Do I write tests first?",
    """Yes — the TDD skill is explicit: "Existing code has no tests → you're improving it. Add tests for existing code." Refactoring without tests is reckless; you can't tell if behavior changed.

But for legacy code the order flexes slightly: write **characterization tests** that capture *current* behavior (they pass against the existing implementation), run them to confirm they pin the behavior, *then* refactor freely with the tests as a safety net. Watch them pass before, stay green during, and green after. This is still "test-first" in the sense that the tests exist before you change behavior — they just don't fail first because the behavior already exists.

If a test passes trivially with no assertion of real value, it's not a characterization test — delete it and write one that would break under a meaningful change."""),

    ex(TDD,
    "My test name is 'validates email and domain and whitespace'. OK?",
    """No — "and" in a test name means you're testing multiple behaviors in one test. The skill flags this as the classic anti-pattern. Split it:

```dart
test('rejects empty email', () => expect(validateEmail(''), 'Email required'));
test('rejects missing @', () => expect(validateEmail('noat'), 'Invalid'));
test('rejects surrounding whitespace only', () => expect(validateEmail('   '), 'Email required'));
```

One behavior per test. When one fails, you know exactly which contract broke, and the test name reads as documentation of the behavior. A 3-line test asserting one thing is better than a 15-line test asserting three."""),

    ex(TDD,
    "This code is too simple to bother with TDD. Right?",
    """No — "too simple to test" is rationalization #1 in the TDD skill's table. Simple code breaks (off-by-one, null guard missing, inverted condition), and the test takes 30 seconds. A test that proves `progress >= 3` means "onboarded" is trivial to write and would have caught the kind of off-by-one that ships a bug to every new user.

Write the test. If it's genuinely trivial, the test is trivially short. The cost is near-zero; the downside of skipping it is a regression nobody catches until prod."""),

    ex(TDD,
    "What counts as 'watching it fail for the right reason'?",
    """The failure must be caused by the **feature being missing**, not by a typo, import error, or compilation problem. The skill's check:

- Test fails ✓ — but WHY?
  - "validateEmail is not defined" → correct reason (feature missing). Proceed to green.
  - "Expected: 'Email required', Got: 'Email required'" with a typo in the assertion → wrong reason. Fix the test.
  - Compile error from a missing import → not even a test failure yet. Fix it, re-run until the assertion genuinely fails.

If the test errors (throws) rather than fails (assertion mismatch), that's usually the wrong reason — get it to a clean assertion failure first. Only then does green prove something."""),

    ex(TDD,
    "I found a bug. Can I just fix it?",
    """Not without a test — the TDD skill's debugging integration is explicit: "Never fix bugs without a test." Write a failing test that reproduces the bug first:

1. RED: a test that reproduces the bug (e.g. empty email wrongly accepted). Run it — fails.
2. Confirm it fails for the bug, not a typo.
3. GREEN: minimal fix. Run — passes.
4. Run the whole suite — nothing else broke.

Now the bug can't come back. If you "just fix it," the next refactor reintroduces it silently. This pairs with systematic-debugging: root-cause first, then the failing test, then the fix."""),

    ex(TDD,
    "Should I mock everything to make the test fast?",
    """Mocking everything is a red flag the TDD skill calls out: "Must mock everything → code too coupled. Use dependency injection." If your unit under test needs ten mocks, the design is wrong — extract the pure logic and test that with no mocks.

In emerge_app, prefer fakes (`fake_cloud_firestore`, `firebase_auth_mocks`) over mocks because fakes run the real query/transform logic. Use `mocktail` only for collaborators you genuinely don't own (an external HTTP API). A test that asserts `mock.fetch was called 3 times` tests the *mock*, not your code — assert on real outcomes (the returned value, the written doc) instead. (See the testing-anti-patterns guidance referenced from the skill.)"""),

    ex(TDD,
    "When do I add edge case tests — during green or after?",
    """During RED, one at a time. Each edge case is its own test, written before the code that handles it:

1. RED: `test('returns null for progress 0', ...)`. Watch fail.
2. GREEN: minimal code so that case passes.
3. RED: `test('returns null for negative progress', ...)`. Watch fail.
4. GREEN.

This forces you to *discover* edge cases by thinking about inputs before implementing, rather than remembering them after (you'll forget some). The skill: "Tests-first force edge case discovery before implementing. Tests-after verify you remembered everything (you didn't)." The empty/null/negative/boundary cases for `decideRedirect` are why its test file is so thorough — each was a deliberate RED."""),

    ex(TDD,
    "The test suite is slow. Should I delete some tests?",
    """No — slow tests usually mean a *design* smell, not too many tests. Per the skill's "When Stuck" table: "Test setup huge → extract helpers. Still complex? Simplify design." Diagnose first:

- Widget tests dominate? Move logic out of widgets into providers/pure functions and unit-test those instead (10x faster).
- Each test re-seeds a big Firestore fixture? Extract a helper or shrink the fixture.
- Tests sleep/pump long durations? You're masking a race — fix the race, shorten the pump.

Never delete a test to buy speed; you're trading away regression protection. Make the slow tests fast by simplifying what they test."""),

    ex(TDD,
    "How do I TDD a Flutter widget?",
    """Mostly you don't TDD the widget itself — you TDD the *logic* behind it (validation, state transitions, mappers) as pure functions/providers, then write widget tests that assert the wiring renders correctly.

The TDD flow for a widget is:
1. Extract the logic to a pure function/provider. TDD that (red-green).
2. Write a widget test describing what the user sees for a given state: "given provider emits X, widget shows Y." This is closer to characterization — it pins the rendered output.
3. Implement/minimize the widget to satisfy it.

Pure-logic tests are where the red-green rigor lives. Widget tests verify glue, not deep logic, so don't force the iron law on every pixel — but never ship a widget with zero tests either."""),

    ex(TDD,
    "build_runner says my generated file conflicts. How do I get back to green?",
    """That's a tooling failure mode, not a TDD failure — clear the stale output and regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

The `--delete-conflicting-outputs` flag is in the project's standard regenerate command precisely for this. It removes stale `*.g.dart` that block generation. Don't manually edit the `.g.dart` to "fix" it — that masks the conflict and gets overwritten next build. If it *still* conflicts after the flag, the source has a real error (two providers with colliding names, a missing `part` directive) — read the analyzer output and fix the source."""),
]

# ---------------------------------------------------------------------------
# 4. SYSTEMATIC DEBUGGING
# ---------------------------------------------------------------------------
DEBUG = "systematic_debugging"

EXAMPLES += [
    ex(DEBUG,
    "My widget test throws 'A ProviderScope is required'. Quick fix?",
    """No fixes before root cause. Per the systematic-debugging skill, read the error fully first — this one tells you exactly what's wrong: the test pumps a widget that calls `ref.watch` but there's no `ProviderScope` ancestor.

The fix is small but let's confirm it's the real issue. Check your test:

```dart
testWidgets('renders', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: MyScreen())); // no scope
});
```

Wrap it:

```dart
await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: MyScreen())));
```

Verify:

```bash
flutter test test/path/...
```

If it's a different error now, that's new information — form a fresh hypothesis, don't stack fixes. (If you'd instead "just tried" adding overrides without reading the error, you'd have masked the real cause.)"""),

    ex(DEBUG,
    "I've tried three fixes for this Firestore null error and none worked.",
    """Stop. Three failed fixes is the project's signal that this is an **architecture** problem, not a bug to patch. Don't attempt fix #4.

Per the systematic-debugging skill, return to Phase 1 with everything you've learned:

1. What did each fix reveal? If each fix surfaced a new problem in a *different* place, that's coupling — the symptom layering means the data model or nullability boundary is wrong.
2. Where does the null actually originate? Trace backward from the crash site to the source (`collection('x').doc('y').get()` returning `exists == false`? a `role` claim still resolving?).
3. Question the fundamentals: is the assumption "this doc always exists" even valid? In this codebase the role-claim race window (see `decideRedirect` branch 4 in `lib/core/router/router.dart`) is a known case where null is *expected*, not exceptional.

Surface this to me before refactoring — an architectural change needs a decision, not another patch."""),

    ex(DEBUG,
    "Tests pass locally but fail in CI with a timing flake. How do I debug?",
    """Treat it as a reproduction problem first (systematic-debugging Phase 1, step 2) — a flake you can't reproduce is a guess, not a fix.

Gather evidence at the boundaries:
- Is it `await tester.pump()` vs `await tester.pumpAndSettle()`? A provider doing an async Firestore read needs a pump to resolve. Add `await tester.pump(Duration.zero)` after the action and assert only after settle.
- CI is often slower — an `AsyncValue.isLoading` assertion that races the data state is the usual culprit. Assert on `.value` only after the stream emits.
- Run locally with `--coverage` off and watch for "pump timed out" messages.

Once you can reproduce it reliably (e.g. by adding an artificial delay), write a failing test that reproduces it, then fix at the source — usually "assert after settle, not before." Don't add `sleep` or longer timeouts; that masks the race."""),

    ex(DEBUG,
    "`dart analyze` passes but the app redscreens. How?",
    """That's expected — `analyze` is static type/lint checking, it does **not** compile-check runtime or prove the app runs. (The verification skill calls out "linter ≠ compiler" explicitly.)

Don't trust "analyze clean" as a build-pass. To actually verify:

```bash
flutter build apk --debug      # or: flutter run
```

Read the full error from the redscreen / build output. Common analyze-blind spots in this project: a provider returning `null` where a non-null `Widget` is expected, a `ref.read` inside `build()` that's stale, or a missing route in `lib/core/router/router.dart`. Fix the real error, then re-build to confirm."""),

    ex(DEBUG,
    "How do I trace a 'Null check operator used on a null value' back to its source?",
    """Backward tracing — Phase 1, step 5 of systematic-debugging. The stack trace points at the `!` that blew up, but the *bad value* originated earlier.

1. Read the **full** stack trace, not just the top frame. Note the file:line of the `!`.
2. At that line, which variable is null? That's the symptom.
3. Where was it assigned? Trace the data flow *up*: who passed it, who created it, back to where null first appeared.
4. Fix at the origin (e.g. the provider returning null, the doc `.data()` not existing), not by removing the `!`.

In emerge_app the origin is often a Firestore read returning a missing doc, or the role-claim race where `role` is legitimately `null`. After the fix, add a test that reproduces the null path so it can't regress."""),
]

EXAMPLES += [
    ex(DEBUG,
    "There's a bug. What's the very first thing I do?",
    """Stop before writing any fix. Phase 1 of systematic-debugging is root-cause investigation, and it has a strict order:

1. **Read the error message fully** — don't skim. Note file paths, line numbers, error codes. They usually contain the answer.
2. **Reproduce consistently** — can you trigger it on demand? If not, you don't have enough data to fix it; gather more (logs, steps) before guessing.
3. **Check recent changes** — `git diff`, recent commits, new deps, config edits. What changed that could cause this?

Only after those three can you even form a hypothesis (Phase 3). The Iron Law: "NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST." If you find yourself typing a fix before reading the error, that's a red flag — stop and restart Phase 1."""),

    ex(DEBUG,
    "How do I debug a Cloud Function (setUserRole) that's misbehaving?",
    """Treat it as a multi-component system and gather evidence at each boundary (Phase 1, step 4). The chain is: client call → callable → Firestore/Firebase Admin → return → client. Before guessing where it fails:

1. **Client side** — log what you're sending: `AppLogger.d('calling setUserRole role=$role')` and whether the call resolves or rejects.
2. **Function side** — in the function, log the incoming `data`, the resolved uid, and the custom-claim set.
3. **Persistence** — after it returns, read the user's `getIdTokenResult(true).claims` from the client to confirm the claim landed.
4. **Mirror** — check the `creator_profiles`/`users` Firestore doc the fallback uses.

Run once, read the layer where the value goes wrong, then investigate *that* layer. Don't fix across all four at once — one hypothesis, one minimal change. (The signup code already wraps the callable in try/catch + `AppLogger.w` so a failure surfaces rather than crashing signup — keep that boundary logging.)"""),

    ex(DEBUG,
    "Two of my fixes 'kinda worked' but the bug came back. What now?",
    """That's the classic thrash signal — and per the skill, after a couple of failed fixes you should NOT attempt another. Each "kinda worked" means you patched a symptom, not the cause. Return to Phase 1:

- Did you actually reproduce it before each fix, or were you testing different states?
- Is the bug the *same* bug each time it "comes back," or a new one introduced by your patch? (Patch-induced bugs mean you're treating symptoms.)
- Trace the data flow again, fresh — your mental model is probably wrong somewhere.

Form ONE specific hypothesis ("X is null because provider Y hasn't resolved"), make the smallest change that tests *only that*, verify. If it doesn't hold, form a new hypothesis — don't stack fixes. And if you hit 3 total, stop and question the architecture with me before fix #4."""),

    ex(DEBUG,
    "The bug only happens on a slow connection. How do I investigate?",
    """Timing-dependent bugs are the skill's "no root cause" edge case — but it still says 95% of those are *incomplete* investigation, not true nondeterminism. Approach it as evidence-gathering:

1. **Reproduce** by adding artificial latency (a delayed provider, a slow fake) so it happens on demand — a flake you can't reproduce is a guess.
2. **Instrument boundaries**: log timestamps at "request sent" / "response received" / "assertion made" to see what's racing what.
3. The usual culprit in Flutter is asserting on an `AsyncValue` before it resolves — `isLoading`/`hasData` checks that run before the stream emits. The fix is almost always "assert after settle," not "add a longer timeout."

Add a test that reproduces the race (delayed stream + assertion), fix at the source, keep the test as regression armor. Never fix a timing bug with `sleep` or a bigger timeout — that masks the race until it resurfaces on a slower device."""),

    ex(DEBUG,
    "What does 'trace data flow backward' actually mean in Dart?",
    """Take the bad value at the crash and walk *up* the call chain asking "where did this come from?" until you find where it went wrong. The skill's quick version:

- Where does the bad value originate? (the `null`, the wrong id, the stale flag)
- What called this function with that value? Go to that frame.
- Keep going up until the value was correct — the bug is between "correct" and "wrong."

In Dart use the **full stack trace** (every frame has file:line). For async, enable chain-style stack traces and follow `.then`/`await` frames. For Riverpod, the "caller" is often the provider that supplied the value — `ref.watch`/`ref.read` it traces to is a frame in the data-flow graph. Fix at the origin (the provider returning the wrong value, the doc read that should've existed), not at the crash site where you first noticed it."""),

    ex(DEBUG,
    "I 'see the problem' in the code — can I just fix it?",
    """Careful — "I see the problem, let me fix it" is a named red flag in the skill. Seeing a *symptom* ≠ understanding the *root cause*. Before fixing:

1. State the hypothesis explicitly: "I think the role is null because the claim hasn't propagated yet."
2. Find a working example to compare against (Phase 2): what similar code path works correctly? What's different?
3. List every difference, however small — don't dismiss "that can't matter."
4. Make the **smallest** change that tests *only* this hypothesis.

If the fix works, verify with a regression test. If it doesn't, you saw a symptom, not the cause — go back to Phase 1. The discipline prevents the thrash where each "obvious" fix reveals a new problem."""),

    ex(DEBUG,
    "My provider returns stale data after navigation. Bug?",
    """Likely an auto-dispose vs keepAlive mismatch, but confirm root cause before fixing (don't guess the lifecycle). Investigate:

1. Is the provider `@riverpod` (auto-dispose)? It rebuilds when no listener is attached, so coming back can re-fetch — sometimes desired, sometimes not.
2. Did you `ref.watch` (reactive, stays subscribed) vs `ref.read` (one-shot, no subscription)? A `ref.read` in `build` won't update on changes.
3. For data that should persist across navigation, use `@Riverpod(keepAlive: true)` (see how `firestore`, `authRepository` are kept alive in `auth_providers.dart`).

Reproduce: navigate away and back, assert the value. Fix the lifecycle at the source, then add a test that navigates and checks freshness. Don't paper over it with `ref.invalidate` on every build."""),

    ex(DEBUG,
    "Tests are red in CI but green locally — same branch. How do I find it?",
    """Don't blindly mirror CI. Treat it as a reproduction problem (Phase 1, step 2): you can't fix what you can't reproduce.

Gather differences:
- **Analyzer/lint level**: is CI running `dart analyze` with stricter rules or a different Flutter/Dart SDK? Check the CI workflow + `analysis_options.yaml`.
- **Test isolation**: local tests may share state (a leftover Firestore fake doc, a cached provider). Does it pass alone but fail in the full run? Run `flutter test` (full) locally, not just the one file.
- **Timing**: CI runners are slower — the same async-race advice applies (assert after settle).

Once you can reproduce locally (often by running the full suite, or matching the SDK), you have a real failure to root-cause. Committing "should be fixed" without reproduction is exactly the unverified-claim pattern to avoid."""),

    ex(DEBUG,
    "What's the '3-strike architecture' rule again?",
    """From Phase 4, step 5 of the skill: if **3+ fixes** have failed, stop fixing and **question the architecture**. The pattern that indicates an architectural (not a bug) problem:

- Each fix reveals new shared state / coupling / a problem in a *different* place.
- Fixes require "massive refactoring" to implement.
- Each fix creates a new symptom elsewhere.

When you see that, continuing to patch is failure-by-inertia. Stop, list the assumptions that keep biting you, and bring me the architectural question before attempting fix #4. This is *not* a failed hypothesis — it's a wrong architecture, and patching it further just moves the bug around. The role-claim race in this codebase is a good model: it wasn't "fixed" by more null checks, it was resolved by holding the path until the claim settles (an architectural decision in `decideRedirect`)."""),
]

# ---------------------------------------------------------------------------
# 5. VERIFICATION BEFORE COMPLETION
# ---------------------------------------------------------------------------
VERIFY = "verification"

EXAMPLES += [
    ex(VERIFY,
    "Is my bug fix done? I changed the validation logic.",
    """I can't say until it's verified — and neither can you. Per the verification skill, run the proving command and quote the output before claiming done.

1. Identify the test for this validation.
2. Run it fresh:

```bash
flutter test test/path/to/validation_test.dart
```

3. Read the output — count failures. For a regression, also prove the test *catches* the bug: revert your fix → run (must fail) → restore → run (must pass). That's red-green verification, not just "it passes now."

Paste the output and I'll confirm. Until then, "done" is unverified."""),

    ex(VERIFY,
    "Done! The login screen works.",
    """Hold on — "works" is a claim I can't verify from that. The verification skill is explicit: no completion claims without fresh evidence.

What did you actually run? For a login screen change I'd expect:

```bash
flutter test test/features/auth/presentation/screens/login_screen_test.dart
dart analyze lib/features/auth/
```

Both need to be green *and* you need to show me the tail of the output (e.g. "All tests passed! (7)"). If you only manually tapped the button, that's ad-hoc — re-run the automated checks and share the result, then I'll agree it's done."""),

    ex(VERIFY,
    "Can I commit? I think the refactor is clean.",
    """Run verification first, then commit. Before a commit in this repo:

```bash
dart analyze
flutter test
```

Read both fully. `analyze` should show 0 issues; `test` should show "All tests passed!" with a count. If you changed generated code, also confirm `dart run build_runner build --delete-conflicting-outputs` produces no diff.

Once you paste the green output, commit. Don't commit on "I think" — the verification skill flags that as a red flag."""),

    ex(VERIFY,
    "I wrote a regression test for the redirect bug.",
    """Good — but "wrote a regression test" isn't enough; prove it actually catches the bug (red-green):

1. Run it against the **unfixed** code → it must FAIL.
2. Apply your fix → run → it must PASS.
3. Revert the fix again → run → it must FAIL.

If it passes even without the fix, the test isn't wired to the regression and proves nothing. Show me the three runs and I'll trust it. This matches the regression-test pattern in the verification skill."""),
]

EXAMPLES += [
    ex(VERIFY,
    "I think the redirect refactor is safe. Good to merge?",
    """"I think" is the red flag the verification skill names directly. Before merging, produce fresh evidence:

```bash
dart analyze
flutter test test/core/router/router_redirect_test.dart
flutter test
```

For a redirect change specifically, the redirect tests (`router_redirect_test.dart`) are the proof — confirm they're all green and quote the count. Also `dart analyze` for 0 issues. Once you paste that output, it's verified and safe to merge. Until then, "I think it's safe" is an unverified claim, and the skill treats unverified completion claims as dishonesty, not efficiency."""),

    ex(VERIFY,
    "What's the difference between 'analyze clean' and 'build passes'?",
    """Different gates, and the verification skill is explicit that one doesn't substitute for the other:

- `dart analyze` — **static** type + lint checks. Catches type errors, unused vars, lint. Does NOT compile the app or prove it runs.
- `flutter build` / `flutter run` — **compiles** and (for run) executes. Catches things analyze can't: missing assets, runtime null checks, provider wiring at runtime, tree-shake issues.

"Linter passed" does NOT mean "build passes" — don't claim a build is green because analyze is. For "is it done," run the gate that actually proves your claim: tests for behavior, build for compilation, run for behavior-in-context. Often you need several."""),

    ex(VERIFY,
    "I delegated the change to a sub-agent and it reported success.",
    """Don't trust the report — verify independently. The skill lists "Agent reports 'success'" as a common failure: undefined functions shipped, missing requirements, time wasted on false completion. The gate:

1. Check the **VCS diff** — what actually changed? Does it match the task?
2. Read the changed files — do they compile? Are there TODOs or stubs?
3. Run the proving commands yourself (`dart analyze`, `flutter test`).
4. Re-read the original requirements as a checklist and tick each off against the diff.

Only then report "done" — and report the *actual* state, including gaps. If the agent claimed success but tests fail, say "agent reported done but `flutter test` shows 2 failures" — that's the honest, verifiable status."""),

    ex(VERIFY,
    "How do I verify a requirements-driven task is actually complete?",
    """Don't infer from "tests pass." The skill's requirements pattern: re-read the plan/spec → make a checklist → verify each item → report gaps or completion.

For a change driven by a spec like `docs/superpowers/specs/2026-06-23-creator-routes-design.md`:
1. Open the spec's "Files Changed" / "Verification" section.
2. Turn each bullet into a check: "creator routes extracted? ✓", "dead `/creator/verify-email` removed? ✓", "existing router tests pass? ✓".
3. For each, cite the evidence (file path, command output).
4. Any unchecked box → not complete; report which.

"Tests pass, phase complete" is the failure mode the skill calls out — tests passing is one input, not the definition of done."""),

    ex(VERIFY,
    "Is it OK to say 'this should fix it'?",
    """No — "should" is on the skill's red-flag list ("should", "probably", "seems"). It telegraphs an unverified claim. Replace it with evidence:

- ❌ "This should fix the redirect loop."
- ✅ "Ran `flutter test test/core/router/...` → 14/14 pass. The loop no longer reproduces on `flutter run`."

If you genuinely haven't verified, say that instead: "I've made the change but haven't run the tests yet — running now." Honesty about an unverified state is fine; implying success without evidence is not. The Iron Law: "NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE."""),

    ex(VERIFY,
    "I'm tired and want to wrap up. Can I commit what I have?",
    """The skill explicitly anticipates this: "I'm tired" → "Exhaustion ≠ excuse." Tiredness is exactly when false completion claims slip in. Before committing:

```bash
dart analyze
flutter test
```

Read both fully — count failures, check for warnings. If something is unfinished or untested, commit it as such with an honest message (e.g. "WIP: redirect logic, tests pending"), or stop and pick it up fresh. Don't commit "done" on fatigue. The cost of a rollback later is higher than 5 minutes of verification now."""),

    ex(VERIFY,
    "The sub-agent's diff looks right. Done?",
    """"Looks right" isn't verified — run the commands. For any change in this repo the minimum gates are:

```bash
dart analyze                         # 0 issues
flutter test                         # All tests passed!
```

Read the actual output, don't recall it. Then, if generated code was touched, confirm `dart run build_runner build --delete-conflicting-outputs` produces no diff. Paste the green tails and the claim becomes true. The skill's gate function: identify the command → run it → read it → verify → then claim."""),

    ex(VERIFY,
    "How do I verify a UI change without a manual tap-through?",
    """With a widget test that asserts the rendered output for the relevant state. Manual tap-throughs are ad-hoc (no record, can't re-run, easy to miss cases). For a screen change:

```dart
testWidgets('shows error text when provider errors', (tester) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [myProvider.overrideWith((ref) => Stream.error(Exception('x')))],
    child: const MaterialApp(home: MyScreen()),
  ));
  await tester.pumpAndSettle();
  expect(find.textContaining('x'), findsOneWidget);
});
```

Run it, quote the pass count. That's repeatable verification; a manual tap is not. Use manual checks only as a *supplement* to confirm feel/polish, never as the sole proof."""),

    ex(VERIFY,
    "build_runner finished — is the generated code correct?",
    """Completion of the generator ≠ correctness of the output. Verify the result matches intent:

1. **Diff the `.g.dart`** — did the expected `*Provider` symbol appear? Are there unexpected changes?
2. **`dart analyze`** — the generated code must analyze clean; a generation that produced broken code is a fail.
3. **`flutter test`** — anything that consumes the provider should still pass.

If a provider you expected didn't generate, the source annotation/`part` directive is wrong — fix the source and regenerate. Don't commit generated code you haven't seen compile and test green."""),

    ex(VERIFY,
    "What evidence do I need before marking a PR ready for review?",
    """Treat "ready for review" as a completion claim — same gate applies. On the PR description, attach:

1. `dart analyze` → 0 issues (paste or screenshot).
2. `flutter test` → "All tests passed! (N)" with the count.
3. If behavior changed: the test(s) that prove it, and for a bugfix the red-green proof.
4. Requirements checklist from the linked spec/plan, each ticked with evidence.
5. Note anything skipped or known-broken, honestly.

A reviewer should be able to reproduce your "green" by running the same commands. If you can't fill those in, the PR isn't ready — finish the verification first."""),
]

# ---------------------------------------------------------------------------
# 6. PROJECT-SPECIFIC GOTCHAS
# ---------------------------------------------------------------------------
GOTCHA = "project_gotchas"

EXAMPLES += [
    ex(GOTCHA,
    "My router rebuilds in an infinite loop after I added a redirect. Why?",
    """You almost certainly used `ref.watch` **inside** the `redirect:` closure. That creates a rebuild loop: watch → router rebuilds → redirect runs → watch again.

In emerge_app the rule is: **watch the sources outside the closure, `ref.read` inside it.** See `lib/core/router/router.dart`:

```dart
@riverpod
GoRouter router(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);   // watch up here
  final roleAsync = ref.watch(currentUserRoleProvider);
  // ...
  return GoRouter(
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final role = roleAsync.hasValue ? roleAsync.value : null;  // read, don't watch
      return decideRedirect(currentPath: state.uri.path, ctx: ...);
    },
  );
}
```

The `decideRedirect` decision is pure so it can be tested directly. Move your `ref.watch` above the `GoRouter(` and use `ref.read` (or the already-watched local) inside `redirect`. Verify the loop stops with `flutter run`."""),

    ex(GOTCHA,
    "Right after creator signup the user lands on the wrong screen. Race condition?",
    """Likely yes — this is the known **role-claim race window**. Between Firebase Auth user creation and the `setUserRole` Cloud Function returning, `role` is `null`/`unknown`. If the router reacts too eagerly it misroutes.

The fix is already encoded in `decideRedirect` branch 4 (`lib/core/router/router.dart`): when `role` is `null`/`unknown`, **hold the current path** rather than yank the user:

```dart
if (ctx.role == null || ctx.role == UserRole.unknown) {
  if (isOnCreatorPath) return null;        // hold
  if (isOnCreatorOnboardingPath) return null;
  // ...don't force-redirect mid-signup
}
```

Also, post-signup navigate to `/splash` (not directly to the onboarding step) so splash's role-aware routing resolves the claim — see `creator_signup_screen.dart`. Don't try to "fix" the race by adding sleeps; hold the path and let the provider settle."""),

    ex(GOTCHA,
    "The `setUserRole` Cloud Function failed in signup. Should I throw?",
    """No — and the existing code deliberately doesn't. Look at `signUpCreatorProvider` in `lib/features/auth/presentation/providers/auth_providers.dart`: it writes the `creator_profiles` doc, *attempts* the callable, and on failure only **warns**, it doesn't throw:

```dart
try {
  await functions.httpsCallable('setUserRole').call({'role': 'creator'});
  await user.getIdToken(true);
} catch (e, s) {
  AppLogger.w('setUserRole failed; router will fall back to mirror.', error: e, stackTrace: s);
}
```

The router has a Firestore mirror fallback (`isCreator`/`isNormalUser` check the `users`/`creator_profiles` collections) so a transient callable failure doesn't block signup. Throwing would surface an infrastructure blip as a user-facing error. Keep the warn + fallback design; fix the *function* separately if it's persistently failing."""),

    ex(GOTCHA,
    "I want to unify the Google sign-in for web and mobile into one code path.",
    """Don't — they genuinely fork on `kIsWeb`, and unifying them breaks one platform. From `signUpCreatorWithGoogleProvider`:

```dart
if (kIsWeb) {
  final googleProvider = firebase_auth.GoogleAuthProvider();
  googleProvider.addScope('email');
  await auth.signInWithRedirect(googleProvider);   // web: redirect flow
  return;
} else {
  final googleUser = await GoogleSignIn.instance.authenticate();  // native
  final credential = firebase_auth.GoogleAuthProvider.credential(
    idToken: googleUser.authentication.idToken,
  );
  userCredential = await auth.signInWithCredential(credential);
}
```

Web requires `signInWithRedirect` (popup/redirect via `GoogleAuthProvider`); native requires `GoogleSignIn.instance.authenticate()` then a `credential`. Also note native path checks for an existing `users` doc and throws if the Google account is already a normal user — keep that guard in the native branch. Two branches is the correct shape here."""),

    ex(GOTCHA,
    "How should repository methods signal errors in this codebase?",
    """With `fpdart`'s `Either<Failure, T>`, not by throwing across the boundary. A repo returns `Either<Failure, T>` and the consumer folds:

```dart
final result = await repository.signInWithEmailAndPassword(email: email, password: password);
result.fold(
  (error) => throw Exception(error.message),  // or surface to UI
  (_) => null,
);
```

(See how `signInProvider` consumes `AuthRepository` in `auth_providers.dart`.) Define a `Failure` type in the feature's `domain/` with the failure cases you actually have. This makes errors values you can test, rather than exceptions you can only catch. Reserve `throw` for programmer errors (preconditions), not expected domain failures."""),

    ex(GOTCHA,
    "Where do creator routes live vs normal-user routes?",
    """Separately. Creator routes were extracted into `lib/core/router/creator_routes.dart` (a `List<RouteBase> get creatorRoutes`) and spread into the main router:

```dart
// router.dart
routes: [
  GoRoute(path: '/splash', ...),
  ...creatorRoutes,           // imported from creator_routes.dart
  // normal-user + deep-link routes inline here
]
```

- **`creator_routes.dart`**: `/creator/login`, `/creator/signup`, `/onboarding/creator/*`, and the `/creator/dashboard` shell (`StatefulShellRoute.indexedStack` with 3 branches).
- **`router.dart`**: public/auth routes, normal-user onboarding (`/onboarding/identity-studio` etc.), top-level deep-links (`/creators/:id`, `/blueprint/:id`, `/creators`, `/challenges`), and the user bottom-nav shell (4 branches).
- **`decideRedirect()`** stays in `router.dart` — it works on path matching + role state, not route definitions, so the split doesn't affect it.

Keep this separation when adding creator-only routes; don't re-mingle them into `router.dart`."""),

    ex(GOTCHA,
    "Can I edit the .g.dart file to fix a provider name?",
    """No — generated files are build artifacts. Edit the source `.dart` (the `@riverpod` function) and regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Any change to `auth_providers.g.dart`, `router.g.dart`, etc. will be silently overwritten on the next build and wastes time. The `--delete-conflicting-outputs` flag clears stale outputs that often cause "part already exists" errors. If generation fails, the fix is in the source annotation/imports, not the generated file."""),

    ex(GOTCHA,
    "I need to add a deep-link `/campaign/:id`. Where does it go?",
    """Top-level in `router.dart` with `parentNavigatorKey: _rootNavigatorKey` so it renders full-screen above the bottom nav:

```dart
GoRoute(
  path: '/campaign/:id',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) => CampaignScreen(
    campaignId: state.pathParameters['id']!,
  ),
),
```

This mirrors the existing `/creators/:id` and `/blueprint/:id` routes. If the screen can receive a pre-fetched object, follow the `/blueprint/:id` pattern: check `state.extra` first to skip the fetch. If auth/role gates apply, handle them in `decideRedirect` (pure function + `RedirectContext`), not in the route builder."""),
]

EXAMPLES += [
    ex(GOTCHA,
    "Where does role resolution actually happen — Auth claim or Firestore?",
    """Both, with the Auth custom claim as canonical and Firestore as fallback. `currentUserRoleProvider` resolves the role from the Firebase Auth custom claim (set by the `setUserRole` Cloud Function), and falls back to checking the `users`/`creator_profiles` mirror collections if the claim isn't there yet.

That dual source is deliberate: the claim can lag (the race window) and the Firestore doc is the source the app *writes* synchronously during signup (`creator_profiles/${uid}` is written before the callable returns). So `decideRedirect` keys off `role`, but providers like `isCreator`/`isNormalUser` read Firestore for cases where the claim hasn't propagated. Don't collapse them to one source — you'd reintroduce the race."""),

    ex(GOTCHA,
    "How do I guard a route so only creators can reach it?",
    """Two layers. (1) Add the route under `creator_routes.dart` so it lives with creator surfaces, and (2) rely on `decideRedirect` to bounce non-creators — it already sends `role == user` off any `/creator*` or `/onboarding/creator/*` path to `/onboarding/identity-studio`.

```dart
// creator_routes.dart
GoRoute(
  path: '/creator/payouts',
  builder: (context, state) => const CreatorPayoutsScreen(),
),
```

Don't put the role check inside the screen's `build` — that's duplicated logic and a flash of wrong UI. The router is the single enforcement point (see the test `role=user, on /creator/dashboard -> /onboarding/identity-studio`). If you need a finer-grained check (e.g. verified-creator only), add it to `decideRedirect` as a pure branch and a matching test case."""),

    ex(GOTCHA,
    "I want to add a new bottom-nav tab. What do I touch?",
    """Add a branch to the user `StatefulShellRoute.indexedStack` in `router.dart` (the 4-branch shell) and the matching nav item in `lib/core/presentation/widgets/scaffold_with_nav_bar.dart`. A new branch looks like:

```dart
StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/inbox',
      builder: (context, state) => const InboxScreen(),
      routes: [ /* nested detail routes */ ],
    ),
  ],
),
```

The branch order must match the nav-bar item order. Creator-only tabs are a *separate* shell (`creator_routes.dart`'s dashboard shell with 3 branches) — don't mix a creator tab into the user shell. Add a widget test for `ScaffoldWithNavBar` showing the new tab, and a routing test if the tab has access guards."""),

    ex(GOTCHA,
    "Why does `_BlueprintByIdLoader` invalidate the provider on retry?",
    """Because the error could be transient (a Firestore blip), and `ref.invalidate` forces a fresh fetch. From `router.dart`:

```dart
error: (e, _) => Scaffold(
  body: AppErrorWidget(
    message: 'Failed to load blueprint: $e',
    onRetry: () => ref.invalidate(blueprintByIdProvider(blueprintId)),
  ),
),
```

`invalidate` drops the cached `AsyncError` and re-subscribes, so the `.when()` re-runs through loading → data. Use this pattern (invalidate the specific family provider, not a broad one) for any deep-link loader that can fail transiently. Don't `invalidate` global providers from a retry — that nukes unrelated state. Also note it uses `blueprintByIdProvider` (a single-doc fetch), not a whole-collection stream, so deep-linking stays cheap."""),

    ex(GOTCHA,
    "How should I handle the role being 'unknown' vs 'null' in new routing code?",
    """They mean the same thing operationally ("not yet resolved") and `decideRedirect` treats them together:

```dart
if (ctx.role == null || ctx.role == UserRole.unknown) { /* hold the path */ }
```

`null` = the provider hasn't emitted a value yet (`AsyncValue` still loading). `UserRole.unknown` = it emitted but couldn't determine the role (claim absent, mirror doc absent). When writing new routing, **hold** the current path in both cases rather than redirect — yanking the user mid-resolution causes the misroute bug. Only redirect once `role` is a concrete `user`/`creator`. Keep both in the condition so a refactor to either representation doesn't reopen the race."""),

    ex(GOTCHA,
    "I'm writing a new repository. What should its method signatures look like?",
    """Return `Future<Either<Failure, T>>` for operations that can fail, mirroring `AuthRepository`. Define a `Failure` type in `domain/` (with subtypes for the failures you actually have — not a generic string). Example:

```dart
abstract class RewardRepository {
  Future<Either<Failure, List<Reward>>> fetchRewards({required String uid});
  Future<Either<Failure, Reward>> claimReward({required String rewardId});
}
```

The Firebase implementation injects `FirebaseFirestore` (via the `firestoreProvider`) and never throws across the boundary — it catches Firebase exceptions and maps them to `Failure`. Consumers fold (see `signInProvider`'s `.fold((error) => throw Exception(...), (_) => null)`). This makes errors testable values and keeps the domain Firebase-agnostic."""),

    ex(GOTCHA,
    "Can I use `ref.read` in a widget's build method?",
    """Generally no — in `build`, use `ref.watch` so the widget rebuilds when the value changes. `ref.read` is for event handlers (button onTap), inside `redirect:` closures (to avoid rebuild loops — see the router gotcha), or in `initState`/`dispose` of a `ConsumerStatefulWidget`.

The one nuance: inside `go_router`'s `redirect`, you read from the already-watched locals (e.g. `roleAsync.value`), not re-watch — because watching inside redirect loops. But that's a router-specific rule; in a normal widget, `build` + `ref.watch` is correct, and `ref.read` in `build` is almost always a bug (stale value, no rebuild)."""),

    ex(GOTCHA,
    "How do I pass a complex object between routes instead of re-fetching it?",
    """Use `state.extra` on `context.go`/`context.push`, and read it in the route builder — the `/blueprint/:id` route shows the idiom:

```dart
GoRoute(
  path: '/blueprint/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    final extra = state.extra;
    if (extra is Blueprint) return BlueprintDetailScreen(blueprint: extra);
    return _BlueprintByIdLoader(blueprintId: id);  // fall back to fetch
  },
),
```

Sender: `context.push('/blueprint/$id', extra: blueprint)`. Always handle the `extra is null` case (deep link from cold start has no extra) by falling back to a fetch. Don't pass non-serializable junk in `extra` if the route can be deep-linked — on a cold deep link there's no extra at all."""),

    ex(GOTCHA,
    "Firestore security rules — where are they and what should I check?",
    """They're in `firestore.rules` at the repo root. Before relying on a new collection, audit the rules with the `firebase-security-rules-auditor` skill (it's in `.agents/skills/`). Common checks:

- Every collection has a rule (no default-open).
- Reads are scoped to the user's own docs or explicitly-shared ones (`request.auth.uid == resource.data.uid`).
- Role-gated writes (e.g. only the creator can write their `creator_profiles` doc; `setUserRole`-equivalent writes are function-only, not client-writable).
- Validate field types/shapes on write (`request.resource.data.role is string`).

Rules are the real security boundary — client code is convenience, not enforcement. A missing rule is a security bug even if the UI never exposes the path. Run the rules emulator tests if any exist."""),

    ex(GOTCHA,
    "I get 'MissingPluginException' for a Firebase service in tests.",
    """That's a test-initialization issue, not a code bug. In widget/unit tests, Firebase plugins aren't initialized by default. Two correct responses:

1. **Prefer overriding the provider** with a fake (`fake_cloud_firestore`, `firebase_auth_mocks`) so the real plugin is never called — this is the project's standard approach and avoids the exception entirely.
2. If you must use the real Firebase object, call `Firebase.initializeApp` with test options and `setupFirebaseCoreMocks()` in `setUp` — but this is the slow, brittle path.

The "MissingPluginException" means your code reached the real plugin instead of a fake, which usually means you forgot an `overrideWith` on `firestoreProvider`/`firebaseAuthProvider`. Fix the override, don't try to initialize real Firebase in a unit test."""),

    ex(GOTCHA,
    "How do I add a Cloud Function call from the client, like setUserRole?",
    """Use `FirebaseFunctions.instance.httpsCallable`, and **always wrap it in try/catch** so a function outage doesn't crash the feature — the signup code is the model:

```dart
try {
  await FirebaseFunctions.instance
      .httpsCallable('myFunction')
      .call(<String, dynamic>{'arg': value});
} catch (e, s) {
  AppLogger.w('myFunction failed; <what falls back>.', error: e, stackTrace: s);
  // fall back gracefully or surface a user-facing error — don't rethrow blindly
}
```

Decide consciously whether a failure is fatal (throw up) or recoverable (warn + fallback). For `setUserRole` it's recoverable because the Firestore mirror covers it; for a function with no fallback, throwing a domain `Failure` via `Either` is correct. Never let a raw `FirebaseFunctionsException` reach the widget layer."""),

    ex(GOTCHA,
    "Should onboarding state live in Firestore or locally?",
    """Persist it in Firestore so it survives reinstall and cross-device, but keep a local cache (`shared_preferences` / drift) so the splash screen can route instantly without waiting for a fetch. The project already does this split: `userStatsStreamProvider` reads `user_stats` from Firestore (source of truth), while `onboardingControllerProvider` tracks the in-progress flow, and `isFirstLaunch` is local.

`decideRedirect` reads the Firestore-backed progress/timestamp (`userOnboardingProgress`, `userOnboardingCompletedAt`) as the authoritative gate. Don't gate routing on purely-local state — a reinstall would reset it and misroute a returning user. Local = optimistic fast path; Firestore = truth."""),

    ex(GOTCHA,
    "What's the splash screen's job, and why navigate to /splash after signup?",
    """Splash is the **role-aware router resolver**: it reads `authStateChangesProvider`, `currentUserRoleProvider`, and the onboarding providers, then `context.go(...)` to the correct destination for the current state — without the user seeing a flash of the wrong screen. That's why `creator_signup_screen.dart` navigates to `/splash` (not directly to the onboarding step): splash waits for the role claim to settle and then routes correctly, sidestepping the race window.

Don't bypass splash by hard-navigating post-auth — you'd reimplement (badly) the routing logic it already centralizes. New auth flows should `context.go('/splash')` and let it decide. Splash itself is always allowed by `decideRedirect` (`if (currentPath == '/splash') return null`)."""),

    ex(GOTCHA,
    "How do I make a new screen feel consistent with the app's dark theme?",
    """The app is dark-first (the launcher/splash background is `#0A0A1A` "Cosmic Void Dark", see `pubspec.yaml`). Use the theme from `Theme.of(context)` rather than hardcoding colors — there are theme providers under `lib/core/theme/` (`theme_provider.dart` + generated). Reuse shared widgets like `EmergePrimaryButton` (`lib/core/presentation/widgets/emerge_primary_button.dart`) and `AppErrorWidget` instead of reinventing buttons/error states, so spacing, color, and behavior stay consistent.

For images, declare them in `pubspec.yaml` and prefer SVG (`flutter_svg`) for icons. Don't sprinkle raw `Color(0xFF...)` literals — route colors through the theme so a future light mode doesn't break the screen."""),

    ex(GOTCHA,
    "I want to read a single Firestore doc cheaply in a provider. Stream or Future?",
    """Future, unless you need live updates. The project distinguishes these deliberately — `blueprintByIdProvider` is a single-doc fetch (cheap, one-shot) used by `_BlueprintByIdLoader`, while `userStatsStreamProvider` is a stream because the dashboard must react to changes. From `router.dart`'s comment on `_BlueprintByIdLoader`:

> "Uses `blueprintByIdProvider` (single-doc fetch, not a full collection stream) so deep-link navigation is cheap even when the `blueprints` collection is large."

For a detail screen reached once, `Future<Doc?>` via `.doc(id).get()` is right. For anything the user watches change (stats, presence, a live lobby), use a `Stream`. Don't default everything to streams — they cost more and complicate loading/error handling."""),

    ex(GOTCHA,
    "How do I handle the 'already registered as normal user' case in Google signup?",
    """Check before committing — the native Google signup path in `signUpCreatorWithGoogleProvider` does exactly this:

```dart
final userDoc = await firestore.collection('users').doc(user.uid).get();
if (userDoc.exists) {
  await auth.signOut();
  if (!kIsWeb) await GoogleSignIn.instance.signOut();
  throw Exception('This Google account is already registered as a normal user.');
}
```

The guard: fetch the existing `users` doc; if present, sign out of both Auth and Google (so a retry is clean) and throw a user-facing message. This prevents a single Google identity from being both a user and a creator. Keep this check *before* writing `creator_profiles`. The thrown exception surfaces through the provider to the UI — handle it there with a clear message, not a generic error."""),

    ex(GOTCHA,
    "When should I use Equatable vs a plain class?",
    """`Equatable` (a project dep) when value equality matters: entities (`CreatorProfile`), state objects (`CreatorOnboardingState`), and anything compared in `==` for Riverpod/`AsyncValue` to skip rebuilds, or put in a `Set`/used as a `Map` key. The `props` override defines identity-by-value.

Plain class when it's a service/handler with identity semantics (a repository, a controller) — you don't compare those by field. Don't slap `Equatable` on everything (it adds noise where equality is irrelevant), and don't hand-write `==`/`hashCode` when `Equatable` already does it correctly. If two instances of your class should be "equal" when their fields match, use `Equatable`."""),

    ex(GOTCHA,
    "How do I add a settings row that toggles a Remote Config flag?",
    """Remote Config (`firebase_remote_config`) is already a dependency. Read flags through a provider wrapping `FirebaseRemoteConfig.instance`, and toggle UI off the fetched value. Don't call Remote Config directly in widgets — go through a provider so it's overridable in tests and rebuilds on fetch.

```dart
@riverpod
Future<bool> featureXEnabled(Ref ref) async {
  final rc = FirebaseRemoteConfig.instance;
  await rc.fetchAndActivate();
  return rc.getBool('feature_x_enabled');
}
```

The settings row reads `featureXEnabledProvider` and shows a switch only when the flag is on (or whatever the product decision is). Activate is async — use `.when()`/`AsyncValue` in the UI, and a default value so the screen renders before fetch completes. Crashlytics + Remote Config together let you roll out safely."""),

    ex(GOTCHA,
    "What logging should a new provider have?",
    """Use `AppLogger` (in `lib/core/utils/app_logger.dart`) at the meaningful boundaries — not every line. The signup providers are the model:

- `AppLogger.d('signUpCreator: wrote creator_profiles/${user.uid}')` after a successful side-effect write (helps trace the race window).
- `AppLogger.w('... failed; router will fall back to mirror.', error: e, stackTrace: s)` on a caught failure, *with* the stack trace and *what falls back*.

Don't `print`. Don't log inside hot loops. Log state transitions and the boundaries between components (the systematic-debugging skill wants evidence at boundaries — your logs *are* that evidence later). And never log secrets/PII (full emails, tokens) — Crashlytics may ingest these."""),

    ex(GOTCHA,
    "How do I test that the nav bar shows the right tabs?",
    """Widget test `ScaffoldWithNavBar` (in `lib/core/presentation/widgets/scaffold_with_nav_bar.dart`) with a `StatefulShellRoute` or by pumping it directly with a fake `navigationShell`. Assert the expected number of tabs and their labels/icons:

```dart
testWidgets('shows 4 nav tabs', (tester) async {
  await tester.pumpWidget(MaterialApp(home: ScaffoldWithNavBar(navigationShell: fakeShell)));
  expect(find.byIcon(Icons.explore), findsOneWidget);   // World
  // ...one assertion per tab
});
```

There are existing tests under `test/core/presentation/` (e.g. `app_back_handler_test.dart`, `emerge_primary_button_test.dart`) — mirror their structure. Keep the test about *what the user sees*, not implementation details like the branch index."""),

    ex(GOTCHA,
    "What should I do before adding a new Firebase collection?",
    """Three things, in order:

1. **`firestore.rules`** — add read/write rules scoped to the user's own docs and any role gates. A collection without rules is default-deny in prod but default-open in some emulator setups; don't ship without explicit rules. (Run the `firebase-security-rules-auditor` skill.)
2. **Domain layer** — entity + repository interface in `features/<feature>/domain/`, Firebase impl in `data/`, wired via a provider.
3. **A fake-backed test** — seed `fake_cloud_firestore` and exercise the repo to prove the queries work before building UI.

Skipping the rules step is a security bug; skipping the test means you find query bugs in the UI later. The `users`/`creator_profiles` split in this repo is the reference for a role-segregated collection design."""),

    ex(GOTCHA,
    "How do I cleanly handle AsyncValue loading/error/data in a screen?",
    """Use `.when()` (or the newer `.switch_`/pattern) — never index `.value` blindly. `_BlueprintByIdLoader` in `router.dart` is the canonical example:

```dart
return blueprintAsync.when(
  loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
  error: (e, _) => Scaffold(body: AppErrorWidget(
    message: 'Failed to load: $e',
    onRetry: () => ref.invalidate(blueprintByIdProvider(id)),
  )),
  data: (blueprint) => blueprint == null
      ? Scaffold(body: AppErrorWidget(message: 'Not found', onRetry: ...))
      : BlueprintDetailScreen(blueprint: blueprint),
);
```

Every branch renders a real widget — no blank screens, no unhandled error. Reuse `AppErrorWidget` for errors so retry/logging is consistent. The `data == null` case (doc missing) is a real state, handle it as its own branch. Never `builder: (_) => Text(async.value!.name)` — that crashes on loading/error."""),
]


def main() -> None:
    out = HERE / "seeds.jsonl"
    seen = set()
    rows = []
    for e in EXAMPLES:
        key = _norm(e["conversations"][1]["value"])
        if key in seen:
            raise SystemExit(f"Duplicate prompt detected: {e['conversations'][1]['value'][:60]!r}")
        seen.add(key)
        rows.append(e)

    with out.open("w", encoding="utf-8") as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")

    print(f"Wrote {len(rows)} examples -> {out}")
    # quick category tally
    from collections import Counter
    counts = Counter(r["category"] for r in rows)
    for cat, n in sorted(counts.items()):
        print(f"  {cat:24} {n}")


def _norm(text: str) -> str:
    return " ".join(text.lower().split())


if __name__ == "__main__":
    main()
