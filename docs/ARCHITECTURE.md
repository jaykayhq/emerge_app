# Architecture & Navigation

This document defines the technical architecture and the user navigation flow for the Emerge application, strictly adhering to the "Atomic Architecture" blueprint.

## 1. System Architecture

We will follow **Clean Architecture** principles to ensure scalability, testability, and maintainability.

### High-Level Diagram

```mermaid
graph TD
    User[User UI] -->|Events| Bloc[Presentation Layer (Bloc)]
    Bloc -->|States| User
    Bloc -->|Use Cases| Domain[Domain Layer (Use Cases)]
    Domain -->|Repository Interface| Data[Data Layer (Repository Impl)]
    Data -->|DTOs| Remote[Firebase Cloud Firestore]
    Data -->|DTOs| Local[Hive (Offline First)]
    Data -->|DTOs| AI[AI Service (Gemini/Local)]
```

### Folder Structure

```text
lib/
├── core/                   # Global utilities, extensions, constants
│   ├── config/             # Firebase options, env vars
│   ├── di/                 # Dependency Injection setup
│   ├── error/              # Failure classes
│   └── theme/              # AppTheme (Spline Sans)
├── features/               # Feature-based modular structure
│   ├── auth/               # Authentication & Identity
│   ├── habits/             # Core Habit Logic
│   │   ├── data/           # HabitNodeDTO, Hive Adapters
│   │   ├── domain/         # Entities: HabitNode, HabitStack
│   │   └── presentation/   # ScorecardBloc, StackBuilderBloc
│   ├── gamification/       # Identity Votes, Streaks
│   ├── social/             # Tribes, Habit Contracts
│   └── monetization/       # Paywall, Ads logic
├── shared/                 # Reusable widgets (Buttons, Input fields)
└── main.dart               # Entry point
```

---

## 2. Core Modules & Data Structures

### A. The Habits Scorecard (The Cue)
*   **Concept:** An audit log of daily behaviors.
*   **Data Structure:** `HabitNode`
    *   `id`: String
    *   `description`: String
    *   `impact`: Enum (`positive`, `negative`, `neutral`)
    *   `approximateTime`: TimeOfDay
    *   `locationCue`: String
*   **UX:** `ReorderableListView` for chronological sorting.
*   **Logic:** "Pointing-and-Calling" modal for negative habits.

### B. Implementation Intentions Engine
*   **Concept:** Strict validation for habit creation.
*   **Formula:** `I will [BEHAVIOR] at [TIME] in [LOCATION]`.
*   **Validation:** "Save" button disabled until all 3 fields are filled.

### C. Habit Stacking Logic
*   **Concept:** Linking a new habit to an existing "Anchor".
*   **Structure:** Linked List or Recursive Model.
    ```json
    {
      "stack_id": "morning_routine",
      "sequence": [
        { "type": "anchor", "habit_id": "coffee_pour" },
        { "type": "new_habit", "habit_id": "meditate_1min" }
      ]
    }
    ```
*   **Notification:** Triggered by the *Anchor's* typical time.

### D. Temptation Bundling (The "Digital Locker")
*   **Concept:** Gating a "Want" (e.g., YouTube) behind a "Need".
*   **Mechanism:**
    *   User sets a "Reward Link" (URL).
    *   Button is `disabled` (Grey).
    *   Upon `HabitCompleted` event, Button becomes `enabled` (Gold).

### E. Gamification: Identity Votes (The Reward)
*   **Concept:** Shifting focus from "XP" to "Identity Evidence".
*   **Metric:** "Votes" per Identity (e.g., +1 Vote for 'Runner').
*   **Visualization:** Chart showing distribution of votes across identities.

### F. Social: Habit Contracts
*   **Concept:** Social accountability with consequences.
*   **Logic:**
    *   User signs a digital contract (signature pad).
    *   Cloud Function monitors daily status.
    *   **Failure:** Triggers "Snitch Email" to the partner automatically.

---

## 3. Navigation & User Flow Map

### Phase 1: Onboarding (The Setup)
*   **Entry:** `welcome_to_emerge`
*   **Identity Shaping:** `select_your_archetype` -> `map_identity_attributes` -> `integrate_your_'why'`
*   **Habit Setup (Scorecard):** `creator_blueprints` -> `dashboard__timeline_of_cues` (Initial empty state)

### Phase 2: The Core Loop (Daily Usage)
*   **Main Dashboard:** `dashboard__timeline_of_cues`
    *   **View:** Chronological Timeline (Morning -> Night).
    *   **Action:** Tap to "Cast Vote" (Complete).
    *   **Action:** Long press to Edit/Stack.
*   **Creation Flow:** FAB -> `build_your_habit_stacks`
    *   **Step 1:** Select Anchor (from Scorecard).
    *   **Step 2:** Define New Habit (Intention Engine).
    *   **Step 3:** Temptation Bundle (Optional).

### Phase 3: Review & Optimize
*   **Analytics:** `cinematic_progress_recaps` (Weekly Review).
*   **Integrity Report:** Yearly review screen (What went well? What didn't?).
*   **Social:** `tribes_community` -> `accountability_protocol` (Create Contract).

### Phase 4: Settings
*   **Settings:** `app_settings`
*   **Environment:** `environment_priming_prompts` (Digital Environment Reset).
