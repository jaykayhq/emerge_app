# SDD Progress Ledger
## Onboarding Progress Bar & Endowment Refinement


Task 1: complete (commits c92f807..efe22e1, review clean — one Important finding was constraint misalignment, not code bug)
Task 2 BASE: efe22e13117ef83484be809dfee7a1a55be23a65
Task 2: complete (commits efe22e1..c1a0f3a, review clean)
Task 3 BASE: c1a0f3aee4acbf9e3e7be12c8a77630aea6f2d55
Task 3: complete (commits c1a0f3a..c03c736, review clean — two reviewer findings were false positives from diff context)
Task 4 BASE: c03c7366b6ab886fc01b636c7d105adb995ab882
Task 4: complete (commits c03c736..e84b21b, + abb95c9 fix round, review findings resolved)
Task 1: complete (commits d990d68..473315c, review clean)
Task 2: complete (commits 473315c..eb513bf, review clean)
Task 3: complete (commits eb513bf..225349d, review clean)
Task 4: complete (commits 225349d..e16eb7c, review clean)
Task 5: complete (commits e16eb7c..0d2bb5a, review clean)
Task 5: complete (commits e16eb7c..0d2bb5a, review clean)
Task 6: partial (commits 0d2bb5a..2665c43, review found issues needing fixes)
Task 6: complete (commit 2665c43..7e47fd096a1f86d140f4343cd127896d5a18b76a, review + fix approved)
Task 7: complete (commit 7e47fd0..62d16ffb0107bdcd9bbe3e7ea3b67e92e636724d, 5 files + tests, review clean)
Task 8: complete (commit 62d16ff..ee50cfb4b46836926215192c94fa419e068e48ba, 49/49 tests pass, analysis clean)
---
All 8 tasks complete. Proceeding to whole-branch review.
Task 1: complete (commits eaa4759..28aa99e, review clean)
Task 2: complete (commits e911b6e..130b5d7f184558565cc663ee2ebb092f3d640546, review clean, minor: unused import in test, unused tribeId param)
Task 4: complete (commits f55b0a6..2219509, review clean)
Task 3: complete (commits 2219509..fb4bf1e, review clean)
Task 5: complete 29f7733bd1053c18541af501acdb7a281429a7b4
Task 6: complete (commit 29f7733..646858a74ec618a5dde6686b0b33a732f17019dd, 0 errors, 47/47 tests pass)
---
All 6 tasks complete. Ready for whole-branch review.
Task 6: Final verification
---

# SP-F: Blueprints Overhaul (2026-08-02, SDD)
Base: HEAD at dispatch time per task.
Task 1: complete (commits 005184d..b7b98b8, review clean — minor props-coverage note only)
Task 2: complete (commits b7b98b8..b2cbbb6, review clean — minor exact-case coverage note)
Task 3: complete (commits b2cbbb6..b69340e, review clean — 3 minor: backfill-created docs lack createdAt, tests assert non-empty not exact lists, createdAt survival untested; triage at final review)
Task 4: complete (commits b69340e..8bdc241, review clean — 2 minor: duplicated creator-path predicate, test boilerplate; triage at final review)
Task 5: complete (commits 8bdc241..c17b5ca, review clean — 2 minor: pump-loop brittleness, '' vs null boundary; triage at final review)
Task 6: complete (commits c17b5ca..1dce0d3, review clean — 2 minor: hard cast in test, cached branch untested; triage at final review)
Task 7: complete (commits 1dce0d3..23de80c, review clean — 2 minor: cached hero path indirect coverage, pump robustness; triage at final review)
Task 8: complete (commits 23de80c..5fbc25f, review clean — 1 minor: full-width not asserted, structurally guaranteed; triage at final review)
Task 9: complete (commits 5fbc25f..e568d60, review clean — no findings)
Task 10: complete (commits e568d60..4607605, review clean — no findings)
SP-F final review: READY TO MERGE (0 Critical). 2 Important recorded as debt:
  1. cb_* seeds never backfill on deployed DBs (seedCreatorBlueprintsIfEmpty short-circuits on any isCreatorBlueprint doc) — fold into SP-E/SP-H.
  2. Seed tests assert non-empty not exact curated values — add exact-value test at next seed bump.
Docs straggler: screens_overview.md:164 still lists /social/discover — fix in handoff sweep.

# SP-D: Tribes/Creators Split (2026-08-02, SDD)
Base: 005184d-style per-task. Controller notes: tree clean (WIP committed); Task 2 CTA edit is an ADD (SP-F removed the button); line refs stale — locate fresh.
Task 1: complete (commits 4607605..6feeb53, review clean — 2 minor: loading/error creators branches untested, singular blueprint path + tap nav untested; triage at final review)
Task 2: complete (commits 6feeb53..0417b54, review clean — 1 minor: CTA navigation not tap-tested, plan-mandated; triage at final review)
Task 3: complete (commits 0417b54..f80ae58, review clean — no findings)
Task 4: complete (commits f80ae58..af205cc, review clean — 1 report-location nit only, no code findings)
Task 5: complete (commits af205cc..b194513, review clean — 1 minor: verification suite tail not run (killed at timeout, no risk); 2 adjudicated deviations correct)
Task 6: complete (no commit — verification-only, sweep 91/91, analyze clean, greps empty, route audit exact)
SP-D final review: READY TO MERGE (0 Critical/Important). All 4 ledger items record-as-debt. Carry into SP-E: (1) CreatorCard tap-nav test (replaces lost browse-screen coverage); (2) creators error-branch test (Stream.error → 'Creators are coming'); (3) fix stale verifiedCreatorsStreamProvider doc comment (still says "lobby strip and browse-all screen").

