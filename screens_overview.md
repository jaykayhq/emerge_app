# Application Screens Overview

This document provides a comprehensive list of all screens in the Emerge App, categorized by functionality. Each screen includes the exact file path, purpose, and key dependencies.

## Authentication

- **LoginScreen**
  - File: [`lib/features/auth/presentation/screens/login_screen.dart`](lib/features/auth/presentation/screens/login_screen.dart:12)
  - Purpose: Allows users to log in to the application
  - Dependencies: auth_providers, Firebase Auth

- **SignUpScreen**
  - File: [`lib/features/auth/presentation/screens/signup_screen.dart`](lib/features/auth/presentation/screens/signup_screen.dart:15)
  - Purpose: Allows new users to create an account
  - Dependencies: auth_providers, Firebase Auth

## Onboarding

- **WelcomeScreen**
  - File: [`lib/features/onboarding/presentation/screens/welcome_screen.dart`](lib/features/onboarding/presentation/screens/welcome_screen.dart:7)
  - Purpose: Initial welcome screen for new users
  - Dependencies: onboarding_provider

- **OnboardingScreen**
  - File: [`lib/features/onboarding/presentation/screens/onboarding_screen.dart`](lib/features/onboarding/presentation/screens/onboarding_screen.dart:9)
  - Purpose: Main onboarding flow screen
  - Dependencies: onboarding_provider

- **OnboardingArchetypeScreen**
  - File: [`lib/features/onboarding/presentation/screens/onboarding_archetype_screen.dart`](lib/features/onboarding/presentation/screens/onboarding_archetype_screen.dart:11)
  - Purpose: Select user archetype during onboarding
  - Dependencies: onboarding_provider

- **IdentityAttributesScreen**
  - File: [`lib/features/onboarding/presentation/screens/identity_attributes_screen.dart`](lib/features/onboarding/presentation/screens/identity_attributes_screen.dart:9)
  - Purpose: Define identity attributes
  - Dependencies: onboarding_provider

- **IntegrateWhyScreen**
  - File: [`lib/features/onboarding/presentation/screens/integrate_why_screen.dart`](lib/features/onboarding/presentation/screens/integrate_why_screen.dart:9)
  - Purpose: Explain why integration is important
  - Dependencies: onboarding_provider

- **HabitAnchorsScreen**
  - File: [`lib/features/onboarding/presentation/screens/habit_anchors_screen.dart`](lib/features/onboarding/presentation/screens/habit_anchors_screen.dart:9)
  - Purpose: Set habit anchors
  - Dependencies: onboarding_provider

- **HabitStackingScreen**
  - File: [`lib/features/onboarding/presentation/screens/habit_stacking_screen.dart`](lib/features/onboarding/presentation/screens/habit_stacking_screen.dart:10)
  - Purpose: Habit stacking setup
  - Dependencies: onboarding_provider

## Dashboard/Home

- **HomeScreen**
  - File: [`lib/features/home/presentation/screens/home_screen.dart`](lib/features/home/presentation/screens/home_screen.dart:18)
  - Purpose: Main dashboard showing today's habits and world view
  - Dependencies: habitsProvider, userStatsStreamProvider, soundServiceProvider

- **GatekeeperScreen**
  - File: [`lib/features/home/presentation/screens/gatekeeper_screen.dart`](lib/features/home/presentation/screens/gatekeeper_screen.dart:7)
  - Purpose: Gatekeeper tool for habit formation
  - Dependencies: None specific

- **TwoMinuteTimerScreen**
  - File: [`lib/features/home/presentation/screens/two_minute_timer_screen.dart`](lib/features/home/presentation/screens/two_minute_timer_screen.dart:9)
  - Purpose: 2-minute rule timer
  - Dependencies: None specific

## Habits Management

- **CreateHabitScreen**
  - File: [`lib/features/habits/presentation/screens/create_habit_screen.dart`](lib/features/habits/presentation/screens/create_habit_screen.dart:13)
  - Purpose: Create a new habit
  - Dependencies: habit_providers

- **AdvancedCreateHabitScreen**
  - File: [`lib/features/habits/presentation/screens/advanced_create_habit_screen.dart`](lib/features/habits/presentation/screens/advanced_create_habit_screen.dart:10)
  - Purpose: Advanced habit creation
  - Dependencies: habit_providers

