# Application Screens Overview

This document lists all screens in the Emerge app, derived from the live filesystem and `router.dart`.
Categorised by feature area. Each entry includes the file path, route, purpose, and key dependencies.

> **Last updated:** June 2026 — reflects the current router and screen files on disk.

---

## Core

- **SplashScreen**
  - File: [`lib/core/presentation/screens/splash_screen.dart`](lib/core/presentation/screens/splash_screen.dart)
  - Route: `/splash`
  - Purpose: Initial app entry point; waits for auth state and redirects accordingly.
  - Dependencies: None

- **WorldSplashScreen**
  - File: [`lib/core/presentation/screens/world_splash_screen.dart`](lib/core/presentation/screens/world_splash_screen.dart)
  - Route: `/world-splash`
  - Purpose: Cinematic, animated splash that creates a psychological threshold between login and the user's world. Auto-navigates after reveal.
  - Dependencies: None

---

## Authentication

- **WelcomeScreen**
  - File: [`lib/features/onboarding/presentation/screens/welcome_screen.dart`](lib/features/onboarding/presentation/screens/welcome_screen.dart)
  - Route: `/welcome`
  - Purpose: First-launch landing screen shown to unauthenticated new users before login/signup.
  - Dependencies: None

- **LoginScreen**
  - File: [`lib/features/auth/presentation/screens/login_screen.dart`](lib/features/auth/presentation/screens/login_screen.dart)
  - Route: `/login`
  - Purpose: Authenticates returning users via Firebase Auth.
  - Dependencies: `auth_providers`, Firebase Auth

- **SignUpScreen**
  - File: [`lib/features/auth/presentation/screens/signup_screen.dart`](lib/features/auth/presentation/screens/signup_screen.dart)
  - Route: `/signup`
  - Purpose: Registers new users via Firebase Auth.
  - Dependencies: `auth_providers`, Firebase Auth

---

## Onboarding

> Flow (controlled by `onboardingProgress` in Firestore):
> `0–1` → IdentityStudio → `2` → FirstHabit → `3` → WorldReveal → complete

- **IdentityStudioScreen**
  - File: [`lib/features/onboarding/presentation/screens/identity_studio_screen.dart`](lib/features/onboarding/presentation/screens/identity_studio_screen.dart)
  - Route: `/onboarding/identity-studio`
  - Purpose: Two-step paged flow: (1) Archetype selection carousel, (2) Motive/identity attribute selection. Replaces all previous multi-screen onboarding screens.
  - Dependencies: `onboarding_state_notifier`, `archetype_theme`

- **FirstHabitScreen**
  - File: [`lib/features/onboarding/presentation/screens/first_habit_screen.dart`](lib/features/onboarding/presentation/screens/first_habit_screen.dart)
  - Route: `/onboarding/first-habit`
  - Purpose: Guides the user in creating their first habit during onboarding, seeded from their chosen archetype.
  - Dependencies: `onboarding_state_notifier`, `habit_providers`, `user_stats_providers`, `auth_providers`

- **WorldRevealScreen**
  - File: [`lib/features/onboarding/presentation/screens/world_reveal_screen.dart`](lib/features/onboarding/presentation/screens/world_reveal_screen.dart)
  - Route: `/onboarding/world-reveal`
  - Purpose: Cinematic final onboarding screen that dramatically reveals the user's world and marks `onboardingCompletedAt`. Preloads social data in background.
  - Dependencies: `onboarding_provider`, `onboarding_state_notifier`, `social_preload_provider`

---

## World Map (Main Home Tab)

- **WorldMapScreen**
  - File: [`lib/features/world_map/presentation/screens/world_map_screen.dart`](lib/features/world_map/presentation/screens/world_map_screen.dart)
  - Route: `/` (Shell branch 1 — bottom nav tab 1)
  - Purpose: The primary home screen. Renders the user's archetype-specific interactive world map with unlockable nodes tied to XP level.
  - Dependencies: `gamification_providers`, `user_stats_providers`, `archetype_maps_catalog`