# SP-G: Tribe Membership & XP Accounting (2026-08-02, SDD)
Controller notes: tree clean; T6 depends on T7's clubId signature (dispatch T7 first); T13 functions suite has pre-existing paystack failure; T11 emulator verify manual (no Java).
Task 1: complete (commits b194513..8cd996f, review clean — 1 minor: negated raw fields doc note; adjudicated negation semantics; T5 dispatch will avoid double-negation)
Task 2: complete (commits 8cd996f..2a4acf3, review clean — 2 minor: offline branch untested, broad catch; brief-mandated; triage at final review)
Task 3: complete (commits 2a4acf3..7474754, review clean — pre-existing SP-A failure CLOSED; 3 minor: first-join test null-data ambiguity, TOCTOU (spec-inherent), totalHabitsCompleted unasserted; triage at final review)
Task 4: complete (commits 7474754..265d84e, review clean — no material findings)
Task 5: complete (commits 265d84e..f052845, review clean — 2 minor: test helper dedup, contributors undo return unasserted; triage at final review)
Task 7: complete (commits f052845..db30e92, review clean — 2 minor: feed-path substitution unasserted, RED was compile-only for behavior flip; triage at final review)
Task 6: complete (commits db30e92..218fda1, review clean — 3 minor: partial-progress logChallengeComplete unasserted, title fallback unpinned, setup repetition; triage at final review)
Task 8: complete (commits 218fda1..2d5f817, review clean — 3 minor: membershipAsync.value degrade (plan-mandated, flagged), RED transcript nit, decorative test seed; triage at final review)
Task 9: complete (commits 2d5f817..d50b6af, review clean — 2 minor: unreviewed blank line, seed-update-before-RED sequencing; triage at final review)
Task 10: complete (commits d50b6af..772c1b9, review clean — 3 minor: firstOrNull arbitrary-tribe (plan-mandated), misindent, triplicate filter idiom; triage at final review)
Task 11: complete (commits 772c1b9..92070ef incl. review-fix 92070ef, re-review clean — 2 minor carryover: magic '' member value, merge tests plan-scoped; rules delta now exact-caller)
Task 12: complete (commits 92070ef..47d39e9, review clean — 3 minor: members unasserted in 0-XP test, no combined-path test, Set ordering note; triage at final review)
Task 13: complete (commits 47d39e9..ccdc446, review clean — 3 minor: activities scope deviation untested, XP-precedence fallback untested, weak malformed-path assertion; triage at final review)
Task 14: complete (ccdc446..e8390ea, review clean — 1 minor: import ordering nit; 13 pre-existing Flutter failures proven at base; SP-A handoff item CLOSED)
SP-G final review: READY TO MERGE after 2 fix rounds (T11 rules exact-caller delta; final-wave: creator-type gate restored, client official-club seed removed, D4 merge tests added).
SP-H carryover: (1) 13 pre-existing Flutter failures (sync_infrastructure/sync_trigger/sync_providers/splash_routing/auth_providers-signOut) proven pre-existing at SP-G base — triage there; (2) pre-existing functions paystack.test.ts failure; (3) rules ±1 sequence bypass → callables strong option; (4) server seed.ts now the official-club bootstrap (fresh envs need it run); (5) undo contributor-debit no-membership edge (exact-mirror violation, low frequency); (6) recalc archetype normalization + global-activities creator-tribe tests; (7) release note: first recalc may visibly shrink inflated tribe totals; legacy docs without members deny join/leave until recalc.

