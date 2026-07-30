---
kind: error_handling
name: Error Handling — Failure Types, Either Monad, and Centralized UI Error Widgets
category: error_handling
scope:
    - '**'
source_files:
    - lib/core/error/failure.dart
    - lib/core/presentation/widgets/app_error_widget.dart
    - lib/core/deletion/deletion_service.dart
    - lib/core/deletion/delete_account_backend.dart
    - lib/core/drift_repositories/drift_habit_repository.dart
    - lib/core/drift_repositories/drift_challenge_repository.dart
    - lib/core/drift_repositories/drift_leaderboard_repository.dart
    - lib/core/drift_repositories/drift_tribe_repository.dart
    - lib/core/drift_repositories/drift_user_profile_repository.dart
---

The Emerge app uses a layered error-handling strategy that combines functional-style error propagation with centralized UI presentation:

1. **Failure type hierarchy** — `lib/core/error/failure.dart` defines an abstract `Failure` base class (extending `Equatable`) and concrete subclasses: `ServerFailure`, `CacheFailure`, `AuthFailure`, `UnknownFailure`, `HealthFailure`. These represent domain-level errors rather than raw exceptions.

2. **Either-based return types** — Repository and service methods consistently return `Future<Either<Failure, T>>` using the `fpdart` library (`Either<Left, Right>`). Success paths return `Right(value)`; failure paths return `Left(Failure)`. This pattern is used across Drift repositories (`drift_habit_repository.dart`, `drift_challenge_repository.dart`, `drift_leaderboard_repository.dart`, `drift_tribe_repository.dart`, `drift_user_profile_repository.dart`) and deletion services (`deletion_service.dart`, `delete_account_backend.dart`).

3. **Centralized ErrorHandler** — The `ErrorHandler` static class provides:
   - `handleUIError(context, error, ...)` — logs via `AppLogger`, shows a SnackBar or AlertDialog with optional Retry action
   - `handleRepositoryError<T>(operation)` / `handleAsyncError<T>(operation)` — wraps try/catch blocks and returns `Either<Exception, T>`
   - `buildErrorWidget(message, onRetry)` — produces a reusable error widget
   - `handleNavigationError(context, message)` — navigates to `/world-map` on navigation failures
   - `handleAuthError(context, error, onSignOut)` — dedicated auth error dialog with Sign Out option

4. **AppErrorWidget** — A shared Flutter widget (`lib/core/presentation/widgets/app_error_widget.dart`) renders a consistent error screen with an icon, title, message, and optional "Try Again" button. It is consumed directly by many feature screens (social, habits, profile, pulse feed, etc.) as the error branch of async value builders.

5. **Presentation-layer convention** — Feature screens typically use `ValueListenableBuilder`/`Provider` patterns where the `error` callback returns `AppErrorWidget(...)`, keeping error display uniform across the app without ad-hoc dialogs per screen.

6. **Logging** — All error paths go through `AppLogger.e(...)` before user-facing handling, ensuring stack traces are captured for debugging while user messages remain localized.

7. **No global exception handler** — There is no top-level `FlutterError.onError` or `runZonedGuarded` wrapper visible in the scanned code; errors are handled locally at call sites via Either unwrapping or direct try/catch with `ErrorHandler` helpers.