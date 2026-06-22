# Tier 1 Test Coverage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development

**Goal:** Add ~80 unit tests across 15 test suites covering domain models and services in all features.

**Architecture:** Unit tests only, following existing patterns (mocktail, Drift in-memory DB, FakeFirebaseFirestore). Each test file corresponds to one source file or logical group.

**Tech Stack:** Flutter test, mocktail, drift, fpdart

---

### Task A: Social Models (Tribe + ChallengeCatalog)

**Files:**
- Create: `test/features/social/domain/models/tribe_test.dart`
- Create: `test/features/social/domain/models/challenge_catalog_test.dart`

**Tests:** Tribe model (constructor, copyWith, props/equality, fromMap/toMap, default values), ChallengeCatalog (getFeatured, getDailyQuest, getWeeklySpotlight, getChallengeById, getAvailableChallenges)

### Task B: SocialActivityService Expansion

**Files:**
- Modify: `test/features/social/domain/services/club_activity_service_test.dart`

**Tests:** logHabitCompletion, logLevelUp, logChallengeComplete, logStreakMilestone, logNodeClaim, logBadgeEarned, logPartnerJoined, logContractCommitted

### Task C: TribeStatsService + BlueprintRepository + GameLoopEngine

**Files:**
- Modify: `test/features/social/data/services/tribe_stats_service_test.dart`
- Modify: `test/features/blueprints/data/repositories/blueprint_repository_test.dart`
- Modify: `test/core/game_loop/game_loop_engine_test.dart`

**Tests:** TribeStats Firestore methods, BlueprintRepository seed/create/get, GameLoopEngine edge cases

### Task D: Monetization + Avatar + Profile Models

**Files:**
- Create: `test/features/monetization/domain/models/subscription_test.dart`
- Create: `test/features/gamification/domain/models/avatar_state_test.dart`
- Create: `test/features/profile/domain/models/silhouette_test.dart`

### Task E: Settings + Insights + Health + Onboarding + Timeline + AI Models

**Files:**
- Create: `test/features/settings/domain/models/preferences_test.dart`
- Create: `test/features/insights/domain/models/insight_test.dart`
- Modify: `test/features/health/domain/models/` (fill gaps)
- Create: `test/features/onboarding/domain/models/archetype_test.dart`
- Create: `test/features/timeline/domain/models/timeline_event_test.dart`
- Create: `test/features/ai/domain/models/recommendation_test.dart`
