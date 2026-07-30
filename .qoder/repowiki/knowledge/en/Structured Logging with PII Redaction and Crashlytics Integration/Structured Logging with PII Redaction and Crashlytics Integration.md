---
kind: logging_system
name: Structured Logging with PII Redaction and Crashlytics Integration
category: logging_system
scope:
    - '**'
source_files:
    - lib/core/utils/app_logger.dart
    - pubspec.yaml
---

The Emerge app uses a centralized, structured logging system built around the `logger` package (`^2.0.0`) with a custom `AppLogger` wrapper that enforces security, environment-aware output, and production telemetry.

**Framework and Core Implementation**
- The single source of truth is `lib/core/utils/app_logger.dart`, which defines the `AppLogger` static utility class.
- It wraps the `package:logger` `Logger` with a `PrettyPrinter` configured for concise console output (no method count, 5 error frames, 50 char line length, colored output, emojis, no timestamps).
- Production non-console output is routed to `firebase_crashlytics` via `FirebaseCrashlytics.instance.log()` and `recordError()`.

**Log Levels and Behavior**
- `d(message)` — Debug: only emitted when `kDebugMode` is true; never reaches production.
- `i(message)`, `w(message)` — Info/Warning: printed in debug mode; in production (non-web), sent to Crashlytics as log entries or non-fatal errors.
- `e(message, [error, stackTrace])` — Error: always visible in debug; in production, logged to Crashlytics with optional error/stacktrace recorded as non-fatal.
- `security(event, {context})` — Security events are always forwarded to Crashlytics in production and logged at warning level in debug.
- `networkRequest(method, url, {statusCode})` — Structured HTTP request logging with URL query-parameter redaction.
- `performance(operation, duration)` — Performance timing; emits debug logs for fast operations and warnings for slow ones (>1s).

**PII Redaction Policy**
Every log message passes through `_redactPii()`, which strips:
- Email addresses → `***@***.***`
- API tokens/keys (32+ alphanumeric strings) → `***REDACTED_TOKEN***`
- Credit card numbers (16 digits, with optional separators) → `****-****-****-****`
- Phone numbers (various formats) → `***-***-****`
- Firebase project IDs (`*.firebaseapp.com`) → `***.firebaseapp.com`
- Query parameters containing `token|key|password|api_key|access_token|secret` are stripped from URLs.

**Architecture and Conventions**
- All feature modules import `package:emerge_app/core/utils/app_logger.dart` and call `AppLogger.d/i/w/e/security/networkRequest/performance` rather than using `print()` or the raw `logger` package directly.
- The pattern is consistent across core services (config, deletion audit, drift repositories, notification service, remote config, social notifications, web updates, sync engine) and scripts.
- Some legacy `print()` calls remain in `core/services/notification_service.dart` for FCM debugging, but new code should use `AppLogger`.
- Crashlytics integration is guarded by `!kIsWeb` and `Firebase.apps.isNotEmpty` checks so it does not crash during tests or early initialization.

**Dependencies**
- `logger: ^2.0.0` — structured console logging with pretty printing.
- `firebase_crashlytics: ^5.1.5` — production error/telemetry sink.
- `firebase_core` — required for Crashlytics initialization.

**Constraints Observed**
- No direct `print()` usage is encouraged for new code; `AppLogger` methods are the enforced interface.
- Log messages must be safe to send to Crashlytics because they are automatically redacted.
- Web builds skip Crashlytics emission entirely (`!kIsWeb`).
- Errors passed to `e()` are recorded as non-fatal in Crashlytics, preserving application flow.