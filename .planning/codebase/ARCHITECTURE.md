# Architecture Overview

**Analysis Date:** 2026-03-30 (Updated)

## Architectural Pattern: Feature-First Clean Architecture

The codebase follows a modular, feature-oriented structure combined with Clean Architecture layers within each feature. This approach ensures scalability while maintaining clear separation of concerns.

### 1. Layers (Inside `lib/features/`)

- **Domain Layer:** Pure Dart logic. Contains Entities, Repositories (interfaces), and Value Objects. No dependencies on Flutter or data sources.
- **Data Layer:** Implementation of repositories. Handles data fetching (Firestore, Hive, APIs), Data Transfer Objects (DTOs), and mappers.
- **Presentation Layer:** Flutter UI logic. Contains Screens, Widgets, and Riverpod Providers (Controllers).

### 2. Global Core (Inside `lib/core/`)

Shared infrastructure used across all features:
- **router:** Declarative routing using `go_router`.
- **theme:** Centralized branding, light/dark mode adaptation, and archetype-specific themes.
- **init:** Application bootstrap logic (`initApp`).
- **services:** Cross-cutting services like Notifications, Sound, and Analytics.
- **presentation/widgets:** Shared UI components following the "Cosmic" design system.

## State Management: Riverpod (v2/v3 Logic)

The app leverages `flutter_riverpod` with code generation (`riverpod_generator`).
- **Providers:** Used for dependency injection and state observation.
- **Controllers:** Presentation-layer logic that bridges UI and Domain layers.
- **Streams:** Heavy use of `StreamProvider` for real-time Firestore synchronization.

## Routing: GoRouter

- Centralized route configuration in `lib/core/router/router.dart`.
- Supports nested navigation (ShellRoute) for bottom navigation bars.
- Integrates with Auth state for redirection logic (Login -> Home).

## Backend Integration: Firebase First

- **Firestore-Centric:** Most application state is persisted in Firestore.
- **Functions-Driven:** Heavy or sensitive logic is delegated to Firebase Cloud Functions (Gen 2).
- **Identity-First:** User identity is the central pivot for data organization and archetypes.

## Visual Engine: Flame & Rive

- The "World Map" and "Avatar" systems use the Flame engine for performance-critical 2D rendering.
- Rive is used for complex, interactive vector animations (Hero/Identity metrics).
