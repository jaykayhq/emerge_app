# Health Connect & Screen Time Integration Design

**Date:** 2026-06-09
**App:** Emerge — Identity-First Habit Formation
**Platform:** Android (Health Connect + UsageStats)

---

## 1. Goal

Add Google Health Connect and Android UsageStats (screen time) integration to Emerge, enabling auto-completion of habits from real-world data. The existing data model is pre-wired (`HabitIntegrationType`, `healthKitConnected`/`screenTimeConnected` flags) — this implementation brings those fields to life.

## 2. Architecture (Approach B — Clean Architecture Service Layer)

```
Presentation (Habit Card / Settings)
    ↕ Providers (Riverpod)
Domain (HealthRepository / ScreenTimeRepository interfaces)
    ↕
Data (HealthConnectDataSource / UsageStatsDataSource)
    ↓
Android Native (Health Connect Client via health_connect / UsageStats via MethodChannel)
```

### Files to create

```
lib/features/health/
├── data/
│   ├── services/
│   │   ├── health_connect_service.dart     # Health Connect API bridge (steps)
│   │   └── screen_time_service.dart        # UsageStats API bridge
│   └── repositories/
│       └── health_repository.dart          # Coordinates health + habit completion
├── domain/
│   ├── health_repository.dart              # Abstract interface
│   └── screen_time_repository.dart         # Abstract interface
└── presentation/
    ├── providers/
    │   ├── health_connection_provider.dart  # Connection state + permissions
    │   └── health_sync_provider.dart        # Auto-complete trigger
    └── widgets/
        ├── health_connect_tile.dart         # Settings integration toggle
        └── screen_time_tile.dart            # Settings integration toggle
```

### No schema changes needed

The following already exist in the data model:

| Field | Location | Purpose |
|-------|----------|---------|
| `healthKitConnected` | `UserSettings` | Global health connection flag |
| `screenTimeConnected` | `UserSettings` | Global screen time flag |
| `HabitIntegrationType.healthSteps` | `Habit` | Links habit to step count metric |
| `HabitIntegrationType.screenTimeLimit` | `Habit` | Links habit to screen time metric |
| `Habit.integrationTarget` | `Habit` | Target value for auto-completion |

## 3. Settings UI

New section in `Integrations & Data` (currently has only "Export Data"):

- **Connect Health Data** — launches Health Connect permission flow (native permission UI)
  - Status: Not Connected / Connected
  - Permissions: Steps, Active Minutes
- **Connect Screen Time** — opens Android Usage Settings for permission grant
  - Status: Not Connected / Connected
- **Auto-Complete Habits** — toggle in UserSettings

## 4. Habit Editor

New fields in habit creation/editor screen:

- Integration Type: None / Health Steps / Screen Time Limit
- Integration Target: numeric input (steps or minutes)
- Connection status indicator: green check / gray warning

## 5. Auto-Complete Flow

1. Poll Health Connect / UsageStats every 60s (foreground only)
2. Read today's step count / screen-on time
3. Match against habits with matching `integrationType` + `integrationTarget`
4. If target reached AND habit not completed today → `GameLoopEngine.processHabitCompletion()`
5. User sees: snackbar notification + habit marked complete with real-data context

## 6. Dependencies

- `health_connect` (Google official Health Connect package) — step data, permissions
- Custom `MethodChannel` for Android UsageStats API
- No new Firebase/Firestore changes needed

## 7. Dependencies to add to pubspec.yaml

```yaml
health_connect: ^1.0.0  # Google Health Connect SDK
```

## 8. Out of Scope (for this phase)

- iOS HealthKit (future)
- Background health sync via WorkManager (future enhancement)
- Additional health metrics (heart rate, sleep, nutrition)
- GDPR/health data privacy consent beyond platform permissions