# SP-H: Firebase Backend Hardening (2026-08-02, SDD — re-scoped)
Plan written pre-SP-E/SP-G. Verified current state: rules isVerifiedCreator/creator_invite_codes/creator_profiles/challenges/tribes-gate-±1 LANDED; Task 9 (recalc) SUPERSEDED by SP-G T13; Task 10 (creator_invites) SUPERSEDED by SP-E. Remaining code: rateLimited removal, isValidStats premium block, blueprints 'system' carve-out, dead triggers, ai_recap gate, paystack claims, purge skip-list, emulator script. Manual (deferred): firebase access/deploy (T1/T11), emulator run (T5), admin console deletions, smoke (T12). Rollback baseline: HEAD before SP-H = e8390ea.
Task SP-H-1: complete (8d4c425..90ddb72, review clean — 1 cosmetic comment-attribution nit)
Task SP-H-2: complete (90ddb72..e75aea3, review clean — 1 cosmetic: stale habit_notifications doc header)
Task SP-H-3: complete (e75aea3..79784c7, review clean — 2 minor: dominantIdentityThisWeek source change noted, mock shape cosmetic)
Task SP-H-4: complete (79784c7..193ba43, review clean — 2 minor spec-inherent trade-offs: claim-failure-marker ordering, TOCTOU on claims merge; note for final review)
Task SP-H-5: complete (193ba43..63847fe, review clean — 1 minor: skipped counter now always 0, defensible)
Task SP-H-6: complete (63847fe..5eed1d6 incl. review-fix, spot-verified — get-or-create signUp + error-message fix)
Task SP-H-7: complete (verification-only, no commit — suite 57/58, dry-run OK, greps clean, superseded tasks green)
SP-H final review: APPROVED after fix wave (C1 createdBy guard, C2 startsWith carve-out deletion, NEW difference()→removeAll discovery, I1 script plumbing, I2 isAdmin guard, cosmetics). Matrix 26/26 PASS live (add + remove branches). Deferred manual ops: deploy rules+functions, admin console deletions (12 seeds + v1 purge + morning_3 URL), post-deploy logs check, smoke checklist. Note: firebase CLI IS authenticated in this environment — deploy available on explicit request.
DEPLOYED 2026-08-02 (user-requested): firestore.rules live; functions deployed --force (3 dead functions deleted: enforceRateLimit, onHabitChanged, notifyAchievement; creator_invites callables live; ai_recap gate + paystack claims sync + purge skip-list live). Remaining manual: admin console deletions (12 seeds + v1 purge + morning_3 URL), post-deploy log check, smoke checklist.

# Signup Validation + Premium Cancel (2026-08-02, SDD)
Base: 2e41813 (docs committed). Plan: docs/superpowers/plans/2026-08-02-signup-validation-premium-cancel.md
Controller note: approved implementer-flagged fixture fix 'Tr0ub4dor!' -> 'Tr0ub4dor&3!' (brief was self-contradictory vs minLength=12).
Task 1: complete (2e41813..f745693, review clean — 4 minor: anti-drift assertion unenforced, maxLength uncovered by checklist, maxLength/minCharacterClasses branch untested, vestigial take(50) cap; triage at final review)
Task 2: complete (f745693..50da6e7, review clean — 2 minor: mixed tick-state never asserted (only all-fail/all-pass), double rule.passes evaluation per build; triage at final review)
Task 3: complete (50da6e7..2372c7e, review clean — 2 minor: findsNothing assertion trivially true, index-based field selection order-fragile (file convention); triage at final review)
Task 4: complete (2372c7e..fec62ad, review clean — 2 minor: RED evidence attribution mismatch in report, onUserInteraction-vs-always distinction unasserted; triage at final review)
Task 5: complete (fec62ad..98c86de, review clean — 2 minor: as String?/as DateTime? casts in pure fn (plan-mandated, production-safe), recordToPremium string/DateTime branches untested; triage at final review). CONTROLLER NOTE: paused-web premium past premiumEndsAt only drops at next provider rebuild (stream emits on doc change, not time passage) — known limitation, triage at final review / flag to user.
Task 6: complete (98c86de..0de51d1, review clean — 2 minor: docGet fake is dead weight + missing-doc cancel untested (merge-set succeeds, correct), absent-claims branch untested; triage at final review)
Task 7: complete (0de51d1..6f46f03, review clean — 1 minor: malformed managementURL -> raw e.toString() Left (plan-mandated, file convention); triage at final review)
Task 8: complete (6f46f03..c66e691, review clean — 1 minor: failure-path test emits AppLogger.e noise (brief-mandated design); triage at final review)
Task 9: complete (c66e691..94b7f5a + fix 0fb571b, review approved after fix round — Important: native double store-open + false 'Premium cancelled' (FIXED: inert 'Finish in Google Play' CTA + early-return guard + tightened test). Minors carried: free-user status step shows active Cancel CTA (behavior change: tile no longer routes free users to /paywall — flag user), web path untested (kIsWeb), 1 cosmetic comment nit; triage at final review)
Task 10: complete (verification-only, no commit — sweep 51/51, functions jest 6/6, dart analyze clean after 1 fix commit b70ac11 (paywall mock missing openManageSubscription + unused import); manual Android/web smoke deferred to user)
Final whole-branch review (2e41813..b70ac11): NOT READY -> 2 Important fixed in 1b382e9 -> RE-REVIEW APPROVED. Finding 1: pause-end Timer in _buildFromFirestore (dispose-cancel, try/catch, future-guarded re-schedule). Finding 2: free-user status step gates billing line + Cancel CTA, 'Go Premium' -> /paywall. 3 minors carried (comment arithmetic 30d vs Timer 24.7d cap — behavior safe via clamp+reschedule; stale timer across uid change mirrors pre-existing sub pattern; free-user test 'Billed at' assertion weaker than intended). 17 accepted-debt findings from triage. Manual Android/web smoke + functions deploy still pending (user action). No iOS config touched (verified zero ios/ changes).
DEPLOYED 2026-08-02 (user-requested): functions:managePremium live on tradeflash-l2966 (us-central1). Predeploy npm build verified clean; CLI deploy reported Successful create operation.