- **LevelImmersiveScreen**
  - File: [`lib/features/world_map/presentation/screens/level_immersive_screen.dart`](lib/features/world_map/presentation/screens/level_immersive_screen.dart)
  - Route: `/node/:nodeId` (root navigator)
  - Purpose: Full-screen immersive detail view for a tapped world map node; shows the node's lore, unlock requirements, and rewards.
  - Dependencies: `gamification_providers`, `user_stats_providers`, `archetype_maps_catalog`

- **RecapHubScreen**
  - File: [`lib/features/gamification/presentation/screens/recap_hub_screen.dart`](lib/features/gamification/presentation/screens/recap_hub_screen.dart)
  - Route: `/recap-hub` (root navigator)
  - Purpose: Hub screen listing all available weekly and historical recaps for the user.
  - Dependencies: `gamification_providers`

- **WeeklyRecapScreen**
  - File: [`lib/features/gamification/presentation/screens/weekly_recap_screen.dart`](lib/features/gamification/presentation/screens/weekly_recap_screen.dart)
  - Route: `/recap?id=&start=&end=` (root navigator)
  - Purpose: Detailed weekly performance recap with XP earned, habits completed, and world growth summary. Accepts optional `recapId`, `startDate`, `endDate` parameters.
  - Dependencies: `gamification_providers`

---

## Timeline / Habits (Tab 2)

- **TimelineScreen**
  - File: [`lib/features/timeline/presentation/screens/timeline_screen.dart`](lib/features/timeline/presentation/screens/timeline_screen.dart)
  - Route: `/timeline` (Shell branch 2 — bottom nav tab 2)
  - Purpose: Chronological timeline view of all user habits with today's completions, streaks, and quick-log actions.
  - Dependencies: `habit_providers`, `user_stats_providers`

- **HabitDetailScreen**
  - File: [`lib/features/habits/presentation/screens/habit_detail_screen.dart`](lib/features/habits/presentation/screens/habit_detail_screen.dart)
  - Route: `/timeline/detail/:habitId`
  - Purpose: Full-screen habit detail with editing capabilities, timer integration, and completion history. Uses `WorldBackground` themed to the user's archetype.
  - Dependencies: `habit_providers`, `notification_service`

- **StreakRecoveryScreen**
  - File: [`lib/features/habits/presentation/screens/streak_recovery_screen.dart`](lib/features/habits/presentation/screens/streak_recovery_screen.dart)
  - Route: Launched as a modal (not a named go_router route)
  - Purpose: Shown when a user misses a habit. Frames recovery positively ("You're human. Never miss twice.") and visually restores identity momentum.
  - Dependencies: `habit` entity

- **AdvancedCreateHabitDialog**
  - File: [`lib/features/habits/presentation/screens/advanced_create_habit_dialog.dart`](lib/features/habits/presentation/screens/advanced_create_habit_dialog.dart)
  - Route: `/timeline/create-habit`
  - Purpose: Full-screen dialog (presented inline within the Timeline shell) for creating or editing a habit with advanced options.
  - Dependencies: `habit_providers`

---

## Social / Tribes (Tab 3)

The Tribe tab is a **dual hub** — the social home for both the user's
archetype tribe (collective) and their accountability partners (personal).

**Screen:** `TribeLobbyScreen`
[`lib/features/social/presentation/screens/tribe_lobby_screen.dart`](lib/features/social/presentation/screens/tribe_lobby_screen.dart)

- Route: `/social` (Shell branch 3 — bottom nav tab 3)
- Purpose: Identity-first social lobby that surfaces both tribe (collective)
  and partner (personal) graphs as first-class peers. Replaces the previous
  `SocialScreen` whose identity was undefined and whose live feed deep-links
  were misrouted.