- **HabitBuilderScreen**
  - File: [`lib/features/habits/presentation/screens/habit_builder_screen.dart`](lib/features/habits/presentation/screens/habit_builder_screen.dart:7)
  - Purpose: Build and customize habits
  - Dependencies: habit_providers

- **EnvironmentPrimingScreen**
  - File: [`lib/features/habits/presentation/screens/environment_priming_screen.dart`](lib/features/habits/presentation/screens/environment_priming_screen.dart:7)
  - Purpose: Prime environment for habits
  - Dependencies: None specific

- **HabitDashboardScreen**
  - File: [`lib/features/habits/presentation/screens/habit_dashboard_screen.dart`](lib/features/habits/presentation/screens/habit_dashboard_screen.dart:20)
  - Purpose: Dashboard for habits
  - Dependencies: habit_providers

- **HabitsScorecardScreen**
  - File: [`lib/features/habits/presentation/screens/habits_scorecard_screen.dart`](lib/features/habits/presentation/screens/habits_scorecard_screen.dart:7)
  - Purpose: Scorecard for habits
  - Dependencies: habit_providers

## Gamification

- **AvatarCustomizationScreen**
  - File: [`lib/features/gamification/presentation/screens/avatar_customization_screen.dart`](lib/features/gamification/presentation/screens/avatar_customization_screen.dart:14)
  - Purpose: Customize user avatar
  - Dependencies: gamification_providers

- **EnhancedAvatarCustomizationScreen**
  - File: [`lib/features/gamification/presentation/screens/enhanced_avatar_customization_screen.dart`](lib/features/gamification/presentation/screens/enhanced_avatar_customization_screen.dart:10)
  - Purpose: Enhanced avatar customization
  - Dependencies: gamification_providers

- **WorldScreen**
  - File: [`lib/features/gamification/presentation/screens/world_screen.dart`](lib/features/gamification/presentation/screens/world_screen.dart:10)
  - Purpose: View the user's world
  - Dependencies: gamification_providers

- **GrowingWorldScreen**
  - File: [`lib/features/gamification/presentation/screens/growing_world_screen.dart`](lib/features/gamification/presentation/screens/growing_world_screen.dart:17)
  - Purpose: Main screen showing the user's evolving world
  - Dependencies: gamification_providers

- **EvolvingForestScreen**
  - File: [`lib/features/gamification/presentation/screens/evolving_forest_screen.dart`](lib/features/gamification/presentation/screens/evolving_forest_screen.dart:14)
  - Purpose: Evolving forest view
  - Dependencies: gamification_providers

- **LandExpansionScreen**
  - File: [`lib/features/gamification/presentation/screens/land_expansion_screen.dart`](lib/features/gamification/presentation/screens/land_expansion_screen.dart:11)
  - Purpose: View and purchase land expansions
  - Dependencies: gamification_providers

- **BuildingPlacementScreen**
  - File: [`lib/features/gamification/presentation/screens/building_placement_screen.dart`](lib/features/gamification/presentation/screens/building_placement_screen.dart:14)
  - Purpose: Place buildings in the world using drag-and-drop
  - Dependencies: gamification_providers

- **LevelingScreen**
  - File: [`lib/features/gamification/presentation/screens/leveling_screen.dart`](lib/features/gamification/presentation/screens/leveling_screen.dart:9)
  - Purpose: Level up screen
  - Dependencies: gamification_providers

- **TemptationBundlingScreen**
  - File: [`lib/features/gamification/presentation/screens/temptation_bundling_screen.dart`](lib/features/gamification/presentation/screens/temptation_bundling_screen.dart:8)
  - Purpose: Temptation bundling
  - Dependencies: gamification_providers

- **UserProfileScreen**
  - File: [`lib/features/gamification/presentation/screens/user_profile_screen.dart`](lib/features/gamification/presentation/screens/user_profile_screen.dart:18)
  - Purpose: User profile view
  - Dependencies: user_stats_providers

- **DailyReportScreen**
  - File: [`lib/features/gamification/presentation/screens/daily_report_screen.dart`](lib/features/gamification/presentation/screens/daily_report_screen.dart:18)
  - Purpose: Daily report
  - Dependencies: gamification_providers

- **WeeklyRecapScreen**
  - File: [`lib/features/gamification/presentation/screens/weekly_recap_screen.dart`](lib/features/gamification/presentation/screens/weekly_recap_screen.dart:11)
  - Purpose: Weekly recap
  - Dependencies: gamification_providers

