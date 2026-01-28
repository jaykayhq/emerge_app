# Application Screen Registry & Logic Map

This document provides a comprehensive overview of all screens in the application, categorized by functionality. Each entry specifies the screen's purpose, the file responsible for its rendering, and the primary logic controller (Provider/Notifier) where applicable.

## 🔐 Authentication

User identification and access control.

| Screen | File Path | Logic Controller |
| :--- | :--- | :--- |
| **Login** | `lib/features/auth/presentation/screens/login_screen.dart` | `auth_providers.dart` |
| **Signup** | `lib/features/auth/presentation/screens/signup_screen.dart` | `auth_providers.dart` |

## 🚀 Onboarding

Initial user setup, archetype selection, and identity integration.

| Screen | File Path | Logic Controller |
| :--- | :--- | :--- |
| **Welcome** | `lib/features/onboarding/presentation/screens/welcome_screen.dart` | `onboarding_state_notifier.dart` |
| **Archetype Selection** | `lib/features/onboarding/presentation/screens/onboarding_archetype_screen.dart` | `onboarding_state_notifier.dart` |
| **Integration Why** | `lib/features/onboarding/presentation/screens/integrate_why_screen.dart` | `onboarding_state_notifier.dart` |
| **Identity Attributes** | `lib/features/onboarding/presentation/screens/identity_attributes_screen.dart` | `onboarding_state_notifier.dart` |
| **Habit Anchors** | `lib/features/onboarding/presentation/screens/habit_anchors_screen.dart` | `onboarding_state_notifier.dart` |
| **Habit Stacking** | `lib/features/onboarding/presentation/screens/habit_stacking_screen.dart` | `onboarding_state_notifier.dart` |
| **Main Onboarding Container** | `lib/features/onboarding/presentation/screens/onboarding_screen.dart` | `onboarding_state_notifier.dart` |

## 🏠 Home

Main landing and navigation hub.

| Screen | File Path | Logic Controller |
| :--- | :--- | :--- |
| **Home** | `lib/features/home/presentation/screens/home_screen.dart` | *Navigation Shell / GoRouter* |
| **Gatekeeper** | `lib/features/home/presentation/screens/gatekeeper_screen.dart` | *Auth State* |
| **Two Minute Timer** | `lib/features/home/presentation/screens/two_minute_timer_screen.dart` | *Local/Timer State* |

## ⚡ Habits

Habit tracking, creation, and dashboard.

| Screen | File Path | Logic Controller |
| :--- | :--- | :--- |
| **Habit Dashboard** | `lib/features/home/presentation/screens/home_screen.dart` | `habit_providers.dart` + `user_stats_providers.dart` |
| **Create Habit** | `lib/features/habits/presentation/screens/advanced_create_habit_screen.dart` | `habit_providers.dart` |
| **Habit Builder** | `lib/features/habits/presentation/screens/habit_builder_screen.dart` | `habit_providers.dart` |
| **Scorecard** | `lib/features/habits/presentation/screens/habits_scorecard_screen.dart` | `user_stats_providers.dart` |
| **Environment Priming** | `lib/features/habits/presentation/screens/environment_priming_screen.dart` | `habit_providers.dart` |

## 🎮 Gamification

Identity evolution, world building, and avatar customization.

| Screen | File Path | Logic Controller |
| :--- | :--- | :--- |
| **World View** | `lib/features/gamification/presentation/screens/world_screen.dart` | `gamification_providers.dart` |
| **Growing World** | `lib/features/gamification/presentation/screens/growing_world_screen.dart` | `gamification_providers.dart` |
| **Evolving Forest** | `lib/features/gamification/presentation/screens/evolving_forest_screen.dart` | `gamification_providers.dart` |
| **Leveling** | `lib/features/gamification/presentation/screens/leveling_screen.dart` | `user_stats_providers.dart` |
| **User Profile** | `lib/features/gamification/presentation/screens/user_profile_screen.dart` | `user_stats_providers.dart` |
| **Avatar Customization** | `lib/features/gamification/presentation/screens/avatar_customization_screen.dart` | *To be updated with Rive* |
| **Enhanced Customization** | `lib/features/gamification/presentation/screens/enhanced_avatar_customization_screen.dart` | *To be updated with Rive* |
| **Land Expansion** | `lib/features/gamification/presentation/screens/land_expansion_screen.dart` | `gamification_providers.dart` |
| **Building Placement** | `lib/features/gamification/presentation/screens/building_placement_screen.dart` | `gamification_providers.dart` |
| **Creator Blueprints** | `lib/features/gamification/presentation/screens/creator_blueprints_screen.dart` | `blueprint_activation_provider.dart` |
| **Weekly Recap** | `lib/features/gamification/presentation/screens/weekly_recap_screen.dart` | `user_stats_providers.dart` |
| **Daily Report** | `lib/features/gamification/presentation/screens/daily_report_screen.dart` | `user_stats_providers.dart` |
| **Cinematic Recap** | `lib/features/gamification/presentation/screens/cinematic_recap_screen.dart` | *Animation Controller* |
| **Temptation Bundling** | `lib/features/gamification/presentation/screens/temptation_bundling_screen.dart` | *Gamification Logic* |

## 🤝 Social

Community interaction and accountability.

| Screen | File Path | Logic Controller |
| :--- | :--- | :--- |
| **Tribes** | `lib/features/social/presentation/screens/tribes_screen.dart` | `tribes_provider.dart` |
| **Create Tribe** | `lib/features/social/presentation/screens/create_tribe_screen.dart` | `tribes_provider.dart` |
| **Challenges** | `lib/features/social/presentation/screens/challenges_screen.dart` | `challenge_provider.dart` |
| **Challenge Detail** | `lib/features/social/presentation/screens/challenge_detail_screen.dart` | `challenge_provider.dart` |
| **Community Challenges** | `lib/features/social/presentation/screens/community_challenges_screen.dart` | `challenge_provider.dart` |
| **Accountability** | `lib/features/social/presentation/screens/accountability_screen.dart` | `tribes_provider.dart` |

## ⚙️ Settings & System

Configuration and app preferences.

| Screen | File Path | Logic Controller |
| :--- | :--- | :--- |
| **Settings** | `lib/features/settings/presentation/screens/settings_screen.dart` | *Global/User State* |
| **Notifications** | `lib/features/settings/presentation/screens/notification_settings_screen.dart` | *Notification Service* |

## 🧠 Insights & AI

Reflections and data analysis.

| Screen | File Path | Logic Controller |
| :--- | :--- | :--- |
| **Reflections** | `lib/features/insights/presentation/screens/reflections_screen.dart` | *Insights Logic* |
| **Recap** | `lib/features/insights/presentation/screens/recap_screen.dart` | *Insights Logic* |
| **AI Reflections** | `lib/features/ai/presentation/screens/ai_reflections_screen.dart` | *AI Service* |
| **Goldilocks** | `lib/features/ai/presentation/screens/goldilocks_screen.dart` | *AI Service* |

## 💰 Monetization

Premium features and subscriptions.

| Screen | File Path | Logic Controller |
| :--- | :--- | :--- |
| **Paywall** | `lib/features/monetization/presentation/screens/paywall_screen.dart` | *IAP/Monetization Logic* |
| **Habit Contract** | `lib/features/monetization/presentation/screens/habit_contract_screen.dart` | *Monetization Logic* |
