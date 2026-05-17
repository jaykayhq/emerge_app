import 'package:emerge_app/core/drift/app_database.dart';

/// Creates a fresh in-memory [AppDatabase] for testing.
///
/// Each call returns a new isolated database instance.
/// Usage:
/// ```dart
/// final db = createTestDatabase();
/// // ... run tests ...
/// await db.close();
/// ```
AppDatabase createTestDatabase() {
  return AppDatabase.forTesting();
}