- **CinematicRecapScreen**
  - File: [`lib/features/gamification/presentation/screens/cinematic_recap_screen.dart`](lib/features/gamification/presentation/screens/cinematic_recap_screen.dart:6)
  - Purpose: Cinematic recap for leveling
  - Dependencies: None specific

- **CreatorBlueprintsScreen**
  - File: [`lib/features/gamification/presentation/screens/creator_blueprints_screen.dart`](lib/features/gamification/presentation/screens/creator_blueprints_screen.dart:17)
  - Purpose: Creator blueprints
  - Dependencies: blueprint_activation_provider

## AI Features

- **AiReflectionsScreen**
  - File: [`lib/features/ai/presentation/screens/ai_reflections_screen.dart`](lib/features/ai/presentation/screens/ai_reflections_screen.dart:9)
  - Purpose: AI-powered reflections
  - Dependencies: ai_providers

- **GoldilocksScreen**
  - File: [`lib/features/ai/presentation/screens/goldilocks_screen.dart`](lib/features/ai/presentation/screens/goldilocks_screen.dart:10)
  - Purpose: Goldilocks principle application
  - Dependencies: ai_providers

## Insights

- **ReflectionsScreen**
  - File: [`lib/features/insights/presentation/screens/reflections_screen.dart`](lib/features/insights/presentation/screens/reflections_screen.dart:9)
  - Purpose: User reflections
  - Dependencies: insights_repository

- **RecapScreen**
  - File: [`lib/features/insights/presentation/screens/recap_screen.dart`](lib/features/insights/presentation/screens/recap_screen.dart:9)
  - Purpose: Recap insights
  - Dependencies: insights_repository

## Monetization

- **PaywallScreen**
  - File: [`lib/features/monetization/presentation/screens/paywall_screen.dart`](lib/features/monetization/presentation/screens/paywall_screen.dart:9)
  - Purpose: Subscription paywall
  - Dependencies: subscription_provider

- **HabitContractScreen**
  - File: [`lib/features/monetization/presentation/screens/habit_contract_screen.dart`](lib/features/monetization/presentation/screens/habit_contract_screen.dart:11)
  - Purpose: Habit contract for monetization
  - Dependencies: habit_contract_repository

## Settings

- **SettingsScreen**
  - File: [`lib/features/settings/presentation/screens/settings_screen.dart`](lib/features/settings/presentation/screens/settings_screen.dart:15)
  - Purpose: Application settings
  - Dependencies: settings_repository

- **NotificationSettingsScreen**
  - File: [`lib/features/settings/presentation/screens/notification_settings_screen.dart`](lib/features/settings/presentation/screens/notification_settings_screen.dart:10)
  - Purpose: Notification settings
  - Dependencies: settings_repository

## Social

- **TribesScreen**
  - File: [`lib/features/social/presentation/screens/tribes_screen.dart`](lib/features/social/presentation/screens/tribes_screen.dart:15)
  - Purpose: Tribes overview
  - Dependencies: tribes_provider

- **CreateTribeScreen**
  - File: [`lib/features/social/presentation/screens/create_tribe_screen.dart`](lib/features/social/presentation/screens/create_tribe_screen.dart:12)
  - Purpose: Create a new tribe
  - Dependencies: tribes_provider

- **ChallengesScreen**
  - File: [`lib/features/social/presentation/screens/challenges_screen.dart`](lib/features/social/presentation/screens/challenges_screen.dart:10)
  - Purpose: View challenges
  - Dependencies: challenge_provider

- **CommunityChallengesScreen**
  - File: [`lib/features/social/presentation/screens/community_challenges_screen.dart`](lib/features/social/presentation/screens/community_challenges_screen.dart:13)
  - Purpose: Community challenges
  - Dependencies: challenge_provider

- **ChallengeDetailScreen**
  - File: [`lib/features/social/presentation/screens/challenge_detail_screen.dart`](lib/features/social/presentation/screens/challenge_detail_screen.dart:13)
  - Purpose: Details of a specific challenge
  - Dependencies: challenge_provider

- **AccountabilityScreen**
  - File: [`lib/features/social/presentation/screens/accountability_screen.dart`](lib/features/social/presentation/screens/accountability_screen.dart:6)
  - Purpose: Accountability features
  - Dependencies: social_repository

## Core

- **SplashScreen**
  - File: [`lib/core/presentation/screens/splash_screen.dart`](lib/core/presentation/screens/splash_screen.dart:12)
  - Purpose: Application splash screen
  - Dependencies: None specific
