# Companion Engine — Replace Tutorials with Archetype-Aligned AI Mentor

**Date:** 2026-05-21
**Status:** Approved Design

---

## 1. Overview

Replace the existing tutorial overlay system (18 static `TutorialStep` overlays, `TutorialNotifier`, `TutorialOverlay` widget) with a **Companion Engine**: an AI-powered, archetype-aligned mentor that delivers contextual guidance through Groq-generated messages. The companion appears at key moments (first feature use, milestones, struggle, feature unlocks) and can be summoned by the user.

---

## 2. Architecture

```
CompanionEngine (Riverpod Notifier)
├── TriggerManager     — listens to existing providers, emits CompanionEvent
├── PersonaEngine      — maps archetype → persona config (name, tone, avatar, system prompt)
├── GenEngine          — calls Groq Cloud Function with event + persona + context
├── CompanionRepository — persistence (visit tracking, dismissals, cooldown)
└── Presentation       — resolves mode: overlay | panel | inlineCard
```

### Key Design Decisions

- **No new event bus.** `TriggerManager` uses `ref.listen` on existing Riverpod providers (gamification, habits, route changes).
- **Single state source.** `CompanionEngine` manages all state — visibility, mode, current message, persona, cooldown.
- **Groq reuse.** Extends existing `getGroqCoachAdvice` Cloud Function with new prompt templates.
- **Three presentation modes** sharing one state, resolved by event type.

---

## 3. Trigger System

### Event Types

| Event | Source | Mode |
|-------|--------|------|
| `firstFeatureVisit` | Route guard + `CompanionRepository.hasVisited(route)` | Overlay |
| `featureUnlocked` | Gamification provider (level gate) | Overlay |
| `userInitiated` | "Ask Mentor" button tap | Panel |
| `milestoneReached` | Streak/habit completion providers | Inline Card |
| `struggleDetected` | Drift stats (missed days, declining rate) | Inline Card |
| `dailyCheckIn` | `LocalSettingsRepository.lastOpenedDate` | Inline Card |

### Cooldown & Priority

- Max **1 proactive message per session** (excludes user-initiated)
- After dismissal, **10-minute cooldown** before next proactive message
- Daily check-in fires **once per day**
- Priority order: userInitiated > milestoneReached > struggleDetected > dailyCheckIn > firstFeatureVisit > featureUnlocked
- **Rapid trigger coalescing** — only highest-priority pending event fires; others dropped

---

## 4. Persona Engine

### Archetype → Mentor Mapping

| Archetype | Mentor | Tone | Groq System Prompt Prefix |
|-----------|--------|------|--------------------------|
| Athlete | The Coach | Direct, energetic, challenge-oriented | "You are a no-nonsense coach who pushes the user to be their best..." |
| Scholar | The Sage | Thoughtful, curious, pattern-focused | "You are a wise sage who helps the user discover patterns..." |
| Creator | The Muse | Inspiring, playful, possibility-driven | "You are a creative muse who awakens the user's imagination..." |
| Stoic | The Philosopher | Calm, reflective, virtue-centered | "You are a stoic philosopher who guides with quiet wisdom..." |
| Zealot | The Visionary | Intense, purpose-driven, transformative | "You are a visionary who reminds the user of their higher calling..." |

### Persona Config (UI)

- `name`: String (e.g., "The Coach")
- `avatarAsset`: Rive/PNG asset path per archetype
- `accentColor`: Color derived from archetype theme
- `systemPrompt`: String template for Groq
- `greetingTemplate`: String per event type (e.g., "Ready for today's {habitCount} reps?")

---

## 5. Content Generation

### Groq Cloud Function Payload

```dart
{
  "eventType": "milestoneReached" | "struggleDetected" | ...,
  "archetype": "athlete",
  "userContext": {
    "currentStreak": 7,
    "habitsCompleted": 42,
    "featureRoute": "/world-map",
    "missedDays": 0,
    "totalHabits": 5,
    "level": 3
  },
  "conversationHistory": [
    {"role": "assistant", "content": "..."}
  ]
}
```

### Prompt Strategy

Two-part system prompt sent to Groq:
1. **Persona system prompt** — archetype voice (set once per session)
2. **Event instruction** — per-request context (e.g., "User just hit a 7-day streak. Congratulate them through the [archetype] lens.")

### Response Contract

```dart
class CompanionMessage {
  final String message;          // 1-3 sentences
  final String tone;             // "energetic" | "reflective" | "playful" | ...
  final List<String>? suggestions; // optional follow-up actions
}
```

### Fallbacks

- **Offline / Groq failure:** Built-in fallback strings per (archetype, eventType) compiled into the app
- **Latency tolerance:** First-visit messages pre-generated and cached; real-time for milestones/struggles only
- **No blocking:** Companion simply doesn't appear on failure — no error UI

---

## 6. Presentation Modes

### Overlay Mode
- Replaces existing `TutorialOverlay` widget
- Same mechanics: `GlobalKey` targeting, scroll-to-element, frosted glass card
- Content: mentor avatar + name + Groq-generated message
- Actions: "Got It" (dismisses, marks visited), "Skip" (marks visited)
- Used for: `firstFeatureVisit`, `featureUnlocked`

### Panel Mode
- Slide-up bottom sheet
- Lightweight chat UI: mentor avatar + message bubbles
- User can type follow-up questions or tap suggested responses
- Used for: `userInitiated` (and follow-up conversations from inline cards)
- `CompanionEngine` tracks last N exchanges in memory (volatile)
- Access point: a floating "Ask Mentor" button in the app shell (bottom nav bar area), visible on all main screens. Also accessible via inline card tap and Settings.