**Lobby sliver order:**
1. Hero (tribe emoji + name)
2. Stats (members / streak / momentum)
3. Pulse chips (LIVE / MOMENTUM / STREAK / QUESTS)
4. **Your Circle** (accountability partners) → `/social/accountability`
5. Live feed (club activity, top 3) → `/social/activity`
6. Creators strip
7. **Your Quests** (joined, active) → `/social/challenges`
8. **Quests For You** (featured daily/weekly)

**Sub-routes (branch 3 of the shell):**

| Route | Screen | Purpose |
|---|---|---|
| `/social` | `TribeLobbyScreen` | Dual-hub lobby |
| `/social/activity` | `SocialActivityScreen` | Two-tab activity: Tribe + Partners |
| `/social/accountability` | `FriendsScreen` | Partner management (1:1) |
| `/social/contacts` | `SocialContactsScreen` | Address-book discovery |
| `/social/contracts` | `HabitContractScreen` | Habit contracts |
| `/social/leaderboard` | `LeaderboardScreen` | Friends/tribe/world leaderboard |
| `/social/all` | `AllTribesScreen` | Browse all tribes |
| `/social/discover` | `CreatorsBrowseScreen` | Browse creators |
| `/social/onboarding` | `SocialOnboardingScreen` | First-time social onboarding |
| `/social/challenges` | `ChallengesScreen` | All challenges (active + featured) |
| `/social/challenge/:challengeId` | `ChallengeDetailScreen` | Challenge detail |
| `/social/creator/:id` | `CreatorProfileScreen` | Creator profile |
| `/social/blueprint/:id` | `BlueprintDetailScreen` | Blueprint detail |

**Three social graphs** (kept distinct):

- **Tribe** — archetype collective, club-scoped activity feed.
- **Partners** — 1:1 accountability partners via `users/{uid}/friends`.
- **Creators** — asymmetric follow; faces-only strip in the lobby.

**Partner activity** is written via **fan-out-on-write** into
`users/{partnerId}/partner_activity` by `SocialActivityService`. Each
partner-visible event (habit check-in, streak milestone, quest joined,
contract signed) writes a denormalized doc to every partner's activity
subcollection so reads stay a single clean query.

**Contacts = discovery surface, not a relationship tier.** Address-book
contacts are read on-device (via `fast_contacts`), matched against
existing users by phone/email (read-only), and resolve to existing
`partner` relationships — no new relationship model.

**Screens:**

- **TribeLobbyScreen** — the dual-hub lobby (above).
- **SocialActivityScreen** — two-tab activity: Tribe feed (club-scoped) and
  Partners feed (new partner-activity data source).
- **FriendsScreen** — partner management hub: list, requests, contracts, and
  an "Add from contacts" entry to `/social/contacts`.
- **SocialContactsScreen** — address-book discovery surface: matches device
  contacts against existing emerge users by phone or email.
- **ChallengesScreen** — all challenges (active + featured), used both as a
  standalone screen and as a deep-link target from lobby quests.
- **ChallengeDetailScreen** — challenge detail with leaderboard.
- **HabitContractScreen** — formal habit contracts with commitment pledges.
- **LeaderboardScreen** — three-tab leaderboard: Friends, Tribe, World.
- **AllTribesScreen** — browse all public tribes.
- **CreatorsBrowseScreen** — browse creators (re-used for `/social/discover`).
- **SocialOnboardingScreen** — first-time social onboarding (gated by
  `socialOnboardingCompletedProvider`).
- **CreatorProfileScreen** — single creator profile.
- **BlueprintDetailScreen** — creator blueprint detail.

**Internal widgets (not full screens):**

- [`tribe_circle_section.dart`](lib/features/social/presentation/widgets/tribe_circle_section.dart)
  — Lobby "Your Circle" partners section (replaces the orphaned
  `TribeAccountabilitySection`).
- [`tribe_your_quests_section.dart`](lib/features/social/presentation/widgets/tribe_your_quests_section.dart)
  — Active-only quests section.
- [`tribe_quests_for_you_section.dart`](lib/features/social/presentation/widgets/tribe_quests_for_you_section.dart)
  — Featured-only quests section (daily + weekly spotlight).
