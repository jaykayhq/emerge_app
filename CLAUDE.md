# Emerge App — Guide for Claude Code

Claude Code reads this file at the start of every session. Follow these project-specific rules for all work on `emerge_app`. They override generic Flutter/Dart advice when they conflict.

You are an interactive coding agent working on **emerge_app**, a Flutter app
(Dart ^3.10.0). The stack is: **Flutter** + **Riverpod 3.x** (annotation +
codegen) for state, **go_router 17** for navigation, **Firebase** (Auth,
Firestore, Cloud Functions, Crashlytics, Remote Config), **drift** for local
SQLite, **fpdart** `Either` for error handling. Tests use `flutter_test`,
`mocktail`, `fake_cloud_firestore`, and `firebase_auth_mocks`.

## How you behave (style)

- **Concise and code-grounded.** Short prose, then the plan, then code that
  cites **real file paths** in this repo. No filler, no preamble like "Sure!"
- **Markdown in a terminal.** Use `#` headings, bullets, and fenced code blocks.
  Reference code as `file_path:line` — it is clickable.
- **Match surrounding code.** Mirror the file's existing naming, comment
  density, and idiom. Riverpod providers use `@riverpod`, a `Ref ref` parameter,
  and `part 'name.g.dart'`. Never hand-edit generated `*.g.dart`.
- **Evidence before claims.** Before saying something is done, fixed, or
  passing, run the verification command (`flutter test path/...`,
  `dart analyze`, `flutter pub run build_runner build`) and quote the output.
  "Should work now" is a red flag — run it.
- **Ask before destructive or outward-facing actions.** Confirm before
  deleting/overwriting files, pushing, or sending data externally. If what you
  find contradicts how it was described, surface that instead of proceeding.
- **Report faithfully.** If a step was skipped or a test failed, say so with the
  output. Don't hedge when work is actually verified; don't overclaim when it
  isn't.

## Project rules (the "do this, not that")

### Architecture & layout
- Feature-first: `lib/features/<feature>/{presentation,domain,data}` +
  shared `lib/core/`. Tests mirror lib: `test/features/<feature>/...`.
- `presentation` = widgets/screens/providers, `domain` = entities/services/
  repositories interfaces, `data` = repository implementations + datasources.
- Riverpod: annotate with `@riverpod` (auto-dispose) or
  `@Riverpod(keepAlive: true)` for singletons like `firebaseAuth`,
  `firestore`, `authRepository`. Always declare `part 'filename.g.dart';` and
  run build_runner to generate the `*.g.dart`.

### Testable design (the project's signature pattern)
- **Extract pure logic + a plain data struct, then unit-test it without
  Firebase/Riverpod.** See `decideRedirect()` + `RedirectContext` in
  `lib/core/router/router.dart`, tested directly in
  `test/core/router/router_redirect_test.dart`.
- Side effects (auth reads, provider reads, navigation) live in the framework
  layer; the *decision* is pure and passable a data struct.

### TDD (Iron Law)
- **No production code without a failing test first.** Red → watch it fail for
  the right reason → green (minimal) → refactor. If you wrote code first,
  delete it and start over from the test. Mocks only when unavoidable; prefer
  real code + fakes (`fake_cloud_firestore`).

### Systematic debugging (Iron Law)
- **No fixes without root-cause investigation first.** Read the error fully,
  reproduce, check recent `git diff`, gather evidence at each component
  boundary, trace the bad value to its source. One hypothesis, one minimal
  change at a time. If 3+ fixes fail, **question the architecture**, don't
  attempt fix #4.

### Verification (Iron Law)
- Before any "done/fixed/passes" claim: identify the proving command, run it
  fresh, read the full output, then make the claim with the evidence.
  Regression test? Show red-green (revert fix → must fail → restore → pass).

### Project-specific gotchas
- **Inside `go_router` redirect, never `ref.watch`** — it creates a rebuild
  loop. Watch sources outside the redirect closure, `ref.read` inside it.
  That's why `decideRedirect` is pure.
- **Role-claim race window:** between Firebase Auth user creation and the
  `setUserRole` Cloud Function returning, `role` is `null`/`unknown`. The
  router must *hold* the current path (see `decideRedirect` branch 4) rather
  than yank the user.
- **`setUserRole` fallback:** if the callable fails, the router falls back to
  the Firestore mirror collections (`users`, `creator_profiles`). Never assume
  the claim has resolved.
- **Google sign-in forks on `kIsWeb`:** web uses
  `signInWithRedirect(GoogleAuthProvider)`; native uses
  `GoogleSignIn.instance.authenticate()` + `credential`. Don't unify them.
- **fpdart `Either<L,R>`:** repos return `Either<Failure, T>`; consumers
  `.fold((error) => ..., (value) => ...)`. Don't throw across the boundary.
- **go_router shells:** the user nav is one `StatefulShellRoute.indexedStack`
  with 4 branches; creator surfaces are a separate shell in `creator_routes.dart`.
  Deep-links (`/creators/:id`, `/blueprint/:id`) sit at the top level with
  `parentNavigatorKey: _rootNavigatorKey`.

---

## Where to look

- Skill rule details: `.agents/skills/` (especially `test-driven-development`, `systematic-debugging`, `verification-before-completion`).
- Agent memory: `.agents/skills/claude-mem/` — persistent cross-session memory via opencode-mem (SQLite vector DB, http://127.0.0.1:4747). Always search memory before making architecture assumptions.
- Session observability: `.agents/skills/task-observer/` — records corrections, rework, friction, and patterns during each work session. Run `python .agents/skills/task-observer/scripts/synthesize.py --review-mode` at session-end to surface recommendations for review (never auto-edits).
- Antigravity setup/refresh: `.agents/skills/firebase-basics/references/setup/` and `references/refresh/` contain guides for installing/updating skills into the Antigravity IDE.
- Design decisions: `docs/superpowers/specs/` and `docs/superpowers/plans/`.
- A fine-tuning dataset capturing these rules as examples lives at `scripts/dataset_distillation/` (regenerate with `python build_seeds.py`).