### Inline Card Mode
- Compact card rendered in-context (e.g., top of Timeline, World Map)
- Mentor avatar + 1-2 sentence message
- Auto-dismisses after 5 seconds, or on tap
- Tap opens Panel mode for follow-up
- Used for: `milestoneReached`, `struggleDetected`, `dailyCheckIn`

### Mode Resolution

```dart
CompanionMode resolveMode(CompanionEvent event) => switch (event.type) {
  CompanionEventType.firstFeatureVisit => CompanionMode.overlay,
  CompanionEventType.featureUnlocked   => CompanionMode.overlay,
  CompanionEventType.userInitiated     => CompanionMode.panel,
  CompanionEventType.milestoneReached  => CompanionMode.inlineCard,
  CompanionEventType.struggleDetected  => CompanionMode.inlineCard,
  CompanionEventType.dailyCheckIn     => CompanionMode.inlineCard,
};
```

---

## 7. State Management

### Riverpod Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `companionEngineProvider` | `Notifier<CompanionState>` | Core engine — visibility, message, mode, cooldown |
| `companionTriggerProvider` | Provider | Init listener, feeds events to engine |
| `companionPersonaProvider` | Provider<PersonaConfig> | Derived — maps user archetype to persona config |
| `companionVisibilityProvider` | Provider<CompanionState?> | UI-facing derived state |

### CompanionState

```dart
class CompanionState {
  final CompanionMessage? message;
  final CompanionMode mode;
  final CompanionEventType? eventType;
  final GlobalKey? targetKey;        // only for overlay mode
  final bool visible;
  final String? personaName;
  final String? personaAvatar;
}
```

---

## 8. Persistence

`CompanionRepository` (replaces tutorial keys in `LocalSettingsRepository`):

| Key | Type | Purpose |
|-----|------|---------|
| `companion_visited_{route}` | `bool` | Per-screen visit tracking |
| `companion_dismissed_{messageId}` | `bool` | Avoid repeats |
| `companion_last_checkin` | `String` (date) | Daily check-in gate |
| `companion_messages_seen` | `int` | Counter for cooldown tuning |

**Migration:** On first launch after update, read all existing `tutorial_{id}` keys and write equivalent `companion_visited_{route}` entries.

---

## 9. Removal of Existing Tutorial System

Files to delete:
- `lib/features/tutorial/presentation/providers/tutorial_provider.dart`
- `lib/features/tutorial/presentation/widgets/tutorial_overlay.dart`
- Entire `lib/features/tutorial/` directory

Keys to remove from `LocalSettingsRepository`:
- `tutorialsEnabled`
- `tutorialAutoShow`
- `tutorial_{id}` (all per-step keys)

References to remove:
- `TutorialStep` enum in all screens
- `_checkTutorial()` calls in screen `initState`s
- Toggle "Show Tutorials" in Settings screen → replace with "Show Companion" toggle (enabled by default, disables proactive messages — "Ask Mentor" panel still accessible)

---

## 10. Error Handling & Edge Cases

| Scenario | Behavior |
|----------|----------|
| Groq API down | Fallback to compiled strings, no companion visible |
| User offline | Cache first-visit messages, fallback for proactive events |
| Rapid consecutive triggers | Cooldown coalescing — one per session |
| User dismisses mid-overlay | Mark visited — won't retrigger |
| Archetype changes | PersonaEngine re-evaluates on next trigger |
| First launch after update | Migrate old tutorial keys to companion visited keys |

---

## 11. Groq API Health Integration Test

### Dart Test (`test/features/ai/data/datasources/groq_ai_service_integration_test.dart`)

```dart
@Tags(['integration'])
void main() {
  late GroqAiService service;

  setUpAll(() async {
    // Real Firebase init
    service = GroqAiService();
  });

  group('Groq API Health', () {
    test('getCoachAdvice returns valid response for each archetype', () async {});
    test('getCoachAdvice produces archetype-distinct tones', () async {});
    test('getCoachAdvice handles missing context gracefully', () async {});
    test('fallback messages are used when API unavailable', () async {});
  });
}
```

### Cloud Function Test (`functions/src/tests/groq.test.ts`)

- Invokes `getGroqCoachAdvice` with a mock request
- Validates response JSON structure
- Verifies archetype-specific system prompt produces correct tone
- Tests with minimal user context to verify robustness

### CI

- Weekly GitHub Actions cron: `flutter test --tags=integration`
- Tagged with `integration` — excluded from default `flutter test`

---

## 12. Testing Strategy

| Layer | Type | Scope |
|-------|------|-------|
| TriggerManager | Unit | Priority, cooldown, dedup logic |
| PersonaEngine | Unit | Archetype → persona mapping |
| CompanionRepository | Unit | Persistence read/write, migration |
| Overlay widget | Widget test | Renders with mock state, buttons work |
| Panel widget | Widget test | Chat UI renders, input works |
| Inline card widget | Widget test | Auto-dismiss timer, tap opens panel |
| Trigger → Engine → UI | Integration | Full pipeline with mock Groq |
| Groq API | Integration | Real Cloud Function → Groq |

---

## 13. Migration Path

1. Add `CompanionEngine` providers alongside existing tutorial providers (no deletion yet)
2. Implement `TriggerManager` to match current tutorial triggers — both systems fire in parallel
3. Implement `PersonaEngine`, `GenEngine`, presentation widgets
4. Replace screen `_checkTutorial()` calls with `companionEngineProvider` triggers
5. Verify feature parity — every tutorial point has a companion equivalent
6. Delete tutorial system files and keys
7. Run Groq API integration test
8. Remove tutorial toggle from Settings, add companion preference