- [`tribe_live_compact.dart`](lib/features/social/presentation/widgets/tribe_live_compact.dart)
  — Compact two-tab block (LIVE FEED + LEADERBOARD); "View More" →
  `/social/activity?tribeId=…`.
- [`tribe_pulse_status_row.dart`](lib/features/social/presentation/widgets/tribe_pulse_status_row.dart)
  — Pulse chips row; LIVE chip → `/social/activity?tribeId=…`.
- [`tribe_creators_strip.dart`](lib/features/social/presentation/widgets/tribe_creators_strip.dart)
  — Horizontal strip of verified creator faces.
- [`create_solo_challenge_dialog.dart`](lib/features/social/presentation/screens/create_solo_challenge_dialog.dart)
  — Dialog for solo challenge creation.
- [`invite_code_dialog.dart`](lib/features/social/presentation/screens/invite_code_dialog.dart)
  — Dialog for tribe invite codes.

---

## Profile / Identity (Tab 4)

- **FutureSelfStudioScreen**
  - File: [`lib/features/profile/presentation/screens/future_self_studio_screen.dart`](lib/features/profile/presentation/screens/future_self_studio_screen.dart)
  - Route: `/profile` (Shell branch 4 — bottom nav tab 4)
  - Purpose: The user's identity profile hub. Visualises their future self, archetype, XP level, and provides access to all identity-related tools (reflections, leveling, Goldilocks).
  - Dependencies: `user_stats_providers`, `auth_providers`

---

## AI Features

- **AiReflectionsScreen**
  - File: [`lib/features/ai/presentation/screens/ai_reflections_screen.dart`](lib/features/ai/presentation/screens/ai_reflections_screen.dart)
  - Route: `/profile/reflections`
  - Purpose: Displays AI-generated personalised reflections and insights based on the user's habit data. Powered by Groq via Firebase Cloud Functions.
  - Dependencies: `ai_providers`

- **GoldilocksScreen**
  - File: [`lib/features/ai/presentation/screens/goldilocks_screen.dart`](lib/features/ai/presentation/screens/goldilocks_screen.dart)
  - Route: `/profile/goldilocks`
  - Purpose: Analyses the user's completion patterns and recalibrates habit difficulty to keep engagement in the optimal zone (not too easy, not too hard).
  - Dependencies: `ai_providers`

---

## Gamification

- **LevelingScreen**
  - File: [`lib/features/gamification/presentation/screens/leveling_screen.dart`](lib/features/gamification/presentation/screens/leveling_screen.dart)
  - Route: `/profile/leveling`
  - Purpose: Shows the user's full XP progression, level milestones, and what unlocks at each level.
  - Dependencies: `gamification_providers`

- **LevelUpRewardScreen**
  - File: [`lib/features/gamification/presentation/screens/level_up_reward_screen.dart`](lib/features/gamification/presentation/screens/level_up_reward_screen.dart)
  - Route: `/profile/level-up-reward/:level` (root navigator)
  - Purpose: Full-screen celebration shown when the user levels up. Displays unlocked rewards for the `celebratedLevel`.
  - Dependencies: `gamification_providers`

---

## Settings

- **SettingsScreen**
  - File: [`lib/features/settings/presentation/screens/settings_screen.dart`](lib/features/settings/presentation/screens/settings_screen.dart)
  - Route: `/profile/settings`
  - Purpose: General app settings (account, theme, data management).
  - Dependencies: `settings_repository`

- **NotificationSettingsScreen**
  - File: [`lib/features/settings/presentation/screens/notification_settings_screen.dart`](lib/features/settings/presentation/screens/notification_settings_screen.dart)
  - Route: `/profile/notifications`
  - Purpose: Configure habit reminder notifications and quiet hours.
  - Dependencies: `settings_repository`

---

## Monetization

