# Development Conventions

**Analysis Date:** 2026-03-30 (Updated)

## General Principles

- **Identity-First Design:** All features must reinforce the user's chosen identity (archetype).
- **Behavioral Mechanics:** Implementation should follow habit loop principles (Cue, Craving, Response, Reward).
- **No Mock Data:** In production code, always wire to real providers/data sources. Handle empty/loading states gracefully.

## Coding Standards (Dart/Flutter)

### 1. State Management (Riverpod)
- **Prefer Code Generation:** Use `@riverpod` annotation over manual provider definitions.
- **Provider Scoping:** Keep providers local to features unless they are truly global (e.g., auth, settings).
- **Asynchrony:** Use `AsyncValue` for UI-bound asynchronous data.

### 2. UI Development
- **Responsive Layouts:** Use `Flex`, `LayoutBuilder`, and `FractionallySizedBox`. Avoid hardcoded pixel values.
- **Themes:** Always use `Theme.of(context)` and `context.emergeTheme` (extension). Never hardcode colors.
- **Loading:** Use shimmer/skeleton loaders matching the target layout instead of generic spinners.

### 3. Data Modeling
- **Immutable Models:** Use `Freezed` for entities and DTOs.
- **JSON Serialization:** Use `json_serializable` for all objects interacting with Firestore or APIs.
- **Null Safety:** Strict enforcement. Use `?` only when a field is truly optional.

### 4. Code Style
- **Linter:** Follow `flutter_lints` standards.
- **Naming:**
  - Classes: PascalCase.
  - Variables/Methods: camelCase.
  - Files: snake_case.
- **Imports:** Prefer package imports over relative imports.

## Git & Workflow

- **Branching:** Feature-based branching (`feature/name` or `fix/issue`).
- **Commits:** Clear, descriptive messages. (e.g., `feat(habits): add 2-minute rule timer`).
- **GSD Integration:** Use GSD workflows for planning, implementation, and verification.

## Backend (Firebase)

- **Security Rules:** Every Firestore collection must have restrictive rules in `firestore.rules`.
- **Functions:** Use `v2` Cloud Functions. Heavy transformations or batch updates must happen on the server.
- **Migrations:** Use structured seed scripts in `functions/src/seed.ts`.
