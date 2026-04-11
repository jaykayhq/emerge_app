# Codebase Concerns

**Analysis Date:** 2026-03-30 (Updated)

## Tech Debt

**Hardcoded Theme References:**
- Issue: Many widgets still use hardcoded dark-mode colors instead of the new theme extension.
- Why: Evolutionary build; the theme extension system was added later.
- Impact: Incomplete light mode support; visual inconsistencies during theme switching.
- Fix approach: Systematic refactoring of UI components to use `context.emergeTheme`.

**Riverpod v2/v3 Migration:**
- Issue: Mix of manual Providers and Code-Generated providers.
- Why: Incremental adoption of `riverpod_generator`.
- Impact: Potential for inconsistent state behavior or boilerplate fatigue.
- Fix approach: Transition all providers to code generation using `@riverpod`.

## Known Bugs

**Onboarding Tutorial Race Condition:**
- Symptoms: Tutorials may fail to load correctly immediately after onboarding.
- Trigger: Rapid navigation from the final onboarding step to the world map.
- Workaround: Manual app restart often resolves the state sync issue.
- Root cause: Auth state and user profile initialization latency.

## Security Considerations

**Firestore Rules Coverage:**
- Risk: Potential for broadly defined write rules in early-stage collections.
- Current mitigation: Rules are updated per-feature, but a holistic audit is needed.
- Recommendations: Run a formal security rule audit before scaling user base.

## Performance Bottlenecks

**World Map Initialization:**
- Problem: Large Tiled maps can cause jitters during initial Flame engine load.
- Measurement: 200ms+ stutter on low-end Android devices.
- Cause: Synchronous asset loading and complex layer composition.
- Improvement path: Implement progressive rendering or improved asset caching.

## Dependencies at Risk

**Legacy Packages:**
- Risk: Usage of `WillPopScope` (deprecated in Flutter 3.12+).
- Impact: Future breakage when deprecated APIs are removed.
- Migration plan: Refactor to `PopScope`.

## Test Coverage Gaps

**Integration Testing:**
- What's not tested: Full "End-to-End" flow from user signup to first habit completion and world evolution.
- Risk: Regression in the core habit loop.
- Priority: High.
- Difficulty to test: Requires complex UI automation with real/mocked Firebase auth.
