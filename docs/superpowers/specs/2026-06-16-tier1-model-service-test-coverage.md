# Tier 1: Model & Service Test Coverage

## Goal
Achieve 80%+ test coverage on domain models and services across all features.

## Scope
15 test suites, ~1,200 new test lines, ~80 tests.

## Priority Order

### 1. Social Domain Models (NEW)
- `test/features/social/domain/models/tribe_test.dart` — Tribe constructor, copyWith, props, equality, fromMap/toMap, default values
- `test/features/social/domain/models/challenge_catalog_test.dart` — getFeatured, getDailyQuest, getWeeklySpotlight, getChallengeById, getAvailableChallenges

### 2. SocialActivityService (EXPAND)
- `test/features/social/domain/services/club_activity_service_test.dart` — Add tests for: logHabitCompletion, logLevelUp, logChallengeComplete, logStreakMilestone, logNodeClaim, logBadgeEarned, logPartnerJoined, logContractCommitted

### 3. TribeStatsService Firestore Methods (EXPAND)
- `test/features/social/data/services/tribe_stats_service_test.dart` — Add Firestore-based tests for getMemberCount, getTotalXp, getTotalHabitsCompleted, getTotalChallengesCompleted, getTribeStats, syncTribeStats

### 4. BlueprintRepository (EXPAND)
- `test/features/blueprints/data/repositories/blueprint_repository_test.dart` — Add tests for createBlueprint, seedBlueprintsIfEmpty, getBlueprints

### 5. GameLoopEngine Edge Cases (EXPAND)
- `test/core/game_loop/game_loop_engine_test.dart` — Add tests for zero/negative values, overflow, boundary conditions

### 6. Monetization Models (NEW)
- `test/features/monetization/domain/models/` — Subscription, paywall, contract, ad models

### 7. Avatar Models (NEW)
- `test/features/gamification/domain/models/avatar*_test.dart` — Avatar state, evolution, archetype models

### 8. Profile Domain Models (EXPAND)
- `test/features/profile/domain/models/` — Silhouette, radar chart data models

### 9. Settings Models (NEW)
- `test/features/settings/domain/models/` — Preferences, notification settings

### 10. Insights Models (NEW)
- `test/features/insights/domain/models/` — AI insight models

### 11. Health Models (EXPAND)
- `test/features/health/domain/models/` — Fill remaining gaps

### 12. Onboarding Models (NEW)
- `test/features/onboarding/domain/models/` — Archetype, question models

### 13. Timeline Models (NEW)
- `test/features/timeline/domain/models/` — Timeline event models

### 14. AI Models (NEW)
- `test/features/ai/domain/models/` — AI recommendation models

## Architecture
- Unit tests only (no widget/integration tests in Tier 1)
- Follow existing patterns: mocktail for mocks, Drift in-memory database for repository tests
- No Firebase dependency — use FakeFirebaseFirestore or mocks
