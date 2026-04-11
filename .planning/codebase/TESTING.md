# Testing Strategy

**Analysis Date:** 2026-03-30 (Updated)

## Test Architecture

The project follows a standard Flutter testing hierarchy:
- **Unit Tests:** Business logic, models, and purely functional code.
- **Widget Tests:** UI component interactions and state-to-view mapping.
- **Integration Tests:** End-to-end flows on physical devices or emulators.

## Tools & Libraries

- **flutter_test:** Core testing framework.
- **mocktail:** Primary library for mocking dependencies.
- **integration_test:** Official package for E2E testing.

## Directory Structure

Tests are located in the `test/` directory, mirroring the `lib/` structure:
```text
test/
├── core/               # Testing for global services and utils
└── features/           # Feature-specific test suites
    ├── auth/
    ├── habits/
    └── user_stats/     # Example: user_stats_controller_test.dart
```

## Testing Patterns

### 1. Mocking Providers (Riverpod)
When testing widgets or controllers, override providers to provide controlled data:
```dart
final container = ProviderContainer(
  overrides: [
    authRepositoryProvider.overrideWithValue(mockAuthRepository),
  ],
);
```

### 2. Goldens / Visual Regression
(Potential addition: Ensure visual identity is preserved across archetypes).

### 3. CI Integration
- Tests are expected to run before any major deployment or PR merge.
- Coverage goals: Aim for high coverage in `domain` and `presentation` controllers.

## Known Gaps

- **Integration Tests:** Comprehensive E2E coverage for the onboarding -> world map flow is currently a work in progress.
- **Function Tests:** TypeScript logic in `functions/` should ideally have its own `mocha`/`jest` suite (checking for coverage).