- **PaywallScreen**
  - File: [`lib/features/monetization/presentation/screens/paywall_screen.dart`](lib/features/monetization/presentation/screens/paywall_screen.dart)
  - Route: `/paywall`
  - Purpose: Premium subscription upsell screen. Presents plan options and routes to checkout (RevenueCat or Paystack).
  - Dependencies: `subscription_provider`

- **PaystackCheckoutScreen**
  - File: [`lib/features/monetization/presentation/screens/paystack_checkout_screen.dart`](lib/features/monetization/presentation/screens/paystack_checkout_screen.dart)
  - Route: Launched programmatically from `PaywallScreen`
  - Purpose: In-app WebView checkout using Paystack Standard, supporting Google Pay and Apple Pay natively. Accepts `amount`, `email`, and `identityType` parameters.
  - Dependencies: `paystack_payment_repository`, `flutter_inappwebview`

- **HabitContractScreen**
  - File: [`lib/features/monetization/presentation/screens/habit_contract_screen.dart`](lib/features/monetization/presentation/screens/habit_contract_screen.dart)
  - Route: `/tribes/contracts` (root navigator)
  - Purpose: Lets users create a formal, binding digital habit contract with a commitment pledge. Behavioural commitment device for premium users.
  - Dependencies: `habit_contract_repository`

---

## Navigation Structure (Bottom Nav)

| Tab | Route | Screen | Branch |
|-----|-------|---------|--------|
| 1 — World | `/` | `WorldMapScreen` | Branch 1 |
| 2 — Timeline | `/timeline` | `TimelineScreen` | Branch 2 |
| 3 — Tribe | `/social` | `TribeLobbyScreen` | Branch 3 |
| 4 — Profile | `/profile` | `FutureSelfStudioScreen` | Branch 4 |

> All tabs wrapped in `LevelUpListener` → `ScaffoldWithNavBar` via `StatefulShellRoute.indexedStack`.

---

## Removed Screens (no longer in codebase)

The following screens existed in a previous version and have since been deleted or consolidated:

| Old Screen | Replaced By |
|---|---|
| `OnboardingScreen` | `IdentityStudioScreen` |
| `OnboardingArchetypeScreen` | `IdentityStudioScreen` (page 1) |
| `IdentityAttributesScreen` | `IdentityStudioScreen` (page 2) |
| `IntegrateWhyScreen` | Removed |
| `HabitAnchorsScreen` | Removed |
| `HabitStackingScreen` | Removed |
| `HomeScreen` | `WorldMapScreen` |
| `GatekeeperScreen` | Removed |
| `TwoMinuteTimerScreen` | Integrated into `HabitDetailScreen` |
| `CreateHabitScreen` | `AdvancedCreateHabitDialog` |
| `HabitBuilderScreen` | Removed |
| `EnvironmentPrimingScreen` | Removed |
| `HabitDashboardScreen` | `TimelineScreen` |
| `HabitsScorecardScreen` | `TimelineScreen` |
| `AvatarCustomizationScreen` | `FutureSelfStudioScreen` |
| `EnhancedAvatarCustomizationScreen` | `FutureSelfStudioScreen` |
| `WorldScreen` | `WorldMapScreen` |
| `GrowingWorldScreen` | `WorldMapScreen` |
| `EvolvingForestScreen` | `WorldMapScreen` |
| `LandExpansionScreen` | `WorldMapScreen` / `LevelImmersiveScreen` |
| `BuildingPlacementScreen` | `WorldMapScreen` |
| `TemptationBundlingScreen` | Removed |
| `UserProfileScreen` | `FutureSelfStudioScreen` |
| `DailyReportScreen` | `RecapHubScreen` / `WeeklyRecapScreen` |
| `CinematicRecapScreen` | `WeeklyRecapScreen` |
| `CreatorBlueprintsScreen` | `BlueprintDetailScreen` |
| `ReflectionsScreen` | `AiReflectionsScreen` |
| `RecapScreen` | `RecapHubScreen` |
| `CommunityChallengesScreen` | `SocialScreen` (challenges tab) |
| `CreateTribeScreen` | Inline dialog in `AllTribesScreen` |
