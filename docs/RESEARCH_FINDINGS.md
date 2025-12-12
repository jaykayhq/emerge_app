# Research Findings & Implementation Plan

This document outlines the research conducted on top-tier open-source Flutter repositories and extracts specific code patterns and logic to implement the "Emerge" habit tracking application.

## 1. Top Repository References

### Core Habit Tracking & Visualization
**Repository:** `OmarZen/habit-tracker` (and its Riverpod variant)
*   **Relevance:** Excellent implementation of the core "Habit" data model and the "Heatmap" visualization which is crucial for the "Streak" feature in Emerge.
*   **Key Features to Adapt:**
    *   **Heatmap Calendar:** Uses `flutter_heatmap_calendar` to visualize consistency (The "Seinfeld Strategy").
    *   **Local Persistence:** Uses Hive for offline-first capability (we will adapt this to cache Firestore data).
    *   **Simple Completion Logic:** Boolean toggle for daily completion.

### Architecture & Scalability
**Repository:** `maxonflutter/Flutter-Clean-Architecture-With-Firebase`
*   **Relevance:** Directly aligns with the required tech stack: Flutter, Firebase, Bloc, and Clean Architecture.
*   **Key Features to Adapt:**
    *   **Folder Structure:** Separation of `domain`, `data`, and `presentation` layers.
    *   **Bloc Implementation:** Clear separation of events and states for complex UI logic.
    *   **Repository Pattern:** Abstracts Firebase calls, making testing and caching easier.

### Gamification UI
**Repository:** `MobileVerse/Gamify-Flutter-App`
*   **Relevance:** Provides UI patterns for "Game-like" interfaces.
*   **Key Features to Adapt:**
    *   **Animated Progress Bars:** For XP and Leveling.
    *   **Card Designs:** For "Quests" or "Challenges".

---

## 2. Implementation Plans for Key Features

### Feature A: The "Streak" & Heatmap Logic
*   **Concept:** Visualizing consistency to reward the user (Atomic Habits: "Make it Satisfying").
*   **Implementation:**
    *   **Data Structure:** A `Habit` document in Firestore contains a map `completionDates: { "2023-10-27": true }`.
    *   **Logic:** A Cloud Function or local logic calculates the "current streak" by iterating backwards from today.
    *   **Visualization:** Use `flutter_heatmap_calendar`.
    *   **Recovery:** Implement "Streak Freeze" logic if the user has a "Freeze" item in their inventory.

### Feature B: Gamification (Identity Votes)
*   **Concept:** Instead of generic XP, users gain "Votes" for their identity (e.g., "Athlete", "Writer").
*   **Implementation:**
    *   **Calculation:** Each habit completion = +1 Vote for the tagged Identity.
    *   **Leveling:** $Level = \sqrt{TotalVotes / 100}$.
    *   **State Management:** `GamificationBloc` listens to `HabitLogged` events.
    *   **Persistence:** Update `userProfile.identities['athlete'].votes` atomically in Firestore.

### Feature C: Social Accountability (Tribes)
*   **Concept:** Users join "Tribes" to share progress.
*   **Implementation:**
    *   **Data Model:** `Tribe` collection with `memberIds`. `FeedPosts` subcollection within a Tribe.
    *   **Privacy:** Security rules ensure only members can read a Tribe's feed.
    *   **Notifications:** Cloud Functions trigger FCM notifications when a tribe member completes a "Habit Contract".

### Feature D: Dynamic Habit Stacking (Timeline)
*   **Concept:** A timeline view of habits anchored to specific times of day.
*   **Implementation:**
    *   **UI:** A custom `CustomScrollView` with `Slivers` for different time blocks (Morning, Afternoon, Evening).
    *   **Logic:** Sort habits by `approximateTime` locally.
    *   **Interactivity:** Drag-and-drop reordering to adjust the "Stack".

---

## 3. Technology Stack Recommendation

*   **Framework:** Flutter (Mobile, Web support).
*   **Backend:** Firebase (Auth, Firestore, Cloud Functions, Storage).
*   **State Management:** **Bloc / Cubit** (Strict separation of concerns).
*   **Dependency Injection:** `get_it` + `injectable`.
*   **Local Storage:** `hive` (for offline caching).
*   **Navigation:** `go_router` (Deep linking support).
*   **Monetization:** `revenue_cat` (Subscriptions), `google_mobile_ads` (AdMob).
