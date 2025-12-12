# AI Development Guidelines (CLAUDE.md)

This document provides specific instructions for AI agents and human developers working on the Emerge codebase. Follow these rules to ensure consistency, quality, and maintainability.

## 1. Do's and Don'ts

### Architecture & State Management
*   **DO** use **Riverpod** for state management (specifically `riverpod_generator` and `flutter_riverpod`).
*   **DO** follow **Clean Architecture**. Logic must flow: UI -> Provider/Notifier -> Use Case -> Repository -> Data Source.
*   **DO NOT** use `GetX` or `Bloc` (legacy).
*   **DO NOT** place business logic inside UI widgets (e.g., `onTap: () { firestore.update(...) }`). Always call a method on the Provider/Notifier.

### UI & Design System
*   **DO** use the `Spline Sans` font family as defined in `app_theme.dart`.
*   **DO** use `Tailwind`-like color naming conventions in the theme (e.g., `background-dark`, `primary-green`) if mapped, but stick to Flutter's `Theme.of(context)` strictly.
*   **DO NOT** hardcode colors or text styles. Use `Theme.of(context).colorScheme` and `Theme.of(context).textTheme`.

### Code Quality & Testing
*   **DO** write unit tests for all **Providers/Notifiers** and **Use Cases**.
*   **DO** use `mocktail` for mocking dependencies in tests.
*   **DO NOT** commit commented-out code.
*   **DO** run `flutter analyze` before finishing a task to ensure no linting errors.

### Firebase & Data
*   **DO** use **DTOs (Data Transfer Objects)** for serializing/deserializing Firestore data in the Data Layer, and map them to clean **Entities** for the Domain layer.
*   **DO NOT** expose Firestore classes (`DocumentSnapshot`) to the UI or Domain layer.

## 2. Specific Implementation Instructions

### Working with Habits
*   When modifying habit logic, remember to update both the local `Hive` cache (for offline support) and the remote `Firestore` document.
*   **Identity Votes:** Remember that every habit completion increments the `votes` counter for the associated identity.

### Working with Gamification
*   Any XP/Vote gain must be validated on the server-side (Cloud Functions) eventually to prevent cheating, even if the UI updates optimistically.

## 3. Command Line Shortcuts
*   **Run App:** `flutter run`
*   **Run Build Runner (for code gen):** `dart run build_runner build --delete-conflicting-outputs`
*   **Run Tests:** `flutter test`
