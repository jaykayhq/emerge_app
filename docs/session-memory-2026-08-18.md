# Session Memory — 2026-08-18

**Product:** Emerge (identity-first habit engine). Firebase (Auth/Firestore africa-south1/Functions nodejs22), Riverpod 3 + Drift + go_router 17, fpdart Either. Flutter 3.47, drift 2.34, share_plus 12.

## Review-driven hardening of the pushed 4-day changes (committed `0ced5710`)

Three parallel reviewers → four parallel fix agents over the uncommitted fixes of the pushed 15-commit window (`35ae1420..origin/main`). All fixes landed on `main` in `0ced5710` (48 files). Working tree clean after that commit and again after this session's landing-page fix.

### Delete-habit button — verified end-to-end + 2 real bugs fixed

- Path: `habit_options_sheet.dart` → `deleteHabit` → `DeletionService.deleteHabit` (archive + local completion cascade in one Drift transaction) → sync engine enqueues a remote `delete` on `habits/{id}` (rules allow owner delete; `sync_infrastructure_test.dart` covers the delete op execution).
- **Bug 1 (UI):** the sheet ignored the `Either` — on failure it still showed "Habit deleted" and skipped notification cancellation. Fixed: result folded; notifications always cancelled; sheet stays open with an honest error on failure.
- **Bug 2 (history leak):** remote `users/{uid}/habit_completions/{completionId}` docs were never deleted → a clean reinstall resurrected "permanently deleted" history (the dialog promises exactly that). Fixed: `DeletionService` captures completion ids inside the transaction and enqueues idempotent deletes (`del:completion:<id>`) best-effort, moved BEFORE the habit-doc enqueue so a habit-enqueue failure can't strand them; the already-archived retry path re-enqueues the habit-doc delete so failures self-heal.
- Also fixed a pre-existing broken test fake (`_FakeHabitRepo.completeHabit` had a stale `Unit` return vs the interface's `Either<Failure,bool>` — the test file hadn't compiled since the onboarding commit — and a tautological failure test (`namedArguments['collectionPath']` String key over a `Map<Symbol,_>`; must use `#collectionPath`).

### Email-worker / rules / scripts (reviewer caught 3 provable worker bugs)

- `reset.js` per-run cap no longer drops the uncommitted batch (was: `return` before `batch.commit()` → guaranteed duplicate sends); run-scoped `checkedEmail` + a per-run `sentThisRun` set close the within-page duplicate burst; stale (`sentAt==null`, >24h) requests are garbage-collected per run (dry-run safe).
- `firestore.indexes.json` gained the 3 `email_requests` composites the worker's queries require: `(type,sentAt)`, `(email,sentAt)`, `(sentAt,requestedAt)` — the cooldown query would have thrown `FAILED_PRECONDITION` in production.
- `email_requests` create rule: deliberately ANONYMOUS but shape-strict (`type == 'password_reset'`, `userId == '' | request.auth.uid`, 4-key `hasOnly`, email regex, timestamp). Anti-abuse lives in the worker: 15-min per-email cooldown, 24h age cap, USER_NOT_FOUND quiet skip, 500/run cap. Rationale: login-screen forgot-password is inherently signed-out; requiring auth killed the feature (found and fixed in this session).
- `partner_activity` create rule: friendship-gated (`users/{owner}/friends/{actor}.exists` — verified against `club_activity_service.dart` / `friend_repository.dart` paths) + 5-key whitelist; owner-gated deletes added for `global_activities` + `tribes/{tribeId}/activity` (undo was dead-lettering forever).
- `purgeOrphanedUserData.ts` recreates the WriteBatch after each 400-op commit; `purge_orphaned_data.js` runs tribe-membership cleanup BEFORE `recursiveDelete` and uses an `array-contains` query like the deployed TS; iOS key lookup in `restrict_api_keys.sh` fixed (space-safe `while IFS=$'\t' read`); API key literals redacted from docs/scripts.
- Router: `/reset-password` + `/verify-email` added to the signed-in oobCode-safe carve-out (signed-in users no longer burn a single-use oobCode); big set of signed-in/role-gated redirect tests added.
- Username claiming extended to Google + creator signups (`deriveUsernameCandidate`, pending_creator_username stash for the web redirect + `finally` cleanup); onboarding resume restores interests/joinedClubId; blueprint adoption is now a Drift transaction (was a plain loop → partial-failure wedge) + best-effort adoption counter + provider invalidation; malformed blueprint docs no longer kill the stream; partner lookup is best-effort like partner writes.

## Landing page (web-landing) — LEVEL UP toast overlap fixed (uncommitted after this doc)

- **Bug:** the `.level-toast` ("LEVEL UP — EXPLORER" pill in the phone mockup) was `position:absolute; top:40%` with a 16%-alpha background, appearing directly over the habit cards so their text bled through the pill.
- **Fix (`web-landing/styles.css`):** repositioned to `top:50%` (translate(-50%,-50%), the empty lane between the habit list and the XP row), opaque `rgba(10,10,26,0.92)` + `backdrop-filter: blur(6px)`, border/shadow, `z-index:5`, subtle pop scale on `.visible`.
- **Verification without screenshots** (headless env has NO fonts → glyph widths are 0, so pixel screenshots lie): puppeteer-core + Nix chromium measured layout boxes (heights/offsets are font-metric-driven and reliable). At 390×844 and 1440×900 the toast's computed box intersects NO habit card, xp-row, or mini-world, and stays inside the phone screen. Script loop phase 3 (`script.js` `apply(3)`) toggles `.visible`.

## Environment notes / gotchas discovered

- **opencode-mem is NOT available in this environment**: no `memory` tool, no CLI (`npx opencode-mem` has no executable), no server on :4747, no `~/.opencode-mem`. Durable memory is stored via the repo's `docs/session-memory-*.md` convention instead. Re-evaluate if the backend is ever installed.
- **Parallel `flutter test` invocations deadlock** on the shared Dart tool lock — ALWAYS run them sequentially (verified 3 times this session).
- **Playwright MCP** wants the `chrome` channel (`/opt/google/chrome`) which is absent; `npx playwright install` fails (no root TTY). Use the Nix Chromium directly (`/nix/store/*chromium-143*/bin/chromium --headless=new`) with puppeteer-core for browser checks. No fonts in the headless env → 0-width glyphs; verify overlap GEOMETRY via layout boxes, not text widths.
- Repo serves `web-landing/landing.html` — a static server won't auto-serve it at `/` (no `index.html`).

## Pending

- None from this session; working tree clean after the landing-page doc+fix commit.