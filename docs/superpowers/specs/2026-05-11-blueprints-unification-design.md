# Design Spec: Blueprint & Tribe Unification

## Goal
Unify the fragmented blueprint systems from `social` and `gamification` into a single "Source of Truth" module. This resolves the bug where only one blueprint shows per category and eliminates architectural conflicts.

## User Review Required
> [!IMPORTANT]
> This change will move all blueprint-related logic to a new `lib/features/blueprints` directory. Existing collections in Firestore (`creator_blueprints`) will be deprecated in favor of a unified `blueprints` collection.

## Proposed Changes

### 1. Unified Model: `lib/features/blueprints/domain/models/blueprint.dart`
- **IdentityBlueprint**: Merges `CreatorBlueprint` and `Blueprint`.
- **Fields**:
  - `id`, `title`, `description`, `category` (The Tribe/Archetype).
  - `imageUrl`, `difficulty` (Beginner/Intermediate/Advanced).
  - `habits` (List of `BlueprintHabit` with title, timeOfDay, frequency).
  - `creatorName`, `adoptionCount`, `isPremium`.

### 2. Unified Repository: `lib/features/blueprints/data/repositories/blueprint_repository.dart`
- **Collection**: `blueprints`.
- **Seeding**: Robust `seedBlueprints()` that ensures 5 blueprints per archetype (25 total) are always present.
- **Provider**: `blueprintRepositoryProvider`.

### 3. Tribe Aesthetic Refresh
- **Tribes**: Standardize on the 5 core archetypes (**Athlete, Creator, Scholar, Stoic, Zealot**).
- **Images**: New vibrant, premium Unsplash URLs for both Tribe headers and Blueprint cards.

### 4. UI Refactor: `lib/features/social/presentation/screens/social_discover_tab.dart`
- Switch from `blueprintsStreamProvider` (social) to the new `unifiedBlueprintsProvider`.
- Ensure grouping logic is robust and shows the full list of 5+ cards per category strip.

## Verification Plan
### Automated Tests
- `flutter test` for the new `Blueprint` model serialization.
- Verify `seedBlueprints()` batch logic.

### Manual Verification
- Open Social -> Discover tab.
- Verify that each category (Athlete, Creator, etc.) shows **multiple** cards in the horizontal scroll.
- Verify that clicking a card opens the correct detail view with unified data.
