# Implementation Plan: Recap Hub & Gated AI Insights

**Status**: Draft
**Goal**: Implement a reflection hub with tiered AI insights and persistent historical recaps.

---

## Phase 1: Data Model & Persistence
- [ ] **Model Update**: Update `UserWeeklyRecap` in `lib/features/gamification/domain/models/weekly_recap.dart`.
    - Add `isLocked` (bool).
    - Ensure it matches the Firestore schema for caching.
- [ ] **Service Refactor**: Update `WeeklyRecapService`.
    - Implement `getSavedRecaps()` to fetch from `users/{uid}/recaps`.
    - Implement `generateRecap(DateTime start, DateTime end)` with premium check.
    - Save results to Firestore after successful generation.

## Phase 2: Cloud Function Guard
- [ ] **Check Premium**: Update `generateAiRecap` in `functions/src/ai_recap.ts`.
    - Fetch the user's profile from Firestore.
    - Verify `isPremium === true` before calling AI.
    - Return a specific error code if not premium.

## Phase 3: Recap Hub UI
- [ ] **Screen Creation**: Create `lib/features/gamification/presentation/screens/recap_hub_screen.dart`.
    - Use `HexMeshBackground` for aesthetics.
    - Implement "Current Week" featured card.
    - Implement "History" list with date range calculations.
- [ ] **Provider**: Create `recap_hub_provider.dart` to manage the list of available recaps.

## Phase 4: Gated UI (Spotify Wrapped)
- [ ] **Locked State**: Update `SpotifyWrappedRecap` widget.
    - Add a `PremiumGate` overlay for the AI Insight slide.
    - Add "Upgrade Now" button connecting to the Paywall.
- [ ] **Dynamic Loading**: Update `WeeklyRecapScreen` to accept `recapId` or dates via GoRouter state.

## Phase 5: Routing & Polish
- [ ] **Router**: Update `lib/core/router/router.dart`.
    - Add `/recap-hub` route.
    - Add sub-route `/recap-hub/recap/:id`.
- [ ] **Home Link**: Update the main "Recap" button on the World Map/Home to point to the Hub.
- [ ] **Verification**: Run tests and manual walkthrough.
